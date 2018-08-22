# Rebuild HLS IP from source
set current_dir [pwd]
cd ../../ip/hls/
# get list of IP from folder names
set ip {color_convert_2 pixel_pack_2 pixel_unpack_2}
# Check and build each IP
foreach item $ip {
   if {[catch { glob -directory ${item}/solution1/impl/ip/ *.zip} zip_file]} {
# Build IP only if a packaged IP does not exist
      puts "Building $item IP"
      exec vivado_hls -f $item/script.tcl
   } else {
# Skip IP when a packaged IP exists in ip directory
      puts "Skipping building $item"
   }
   unset zip_file
# Testing the built IP
   puts "Checking $item"
   set fd [open ${item}/solution1/syn/report/${item}_csynth.rpt r]
   set timing_flag 0
   set latency_flag 0
   while { [gets $fd line] >= 0 } {
# Check whether the timing has been met
    if [string match {+ Timing (ns): } $line]  { 
      set timing_flag 1
      set latency_flag 0
      continue
    }
    if {$timing_flag == 1} {
      if [regexp {[0-9]+} $line]  {
        set period [regexp -all -inline {[0-9]*\.[0-9]*} $line]
        lassign $period target estimated uncertainty
        if {$target < $estimated} {
            puts "ERROR: Estimated clock period $estimated > target $target."
            puts "ERROR: Revise $item to be compatible with Vivado_HLS."
            exit 1
        }
      }
    }
# Check whether the II has been met
    if [string match {+ Latency (clock cycles): } $line]  { 
      set timing_flag 0
      set latency_flag 1
      continue
    }
    if {$latency_flag == 1} {
      if [regexp {[0-9]+} $line]  {
        set interval [regexp -all -inline {[0-9]+} $line]
        lassign $interval l iteration achieved target
        if {$achieved != $target} {
            puts "ERROR: Achieved II $achieved != target $target for loop $l."
            puts "ERROR: Revise $item to be compatible with Vivado_HLS."
            exit 1
        }
      }
    }
# Testing ends
    if [string match {== Utilization Estimates} $line]  { 
       unset timing_flag latency_flag period interval
       break
    }
   }
   unset fd
}
cd $current_dir
puts "HLS IP builds complete"

