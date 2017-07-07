set cur_dir [pwd]
open_hw_design ${cur_dir}/pynq.hdf
set_repo_path ${cur_dir}/device-tree-xlnx
create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
generate_target -dir pynq_dts
