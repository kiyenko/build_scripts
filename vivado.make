export FPGA_ARCH = $(word 2, $(subst _, ,$(shell basename $(CURDIR))))
export PROJECT_NAME = $(word 3, $(subst _, ,$(shell basename $(CURDIR))))
export TOOLS_VER = $(word 4, $(subst _, ,$(shell basename $(CURDIR))))

export LINUX_PROJECT_NAME = petalinux_$(FPGA_ARCH)_$(PROJECT_NAME)_$(TOOLS_VER)
SCRIPTS_DIR = ../build_scripts
VIVADO = LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1 vivado
BOOTGEN = LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1 bootgen
PROJECT_FILE = project/project.xpr
XSA_FILE = TOP_wrapper.xsa
BOOT_FILE = BOOT.bin
BIT_FILE = project/project.runs/impl_1/TOP_wrapper.bit

.DEFAULT_GOAL := $(XSA_FILE)

.PHONY: create
create : $(PROJECT_FILE)

$(PROJECT_FILE):
	@$(VIVADO) -mode batch -source $(SCRIPTS_DIR)/create_project.tcl

.PHONY: open
open : $(PROJECT_FILE)
	@$(VIVADO) -mode batch -source $(SCRIPTS_DIR)/open_project.tcl

.PHONY: build
build : $(BIT_FILE)

$(BIT_FILE): $(PROJECT_FILE)
	@$(VIVADO) -mode batch -source $(SCRIPTS_DIR)/build_project.tcl

.PHONY: boot
boot : $(BOOT_FILE)

$(BOOT_FILE): $(BIT_FILE)
	@echo "the_ROM_image:" > linux.bif
	@echo "{" >> linux.bif
	@echo "  [bootloader]../$(LINUX_PROJECT_NAME)/images/linux/zynq_fsbl.elf" >> linux.bif
	@echo "  $(BIT_FILE)" >> linux.bif
	@echo "  ../$(LINUX_PROJECT_NAME)/images/linux/u-boot.elf" >> linux.bif
	@echo $(EXTRA_BIF_PART) >> linux.bif
	@echo "}" >> linux.bif
	@$(BOOTGEN) -arch zynq -image linux.bif -o $@ -w
	@rm -f linux.bif

.PHONY: program
program: $(BIT_FILE)
	@$(VIVADO) -mode batch -source $(SCRIPTS_DIR)/program_fpga.tcl

.PHONY: flash
flash_boot: $(BOOT_FILE)
	program_flash -f $(BOOT_FILE) -offset 0 -flash_type qspi_single -fsbl prebuilt/flash_fsbl.elf

.PHONY: export
export : $(XSA_FILE)

$(XSA_FILE) : $(BIT_FILE)
	@$(VIVADO) -mode batch -source $(SCRIPTS_DIR)/export_hw.tcl

.PHONY: fix
fix:
	sudo cp prebuilt/zynq_qspi_x4_single.bin /opt/Xilinx/$(XILINX_SDK_TOOL)/$(TOOLS_VER)/data/xicom/cfgmem/uboot/

.PHONY: upload
update_boot: $(BOOT_FILE)
	scp -O $(BOOT_FILE) $(SCP_PATH)

.PHONY: clean
clean :
	@rm -rf *.log *.jou *.str vivado_pid*.zip .Xil .hbs

.PHONY: clean_all
clean_all : clean
	@rm -rf project/project.*

