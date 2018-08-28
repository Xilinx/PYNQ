overlay_name := base
design_name := base

all: hls_ip bitstream check_timing dsa
	@echo
	@tput setaf 2 ; echo "Built $(overlay_name) successfully!"; tput sgr0;
	@echo

hls_ip:
	vivado -mode batch -source build_$(overlay_name)_ip.tcl -notrace

bitstream:
	vivado -mode batch -source $(overlay_name).tcl -notrace

check_timing:
	vivado -mode batch -source check_$(overlay_name).tcl -notrace

dsa:
	vivado -mode batch -source build_$(overlay_name)_dsa.tcl -notrace
	unzip -qo $(overlay_name).dsa -d .dsa
	cp -rf .dsa/$(design_name).hwh ./$(overlay_name).hwh

clean:
	rm -rf $(overlay_name) *.jou *.log NA
	rm -rf .dsa
