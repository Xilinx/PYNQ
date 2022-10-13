# Copyright (c) 2022, Xilinx, Inc.
# SPDX-License-Identifier: BSD-3-Clause

from pynq import DefaultIP
from pynqutils.runtime.repr_dict import ReprDict
from threading import Thread, Event
from struct import Struct
import socket


class _DebugBridgeXVCServerThread(Thread):
    def __init__(self, dbridge, bufferLen=4096, serverAddress="0.0.0.0",
                 serverPort=2542, reconnect=True, verbose=True):
        Thread.__init__(self)

        self.dbridge = dbridge
        self.bufferLen = 4096

        self.dbridge = dbridge
        self.dbrf = self.dbridge.register_map
        self.mmio = self.dbridge.mmio

        # Bufflen in number of bytes
        self.xvcInfo = bytes(f"xvcServer_v1.0:{self.bufferLen}\n", 'UTF-8')
        self.tckval = 0

        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.reconnect = reconnect
        self.clientAddress = None
        self.clientSocket = None

        self._stopevent = Event()

        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

        self.verbose = verbose

    def _xvcServer(self):
        wordstruct = Struct('<L')

        def _sock_recvall(size):
            return self.clientSocket.recv(size, socket.MSG_WAITALL)

        def _sock_recvall_into(buf, size):
            return self.clientSocket.recv_into(buf, size, socket.MSG_WAITALL)

        def _sock_send(buf):
            return self.clientSocket.send(buf)

        def _word_unpack(buf):
            return wordstruct.unpack(buf)[0]

        # Use fixed buffer to reduce overhead
        tmsVec = bytearray(self.bufferLen)
        tmsView = memoryview(tmsVec)
        tdiVec = bytearray(self.bufferLen)
        tdiView = memoryview(tdiVec)
        tdoVec = bytearray(self.bufferLen)
        tdoView = memoryview(tdoVec)

        while not self._stopevent.isSet():
            msg = _sock_recvall(2).decode()

            if msg == 'ge':  # 'getinfo:'
                _sock_recvall(6)
                _sock_send(self.xvcInfo)
            elif msg == 'se':  # 'settck:<tck period>
                _sock_recvall(5)
                newtck = _sock_recvall(4)
                self.tckval = _word_unpack(newtck)
                _sock_send(newtck)
            elif msg == 'sh':  # 'shift:<num bits><tms vector><tdi vector>
                _sock_recvall(4)
                # Get required bit and word count
                numbits = _word_unpack(_sock_recvall(4))
                numbytes = (numbits + 7) // 8
                numwords = (numbytes + 3) // 4
                numpackbytes = numwords * 4
                # Receive data to be transmitted
                _sock_recvall_into(tmsVec, numbytes)
                _sock_recvall_into(tdiVec, numbytes)

                # Set default shift length
                # self.dbrf.LENGTH = 32
                self.mmio.write(0x00, 32)

                for i, ((tms,), (tdi,)) in enumerate(
                    zip(wordstruct.iter_unpack(tmsView[:numpackbytes]),
                        wordstruct.iter_unpack(tdiView[:numpackbytes]))
                ):
                    if i + 1 == numwords:
                        # Set final shift length
                        # self.dbrf.LENGTH = numbits % 32
                        self.mmio.write(0x00, numbits % 32)

                    # Write data
                    # MSBs of the last word won't be shifted
                    # self.dbrf.TMS_VECTOR = tms
                    self.mmio.write(0x04, tms)
                    # self.dbrf.TDI_VECTOR = tdi
                    self.mmio.write(0x08, tdi)

                    # Set enable
                    # self.dbrf.CTRL = 1
                    self.mmio.write(0x10, 0x01)

                    # Wait for finish
                    # while int(self.dbrf.CTRL) != 0:
                    while self.mmio.read(0x10) != 0:
                        pass

                    # Read and pack
                    # wordstruct.pack_into(tdoVec, i<<2,
                    #                       int(self.dbrf.TDO_VECTOR) )
                    wordstruct.pack_into(tdoVec, i << 2, self.mmio.read(0x0C))

                # Transmit result
                _sock_send(tdoView[:numbytes])
            elif not msg:
                break
            else:
                print(f"XVC Invalid cmd {msg}")
                break

    def run(self):
        self.server.bind((self.serverAddress, self.serverPort))
        if self.verbose:
            print("XVC server started")

        while not self._stopevent.isSet():
            self.server.listen(0)
            self.clientSocket, self.clientAddress = self.server.accept()

            if self._stopevent.isSet():
                break

            try:
                if self.verbose:
                    print(f"Connection from : {self.clientAddress}")
                self._xvcServer()
            except ConnectionResetError:
                if self.verbose:
                    print(f"Client at {self.clientAddress} "
                          "disconnected by exception...")
            except OSError:
                if self.verbose:
                    print(f"Client at {self.clientAddress} "
                          "disconnected by stop...")
            else:
                if self.verbose:
                    print(f"Client at {self.clientAddress} "
                          "disconnected...")
            finally:
                self.clientSocket.close()
                self.clientSocket = None

            if not self.reconnect:
                break

        self.server.close()
        if self.verbose:
            print("XVC server stopped")

    def stop(self, timeout=None):
        self._stopevent.set()
        if not self.clientSocket is None:
            self.clientSocket.close()
        else:
            # Workaround to stop a listening socket
            try:
                ubSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                ubSocket.setblocking(False)
                ubSocket.connect((self.serverAddress, self.serverPort))
            except:
                pass
        Thread.join(self, timeout)


