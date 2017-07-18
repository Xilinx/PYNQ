
all:
	cd ../../ip/hls/ && ./build_ip.sh
	vivado -mode batch -source interface.tcl

clean:
	rm -rf interface *.jou *.log
