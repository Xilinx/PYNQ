# Rebuild HLS IP from source
set current_dir [pwd]
cd ../../ip/hls/
# get list of IP from folder names
set ip [glob -types d *];
# Check and build each IP
foreach item $ip {
# Check if a zip file exists in ip directory (assume this to be packaged IP)
   if {[catch { glob -directory ${item}/solution1/impl/ip/ *.zip} zip_file]} {
      puts "Building $item IP"
      exec vivado_hls -f $item/script.tcl
   } else {
      puts "Skipping $item; IP already built"
   }
   unset zip_file
}
cd $current_dir
puts "HLS IP builds complete"