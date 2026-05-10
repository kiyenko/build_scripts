puts "Generating MCS"
set MCS_BIT_FILE $env(MCS_BIT_FILE)
set MCS_FILE $env(MCS_FILE)

open_project project/project.xpr
set loadbit { up  0x00000000 }
lappend loadbit $MCS_BIT_FILE
write_cfgmem -force -format mcs -size 64 -interface SPIx4 -loadbit $loadbit -file $MCS_FILE
