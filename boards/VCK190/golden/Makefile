# Copyright (c) 2026, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#
# VCK190 Golden Reference Design Build

overlay_name := golden
design_name  := golden

all: block_design build
	@echo
	@echo "Golden reference built for VCK190 (Segmented Configuration)"
	@echo "  XSA:     $(overlay_name).xsa          (for EDF BOOT.BIN)"
	@echo "  NCR:     golden_noc.ncr               (NoC solution contract)"
	@echo "  DCP:     golden_routed.dcp             (for pr_verify)"
	@echo "  Boot:    golden_boot.pdi               (PS/DDR boot image)"
	@echo

block_design:
	vivado -mode batch -source golden_ref.tcl -notrace

build:
	vivado -mode batch -source build_golden.tcl -notrace

clean:
	rm -rf $(overlay_name) *.jou *.log NA .Xil .crashReporter
	rm -f *.pdi *.hwh *.xsa *.ncr *.dcp

.PHONY: all block_design build clean
