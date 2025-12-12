# This Makefile can be used to build the PetaLinux projects.
FPGA_ARCH = $(word 2, $(subst _, ,$(shell basename $(CURDIR))))
PROJECT_NAME = $(word 3, $(subst _, ,$(shell basename $(CURDIR))))
TOOLS_VER = $(word 4, $(subst _, ,$(shell basename $(CURDIR))))

# defaults
.DEFAULT_GOAL := linux

.PHONY: linux
linux: init

.PHONY: init
init: .repo

.repo:
	repo init -u https://github.com/Xilinx/yocto-manifests.git -b rel-v$(TOOLS_VER)
	repo sync


