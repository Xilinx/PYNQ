set overlay_name "pynqz2"
set design_name "pynqz2"

# Add top wrapper, no xdc files
make_wrapper -files [get_files ./${overlay_name}/${overlay_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ./${overlay_name}/${overlay_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v
set_property top ${design_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

# call implement
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# This hardware definition file will be used for microblaze projects
file mkdir ./${overlay_name}/${overlay_name}.sdk
write_hwdef -force  -file ./${overlay_name}/${overlay_name}.sdk/${overlay_name}.hdf
file copy -force ./${overlay_name}/${overlay_name}.sdk/${overlay_name}.hdf .

# move and rename bitstream to final location
file copy -force ./${overlay_name}/${overlay_name}.runs/impl_1/${design_name}_wrapper.bit ${overlay_name}.bit
