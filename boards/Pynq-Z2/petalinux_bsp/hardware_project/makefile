overlay_name := pynqz2
design_name := pynqz2

all: block_design bitstream
	@echo
	@tput setaf 2 ; echo "Built $(overlay_name) successfully!"; tput sgr0;
	@echo

block_design:
	vivado -mode batch -source $(overlay_name).tcl -notrace

bitstream:
	vivado -mode batch -source build_bitstream.tcl -notrace

clean:
	rm -rf $(overlay_name) *.jou *.log NA .Xil
