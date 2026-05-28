# Override machine compatibility restriction for RFSoC boards
# The build system only adds rfdc when RFSoC_boardname := 1 is set in the board spec
COMPATIBLE_MACHINE = ".*"
