# Globals
PROJECT_NAME         ?= project

# Project folders
PROJECT_DIR          ?= project
CONSTRAINTS_DIR      ?= constraints
SCRIPTS_DIR          ?= build_scripts
IP_DIR               ?= ip_lib

# Name of top-level blockdesign
TOP_BD               ?= TOP

# Project files
ifeq ($(TOOLS_VER),2020.1)
SRC_TOP_FILE         ?= $(PROJECT_DIR)/$(PROJECT_NAME).srcs/sources_1/bd/$(TOP_BD)/hdl/$(TOP_BD)_wrapper.vhd
else
SRC_TOP_FILE         ?= $(PROJECT_DIR)/$(PROJECT_NAME).gen/sources_1/bd/$(TOP_BD)/hdl/$(TOP_BD)_wrapper.vhd
endif
BIT_FILE             ?= $(PROJECT_DIR)/$(PROJECT_NAME).runs/impl_1/$(TOP_BD)_wrapper.bit
BD_TCL_FILE          ?= $(PROJECT_DIR)/$(TOP_BD).tcl
BD_FILE              ?= $(PROJECT_DIR)/$(PROJECT_NAME).srcs/sources_1/bd/$(TOP_BD)/$(TOP_BD).bd
PROJECT_FILE         ?= $(PROJECT_DIR)/$(PROJECT_NAME).xpr
XSA_FILE             ?= $(PROJECT_DIR)/$(TOP_BD)_wrapper.xsa
USER_CREATE_TCL_FILE ?= user_create.tcl
USER_BUILD_TCL_FILE  ?= user_build.tcl
IP_PROJECT_FILE       = $(IP_DIR)/managed_ip_project/managed_ip_project.xpr
MCS_FILE             ?= project.mcs

# Tools
VIVADO  = vivado
VITIS   = vitis
BOOTGEN = bootgen

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

### Export variables to be used in tcl scripts
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

export JOBS

### Goals
.DEFAULT_GOAL := $(BIT_FILE)

.PHONY: build
build : $(BIT_FILE)

$(BIT_FILE): $(SRC_TOP_FILE)
ifneq (, $(wildcard $(USER_BUILD_TCLFILE)))
	@echo -e "$(txtylw)Apply USER build script$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(USER_BUILD_TCL_FILE)
endif
	@echo -e "$(txtylw)Build project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/build_project.tcl

.PHONY: create
create: $(SRC_TOP_FILE)

$(SRC_TOP_FILE): $(PROJECT_FILE)
	@echo -e "$(txtylw)Generate TOP level wrapper$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/create_top_wrapper.tcl

$(PROJECT_FILE): $(BD_TCL_FILE)
	@echo -e "$(txtylw)Create project from TCL$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/create_project.tcl
	@echo -e "$(txtylw)Add project constraints$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/add_constraints.tcl
ifneq (, $(wildcard $(USER_CREATE_TCLFILE)))
	@echo -e "$(txtylw)Apply USER create script$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(USER_CREATE_TCL_FILE)
endif

.PHONY: open
open : $(PROJECT_FILE) $(SRC_TOP_FILE)
	@echo -e "$(txtylw)Open project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/open_project.tcl &

$(IP_PROJECT_FILE):
	@echo -e "$(txtylw)Creating IP project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/create_ip_project.tcl

.PHONY: ip
ip: $(IP_PROJECT_FILE)
	@echo -e "$(txtylw)Opening IP project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/open_ip.tcl &

.PHONY: mcs
mcs: $(MCS_FILE)

$(MCS_FILE): $(BIT_FILE)
	@echo -e "$(txtylw)Generate MCS$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/gen_mcs.tcl
	$(V) zip $(MCS_ZIP_FILE) $(MCS_FILE)

.PHONY: flash_mcs
flash_mcs: $(MCS_FILE)
	@echo -e "$(txtylw)Programm MCS$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/flash_mcs.tcl

.PHONY: boot
boot : $(BOOT_FILE)

$(BOOT_FILE): $(BIT_FILE)
	@echo -e "$(txtylw)Generate BIF$(txtrst)"
	@echo "the_ROM_image:" > linux.bif
	@echo "{" >> linux.bif
	@echo "  [bootloader]../$(LINUX_PROJECT_NAME)/images/linux/zynq_fsbl.elf" >> linux.bif
	@echo "  $(BIT_FILE)" >> linux.bif
	@echo "  ../$(LINUX_PROJECT_NAME)/images/linux/u-boot.elf" >> linux.bif
	@echo "  $(EXTRA_BIF_PART)" >> linux.bif
	@echo "}" >> linux.bif
	@echo -e "$(txtylw)Run Bootgen$(txtrst)"
	$(V) $(PREFIX) $(BOOTGEN) -arch zynq -image linux.bif -o $@ -w

.PHONY: upload
upload: $(BOOT_FILE)
	@echo -e "$(txtylw)Run scp$(txtrst)"
	scp $(SCP_OPTIONS) $(BOOT_FILE) $(SCP_PATH)

.PHONY: program
program: $(BIT_FILE)
	@echo -e "$(txtylw)Program FPGA$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/program_fpga.tcl

.PHONY: flash_boot
flash_boot: $(BOOT_FILE)
	@echo -e "$(txtylw)Program Flash$(txtrst)"
	program_flash -f $(BOOT_FILE) -offset 0 -flash_type qspi_single -fsbl prebuilt/flash_fsbl.elf

.PHONY: xsa
xsa : $(XSA_FILE)

$(XSA_FILE) : $(BIT_FILE)
	@echo -e "$(txtylw)Export project$(txtrst)"
	$(V) $(PREFIX) $(VIVADO) -mode batch -source $(SCRIPTS_DIR)/export_hw.tcl

.PHONY: fix
fix:
	@echo -e "$(txtylw)Fix Flash U-Boot$(txtrst)"
	sudo cp ../resources/zynq_qspi_x4_single.bin /opt/Xilinx/$(XILINX_SDK_TOOL)/$(TOOLS_VER)/data/xicom/cfgmem/uboot/

.PHONY: upload
update_boot: $(BOOT_FILE)
	@echo -e "$(txtylw)Upload BOOT.bin$(txtrst)"
	scp -O $(BOOT_FILE) $(SCP_PATH)

.PHONY: clean
clean :
	$(V) rm -rf *.log *.jou *.str vivado_pid*.zip .Xil .hbs

.PHONY: clean_all
clean_all : clean
	$(V) rm -rf $(PROJECT_DIR)/$(PROJECT_NAME).*
