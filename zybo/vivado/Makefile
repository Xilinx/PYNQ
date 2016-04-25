# OVERLAY SELECTION
# default overlay is 'pmod'.
overlay = pmod

bitfile = ./$(overlay)/zybo/project_1.runs/impl_1/top.bit


all: 
	[ -f $(bitfile) ] && echo "Overlay exists - make clean if needed." || { cd $(overlay) ; make ; echo "Bitstream built" ; exit ; }

clean:
	@rm -rf ./$(overlay)/.Xil ./$(overlay)/zybo ./$(overlay)/*.mif \
	./$(overlay)/*.jou ./$(overlay)/*.log
