# License

__author__      = "David McCoy"
__copyright__   = "Copyright 2017, Cospan Design"
__email__       = "dave.mccoy@cospandesign.com"


from time import sleep
import pytest
from pynq import Overlay
from pynq.drivers import VDMA
from random import randint
import numpy as np

BITFILE_NAME = "/home/xilinx/jupyter_notebooks/bits/simple_vdma.bit"
EGRESS_VDMA_NAME = "SEG_axi_vdma_0_Reg"
INGRESS_VDMA_NAME = "SEG_axi_vdma_1_Reg"

DEBUG = True
#DEBUG = False

IMAGE_WIDTH = 1280
IMAGE_HEIGHT = 720

def test_vdma_config():
    ol = Overlay(BITFILE_NAME)
    ol.download()

    print ("")
    vdma = VDMA(name = EGRESS_VDMA_NAME, debug = DEBUG)
    major, minor, revision = vdma.get_version()
    print ("Version: %d.%d Rev: %d" % (major, minor, revision))

def test_vdma_read_status():
    ol = Overlay(BITFILE_NAME)
    ol.download()

    print ("")
    vdma = VDMA(name = EGRESS_VDMA_NAME, debug = DEBUG)
    print ("Is Egress  Enabled: %s" % vdma.is_egress_enabled())
    print ("Is Ingress Enabled: %s" % vdma.is_ingress_enabled())
    vdma.set_image_size(IMAGE_WIDTH, IMAGE_HEIGHT)

def test_vdma_egress_ingress_transfer():
    ol = Overlay(BITFILE_NAME)
    ol.download()

    """
    These can be set between 0 - 2, the VDMA can also be configured for up to
    32 frames in 32-bit memspace and 16 in 64-bit memspace
    """
    EGRESS_FRAME_INDEX  = 0
    INGRESS_FRAME_INDEX = 0

    #Create a really small image
    image_width = 100
    image_height = 100
    color_depth = 3

    image_in = \
        np.zeros((image_height, image_width, color_depth)).astype(np.uint8)
    i = 0
    for y in range(image_height):
        for x in range(image_width):
            for p in range(color_depth):
                #image_in[y, x, p] = randint(0, 255)
                image_in[y, x, p] = i
                if i < 255:
                    i += 1
                else:
                    i = 0



    print ("")
    vdma_egress  = VDMA(name = EGRESS_VDMA_NAME,  debug = DEBUG)
    vdma_ingress = VDMA(name = INGRESS_VDMA_NAME, debug = DEBUG)

    #1. Set the size of the image
    vdma_egress.set_image_size( image_width, image_height)
    vdma_ingress.set_image_size(image_width, image_height)

    egress_frame = vdma_egress.get_frame(EGRESS_FRAME_INDEX)
    egress_frame.set_bytearray(bytearray(image_in.astype(np.int8).tobytes()))




    #Quick Start
    vdma_ingress.start_ingress_engine(  continuous  = False,
                                        num_frames  = 1,
                                        frame_index = INGRESS_FRAME_INDEX,
                                        interrupt   = False)

    running = vdma_ingress.is_ingress_enabled()


    vdma_egress.start_egress_engine(    continuous  = False,
                                        num_frames  = 1,
                                        frame_index = EGRESS_FRAME_INDEX,
                                        interrupt   = False)


    #Determine if the engine is running
    running = vdma_egress.is_egress_enabled()
    print ("Egress Engine is running: %s" % running)

    sleep(0.10)

    print ("Egress WIP: %d" %  vdma_egress.get_wip_egress_frame()  )
    print ("Ingress WIP: %d" % vdma_ingress.get_wip_ingress_frame())

    print ("Ingress Engine is running: %s" % running)
    vdma_egress.stop_egress_engine()
    vdma_ingress.stop_ingress_engine()

    running = vdma_egress.is_egress_enabled()
    print ("Egress Engine is running: %s" % running)
    ingress_frame = vdma_ingress.get_frame(INGRESS_FRAME_INDEX)
    image_out = np.ndarray(  shape = (image_height, image_width, color_depth),
                             dtype=np.uint8,
                             buffer = ingress_frame.get_bytearray())
                             #buffer = egress_frame.get_bytearray())

    for y in range(image_height):
        for x in range(image_width):
            for p in range(color_depth):
                if image_in[y, x, p] != image_out[y, x, p]:
                    print ("[%d, %d]: %d %d %d != %d %d %d" % (y, x,
                                                         image_in[y, x, 0],
                                                         image_in[y, x, 1],
                                                         image_in[y, x, 2],

                                                         image_out[y, x, 0],
                                                         image_out[y, x, 1],
                                                         image_out[y, x, 2]))

                    print ("IN:")
                    print (image_in)
                    print ("OUT:")
                    print (image_out)
                    assert False

