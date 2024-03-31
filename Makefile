-include config.mk

ifndef BLIKVM_PLATFORM
    $(error Must specify BLIKVM_PLATFORM variable as one of: v1-cm4, v2-pcie, or v3-hat)
endif

ifeq ($(BLIKVM_PLATFORM),v1-cm4)
    export PLATFORM = v3-hdmi
    export BOARD = rpi4
    export EDIDTYPE = v4mini
    export SUFFIX = -box
    export FAN = 1
    export OLED = 1
    export BLIKVM_BOARD = cm4
else ifeq ($(BLIKVM_PLATFORM),v2-pcie)
    export PLATFORM = v3-hdmi
    export BOARD = rpi4
    export EDIDTYPE = v4mini
    export SUFFIX = -box
    export FAN = 1
    export OLED = 1
    export BLIKVM_BOARD = cm4
else ifeq ($(BLIKVM_PLATFORM),v3-hat)
    export PLATFORM = v3-hdmi
    export BOARD = rpi4
    export EDIDTYPE = v3
    export SUFFIX = -box
    export FAN = 1
    export OLED = 1
    export BLIKVM_BOARD = rpi4
else
    $(error Must specify BLIKVM_PLATFORM variable as one of: v1-cm4, v2-pcie, or v3-hat)
endif


export PROJECT ?= blikvm-pikvm-os.$(BLIKVM_PLATFORM)$(BLIKVM_SUFFIX)
export STAGES ?= __init__ os pikvm-repo pistat watchdog rootdelay ro pikvm restore-mirrorlist blikvm __cleanup__
export NC ?=

export HOSTNAME ?= pikvm
export LOCALE ?= en_US
export TIMEZONE ?= UTC
export ARCH_DIST_REPO_URL ?= https://mirrors.ocf.berkeley.edu/archlinuxarm/
export BUILD_OPTS ?=

export ROOT_PASSWD ?= root
export WEBUI_ADMIN_PASSWD ?= admin
export IPMI_ADMIN_PASSWD ?= admin

export DISK ?= $(shell pwd)/upstream_os/disk/$(word 1,$(subst -, ,$(PLATFORM))).conf
export CARD ?= /dev/null
# Default to 0 until things are settled with the liblzma stuff
#export IMAGE_XZ ?= 1
export IMAGE_XZ ?= 0
# Hack to use 7zip for image compression for now until pi-builder has another option, or
# liblzma issues are resolved; only tested on Debian Bookworm
export IMAGE_7Z ?= 1

export DEPLOY_USER ?= root


# =====
export SHELL = /usr/bin/env bash
_BUILDER_DIR = ./.pi-builder/$(BLIKVM_PLATFORM)-$(BLIKVM_BOARD)$(BLIKVM_SUFFIX)
_UPSTREAM_OS_DIR = ./upstream_os
_BLIKVM_SOURCE_DIR = $(_BUILDER_DIR)/stages/arch/blikvm_source

define optbool
$(filter $(shell echo $(1) | tr A-Z a-z),yes on 1)
endef

define fv
$(shell curl --silent "https://files.pikvm.org/repos/arch/$(BOARD)/latest/$(1)")
endef


# =====
all:
	@ echo "Available commands:"
	@ echo "    make                # Print this help"
	@ echo "    make os             # Build OS with your default config"
	@ echo "    make shell          # Run Arch-ARM shell"
	@ echo "    make install        # Install rootfs to partitions on $(CARD)"
	@ echo "    make image          # Create a binary image for burning outside of make install"
	@ echo "    make scan           # Find all RPi devices in the local network"
	@ echo "    make clean          # Remove the generated rootfs"
	@ echo "    make clean-all      # Remove the generated rootfs and pi-builder toolchain"


shell: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) shell


os: $(_BUILDER_DIR) $(_UPSTREAM_OS_DIR) $(_BLIKVM_SOURCE_DIR)
	rm -rf $(_BUILDER_DIR)/stages/arch/{pikvm,pikvm-otg-console,blikvm}
	cp -a stages/arch/blikvm $(_BUILDER_DIR)/stages/arch
	cp -a $(_UPSTREAM_OS_DIR)/stages/arch/{pikvm,pikvm-otg-console} $(_BUILDER_DIR)/stages/arch
	$(MAKE) -C $(_BUILDER_DIR) os \
		BUILD_OPTS=' $(BUILD_OPTS) \
			--build-arg PLATFORM=$(PLATFORM) \
			--build-arg VERSIONS=$(call fv,ustreamer)/$(call fv,kvmd)/$(call fv,kvmd-webterm)/$(call fv,kvmd-oled)/$(call fv,kvmd-fan) \
			--build-arg EDIDTYPE=$(EDIDTYPE) \
			--build-arg OLED=$(call optbool,$(OLED)) \
			--build-arg FAN=$(call optbool,$(FAN)) \
			--build-arg ROOT_PASSWD=$(ROOT_PASSWD) \
			--build-arg WEBUI_ADMIN_PASSWD=$(WEBUI_ADMIN_PASSWD) \
			--build-arg IPMI_ADMIN_PASSWD=$(IPMI_ADMIN_PASSWD) \
		'


$(_BUILDER_DIR):
	mkdir -p `dirname $(_BUILDER_DIR)`
	git clone --depth=1 https://github.com/pikvm/pi-builder $(_BUILDER_DIR)


$(_UPSTREAM_OS_DIR):
	mkdir -p `dirname $(_UPSTREAM_OS_DIR)`
	git clone --depth=1 https://github.com/pikvm/os $(_UPSTREAM_OS_DIR)


$(_BLIKVM_SOURCE_DIR):
	mkdir -p `dirname $(_BLIKVM_SOURCE_DIR)`
	git clone --depth=1 https://github.com/ThomasVon2021/blikvm $(_BLIKVM_SOURCE_DIR)


update: $(_BUILDER_DIR) $(_BLIKVM_SOURCE_DIR)
	cd $(_BUILDER_DIR) && git pull --rebase
	cd $(_UPSTREAM_OS_DIR) && git pull --rebase
	cd $(_BLIKVM_SOURCE_DIR) && git pull --rebase
	git pull --rebase


install: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) install


image: $(_BUILDER_DIR)
	$(eval _dated := blikvm-pikvm-$(BLIKVM_PLATFORM)-$(BLIKVM_BOARD)$(BLIKVM_SUFFIX)-$(shell date +%Y%m%d).img)
	mkdir -p images
	$(MAKE) -C $(_BUILDER_DIR) image IMAGE=$(shell pwd)/images/$(_dated)
ifeq ($(IMAGE_7Z),1)
		echo "Compressing image"
		7zz a -mx9 $(shell pwd)/images/$(_dated).7z $(shell pwd)/images/$(_dated)
		sha1sum $(shell pwd)/images/$(_dated).7z | awk '{print $$1}' > $(shell pwd)/images/$(_dated).7z.sha1
		rm -f $(shell pwd)/images/$(_dated)
		rm -f $(shell pwd)/images/$(_dated).sha1
endif


scan: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) scan


clean: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) clean


clean-all:
	rm -rf $(_BLIKVM_SOURCE_DIR)
	- rmdir `dirname $(_BLIKVM_SOURCE_DIR)`
	rm -rf $(_UPSTREAM_OS_DIR)
	- rmdir `dirname $(_UPSTREAM_OS_DIR)`
	- $(MAKE) -C $(_BUILDER_DIR) clean-all
	rm -rf $(_BUILDER_DIR)
	- rmdir `dirname $(_BUILDER_DIR)`
