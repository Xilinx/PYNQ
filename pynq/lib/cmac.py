# Copyright (C) 2021 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import time

from pynq import DefaultIP



class CMAC(DefaultIP):
    """Driver for the UltraScale+ Integrated 100 Gigabit Ethernet Subsystem."""

    def __init__(self, description):
        cmac_registers = {
            "gt_reset_reg": {
                "address_offset": 0,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 0,
                "memory": "dc_2",
            },
            "reset_reg": {
                "address_offset": 4,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 1,
            },
            "conf_tx": {
                "address_offset": 12,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 3,
            },
            "conf_rx": {
                "address_offset": 20,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 4,
            },
            "core_mode": {
                "address_offset": 32,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 5,
            },
            "version": {
                "address_offset": 36,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 6,
            },
            "gt_loopback": {
                "address_offset": 144,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 7,
            },
            "stat_tx_status": {
                "address_offset": 512,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 8,
            },
            "stat_rx_status": {
                "address_offset": 516,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 9,
            },
            "stat_status": {
                "address_offset": 520,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 10,
            },
            "stat_rx_block_lock": {
                "address_offset": 524,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 11,
            },
            "stat_rx_lane_sync": {
                "address_offset": 528,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 12,
            },
            "stat_rx_lane_sync_err": {
                "address_offset": 532,
                "access": "read-write;",
                "size": 32,
                "host_size": 4,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 13,
            },
            "stat_cycle_count": {
                "address_offset": 696,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 17,
            },
            "stat_tx_total_packets": {
                "address_offset": 1280,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 18,
            },
            "stat_tx_total_good_packets": {
                "address_offset": 1288,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 19,
            },
            "stat_tx_total_bytes": {
                "address_offset": 1296,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 20,
            },
            "stat_tx_total_good_bytes": {
                "address_offset": 1304,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 21,
            },
            "stat_tx_total_packets_64B": {
                "address_offset": 1312,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 22,
            },
            "stat_tx_total_packets_65_127B": {
                "address_offset": 1320,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 23,
            },
            "stat_tx_total_packets_128_255B": {
                "address_offset": 1328,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 24,
            },
            "stat_tx_total_packets_256_511B": {
                "address_offset": 1336,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 25,
            },
            "stat_tx_total_packets_512_1023B": {
                "address_offset": 1344,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 26,
            },
            "stat_tx_total_packets_1024_1518B": {
                "address_offset": 1352,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 27,
            },
            "stat_tx_total_packets_1519_1522B": {
                "address_offset": 1360,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 28,
            },
            "stat_tx_total_packets_1523_1548B": {
                "address_offset": 1368,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 29,
            },
            "stat_tx_total_packets_1549_2047B": {
                "address_offset": 1376,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 30,
            },
            "stat_tx_total_packets_2048_4095B": {
                "address_offset": 1384,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 31,
            },
            "stat_tx_total_packets_4096_8191B": {
                "address_offset": 1392,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 32,
            },
            "stat_tx_total_packets_8192_9215B": {
                "address_offset": 1400,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 33,
            },
            "stat_tx_total_packets_large": {
                "address_offset": 1408,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 34,
            },
            "stat_tx_total_packets_small": {
                "address_offset": 1416,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 35,
            },
            "stat_tx_total_bad_fcs": {
                "address_offset": 1464,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 36,
            },
            "stat_tx_pause": {
                "address_offset": 1520,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 37,
            },
            "stat_tx_user_pause": {
                "address_offset": 1528,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 38,
            },
            "stat_rx_total_packets": {
                "address_offset": 1544,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 39,
            },
            "stat_rx_total_good_packets": {
                "address_offset": 1552,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 40,
            },
            "stat_rx_total_bytes": {
                "address_offset": 1560,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 41,
            },
            "stat_rx_total_good_bytes": {
                "address_offset": 1568,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 42,
            },
            "stat_rx_total_packets_64B": {
                "address_offset": 1576,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 43,
            },
            "stat_rx_total_packets_65_127B": {
                "address_offset": 1584,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 44,
            },
            "stat_rx_total_packets_128_255B": {
                "address_offset": 1592,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 45,
            },
            "stat_rx_total_packets_256_511B": {
                "address_offset": 1600,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 46,
            },
            "stat_rx_total_packets_512_1023B": {
                "address_offset": 1608,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 47,
            },
            "stat_rx_total_packets_1024_1518B": {
                "address_offset": 1616,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 48,
            },
            "stat_rx_total_packets_1519_1522B": {
                "address_offset": 1624,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 49,
            },
            "stat_rx_total_packets_1523_1548B": {
                "address_offset": 1632,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 50,
            },
            "stat_rx_total_packets_1549_2047B": {
                "address_offset": 1640,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 51,
            },
            "stat_rx_total_packets_2048_4095B": {
                "address_offset": 1648,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 52,
            },
            "stat_rx_total_packets_4096_8191B": {
                "address_offset": 1656,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 53,
            },
            "stat_rx_total_packets_8192_9215B": {
                "address_offset": 1664,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 54,
            },
            "stat_rx_total_packets_large": {
                "address_offset": 1672,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 55,
            },
            "stat_rx_total_packets_small": {
                "address_offset": 1680,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 56,
            },
            "stat_rx_total_packets_undersize": {
                "address_offset": 1688,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 57,
            },
            "stat_rx_total_packets_fragmented": {
                "address_offset": 1696,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 58,
            },
            "stat_rx_total_packets_oversize": {
                "address_offset": 1704,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 59,
            },
            "stat_rx_total_packets_toolong": {
                "address_offset": 1712,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 60,
            },
            "stat_rx_total_packets_jabber": {
                "address_offset": 1720,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 61,
            },
            "stat_rx_total_bad_fcs": {
                "address_offset": 1728,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 62,
            },
            "stat_rx_packets_bad_fcs": {
                "address_offset": 1736,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 63,
            },
            "stat_rx_stomped_fcs": {
                "address_offset": 1744,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 64,
            },
            "stat_rx_pause": {
                "address_offset": 1784,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 65,
            },
            "stat_rx_user_pause": {
                "address_offset": 1792,
                "access": "read-write;",
                "size": 64,
                "host_size": 8,
                "description": "OpenCL Argument Register",
                "type": "uint",
                "id": 66,
            },
        }
        description["registers"] = cmac_registers
        super().__init__(description=description)

    bindto = ["xilinx.com:ip:cmac_usplus:3.1"]

    def start(self):
        """Run core bring-up sequence."""
        self.register_map.conf_rx = 1
        self.register_map.conf_tx = 0x10
        for _ in range(5):
            time.sleep(0.1)
            if self.register_map.stat_rx_status[1]:
                self.register_map.conf_tx = 1
                return
        raise RuntimeError("Receive channel not aligned")

    @property
    def internal_loopback(self):
        """True if CMAC near-end PMA loopback is enabled."""
        return self.register_map.gt_loopback

    @internal_loopback.setter
    def internal_loopback(self, mode):
        self.register_map.gt_loopback = int(bool(mode))

    def reset(self, tx=0, rx=0, gt=1):
        """Reset transmit path, receive path, or gigabit transceivers (full core).

        Parameters
        ----------
        tx: bool
            Reset transmit path.
        rx: bool
            Reset receive path.
        gt: bool
            Reset GTs.

        """
        if tx:
            self.register_map.reset_reg[30] = 1
            self.register_map.reset_reg[30] = 0
        if rx:
            self.register_map.reset_reg[31] = 1
            self.register_map.reset_reg[31] = 0
        if gt:
            self.register_map.gt_reset_reg[0] = 1
        return

    def copyStats(self) -> None:
        """Triggers a snapshot of CMAC Statistics
        Triggers a snapshot of all the Statistics counters into their
        readable register. The bit self-clears.
        """
        self.write(0x02B0, 1)

    def getStats(self, update_reg: bool = True) -> dict:
        """Return a dictionary with the CMAC stats
        Parameters
        ----------
        debug: bool
        if enabled, the CMAC registers are copied from internal counters
        Returns
        -------
        A dictionary with the CMAC statistics
        """
        if update_reg:
            self.copyStats()

        rmap = self.register_map
        stats_dict = dict()
        stats_dict["tx"] = dict()
        stats_dict["rx"] = dict()
        stats_dict["cycle_count"] = int(rmap.stat_cycle_count)
        # Tx
        stats_dict["tx"] = {
            "packets": int(rmap.stat_tx_total_packets),
            "good_packets": int(rmap.stat_tx_total_good_packets),
            "bytes": int(rmap.stat_tx_total_bytes),
            "good_bytes": int(rmap.stat_tx_total_good_bytes),
            "packets_large": int(rmap.stat_tx_total_packets_large),
            "packets_small": int(rmap.stat_tx_total_packets_small),
            "bad_fcs": int(rmap.stat_tx_total_bad_fcs),
            "pause": int(rmap.stat_tx_pause),
            "user_pause": int(rmap.stat_tx_user_pause),
        }

        stats_dict["rx"] = {
            "packets": int(rmap.stat_rx_total_packets),
            "good_packets": int(rmap.stat_rx_total_good_packets),
            "bytes": int(rmap.stat_rx_total_bytes),
            "good_bytes": int(rmap.stat_rx_total_good_bytes),
            "packets_large": int(rmap.stat_rx_total_packets_large),
            "packets_small": int(rmap.stat_rx_total_packets_small),
            "packets_undersize": int(rmap.stat_rx_total_packets_undersize),
            "packets_fragmented": int(rmap.stat_rx_total_packets_fragmented),
            "packets_oversize": int(rmap.stat_rx_total_packets_oversize),
            "packets_toolong": int(rmap.stat_rx_total_packets_toolong),
            "packets_jabber": int(rmap.stat_rx_total_packets_jabber),
            "bad_fcs": int(rmap.stat_rx_total_bad_fcs),
            "packets_bad_fcs": int(rmap.stat_rx_packets_bad_fcs),
            "stomped_fcs": int(rmap.stat_rx_stomped_fcs),
            "pause": int(rmap.stat_rx_pause),
            "user_pause": int(rmap.stat_rx_user_pause),
        }
        return stats_dict

