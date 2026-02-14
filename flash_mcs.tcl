puts "Programming Flash $env(PROJECT_NAME)"
open_hw_manager
connect_hw_server   -allow_non_jtag

open_hw_target
current_hw_device   [ get_hw_devices $env(FPGA_DEV)_0 ]
set hw_device       [ lindex [get_hw_devices $env(FPGA_DEV)_0] 0 ]
refresh_hw_device   -update_hw_probes false $hw_device
create_hw_cfgmem    -hw_device $hw_device [ lindex [get_cfgmem_parts $env(CFGMEM_PART)] 0 ]
set cfg_mem         [ get_property PROGRAM.HW_CFGMEM $hw_device ]

set_property PROGRAM.BLANK_CHECK            0                     $cfg_mem
set_property PROGRAM.ERASE                  1                     $cfg_mem
set_property PROGRAM.CFG_PROGRAM            1                     $cfg_mem
set_property PROGRAM.VERIFY                 1                     $cfg_mem
set_property PROGRAM.CHECKSUM               0                     $cfg_mem
refresh_hw_device                           $hw_device
set_property PROGRAM.ADDRESS_RANGE          {use_file}            $cfg_mem
set_property PROGRAM.FILES                  [list "project.mcs"]  $cfg_mem
set_property PROGRAM.PRM_FILE               {}                    $cfg_mem
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none}           $cfg_mem
set_property PROGRAM.BLANK_CHECK            0                     $cfg_mem
set_property PROGRAM.ERASE                  1                     $cfg_mem
set_property PROGRAM.CFG_PROGRAM            1                     $cfg_mem
set_property PROGRAM.VERIFY                 1                     $cfg_mem
set_property PROGRAM.CHECKSUM               0                     $cfg_mem
startgroup
create_hw_bitstream -hw_device  $hw_device [ get_property PROGRAM.HW_CFGMEM_BITFILE $hw_device ]
program_hw_devices              $hw_device
refresh_hw_device               $hw_device
program_hw_cfgmem   -hw_cfgmem  $cfg_mem
endgroup
