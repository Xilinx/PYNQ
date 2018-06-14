export ESW_LIBS := v_hdmi_common v_hdmirxss v_hdmirx v_hdmitxss v_hdmitx video_common vphy vtc
export LIB_NAME := _xhdmi/libxhdmi.so

export SRC := $(patsubst %, _xhdmi/%, $(wildcard *.c))

all:
	make -C .. -f embeddedsw_lib.mk
