puts "Creating IP project $env(PROJECT_NAME) with FPGA part $env(FPGA_PARTNAME)"
set PROJECT_NAME $env(PROJECT_NAME)
set FPGA_PARTNAME $env(FPGA_PARTNAME)
set IP_DIR $env(IP_DIR)

create_project managed_ip_project [pwd]/$IP_DIR/managed_ip_project -part $FPGA_PARTNAME -ip
set_property target_language VHDL [current_project]
set_property target_simulator XSim [current_project]
set_property ip_repo_paths [pwd]/$IP_DIR [current_project]
update_ip_catalog
start_gui

