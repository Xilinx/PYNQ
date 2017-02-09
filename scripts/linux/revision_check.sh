if grep -q "Release 2016_09_14" /home/xilinx/REVISION 
then
    echo ""
    echo "PYNQ Github Release v1.4"
    echo "This software is not backwards-compatible with a PYNQ SDCard v1.3 image."
    echo "Please upgrade SDCard image on www.pynq.io"
    echo ""
    exit 1
else
    exit 0
fi
