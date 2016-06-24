
PYNQ_ROOT = ../../..


all:
	vivado_hls trace_ip/solution1/script.tcl
	vivado -mode batch -source ${PYNQ_ROOT}/python/pynq/bitstream/pmod.trace.tcl 


clean:
	rm -rf pmod* vivado* *.log