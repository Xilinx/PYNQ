### Clock constraints ###
# Constrain TMDS clock in the top-level project. Constraining it here, even if overridden in the top-level project
# results in [DRC 23-20] Rule violation (PDRC-34) for the maximum MMCM VCO frequency.
# create_clock -period 6.060 [get_ports TMDS_Clk_p]

### I/O constraints ###
# group data channel IODELAYE2 cells with the IDELAYCTRL
set_property IODELAY_GROUP dvi2rgb_iodelay_grp [get_cells DataDecoders[*].DecoderX/InputSERDES_X/InputDelay]
set_property IODELAY_GROUP dvi2rgb_iodelay_grp [get_cells TMDS_ClockingX/IDelayCtrlX]

### Asynchronous clock domain crossings ###
set_false_path -through [get_pins -filter {NAME =~ */SyncAsync*/oSyncStages*/PRE || NAME =~ */SyncAsync*/oSyncStages*/CLR} -hier]
set_false_path -through [get_pins -filter {NAME =~ */SyncAsync*/oSyncStages_reg[0]/D} -hier]
set_false_path -through [get_pins -filter {NAME =~ */SyncBase*/iIn_q*/PRE || NAME =~ */SyncBase*/iIn_q*/CLR} -hier]
