# This Makefile can be used to build the PetaLinux projects.
FPGA_ARCH = $(word 2, $(subst _, ,$(shell basename $(CURDIR))))
PROJECT_NAME = $(word 3, $(subst _, ,$(shell basename $(CURDIR))))
TOOLS_VER = $(word 4, $(subst _, ,$(shell basename $(CURDIR))))

# defaults
.DEFAULT_GOAL := petalinux
PETL_OFFLINE = .offline
PETL_CFG_DONE = .configdone

# Vivado paths
VIVADO_DIR = ../vivado_$(FPGA_ARCH)_$(PROJECT_NAME)_$(TOOLS_VER)
VIVADO_PROJECT_DIR = $(VIVADO_DIR)/project
VIVADO_XSA = $(VIVADO_DIR)/project/TOP_wrapper.xsa
LINUX_XSA = project-spec/hw-description/system.xsa
FSBL_FILE = images/linux/zynq_fsbl.elf
BIT_FILE = project-spec/hw-description/TOP_wrapper.bit
IMAGE_FILE = images/linux/image.ub
UBOOT_FILE = images/linux/u-boot.elf
DEVTREE_FILE = project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
BOOT_FILE = BOOT.bin
SCR_FILE = images/linux/boot.scr

# Colors
txtylw = \e[0;33m
txtrst = \e[0m

# For offline PetaLinux builds
SSTATE_PATH ?= $(shell test -e $(PETL_OFFLINE) && head -n 1 $(PETL_OFFLINE))
ifneq ($(SSTATE_PATH),)
	MIRROR_URL = CONFIG_PRE_MIRROR_URL="file://$(SSTATE_PATH)/$(TOOLS_VER)/downloads"
	SSTATE_FEEDS = CONFIG_YOCTO_LOCAL_SSTATE_FEEDS_URL="$(SSTATE_PATH)/$(TOOLS_VER)/$(FPGA_ARCH)"
endif

$(PETL_CFG_DONE):
	@if [ ! -z "$(SSTATE_PATH)" ]; then \
		echo '$(MIRROR_URL)' >> ./project-spec/configs/config; \
		echo '$(SSTATE_FEEDS)' >> ./project-spec/configs/config; \
		echo 'Configuring project for offline build ($(SSTATE_PATH))'; \
	fi
	touch $@

.PHONY: import
import: $(LINUX_XSA)

$(LINUX_XSA): $(VIVADO_XSA)
	@echo -e "$(txtylw)Import HW Description$(txtrst)"
	petalinux-config --silentconfig --get-hw-description $(VIVADO_DIR)/project
	touch $@

.PHONY: petalinux
petalinux: $(IMAGE_FILE)

$(IMAGE_FILE): $(PETL_CFG_DONE) $(LINUX_XSA)
	@echo -e "$(txtylw)Build project$(txtrst)"
	petalinux-build

$(BOOT_FILE): $(DEVTREE_FILE) $(BIT_FILE) $(FSBL_FILE) $(UBOOT_FILE)
	@echo -e "$(txtylw)Generate BOOT.bin$(txtrst)"
	rm -f $@
	@if [ "$(TOOLS_VER)" = "2020.1" ]; then \
		petalinux-package --boot --format BIN --fsbl $(FSBL_FILE) --u-boot --fpga $(BIT_FILE) $(USER_IMG) -o $@; \
	else \
		petalinux-package boot --format BIN --fsbl $(FSBL_FILE) --u-boot --fpga $(BIT_FILE) $(USER_IMG) -o $@; \
	fi

.PHONY: upload_image
upload_image: $(IMAGE_FILE)
	@echo -e "$(txtylw)Upload image.ub$(txtrst)"
	scp $(SCP_OPTIONS) $(IMAGE_FILE) $(SCP_PATH)

.PHONY: upload_boot
upload_boot: $(BOOT_FILE)
	@echo -e "$(txtylw)Upload BOOT.bin$(txtrst)"
	scp $(SCP_OPTIONS) $(BOOT_FILE) $(SCP_PATH)

.PHONY: upload
upload: $(IMAGE_FILE) $(BOOT_FILE) $(SCR_FILE)
	@echo -e "$(txtylw)Upload files$(txtrst)"
	scp $(SCP_OPTIONS) $(IMAGE_FILE) $(BOOT_FILE) $(SCR_FILE) $(SCP_PATH)

.PHONY: clean
clean:
	@echo -e "$(txtylw)Clean project$(txtrst)"
	petalinux-build -x mrproper
	rm -f $(PETL_CFG_DONE)
