"""Demo for HDMI(in) and VGA(out)"""

__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"

from pyxi.board import delay
from pyb import overlay

from pyxi.video.hdmi import HDMI
from pyxi.video.vga import VGA

def demo_hdmi_vga():
    """ HDMI-in and VGA-out, grayscale filter demo
    switch to audiovideo overlay - should be updated with conditional checks
    """
    print('Make sure HDMI and VGA already connected.')
    overlay().update("./overlay/audiovideo.bit.bin")
    
    vga = VGA('out')
    vga.mode(3) # 1280x720@60Hz
    hdmi = HDMI('in', vga.frame_buffer())
    vga.start()
    print("Loading ...")
    
    input('Hit enter when the un-filtered image is shown ...')
    index = vga.frame_index() 
    frame_width = vga.frame_width()
    frame_height = vga.frame_height()
    frame_raw = hdmi.frame_raw()
    hdmi.frame_index_next()
    vga.frame_raw(index, rgb2gray(frame_raw,frame_height,frame_width))
    
    print('Grayscale filter applied.')
    input("Hit enter to end this demo ...")
    vga.stop()
    overlay().update("./overlay/pmod.bit.bin")
    print('End of this demo ...') 

def rgb2gray(frame_raw, frame_height, frame_width):
    """convert a raw frame (a bytearray) to grayscale."""
    idx = 0
    for i in range(frame_height):
        for j in range(0, frame_width*3, 3):
            green = frame_raw[idx + 0]
            blue = frame_raw[idx + 1]
            red = frame_raw[idx + 2]
            gray = (red * 298 + green * 587 + blue * 114) >> 10
            frame_raw[idx + 0] = gray
            frame_raw[idx + 1] = gray
            frame_raw[idx + 2] = gray
            idx += 3
        idx += (1920 - frame_width)*3 # adjust to next row at 1920 boundary
    return frame_raw

if __name__ == "__main__":
    demo_hdmi_vga()