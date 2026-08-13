# Copyright (c) 2026, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#
# VCK190 Base Overlay Build (Segmented Configuration)
#
# Sources the golden reference design, adds PL logic (GPIO, DMA, BRAM, UART),
# then builds a PL PDI locked to the golden NoC solution.

overlay_name := base
design_name := base

GOLDEN_DIR := ../golden
GOLDEN_NCR := $(GOLDEN_DIR)/golden_noc.ncr
GOLDEN_DCP := $(GOLDEN_DIR)/golden_routed.dcp

all: $(GOLDEN_NCR) block_design pdi
	@echo
	@echo "Built $(overlay_name) for VCK190 (Segmented Configuration)"
	@echo "  XSA: $(overlay_name).xsa  (primary – contains PDI + HWH)"
	@echo "  PDI: $(overlay_name).pdi  (standalone PLD PDI)"
	@echo "  HWH: $(overlay_name).hwh  (standalone hardware handoff)"
	@echo

# The PL PDI is locked to the golden NoC solution, so the golden reference
# has to exist before the overlay is built.
$(GOLDEN_NCR):
	$(MAKE) -C $(GOLDEN_DIR)

golden: $(GOLDEN_NCR)

block_design:
	vivado -mode batch -source $(overlay_name).tcl -notrace

pdi:
	vivado -mode batch -source build_pdi.tcl -notrace

clean:
	rm -rf $(overlay_name) *.jou *.log NA .Xil .crashReporter *.pdi *.hwh *.xsa

.PHONY: all golden block_design pdi clean
