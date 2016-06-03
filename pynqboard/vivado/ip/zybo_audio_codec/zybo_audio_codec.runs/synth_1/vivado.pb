
[
 Attempting to get a license: %s
78*common2"
Implementation2default:defaultZ17-78
Q
Feature available: %s
81*common2"
Implementation2default:defaultZ17-81
É
+Loading parts and site information from %s
36*device2?
+C:/Xilinx/Vivado/2013.4/data/parts/arch.xml2default:defaultZ21-36
ê
!Parsing RTL primitives file [%s]
14*netlist2U
AC:/Xilinx/Vivado/2013.4/data/parts/xilinx/rtl/prims/rtl_prims.xml2default:defaultZ29-14
ô
*Finished parsing RTL primitives file [%s]
11*netlist2U
AC:/Xilinx/Vivado/2013.4/data/parts/xilinx/rtl/prims/rtl_prims.xml2default:defaultZ29-11
l
Command: %s
53*	vivadotcl2D
0synth_design -top i2s_ctrl -part xc7z010clg400-12default:defaultZ4-113
/

Starting synthesis...

3*	vivadotclZ4-3
ï
@Attempting to get a license for feature '%s' and/or device '%s'
308*common2
	Synthesis2default:default2
xc7z0102default:defaultZ17-347
Ö
0Got license for feature '%s' and/or device '%s'
310*common2
	Synthesis2default:default2
xc7z0102default:defaultZ17-349
ñ
%s*synth2Ü
rStarting Synthesize : Time (s): cpu = 00:00:04 ; elapsed = 00:00:05 . Memory (MB): peak = 232.309 ; gain = 85.730
2default:default
Ë
synthesizing module '%s'638*oasys2
i2s_ctrl2default:default2z
dC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/i2s_ctrl.vhd2default:default2
1742default:default8@Z8-638
_
%s*synth2P
<	Parameter C_S_AXI_DATA_WIDTH bound to: 32 - type: integer 
2default:default
_
%s*synth2P
<	Parameter C_S_AXI_ADDR_WIDTH bound to: 32 - type: integer 
2default:default
o
%s*synth2`
L	Parameter C_S_AXI_MIN_SIZE bound to: 32'b00000000000000000000000111111111 
2default:default
W
%s*synth2H
4	Parameter C_USE_WSTRB bound to: 0 - type: integer 
2default:default
\
%s*synth2M
9	Parameter C_DPHASE_TIMEOUT bound to: 8 - type: integer 
2default:default
i
%s*synth2Z
F	Parameter C_BASEADDR bound to: 32'b11111111111111111111111111111111 
2default:default
i
%s*synth2Z
F	Parameter C_HIGHADDR bound to: 32'b00000000000000000000000000000000 
2default:default
Y
%s*synth2J
6	Parameter C_FAMILY bound to: virtex6 - type: string 
2default:default
U
%s*synth2F
2	Parameter C_NUM_REG bound to: 1 - type: integer 
2default:default
U
%s*synth2F
2	Parameter C_NUM_MEM bound to: 1 - type: integer 
2default:default
Y
%s*synth2J
6	Parameter C_SLV_AWIDTH bound to: 32 - type: integer 
2default:default
Y
%s*synth2J
6	Parameter C_SLV_DWIDTH bound to: 32 - type: integer 
2default:default
ï
&Detected and applied attribute %s = %s3620*oasys2

max_fanout2default:default2
100002default:default2z
dC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/i2s_ctrl.vhd2default:default2
1402default:default8@Z8-4472
ï
&Detected and applied attribute %s = %s3620*oasys2

max_fanout2default:default2
100002default:default2z
dC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/i2s_ctrl.vhd2default:default2
1412default:default8@Z8-4472
Ú
synthesizing module '%s'638*oasys2!
axi_lite_ipif2default:default2
iC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/axi_lite_ipif.vhd2default:default2
2402default:default8@Z8-638
_
%s*synth2P
<	Parameter C_S_AXI_DATA_WIDTH bound to: 32 - type: integer 
2default:default
_
%s*synth2P
<	Parameter C_S_AXI_ADDR_WIDTH bound to: 32 - type: integer 
2default:default
^
%s*synth2O
;	Parameter C_S_AXI_MIN_SIZE bound to: 511 - type: integer 
2default:default
W
%s*synth2H
4	Parameter C_USE_WSTRB bound to: 0 - type: integer 
2default:default
\
%s*synth2M
9	Parameter C_DPHASE_TIMEOUT bound to: 8 - type: integer 
2default:default
ÿ
%s*synth2»
≥	Parameter C_ARD_ADDR_RANGE_ARRAY bound to: 128'b00000000000000000000000000000000111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000 
2default:default
q
%s*synth2b
N	Parameter C_ARD_NUM_CE_ARRAY bound to: 32'b00000000000000000000000000000101 
2default:default
Y
%s*synth2J
6	Parameter C_FAMILY bound to: virtex6 - type: string 
2default:default
˘
synthesizing module '%s'638*oasys2$
slave_attachment2default:default2Ç
lC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/slave_attachment.vhd2default:default2
2262default:default8@Z8-638
ÿ
%s*synth2»
≥	Parameter C_ARD_ADDR_RANGE_ARRAY bound to: 128'b00000000000000000000000000000000111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000 
2default:default
q
%s*synth2b
N	Parameter C_ARD_NUM_CE_ARRAY bound to: 32'b00000000000000000000000000000101 
2default:default
^
%s*synth2O
;	Parameter C_IPIF_ABUS_WIDTH bound to: 32 - type: integer 
2default:default
^
%s*synth2O
;	Parameter C_IPIF_DBUS_WIDTH bound to: 32 - type: integer 
2default:default
^
%s*synth2O
;	Parameter C_S_AXI_MIN_SIZE bound to: 511 - type: integer 
2default:default
W
%s*synth2H
4	Parameter C_USE_WSTRB bound to: 0 - type: integer 
2default:default
\
%s*synth2M
9	Parameter C_DPHASE_TIMEOUT bound to: 8 - type: integer 
2default:default
Y
%s*synth2J
6	Parameter C_FAMILY bound to: virtex6 - type: string 
2default:default
˜
synthesizing module '%s'638*oasys2#
address_decoder2default:default2Å
kC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/address_decoder.vhd2default:default2
1762default:default8@Z8-638
X
%s*synth2I
5	Parameter C_BUS_AWIDTH bound to: 9 - type: integer 
2default:default
^
%s*synth2O
;	Parameter C_S_AXI_MIN_SIZE bound to: 511 - type: integer 
2default:default
ÿ
%s*synth2»
≥	Parameter C_ARD_ADDR_RANGE_ARRAY bound to: 128'b00000000000000000000000000000000111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000 
2default:default
q
%s*synth2b
N	Parameter C_ARD_NUM_CE_ARRAY bound to: 32'b00000000000000000000000000000101 
2default:default
Z
%s*synth2K
7	Parameter C_FAMILY bound to: nofamily - type: string 
2default:default
Í
synthesizing module '%s'638*oasys2
	pselect_f2default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-638
P
%s*synth2A
-	Parameter C_AB bound to: 3 - type: integer 
2default:default
P
%s*synth2A
-	Parameter C_AW bound to: 3 - type: integer 
2default:default
F
%s*synth27
#	Parameter C_BAR bound to: 3'b000 
2default:default
Z
%s*synth2K
7	Parameter C_FAMILY bound to: nofamily - type: string 
2default:default
•
%done synthesizing module '%s' (%s#%s)256*oasys2
	pselect_f2default:default2
12default:default2
12default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-256
˙
synthesizing module '%s'638*oasys2-
pselect_f__parameterized02default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-638
P
%s*synth2A
-	Parameter C_AB bound to: 3 - type: integer 
2default:default
P
%s*synth2A
-	Parameter C_AW bound to: 3 - type: integer 
2default:default
F
%s*synth27
#	Parameter C_BAR bound to: 3'b001 
2default:default
Z
%s*synth2K
7	Parameter C_FAMILY bound to: nofamily - type: string 
2default:default
µ
%done synthesizing module '%s' (%s#%s)256*oasys2-
pselect_f__parameterized02default:default2
12default:default2
12default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-256
˙
synthesizing module '%s'638*oasys2-
pselect_f__parameterized12default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-638
P
%s*synth2A
-	Parameter C_AB bound to: 3 - type: integer 
2default:default
P
%s*synth2A
-	Parameter C_AW bound to: 3 - type: integer 
2default:default
F
%s*synth27
#	Parameter C_BAR bound to: 3'b010 
2default:default
Z
%s*synth2K
7	Parameter C_FAMILY bound to: nofamily - type: string 
2default:default
µ
%done synthesizing module '%s' (%s#%s)256*oasys2-
pselect_f__parameterized12default:default2
12default:default2
12default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-256
˙
synthesizing module '%s'638*oasys2-
pselect_f__parameterized22default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-638
P
%s*synth2A
-	Parameter C_AB bound to: 3 - type: integer 
2default:default
P
%s*synth2A
-	Parameter C_AW bound to: 3 - type: integer 
2default:default
F
%s*synth27
#	Parameter C_BAR bound to: 3'b011 
2default:default
Z
%s*synth2K
7	Parameter C_FAMILY bound to: nofamily - type: string 
2default:default
µ
%done synthesizing module '%s' (%s#%s)256*oasys2-
pselect_f__parameterized22default:default2
12default:default2
12default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-256
˙
synthesizing module '%s'638*oasys2-
pselect_f__parameterized32default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-638
P
%s*synth2A
-	Parameter C_AB bound to: 3 - type: integer 
2default:default
P
%s*synth2A
-	Parameter C_AW bound to: 3 - type: integer 
2default:default
F
%s*synth27
#	Parameter C_BAR bound to: 3'b100 
2default:default
Z
%s*synth2K
7	Parameter C_FAMILY bound to: nofamily - type: string 
2default:default
µ
%done synthesizing module '%s' (%s#%s)256*oasys2-
pselect_f__parameterized32default:default2
12default:default2
12default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/pselect_f.vhd2default:default2
1652default:default8@Z8-256
≤
%done synthesizing module '%s' (%s#%s)256*oasys2#
address_decoder2default:default2
22default:default2
12default:default2Å
kC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/address_decoder.vhd2default:default2
1762default:default8@Z8-256
÷
default block is never used226*oasys2Ç
lC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/slave_attachment.vhd2default:default2
3792default:default8@Z8-226
¥
%done synthesizing module '%s' (%s#%s)256*oasys2$
slave_attachment2default:default2
32default:default2
12default:default2Ç
lC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/slave_attachment.vhd2default:default2
2262default:default8@Z8-256
≠
%done synthesizing module '%s' (%s#%s)256*oasys2!
axi_lite_ipif2default:default2
42default:default2
12default:default2
iC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/axi_lite_ipif.vhd2default:default2
2402default:default8@Z8-256
Ï
synthesizing module '%s'638*oasys2

user_logic2default:default2|
fC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/user_logic.vhd2default:default2
1312default:default8@Z8-638
U
%s*synth2F
2	Parameter C_NUM_REG bound to: 5 - type: integer 
2default:default
Y
%s*synth2J
6	Parameter C_SLV_DWIDTH bound to: 32 - type: integer 
2default:default
Û
Hmodule '%s' declared at '%s:%s' bound to instance '%s' of component '%s'3392*oasys2
	iis_deser2default:default2y
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_deser.vhd2default:default2
242default:default2"
Inst_iis_deser2default:default2
	iis_deser2default:default2|
fC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/user_logic.vhd2default:default2
2062default:default8@Z8-3491
È
synthesizing module '%s'638*oasys2
	iis_deser2default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_deser.vhd2default:default2
352default:default8@Z8-638
Ô
found unpartitioned %s node3665*oasys2
	construct2default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_deser.vhd2default:default2
1272default:default8@Z8-4512
§
%done synthesizing module '%s' (%s#%s)256*oasys2
	iis_deser2default:default2
52default:default2
12default:default2{
eC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_deser.vhd2default:default2
352default:default8@Z8-256
Î
Hmodule '%s' declared at '%s:%s' bound to instance '%s' of component '%s'3392*oasys2
iis_ser2default:default2w
cC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_ser.vhd2default:default2
242default:default2 
Inst_iis_ser2default:default2
iis_ser2default:default2|
fC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/user_logic.vhd2default:default2
2272default:default8@Z8-3491
Â
synthesizing module '%s'638*oasys2
iis_ser2default:default2y
cC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_ser.vhd2default:default2
342default:default8@Z8-638
†
%done synthesizing module '%s' (%s#%s)256*oasys2
iis_ser2default:default2
62default:default2
12default:default2y
cC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_ser.vhd2default:default2
342default:default8@Z8-256
ß
%done synthesizing module '%s' (%s#%s)256*oasys2

user_logic2default:default2
72default:default2
12default:default2|
fC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/user_logic.vhd2default:default2
1312default:default8@Z8-256
£
%done synthesizing module '%s' (%s#%s)256*oasys2
i2s_ctrl2default:default2
82default:default2
12default:default2z
dC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/i2s_ctrl.vhd2default:default2
1742default:default8@Z8-256
ó
%s*synth2á
sFinished Synthesize : Time (s): cpu = 00:00:07 ; elapsed = 00:00:08 . Memory (MB): peak = 297.191 ; gain = 150.613
2default:default
ù
%s*synth2ç
yFinished RTL Optimization : Time (s): cpu = 00:00:07 ; elapsed = 00:00:09 . Memory (MB): peak = 297.191 ; gain = 150.613
2default:default
å
3inferred FSM for state register '%s' in module '%s'802*oasys2!
iis_state_reg2default:default2
	iis_deser2default:defaultZ8-802
ä
3inferred FSM for state register '%s' in module '%s'802*oasys2!
iis_state_reg2default:default2
iis_ser2default:defaultZ8-802
ø
Gencoded FSM with state register '%s' using encoding '%s' in module '%s'3353*oasys2!
iis_state_reg2default:default2
one-hot2default:default2
	iis_deser2default:defaultZ8-3354
Ω
Gencoded FSM with state register '%s' using encoding '%s' in module '%s'3353*oasys2!
iis_state_reg2default:default2
one-hot2default:default2
iis_ser2default:defaultZ8-3354
<
%s*synth2-

Report RTL Partitions: 
2default:default
N
%s*synth2?
++-+--------------+------------+----------+
2default:default
N
%s*synth2?
+| |RTL Partition |Replication |Instances |
2default:default
N
%s*synth2?
++-+--------------+------------+----------+
2default:default
N
%s*synth2?
++-+--------------+------------+----------+
2default:default
ñ
Loading clock regions from %s
13*device2_
KC:/Xilinx/Vivado/2013.4/data\parts/xilinx/zynq/zynq/xc7z010/ClockRegion.xml2default:defaultZ21-13
ó
Loading clock buffers from %s
11*device2`
LC:/Xilinx/Vivado/2013.4/data\parts/xilinx/zynq/zynq/xc7z010/ClockBuffers.xml2default:defaultZ21-11
ó
&Loading clock placement rules from %s
318*place2W
CC:/Xilinx/Vivado/2013.4/data/parts/xilinx/zynq/ClockPlacerRules.xml2default:defaultZ30-318
ï
)Loading package pin functions from %s...
17*device2S
?C:/Xilinx/Vivado/2013.4/data\parts/xilinx/zynq/PinFunctions.xml2default:defaultZ21-17
ì
Loading package from %s
16*device2b
NC:/Xilinx/Vivado/2013.4/data\parts/xilinx/zynq/zynq/xc7z010/clg400/Package.xml2default:defaultZ21-16
ä
Loading io standards from %s
15*device2T
@C:/Xilinx/Vivado/2013.4/data\./parts/xilinx/zynq/IOStandards.xml2default:defaultZ21-15
y
%s*synth2j
VPart Resources:
DSPs: 80 (col length:40)
BRAMs: 120 (col length: RAMB18 40 RAMB36 20)
2default:default
±
%s*synth2°
åFinished Loading Part and Timing Information : Time (s): cpu = 00:00:29 ; elapsed = 00:00:31 . Memory (MB): peak = 530.043 ; gain = 383.465
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
1
%s*synth2"
+---Adders : 
2default:default
Q
%s*synth2B
.	   2 Input     11 Bit       Adders := 1     
2default:default
Q
%s*synth2B
.	   2 Input      5 Bit       Adders := 2     
2default:default
Q
%s*synth2B
.	   2 Input      4 Bit       Adders := 1     
2default:default
4
%s*synth2%
+---Registers : 
2default:default
Q
%s*synth2B
.	               32 Bit    Registers := 5     
2default:default
Q
%s*synth2B
.	               24 Bit    Registers := 4     
2default:default
Q
%s*synth2B
.	               11 Bit    Registers := 1     
2default:default
Q
%s*synth2B
.	                5 Bit    Registers := 2     
2default:default
Q
%s*synth2B
.	                4 Bit    Registers := 1     
2default:default
Q
%s*synth2B
.	                2 Bit    Registers := 3     
2default:default
Q
%s*synth2B
.	                1 Bit    Registers := 16    
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   4 Input     32 Bit        Muxes := 2     
2default:default
Q
%s*synth2B
.	   6 Input     32 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   2 Input     32 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   2 Input     24 Bit        Muxes := 4     
2default:default
Q
%s*synth2B
.	   2 Input      9 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   7 Input      8 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   2 Input      8 Bit        Muxes := 6     
2default:default
Q
%s*synth2B
.	   2 Input      6 Bit        Muxes := 4     
2default:default
Q
%s*synth2B
.	   5 Input      6 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   8 Input      3 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   6 Input      3 Bit        Muxes := 2     
2default:default
Q
%s*synth2B
.	   2 Input      2 Bit        Muxes := 3     
2default:default
Q
%s*synth2B
.	   4 Input      2 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   4 Input      1 Bit        Muxes := 2     
2default:default
Q
%s*synth2B
.	   6 Input      1 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   8 Input      1 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 28    
2default:default
F
%s*synth27
#Hierarchical RTL Component report 
2default:default
4
%s*synth2%
Module i2s_ctrl 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
5
%s*synth2&
Module pselect_f 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 1     
2default:default
E
%s*synth26
"Module pselect_f__parameterized0 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 1     
2default:default
E
%s*synth26
"Module pselect_f__parameterized1 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 1     
2default:default
E
%s*synth26
"Module pselect_f__parameterized2 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 1     
2default:default
E
%s*synth26
"Module pselect_f__parameterized3 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 1     
2default:default
;
%s*synth2,
Module address_decoder 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
4
%s*synth2%
+---Registers : 
2default:default
Q
%s*synth2B
.	                1 Bit    Registers := 7     
2default:default
<
%s*synth2-
Module slave_attachment 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
1
%s*synth2"
+---Adders : 
2default:default
Q
%s*synth2B
.	   2 Input      4 Bit       Adders := 1     
2default:default
4
%s*synth2%
+---Registers : 
2default:default
Q
%s*synth2B
.	               32 Bit    Registers := 1     
2default:default
Q
%s*synth2B
.	                4 Bit    Registers := 1     
2default:default
Q
%s*synth2B
.	                2 Bit    Registers := 3     
2default:default
Q
%s*synth2B
.	                1 Bit    Registers := 3     
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input      9 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   4 Input      2 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   2 Input      2 Bit        Muxes := 3     
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 9     
2default:default
9
%s*synth2*
Module axi_lite_ipif 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
5
%s*synth2&
Module iis_deser 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
1
%s*synth2"
+---Adders : 
2default:default
Q
%s*synth2B
.	   2 Input      5 Bit       Adders := 1     
2default:default
4
%s*synth2%
+---Registers : 
2default:default
Q
%s*synth2B
.	               24 Bit    Registers := 2     
2default:default
Q
%s*synth2B
.	                5 Bit    Registers := 1     
2default:default
Q
%s*synth2B
.	                1 Bit    Registers := 2     
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input     24 Bit        Muxes := 2     
2default:default
Q
%s*synth2B
.	   2 Input      8 Bit        Muxes := 6     
2default:default
Q
%s*synth2B
.	   7 Input      8 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   8 Input      3 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   8 Input      1 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 6     
2default:default
3
%s*synth2$
Module iis_ser 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
1
%s*synth2"
+---Adders : 
2default:default
Q
%s*synth2B
.	   2 Input      5 Bit       Adders := 1     
2default:default
4
%s*synth2%
+---Registers : 
2default:default
Q
%s*synth2B
.	               24 Bit    Registers := 2     
2default:default
Q
%s*synth2B
.	                5 Bit    Registers := 1     
2default:default
Q
%s*synth2B
.	                1 Bit    Registers := 3     
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input     24 Bit        Muxes := 2     
2default:default
Q
%s*synth2B
.	   2 Input      6 Bit        Muxes := 4     
2default:default
Q
%s*synth2B
.	   5 Input      6 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   6 Input      3 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   6 Input      1 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   2 Input      1 Bit        Muxes := 8     
2default:default
6
%s*synth2'
Module user_logic 
2default:default
B
%s*synth23
Detailed RTL Component Info : 
2default:default
1
%s*synth2"
+---Adders : 
2default:default
Q
%s*synth2B
.	   2 Input     11 Bit       Adders := 1     
2default:default
4
%s*synth2%
+---Registers : 
2default:default
Q
%s*synth2B
.	               32 Bit    Registers := 4     
2default:default
Q
%s*synth2B
.	               11 Bit    Registers := 1     
2default:default
Q
%s*synth2B
.	                1 Bit    Registers := 1     
2default:default
0
%s*synth2!
+---Muxes : 
2default:default
Q
%s*synth2B
.	   2 Input     32 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   6 Input     32 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   4 Input     32 Bit        Muxes := 2     
2default:default
Q
%s*synth2B
.	   6 Input      3 Bit        Muxes := 1     
2default:default
Q
%s*synth2B
.	   4 Input      1 Bit        Muxes := 2     
2default:default
‚
ESequential element (%s) is unused and will be removed from module %s.3332*oasys2d
P\AXI_LITE_IPIF_I/I_SLAVE_ATTACHMENT/I_DECODER/MEM_DECODE_GEN[0].cs_out_i_reg[0] 2default:default2
i2s_ctrl2default:defaultZ8-3332
À
merging register '%s' into '%s'3619*oasys2:
&USER_LOGIC_I/Inst_iis_ser/lrclk_d1_reg2default:default2<
(USER_LOGIC_I/Inst_iis_deser/lrclk_d1_reg2default:default2y
cC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_ser.vhd2default:default2
632default:default8@Z8-4471
…
merging register '%s' into '%s'3619*oasys29
%USER_LOGIC_I/Inst_iis_ser/sclk_d1_reg2default:default2;
'USER_LOGIC_I/Inst_iis_deser/sclk_d1_reg2default:default2y
cC:/xup/hls/labs/lab4/zybo_audio_codec/zybo_audio_codec.srcs/sources_1/imports/i2s_audio/iis_ser.vhd2default:default2
622default:default8@Z8-4471
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[31]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[30]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[29]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[28]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[27]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[26]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[25]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[24]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[23]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[22]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[21]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[20]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[19]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[18]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[17]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[16]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[15]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[14]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[13]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[12]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[11]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_AWADDR[10]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_AWADDR[9]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_AWADDR[8]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_AWADDR[7]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_AWADDR[6]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_AWADDR[5]2default:defaultZ8-3331
|
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2"
S_AXI_WSTRB[3]2default:defaultZ8-3331
|
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2"
S_AXI_WSTRB[2]2default:defaultZ8-3331
|
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2"
S_AXI_WSTRB[1]2default:defaultZ8-3331
|
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2"
S_AXI_WSTRB[0]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[31]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[30]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[29]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[28]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[27]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[26]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[25]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[24]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[23]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[22]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[21]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[20]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[19]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[18]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[17]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[16]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[15]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[14]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[13]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[12]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[11]2default:defaultZ8-3331
~
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2$
S_AXI_ARADDR[10]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_ARADDR[9]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_ARADDR[8]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_ARADDR[7]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_ARADDR[6]2default:defaultZ8-3331
}
!design %s has unconnected port %s3331*oasys2
i2s_ctrl2default:default2#
S_AXI_ARADDR[5]2default:defaultZ8-3331
©
%s*synth2ô
ÑFinished Cross Boundary Optimization : Time (s): cpu = 00:00:29 ; elapsed = 00:00:31 . Memory (MB): peak = 539.734 ; gain = 393.156
2default:default
¢
%s*synth2í
~---------------------------------------------------------------------------------
Start RAM, DSP and Shift Register Reporting
2default:default
u
%s*synth2f
R---------------------------------------------------------------------------------
2default:default
¶
%s*synth2ñ
Å---------------------------------------------------------------------------------
Finished RAM, DSP and Shift Register Reporting
2default:default
u
%s*synth2f
R---------------------------------------------------------------------------------
2default:default
π
6propagating constant %s across sequential element (%s)3333*oasys2
02default:default2Q
=i_0/\USER_LOGIC_I/Inst_iis_deser/FSM_onehot_iis_state_reg[7] 2default:defaultZ8-3333
∑
6propagating constant %s across sequential element (%s)3333*oasys2
02default:default2O
;i_1/\USER_LOGIC_I/Inst_iis_ser/FSM_onehot_iis_state_reg[5] 2default:defaultZ8-3333
µ
6propagating constant %s across sequential element (%s)3333*oasys2
02default:default2M
9\AXI_LITE_IPIF_I/I_SLAVE_ATTACHMENT/s_axi_bresp_i_reg[1] 2default:defaultZ8-3333
µ
6propagating constant %s across sequential element (%s)3333*oasys2
02default:default2M
9\AXI_LITE_IPIF_I/I_SLAVE_ATTACHMENT/s_axi_rresp_i_reg[1] 2default:defaultZ8-3333
À
ESequential element (%s) is unused and will be removed from module %s.3332*oasys2M
9\USER_LOGIC_I/Inst_iis_deser/FSM_onehot_iis_state_reg[7] 2default:default2
i2s_ctrl2default:defaultZ8-3332
…
ESequential element (%s) is unused and will be removed from module %s.3332*oasys2K
7\USER_LOGIC_I/Inst_iis_ser/FSM_onehot_iis_state_reg[5] 2default:default2
i2s_ctrl2default:defaultZ8-3332
À
ESequential element (%s) is unused and will be removed from module %s.3332*oasys2M
9\AXI_LITE_IPIF_I/I_SLAVE_ATTACHMENT/s_axi_bresp_i_reg[1] 2default:default2
i2s_ctrl2default:defaultZ8-3332
À
ESequential element (%s) is unused and will be removed from module %s.3332*oasys2M
9\AXI_LITE_IPIF_I/I_SLAVE_ATTACHMENT/s_axi_bresp_i_reg[0] 2default:default2
i2s_ctrl2default:defaultZ8-3332
À
ESequential element (%s) is unused and will be removed from module %s.3332*oasys2M
9\AXI_LITE_IPIF_I/I_SLAVE_ATTACHMENT/s_axi_rresp_i_reg[1] 2default:default2
i2s_ctrl2default:defaultZ8-3332
À
ESequential element (%s) is unused and will be removed from module %s.3332*oasys2M
9\AXI_LITE_IPIF_I/I_SLAVE_ATTACHMENT/s_axi_rresp_i_reg[0] 2default:default2
i2s_ctrl2default:defaultZ8-3332
û
%s*synth2é
zFinished Area Optimization : Time (s): cpu = 00:00:30 ; elapsed = 00:00:32 . Memory (MB): peak = 570.086 ; gain = 423.508
2default:default
†
%s*synth2ê
|Finished Timing Optimization : Time (s): cpu = 00:00:30 ; elapsed = 00:00:32 . Memory (MB): peak = 570.086 ; gain = 423.508
2default:default
ü
%s*synth2è
{Finished Technology Mapping : Time (s): cpu = 00:00:30 ; elapsed = 00:00:32 . Memory (MB): peak = 570.086 ; gain = 423.508
2default:default
D
%s*synth25
!Gated Clock Conversion mode: off
2default:default
ô
%s*synth2â
uFinished IO Insertion : Time (s): cpu = 00:00:31 ; elapsed = 00:00:33 . Memory (MB): peak = 570.086 ; gain = 423.508
2default:default
;
%s*synth2,

Report Check Netlist: 
2default:default
l
%s*synth2]
I+------+------------------+-------+---------+-------+------------------+
2default:default
l
%s*synth2]
I|      |Item              |Errors |Warnings |Status |Description       |
2default:default
l
%s*synth2]
I+------+------------------+-------+---------+-------+------------------+
2default:default
l
%s*synth2]
I|1     |multi_driven_nets |      0|        0|Passed |Multi driven nets |
2default:default
l
%s*synth2]
I+------+------------------+-------+---------+-------+------------------+
2default:default
™
%s*synth2ö
ÖFinished Renaming Generated Instances : Time (s): cpu = 00:00:31 ; elapsed = 00:00:33 . Memory (MB): peak = 570.086 ; gain = 423.508
2default:default
ß
%s*synth2ó
ÇFinished Rebuilding User Hierarchy : Time (s): cpu = 00:00:31 ; elapsed = 00:00:33 . Memory (MB): peak = 570.086 ; gain = 423.508
2default:default
¢
%s*synth2í
~---------------------------------------------------------------------------------
Start RAM, DSP and Shift Register Reporting
2default:default
u
%s*synth2f
R---------------------------------------------------------------------------------
2default:default
¶
%s*synth2ñ
Å---------------------------------------------------------------------------------
Finished RAM, DSP and Shift Register Reporting
2default:default
u
%s*synth2f
R---------------------------------------------------------------------------------
2default:default
8
%s*synth2)

