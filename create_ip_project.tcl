puts "Creating IP project $env(PROJECT_NAME) with FPGA part $env(FPGA_PARTNAME)"
set PROJECT_NAME $env(PROJECT_NAME)
set FPGA_PARTNAME $env(FPGA_PARTNAME)

create_project managed_ip_project [pwd]/ip_lib/managed_ip_project -part $FPGA_PARTNAME -ip
set_property target_language VHDL [current_project]
set_property target_simulator XSim [current_project]
set_property ip_repo_paths [pwd]/ip_lib [current_project]
update_ip_catalog
start_gui

