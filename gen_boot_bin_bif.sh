#!/bin/sh
echo "the_ROM_image:"                                                     >  boot_bin.bif
echo "{"                                                                  >> boot_bin.bif
echo "  [bootloader]../${LINUX_PROJECT_NAME}/images/linux/zynq_fsbl.elf"  >> boot_bin.bif
echo "  project/project.runs/impl_1/TOP_wrapper.bit"                      >> boot_bin.bif
echo "  ../${LINUX_PROJECT_NAME}/images/linux/u-boot.elf"                 >> boot_bin.bif
echo "}"                                                                  >> boot_bin.bif