class DebugBridge(DefaultIP):
    """Class for Interacting with the Debug Bridge in AXI -
    BSCAN and AXI - JTAG mode.

    Including a Python-based Xilinx Virtual Cable server for
    remote debugging with on-chip debuggers incuding ILAs and
    VIOs, or use the AXI - JTAG mode to debug another Xilinx
    device.

    The server could be controlled through `start_xvc_server`
    and `stop_xvc_server` methods.

    Note
    ----
    
    The server needs to be manually stopped before loading
    another overlay or the PS might halt.

    """

    def __init__(self, description):
        """Create an instance of the Debug Bridge Driver.
        Parameters
        ----------
        description : dict
            The entry in the IP dict describing the DMA engine
        """
        if type(description) is not ReprDict:
            raise RuntimeError('Description is not valid', str(description))

        # Insert register dict as they are not provided in the IP descriptor
        dbridge_registers = {
        'LENGTH': {
            'access': 'read-write',
            'address_offset': 0x00,
            'description': 'Shift Bit Length Register',
            'fields': {
                'length': {
                    'access': 'read-write',
                    'bit_offset': 0,
                    'bit_width': 6,
                    'description': 'Shift Bit Length Register'
                }
            },
            'size': 32
        },
        'TMS_VECTOR': {
            'access': 'read-write',
            'address_offset': 0x04,
            'description': 'Test Mode Select (TMS) Bit Vector',
            'fields': {
                'tms': {
                    'access': 'read-write',
                    'bit_offset': 0,
                    'bit_width': 32,
                    'description': 'Test Mode Select (TMS) Bit Vector'
                }
            },
            'size': 32
        },
        'TDI_VECTOR': {
            'access': 'read-write',
            'address_offset': 0x08,
            'description': 'Test Data In (TDI) Bit Vector',
            'fields': {
                'tdi': {
                    'access': 'read-write',
                    'bit_offset': 0,
                    'bit_width': 32,
                    'description': 'Test Data In (TDI) Bit Vector'
                }
            },
            'size': 32
        },
        'TDO_VECTOR': {
            'access': 'read',
            'address_offset': 0x0C,
            'description': 'Test Data Out (TDO) Bit Vector',
            'fields': {
                'tdo': {
                    'access': 'read',
                    'bit_offset': 0,
                    'bit_width': 32,
                    'description': 'Test Data Out (TDO) Bit Vector'
                }
            },
            'size': 32
        },
        'CTRL': {
            'access': 'read-write',
            'address_offset': 0x10,
            'description': 'Shift Control Register',
            'fields': {
                'en': {
                    'access': 'read-write',
                    'bit_offset': 0,
                    'bit_width': 1,
                    'description': 'Enable shift operation'
                },
                'loopback': {
                    'access': 'read-write',
                    'bit_offset': 1,
                    'bit_width': 1,
                    'description': 'Control bit to loopback TDI to TDO '
                                   'inside Debug Bridge IP'
                }
            },
            'size': 32
        }
        }
        
        description["registers"] = dbridge_registers
        
        super().__init__(description=description)
        self.description = description

        if 'parameters' not in description:
            raise RuntimeError('Unable to get parameters from description; '
                               'Users must use *.hwh files for overlays.')

        self.serverThread = None

    bindto = ['xilinx.com:ip:debug_bridge:3.0']

    def start_xvc_server(self, bufferLen=4096, serverAddress="0.0.0.0",
                         serverPort=2542, reconnect=True, verbose=True):
        """Start a XVC server and listen to the specified address and
        port for Vivado HW server to connect.

        Parameters
        ----------
        bufferLen: int
            The length of the buffer for XVC shift
            command in bytes

        serverAddress : str
            The address the XVC server listens to

        serverPort : int
            The port the XVC server listens to

        reconnect : bool
            If True, listen to the next connection when the
            previous client is disconnected or interrupted

        verbose : bool
            If True, print the conenction status
            of the XVC server
        """

        if self.serverThread:
            self.stop_xvc_server()

        self.serverThread = _DebugBridgeXVCServerThread(
            dbridge=self,
            bufferLen=bufferLen,
            serverAddress=serverAddress,
            serverPort=serverPort,
            reconnect=reconnect,
            verbose=verbose
        )
        self.serverThread.start()

    def stop_xvc_server(self):
        """Stop the running XVC server and disconnect active client.
        """
        self.serverThread.stop()
        self.serverThread = None

    def __del__(self):
        if self.serverThread:
            self.stop_xvc_server()
