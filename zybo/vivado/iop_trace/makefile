
PYNQ_ROOT = ../../..


all:
	vivado_hls ${PYNQ_ROOT}/zybo/vivado/ip/trace_ctrl_v1_0/solution1/script.tcl
	vivado -mode batch -source ${PYNQ_ROOT}/zybo/bitstream/iop_trace.tcl


clean:
	rm -rf iop_trace* vivado* *.log