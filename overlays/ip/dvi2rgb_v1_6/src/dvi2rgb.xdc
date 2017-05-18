### Clock constraints ###
# Constrain TMDS clock to the 165 MHz maximum from DVI 1.0 specs
create_clock -period 6.060 [get_ports TMDS_Clk_p]

### I/O constraints ###
# group data channel IODELAYE2 cells with the IDELAYCTRL
set_property IODELAY_GROUP dvi2rgb_iodelay_grp [get_cells DataDecoders[*].DecoderX/InputSERDES_X/InputDelay]
set_property IODELAY_GROUP dvi2rgb_iodelay_grp [get_cells TMDS_ClockingX/IDelayCtrlX]

### Asynchronous clock domain crossings ###
set_false_path -through [get_pins -filter {NAME =~ */SyncAsync*/oSyncStages*/PRE || NAME =~ */SyncAsync*/oSyncStages*/CLR} -hier]
set_false_path -through [get_pins -filter {NAME =~ */SyncAsync*/oSyncStages_reg[0]/D} -hier]
set_false_path -through [get_pins -filter {NAME =~ */SyncBase*/iIn_q*/PRE || NAME =~ */SyncBase*/iIn_q*/CLR} -hier]
