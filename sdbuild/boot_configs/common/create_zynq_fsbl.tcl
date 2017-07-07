set cur_dir [pwd]
set hwdesign [open_hw_design "${cur_dir}/pynq.hdf"]
generate_app -hw $hwdesign -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir ${cur_dir}/fsbl