Report BlackBoxes: 
2default:default
A
%s*synth22
+-+--------------+----------+
2default:default
A
%s*synth22
| |BlackBox name |Instances |
2default:default
A
%s*synth22
+-+--------------+----------+
2default:default
A
%s*synth22
+-+--------------+----------+
2default:default
8
%s*synth2)

Report Cell Usage: 
2default:default
9
%s*synth2*
+------+-----+------+
2default:default
9
%s*synth2*
|      |Cell |Count |
2default:default
9
%s*synth2*
+------+-----+------+
2default:default
9
%s*synth2*
|1     |BUFG |     1|
2default:default
9
%s*synth2*
|2     |LUT1 |     5|
2default:default
9
%s*synth2*
|3     |LUT2 |    39|
2default:default
9
%s*synth2*
|4     |LUT3 |    55|
2default:default
9
%s*synth2*
|5     |LUT4 |    86|
2default:default
9
%s*synth2*
|6     |LUT5 |    18|
2default:default
9
%s*synth2*
|7     |LUT6 |    69|
2default:default
9
%s*synth2*
|8     |FDRE |   292|
2default:default
9
%s*synth2*
|9     |IBUF |    46|
2default:default
9
%s*synth2*
|10    |OBUF |    45|
2default:default
9
%s*synth2*
+------+-----+------+
2default:default
<
%s*synth2-

