proc gen_include_files {swproj mhsinst} {
  set inc_file_lines ""

  if {$swproj == 0} {
    return ""
  }
  if {$swproj == 1} {
    return "mailbox_io.h"
  }
}

proc generate {drv_handle} {

}
