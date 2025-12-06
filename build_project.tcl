puts "Building project $env(PROJECT_NAME)"
set PROJECT_NAME $env(PROJECT_NAME)

# start_gui
open_project project/project.xpr
reset_run impl_1

if { [file exists user.tcl] == 1} {
  source user.tcl
}

launch_runs impl_1 -to_step write_bitstream -jobs 6
wait_on_run impl_1
write_hw_platform -fixed -include_bit -force -file ./TOP_wrapper.xsa