Report Instance Areas: 
2default:default
]
%s*synth2N
:+------+-----------------------+-----------------+------+
2default:default
]
%s*synth2N
:|      |Instance               |Module           |Cells |
2default:default
]
%s*synth2N
:+------+-----------------------+-----------------+------+
2default:default
]
%s*synth2N
:|1     |top                    |                 |   656|
2default:default
]
%s*synth2N
:|2     |  USER_LOGIC_I         |user_logic       |   456|
2default:default
]
%s*synth2N
:|3     |    Inst_iis_deser     |iis_deser        |    96|
2default:default
]
%s*synth2N
:|4     |    Inst_iis_ser       |iis_ser          |   128|
2default:default
]
%s*synth2N
:|5     |  AXI_LITE_IPIF_I      |axi_lite_ipif    |   108|
2default:default
]
%s*synth2N
:|6     |    I_SLAVE_ATTACHMENT |slave_attachment |   108|
2default:default
]
%s*synth2N
:|7     |      I_DECODER        |address_decoder  |    56|
2default:default
]
%s*synth2N
:+------+-----------------------+-----------------+------+
2default:default
¶
%s*synth2ñ
ÅFinished Writing Synthesis Report : Time (s): cpu = 00:00:31 ; elapsed = 00:00:33 . Memory (MB): peak = 570.086 ; gain = 423.508
2default:default
j
%s*synth2[
GSynthesis finished with 0 errors, 0 critical warnings and 65 warnings.
2default:default
£
%s*synth2ì
Synthesis Optimization Complete : Time (s): cpu = 00:00:31 ; elapsed = 00:00:33 . Memory (MB): peak = 570.086 ; gain = 423.508
2default:default
]
-Analyzing %s Unisim elements for replacement
17*netlist2
462default:defaultZ29-17
a
2Unisim Transformation completed in %s CPU seconds
28*netlist2
02default:defaultZ29-28
^
1Inserted %s IBUFs to IO ports without IO buffers.100*opt2
02default:defaultZ31-140
^
1Inserted %s OBUFs to IO ports without IO buffers.101*opt2
02default:defaultZ31-141
C
Pushed %s inverter(s).
98*opt2
02default:defaultZ31-138
|
MSuccessfully populated the BRAM INIT strings from the following elf files: %s96*memdata2
 2default:defaultZ28-144
u
!Unisim Transformation Summary:
%s111*project29
%No Unisim elements were transformed.
2default:defaultZ1-111
L
Releasing license: %s
83*common2
	Synthesis2default:defaultZ17-83
æ
G%s Infos, %s Warnings, %s Critical Warnings and %s Errors encountered.
28*	vivadotcl2
492default:default2
652default:default2
02default:default2
02default:defaultZ4-41
U
%s completed successfully
29*	vivadotcl2 
synth_design2default:defaultZ4-42
¸
I%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s
268*common2"
synth_design: 2default:default2
00:00:442default:default2
00:00:462default:default2
944.9692default:default2
759.6722default:defaultZ17-268
<
%Done setting XDC timing constraints.
35*timingZ38-35

sreport_utilization: Time (s): cpu = 00:00:00 ; elapsed = 00:00:00.057 . Memory (MB): peak = 944.969 ; gain = 0.000
*common
w
Exiting %s at %s...
206*common2
Vivado2default:default2,
Wed Feb 05 14:45:31 20142default:defaultZ17-206