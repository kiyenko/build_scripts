puts "Programming project $env(PROJECT_NAME)"
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set_property PROGRAM.FILE {project/project.runs/impl_1/TOP_wrapper.bit} [get_hw_devices $env(FPGA_DEV)_1]
set_property PROBES.FILE {project/project.runs/impl_1/TOP_wrapper.ltx} [get_hw_devices $env(FPGA_DEV)_1]
set_property FULL_PROBES.FILE {project/project.runs/impl_1/TOP_wrapper.ltx} [get_hw_devices $env(FPGA_DEV)_1]
current_hw_device [get_hw_devices $env(FPGA_DEV)_1]
refresh_hw_device [lindex [get_hw_devices $env(FPGA_DEV)_1] 0]
