
PYNQ_ROOT = ../../..


all:
	cd ${PYNQ_ROOT}/Zybo/vivado/ip/trace_ctrl_v1_0 ; vivado_hls solution1/script.tcl
	vivado -mode batch -source ${PYNQ_ROOT}/Zybo/bitstream/iop_trace.tcl


clean:
	rm -rf iop_trace* vivado* *.log