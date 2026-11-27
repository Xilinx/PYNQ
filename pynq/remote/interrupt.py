# Copyright (C) 2026 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause

import asyncio
import itertools
import queue
import threading
import weakref

import grpc

from . import remote_device_pb2 as protocol


def _complete(future, error):
    if not future.done():
        if error is None:
            future.set_result(None)
        else:
            future.set_exception(RuntimeError(error))


class _Source:
    def __init__(self, subscription, raw_irq, route):
        self.subscription = subscription
        self.raw_irq = raw_irq
        self.route = route
        self.references = 0
        self.sequence = 0
        self.acquired = False
        self.waiters = set()


class _InterruptSession:
    def __init__(self, stub):
        self.stub = stub
        self.generation = None
        self.lock = threading.Lock()
        self.requests = queue.Queue()
        self.sources = {}
        self.subscriptions = {}
        self.identifiers = itertools.count(1)
        self.error = None
        self.finalizer = None
        self.call = None
        self.state = stub.interrupt_state.future(
            protocol.InterruptStateRequest(), timeout=5
        )
        self.reader = threading.Thread(target=self._receive, daemon=True)
        self.reader.start()

    def _requests(self):
        while True:
            request = self.requests.get()
            if request is None:
                return
            request.generation = self.generation
            yield request

    def _send(self, operation, source):
        self.requests.put(protocol.InterruptRequest(
            operation=operation,
            subscription=source.subscription,
            sequence=source.sequence,
            raw_irq=source.raw_irq,
            route=[protocol.InterruptRoute(address=address, index=index)
                   for address, index in source.route],
        ))

    def retain(self, raw_irq, route):
        key = (raw_irq, tuple(route))
        with self.lock:
            if key not in self.sources:
                source = _Source(next(self.identifiers), raw_irq, route)
                self.sources[key] = source
                self.subscriptions[source.subscription] = source
            source = self.sources[key]
            source.references += 1
        return key

    def release(self, key):
        with self.lock:
            source = self.sources.get(key)
            if source is None:
                return
            source.references -= 1
            if source.references or source.waiters:
                return
            if source.acquired and self.error is None:
                self._send(protocol.InterruptRequest.RELEASE, source)
            del self.sources[key]
            del self.subscriptions[source.subscription]

    @staticmethod
    def _notify(source, error=None):
        waiters, source.waiters = source.waiters, set()
        for loop, future in waiters:
            try:
                loop.call_soon_threadsafe(_complete, future, error)
            except RuntimeError:
                if not loop.is_closed():
                    raise

    def _receive(self):
        message = "Remote interrupt connection closed; recreate the interrupt object"
        try:
            generation = self.state.result().generation
            with self.lock:
                if self.error is not None:
                    return
                self.generation = generation
                self.call = self.stub.interrupts(self._requests())
            for response in self.call:
                with self.lock:
                    source = self.subscriptions.get(response.subscription)
                    if source is None:
                        continue
                    if (response.event == protocol.InterruptResponse.ERROR
                            and response.sequence == source.sequence):
                        if source.acquired:
                            self._send(protocol.InterruptRequest.RELEASE, source)
                            source.acquired = False
                        self._notify(source, response.message)
                    elif (response.event == protocol.InterruptResponse.FIRED
                          and response.sequence == source.sequence):
                        self._notify(source)
        except grpc.FutureCancelledError:
            pass
        except grpc.RpcError as error:
            if self.generation is None:
                message = (
                    "The remote server does not support interrupts; update the remote image"
                    if error.code() == grpc.StatusCode.UNIMPLEMENTED else
                    "Cannot connect to the remote interrupt service"
                )
            else:
                message = (
                    "Remote interrupt connection lost or overlay changed; "
                    f"recreate the interrupt object ({error.code().name})"
                )
        finally:
            with self.lock:
                if self.error is None:
                    self.error = message
                for source in self.sources.values():
                    self._notify(source, self.error)
            self.requests.put(None)

    async def wait(self, key):
        loop = asyncio.get_running_loop()
        future = loop.create_future()
        waiter = (loop, future)
        with self.lock:
            source = self.sources[key]
            if self.error:
                raise RuntimeError(self.error)
            first = not source.waiters
            if first:
                source.sequence += 1
                if not source.acquired:
                    self._send(protocol.InterruptRequest.ACQUIRE, source)
                    source.acquired = True
            source.waiters.add(waiter)
            if first:
                self._send(protocol.InterruptRequest.ARM, source)
        try:
            await future
            if self.error:
                raise RuntimeError(self.error)
        finally:
            with self.lock:
                if waiter in source.waiters:
                    source.waiters.remove(waiter)
                    if not source.waiters and self.error is None:
                        self._send(protocol.InterruptRequest.CANCEL, source)

    def close(self):
        if self.finalizer is not None:
            self.finalizer.detach()
            self.finalizer = None
        with self.lock:
            self.error = "Remote interrupt connection closed; recreate the interrupt object"
            for source in self.sources.values():
                self._notify(source, self.error)
            call = self.call
        self.requests.put(None)
        self.state.cancel()
        if call is not None:
            call.cancel()
        if threading.current_thread() is not self.reader:
            self.reader.join(timeout=2)


class RemoteInterrupt:
    """Wait for a PL interrupt on a selected remote device."""

    def __init__(self, pinname, device=None):
        from pynq.interrupt import _metadata, _timestamp
        from pynq.pl_server.device import Device

        self.device = device if device is not None else Device.active_device
        metadata = _metadata(self.device)
        if pinname not in metadata.interrupt_pins:
            raise ValueError(f"No Pin of name {pinname} found")
        entry = metadata.interrupt_pins[pinname]
        route = []
        seen = set()
        while True:
            parent = entry.get("parent", entry.get("controller", ""))
            if not parent:
                raw_irq = entry["raw_irq"]
                break
            if parent in seen:
                raise ValueError("Cycle in interrupt controller metadata")
            seen.add(parent)
            route.append((metadata.ip_dict[parent]["phys_addr"], entry["index"]))
            entry = metadata.interrupt_controllers[parent]
        self._timestamp = _timestamp(self.device)
        session = getattr(self.device, "_remote_interrupt_session", None)
        if session is None or session.error is not None:
            if session is not None:
                session.close()
            session = _InterruptSession(self.device._stub["device"])
            self.device._remote_interrupt_session = session
            session.finalizer = weakref.finalize(self.device, session.close)
        self._session = session
        self._key = session.retain(raw_irq, route)
        weakref.finalize(self, session.release, self._key)

    async def wait(self):
        """Wait until the source is active; its driver must clear its status."""
        from pynq.interrupt import _timestamp

        if self._timestamp != _timestamp(self.device):
            raise RuntimeError("Interrupt invalidated by Overlay change")
        await self._session.wait(self._key)
        if self._timestamp != _timestamp(self.device):
            raise RuntimeError("Interrupt invalidated by Overlay change")
