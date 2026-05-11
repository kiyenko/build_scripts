################################################################################
# Globals
################################################################################
export FPGA_ARCH     ?= $(word 2, $(subst _, ,$(shell basename $(CURDIR))))
export PROJECT_NAME  ?= $(word 3, $(subst _, ,$(shell basename $(CURDIR))))
export TOOLS_VER     ?= $(word 4, $(subst _, ,$(shell basename $(CURDIR))))

################################################################################
# Project folders
################################################################################
PROJECT_DIR          ?= project
CONSTRAINTS_DIR      ?= constraints
SCRIPTS_DIR          ?= build_scripts
IP_DIR               ?= ip_lib

# Name of top-level blockdesign
TOP_BD               ?= TOP

################################################################################
# Project files
################################################################################
PROJECT_DIRS          = $(PROJECT_DIR)/$(PROJECT_NAME)
ifeq ($(TOOLS_VER),2020.1)
SRC_TOP_FILE         ?= $(PROJECT_DIRS).srcs/sources_1/bd/$(TOP_BD)/hdl/$(TOP_BD)_wrapper.vhd
else
SRC_TOP_FILE         ?= $(PROJECT_DIRS).gen/sources_1/bd/$(TOP_BD)/hdl/$(TOP_BD)_wrapper.vhd
endif
BIT_FILE             ?= $(PROJECT_DIRS).runs/impl_1/$(TOP_BD)_wrapper.bit
BIT_BIN_FILE         ?= $(PROJECT_DIRS).runs/impl_1/$(TOP_BD)_wrapper.bit.bin
BD_TCL_FILE          ?= $(PROJECT_DIR)/$(TOP_BD).tcl
BD_FILE              ?= $(PROJECT_DIRS).srcs/sources_1/bd/$(TOP_BD)/$(TOP_BD).bd
PROJECT_FILE         ?= $(PROJECT_DIR)/$(PROJECT_NAME).xpr
XSA_FILE             ?= $(PROJECT_DIR)/$(TOP_BD)_wrapper.xsa
USER_CREATE_TCL_FILE ?= user_create.tcl
USER_BUILD_TCL_FILE  ?= user_build.tcl
IP_PROJECT_FILE       = $(IP_DIR)/managed_ip_project/managed_ip_project.xpr
MCS_FILE             ?= $(PROJECT_NAME).mcs
BIT_ELF_FILE         ?= $(PROJECT_NAME).bit
BIN_FILE             ?= $(PROJECT_NAME).bin
HDF_FILE             ?= $(PROJECT_NAME).hdf
MMI_FILE             ?= $(PROJECT_DIRS).runs/impl_1/$(TOP_BD)_wrapper.mmi
TS_FILE               = ts.txt
DATE_TIME             = $(shell cat ts.txt || date "+%g%m%d%H")
MCS_BIT_FILE         ?= $(BIT_FILE)
MCS_ZIP_FILE         ?= $(PROJECT_NAME)_$(DATE_TIME).zip
CONSTRAINTS          := $(wildcard $(CONSTRAINTS_DIR)/*.xsa)
FSBL_FILE            ?= $(LINUX_PROJECT_NAME)/images/linux/zynq_fsbl.elf
U_BOOT_FILE          ?= $(LINUX_PROJECT_NAME)/images/linux/u-boot.elf

# Tools
VIVADO                = vivado
VITIS                 = vitis
BOOTGEN               = bootgen

### Number of parallel jobs. ncores/2 by default
JOBS?=$(shell echo $$(($$(nproc)/2)))

### If VERBOSE is set, the commands are not hidden.
ifeq ($(VERBOSE),)
V=@
endif

### Docker workarounds
ifeq ($(WITHIN_DOCKER),)
PREFIX=LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1
endif

### Colors
txtylw = \e[0;33m
txtrst = \e[0m

################################################################################
# Export variables to be used in tcl scripts
################################################################################
export PROJECT_NAME

export TOP_BD

export PROJECT_DIR
export CONSTRAINTS_DIR
export SCRIPTS_DIR
export IP_DIR

export PROJECT_FILE
export BD_TCL_FILE
export BD_FILE
export USER_CREATE_TCL_FILE
export USER_BUILD_TCL_FILE
export SRC_TOP_FILE
export XSA_FILE
export MCS_FILE
export MCS_BIT_FILE

export JOBS

### Goals
.DEFAULT_GOAL := $(BIT_FILE)

################################################################################
# Build
################################################################################
.PHONY: build
build : $(BIT_FILE)
$(BIT_FILE): $(PROJECT_FILE) $(CONSTRAINTS)
ifneq (, $(wildcard $(USER_BUILD_TCLFILE)))
	@echo -e "$(txtylw)Apply USER build script$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(USER_BUILD_TCL_FILE)
endif
	@echo -e "$(txtylw)Build project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch \
	   	-source $(SCRIPTS_DIR)/build_project.tcl

################################################################################
# Project file
################################################################################
.PHONY: create
create: $(PROJECT_FILE)

$(SRC_TOP_FILE): $(PROJECT_FILE)
	@echo -e "$(txtylw)Generate TOP level wrapper$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch \
	   	-source $(SCRIPTS_DIR)/create_top_wrapper.tcl

$(PROJECT_FILE): $(BD_TCL_FILE)
	@echo -e "$(txtylw)Create project from TCL$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch \
	   	-source $(SCRIPTS_DIR)/create_project.tcl
	@echo -e "$(txtylw)Add project constraints$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch \
	   	-source $(SCRIPTS_DIR)/add_constraints.tcl
	@echo -e "$(txtylw)Generate TOP level wrapper$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch \
	   	-source $(SCRIPTS_DIR)/create_top_wrapper.tcl
ifneq (, $(wildcard $(USER_CREATE_TCLFILE)))
	@echo -e "$(txtylw)Apply USER create script$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(USER_CREATE_TCL_FILE)
endif

.PHONY: open
open : $(PROJECT_FILE)
	@echo -e "$(txtylw)Open project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch\
	   	-source $(SCRIPTS_DIR)/open_project.tcl &

################################################################################
# IP
################################################################################
$(IP_PROJECT_FILE):
	@echo -e "$(txtylw)Creating IP project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch\
	   	-source $(SCRIPTS_DIR)/create_ip_project.tcl

.PHONY: ip
ip: $(IP_PROJECT_FILE)
	@echo -e "$(txtylw)Opening IP project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/open_ip.tcl &

################################################################################
# BOOT.bin
################################################################################
.PHONY: boot
boot : $(BOOT_FILE)
$(BOOT_FILE): $(BIT_FILE)
	@echo -e "$(txtylw)Generate BIF$(txtrst)"
	@echo "the_ROM_image:" > linux.bif
	@echo "{" >> linux.bif
	@echo "  [bootloader]../$(FSBL_FILE)" >> linux.bif
	@echo "  $(BIT_FILE)" >> linux.bif
	@echo "  ../$(U_BOOT_FILE)" >> linux.bif
	@echo "  $(EXTRA_BIF_PART)" >> linux.bif
	@echo "}" >> linux.bif
	@echo -e "$(txtylw)Run Bootgen$(txtrst)"
	$(V) $(PREFIX) $(BOOTGEN) -arch zynq -image linux.bif -o $@ -w

################################################################################
# Export Hardware
################################################################################
.PHONY: xsa
xsa : $(XSA_FILE)
$(XSA_FILE) : $(BIT_FILE)
	@echo -e "$(txtylw)Export XSA$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/export_hw.tcl

.PHONY: hdf
hdf : $(HDF_FILE)
$(HDF_FILE): $(BIT_FILE)
	@echo -e "$(txtylw)Export HDF$(txtrst)"
	@mkdir -p $(PROJECT_DIRS).sdk
	@cp -f $(PROJECT_DIRS).runs/impl_1/$(TOP_BD)_wrapper.sysdef $@

.PHONY: sdk
sdk: $(HDF_FILE)
	launch_sdk -workspace $(PROJECT_DIRS).sdk -hwspec $(HDF_FILE)

################################################################################
# MCS
################################################################################
.PHONY: mcs
mcs: $(MCS_FILE)
$(MCS_FILE): $(BIT_ELF_FILE)
	@echo -e "$(txtylw)Generate MCS$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/gen_mcs.tcl
	$(V) zip $(MCS_ZIP_FILE) $(MCS_FILE)

.PHONY: flash_mcs
flash_mcs: $(MCS_FILE)
	@echo -e "$(txtylw)Programm MCS$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/flash_mcs.tcl

.PHONY: bin
bin: $(BIN_FILE)
$(BIN_FILE): $(BIT_ELF_FILE)
	@echo -e "$(txtylw)Generate BIN$(txtrst)"
	dd if=$(BIT_ELF_FILE) bs=1 skip=121 of=$@

.PHONY: bit_bin
bit_bin : $(BIT_BIN_FILE)
$(BIT_BIN_FILE) : $(BIT_FILE)
	@echo "all:" > convert.bif
	@echo "{" >> convert.bif
	@echo "  $(BIT_FILE)" >> convert.bif
	@echo "}" >> convert.bif
	$(V) $(BOOTGEN) -image convert.bif -arch zynq -process_bitstream bin -w
	@rm -f convert.bif

.PHONY: bit_elf
bit_elf: $(BIT_ELF_FILE)
$(BIT_ELF_FILE): $(BIT_FILE) $(ELF_FILE)
	@echo -e "$(txtylw)Update BIT with ELF software$(txtrst)"
	updatemem -meminfo $(MMI_FILE) \
		-data $(ELF_FILE) \
	   	-bit $(BIT_FILE) \
	   	-proc $(PROC) \
	   	-out $@ -force

################################################################################
# Deploy
################################################################################
.PHONY: upload
update_boot: $(BOOT_FILE)
	@echo -e "$(txtylw)Upload BOOT.bin$(txtrst)"
	@scp $(SCP_OPTIONS) $(BOOT_FILE) $(SCP_PATH)

.PHONY: program
program: $(BIT_FILE)
	@echo -e "$(txtylw)Program FPGA$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/program_fpga.tcl

.PHONY: flash_boot
flash_boot: $(BOOT_FILE)
	@echo -e "$(txtylw)Program Flash$(txtrst)"
	program_flash -f $(BOOT_FILE) -offset 0 -flash_type qspi_single \
		-fsbl prebuilt/flash_fsbl.elf

################################################################################
# Clean
################################################################################
.PHONY: clean
clean :
	$(V) rm -rf *.log *.jou *.str vivado_pid*.zip .Xil .hbs *.mcs *.prm *.bit \
	*.bin *.xsa $(TS_FILE)

.PHONY: clean_all
clean_all : clean
	$(V) rm -rf $(PROJECT_DIR)/$(PROJECT_NAME).cache \
		$(PROJECT_DIR)/$(PROJECT_NAME).gen \
		$(PROJECT_DIR)/$(PROJECT_NAME).hw \
		$(PROJECT_DIR)/$(PROJECT_NAME).ip_user_files \
		$(PROJECT_DIR)/$(PROJECT_NAME).runs \
		$(PROJECT_DIR)/$(PROJECT_NAME).srcs \
		$(PROJECT_FILE) $(XSA_FILE) $(PROJECT_DIR)/*.bit \
		$(PROJECT_DIR)/*.mmi $(PROJECT_DIR)/.Xil $(PROJECT_DIR)/*.log

################################################################################
# Misc
################################################################################
.PHONY: fix
fix:
	@echo -e "$(txtylw)Fix Flash U-Boot$(txtrst)"
	sudo cp ../resources/zynq_qspi_x4_single.bin \
		/opt/Xilinx/$(XILINX_SDK_TOOL)/$(TOOLS_VER)/data/xicom/cfgmem/uboot/

