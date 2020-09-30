overlay_name := logictools
design_name := logictools

all: hls_ip block_design bitstream check_timing
	@echo
	@tput setaf 2 ; echo "Built $(overlay_name) successfully!"; tput sgr0;
	@echo

hls_ip:
	vivado -mode batch -source build_ip.tcl -notrace

block_design:
	vivado -mode batch -source $(overlay_name).tcl -notrace

bitstream:
	vivado -mode batch -source build_bitstream.tcl -notrace

check_timing:
	vivado -mode batch -source check_timing.tcl -notrace

clean:
	rm -rf $(overlay_name) *.jou *.log NA .Xil
