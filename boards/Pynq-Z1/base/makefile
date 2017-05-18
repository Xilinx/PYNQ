all:
	cd ../../ip/hls/ && ./build_ip.sh
	vivado -mode batch -source base.tcl

clean:
	rm -rf base *.jou *.log
