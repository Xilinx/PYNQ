# OVERLAY SELECTION
# default overlay is 'pmod'. Change it to e.g 'audiovideo' when calling make 
# to compile MicroPython with another overlay (in the example, the audiovideo 
# overlay)
overlay = pmod

bitfile = ./$(overlay)/zybo_mipy/project_1.runs/impl_1/top.bit


all: 
	[ -f $(bitfile) ] && echo "Overlay exists - make clean if needed." || { cd $(overlay) ; vivado -mode batch -source ./zybo_mipy.tcl ; echo "Bitstream built" ; exit ; }

clean:
	@rm -rf ./$(overlay)/.Xil ./$(overlay)/zybo_mipy ./$(overlay)/*.mif \
	./$(overlay)/*.jou ./$(overlay)/*.log