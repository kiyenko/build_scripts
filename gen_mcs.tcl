puts "Generating MCS"

open_project project/project.xpr
write_cfgmem -force -format mcs -size 64 -interface SPIx4 -loadbit {up 0x00000000 "project/project.runs/impl_1/TOP_wrapper.bit" } -file "project.mcs"
