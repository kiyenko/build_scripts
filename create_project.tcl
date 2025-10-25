puts "Creating project $env(PROJECT_NAME) with FPGA part $env(FPGA_PARTNAME)"
set PROJECT_NAME $env(PROJECT_NAME)
set FPGA_PARTNAME $env(FPGA_PARTNAME)

create_project project project -part $FPGA_PARTNAME -force
set_property target_language VHDL [current_project]
set_property  ip_repo_paths  ip_lib [current_project]
update_ip_catalog
source project/TOP.tcl
# start_gui
make_wrapper -files [get_files [pwd]/project/project.srcs/sources_1/bd/TOP/TOP.bd] -top
add_files -norecurse [pwd]/project/project.srcs/sources_1/bd/TOP/hdl/TOP_wrapper.vhd
add_files -fileset constrs_1 -scan_for_includes [ glob -nocomplain [pwd]/constraints/*.xdc  ]
update_compile_order -fileset sources_1
#source add_simulation_sources.tcl
#add_files -fileset sim_1 -norecurse [pwd]/project_$PROJECT_NAME/tb_behav.wcfg
#set_property xsim.view [pwd]/project_$PROJECT_NAME/tb_behav1.wcfg [get_filesets sim_1]
