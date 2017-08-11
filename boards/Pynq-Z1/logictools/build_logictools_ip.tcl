# Rebuild Logictools HLS IP from source
set current_dir [pwd]
cd ../../ip/hls/
set ip [glob -types d *];
set item trace_cntrl
if {[file exist xilinx_com_{$item}_1_0.zip] == 0} {
   puts "Building $item IP"
   exec vivado_hls -f $item/script.tcl
} else {
   puts "$item IP already built"
}
cd $current_dir
puts "HLS IP builds complete"