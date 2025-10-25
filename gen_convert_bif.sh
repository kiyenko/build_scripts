#!/bin/sh
echo "all:"                                                             >  convert.bif
echo "{"                                                                >> convert.bif
echo "  project/project.runs/impl_1/TOP_wrapper.bit"                    >> convert.bif
echo "}"                                                                >> convert.bif
echo "Enter the bitstream TAG: "
read tag
bootgen -image convert.bif -arch zynq -process_bitstream bin -w -o prebuilt/$${tag}.bit.bin
rm -f convert.bif
