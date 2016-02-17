
__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from setuptools import setup, Extension, find_packages

###############################################################################
# src
_audio_src = ['pyxi/_pyxi/_audio/_audio.c', 'pyxi/_pyxi/src/audio.c', 
              'pyxi/_pyxi/src/gpio.c', 'pyxi/_pyxi/src/i2cps.c', 
              'pyxi/_pyxi/src/utils.c']

_video_src = ['pyxi/_pyxi/_video/_video.c', 'pyxi/_pyxi/_video/_capture.c', 
              'pyxi/_pyxi/_video/_display.c', 'pyxi/_pyxi/_video/_frame.c', 
              'pyxi/_pyxi/src/gpio.c', 'pyxi/_pyxi/src/py_xaxivdma.c', 
              'pyxi/_pyxi/src/py_xgpio.c', 'pyxi/_pyxi/src/utils_xlnk.c', 
              'pyxi/_pyxi/src/py_xvtc.c', 'pyxi/_pyxi/src/utils.c',  
              'pyxi/_pyxi/src/video_capture.c', 
              'pyxi/_pyxi/src/video_display.c']


###############################################################################
# BSP src
bsp_axivdma = \
  ['pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_0/src/xaxivdma.c',
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_0/src/xaxivdma_channel.c', 
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_0/src/xaxivdma_intr.c', 
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_0/src/xaxivdma_selftest.c']

bsp_gpio = \
  ['pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/gpio_v4_0/src/xgpio.c', 
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/gpio_v4_0/src/xgpio_extra.c',
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/gpio_v4_0/src/xgpio_intr.c',
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/gpio_v4_0/src/xgpio_selftest.c']

bsp_vtc = \
  ['pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/vtc_v7_0/src/xvtc.c', 
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/vtc_v7_0/src/xvtc_intr.c', 
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/vtc_v7_0/src/xvtc_selftest.c']

bsp_standalone = \
  ['pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/standalone_v5_2/src/xplatform_info.c',
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/standalone_v5_2/src/xil_assert.c',
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/standalone_v5_2/src/xil_io.c',
   'pyxi/_pyxi/bsp/ps7_cortexa9_0/libsrc/standalone_v5_2/src/xil_exception.c']
###############################################################################


# merge needed BSP src to _audio src
audio = []
audio.extend(bsp_standalone)
audio.extend(_audio_src)

# merge needed BSP src to _video src
video = []
video.extend(bsp_standalone)
video.extend(bsp_axivdma)
video.extend(bsp_gpio)
video.extend(bsp_vtc)
video.extend(_video_src)

setup(  name='pyxi',
        version='0.1',
        description='Python for Xilinx package',
        author='XilinxPythonProject',
        author_email='xpp_support@xilinx.com',
        url='https://github.com/Xilinx/Pyxi',
        packages = find_packages(),
        download_url = 'https://github.com/Xilinx/Pyxi',
        package_data = {
          '': ['test/*', 'tests/*'],
        },
        ext_modules = [
            Extension('pyxi.audio._audio', audio, 
                      include_dirs = ['pyxi/_pyxi/inc', 
                                      'pyxi/_pyxi/bsp/ps7_cortexa9_0/include'],
                     ),
            Extension('pyxi.video._video', video, 
                      include_dirs = ['pyxi/_pyxi/inc', 
                                      'pyxi/_pyxi/bsp/ps7_cortexa9_0/include'],
                     ),
        ]
    )
