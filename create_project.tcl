puts "Creating project $env(PROJECT_NAME) with FPGA part $env(FPGA_PARTNAME)"
set PROJECT_DIR $env(PROJECT_DIR)
set PROJECT_NAME $env(PROJECT_NAME)
set FPGA_PARTNAME $env(FPGA_PARTNAME)
set IP_DIR $env(IP_DIR)
set BD_TCL_FILE $env(BD_TCL_FILE)

create_project $PROJECT_NAME $PROJECT_DIR -part $FPGA_PARTNAME -force
set_property target_language VHDL [current_project]
set_property ip_repo_paths $IP_DIR [current_project]
update_ip_catalog
source $BD_TCL_FILE

