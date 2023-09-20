-include config.mk

PLATFORM ?= v2-pcie
SUFFIX ?=
export BOARD ?= cm4
export PROJECT ?= blikvm-pikvm-os.$(PLATFORM)$(SUFFIX)
export STAGES ?= __init__ os pikvm-repo watchdog rootdelay ro no-audit pikvm blikvm __cleanup__
export NC ?=

export HOSTNAME ?= pikvm
export LOCALE ?= en_US
export TIMEZONE ?= Europe/Moscow
export REPO_URL ?= https://ca.us.mirror.archlinuxarm.org
BUILD_OPTS ?=

ROOT_PASSWD ?= root
WEBUI_ADMIN_PASSWD ?= admin
IPMI_ADMIN_PASSWD ?= admin

export CARD ?= /dev/mmcblk0

DEPLOY_USER ?= root


ifeq ($(PLATFORM),v2-pcie)
	PIKVM_PLATFORM = v3-hdmi
	PIKVM_BOARD = rpi4
	PIKVM_SUFFIX = -box
	ifndef FAN
		FAN = 1
	endif
	ifndef OLED
		OLED = 1
	endif
else
	PIKVM_PLATFORM = $(PLATFORM)
	PIKVM_BOARD = $(BOARD)
	PIKVM_SUFFIX = $(SUFFIX)
endif


# =====
SHELL = /usr/bin/env bash
_BUILDER_DIR = ./.pi-builder/$(PLATFORM)-$(BOARD)$(SUFFIX)
_BLIKVM_SOURCE_DIR = $(_BUILDER_DIR)/stages/arch/blikvm_source

define optbool
$(filter $(shell echo $(1) | tr A-Z a-z),yes on 1)
endef

define fv
$(shell curl --silent "https://files.pikvm.org/repos/arch/$(PIKVM_BOARD)/latest/$(1)")
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


os: $(_BUILDER_DIR) $(_BLIKVM_SOURCE_DIR)
	rm -rf $(_BUILDER_DIR)/stages/arch/{pikvm,pikvm-otg-console,blikvm}
	cp -a stages/arch/{pikvm,pikvm-otg-console,blikvm} $(_BUILDER_DIR)/stages/arch
	cp -L disk/$(word 1,$(subst -, ,$(PIKVM_PLATFORM))).conf $(_BUILDER_DIR)/disk.conf
	$(MAKE) -C $(_BUILDER_DIR) os \
		BUILD_OPTS=' $(BUILD_OPTS) \
			--build-arg PLATFORM=$(PIKVM_PLATFORM) \
			--build-arg VERSIONS=$(call fv,ustreamer)/$(call fv,kvmd)/$(call fv,kvmd-webterm)/$(call fv,kvmd-oled)/$(call fv,kvmd-fan) \
			--build-arg OLED=$(call optbool,$(OLED)) \
			--build-arg FAN=$(call optbool,$(FAN)) \
			--build-arg ROOT_PASSWD=$(ROOT_PASSWD) \
			--build-arg WEBUI_ADMIN_PASSWD=$(WEBUI_ADMIN_PASSWD) \
			--build-arg IPMI_ADMIN_PASSWD=$(IPMI_ADMIN_PASSWD) \
		'


$(_BUILDER_DIR):
	mkdir -p `dirname $(_BUILDER_DIR)`
	git clone --depth=1 https://github.com/pikvm/pi-builder $(_BUILDER_DIR)


$(_BLIKVM_SOURCE_DIR):
	mkdir -p `dirname $(_BLIKVM_SOURCE_DIR)`
	git clone --depth=1 https://github.com/ThomasVon2021/blikvm $(_BLIKVM_SOURCE_DIR)


update: $(_BUILDER_DIR) $(_BLIKVM_SOURCE_DIR)
	cd $(_BUILDER_DIR) && git pull --rebase
	git pull --rebase
	cd $(_BLIKVM_SOURCE_DIR) && git pull --rebase
	git pull --rebase


install: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) install


image: $(_BUILDER_DIR)
	$(eval _dated := blikvm-$(PLATFORM)-$(BOARD)$(SUFFIX)-$(shell date +%Y%m%d).img)
	mkdir -p images
	$(MAKE) -C $(_BUILDER_DIR) image IMAGE=$(shell pwd)/images/$(_dated) IMAGE_XZ=1
	cd images && ln -sf $(_dated).xz $(_latest).xz


scan: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) scan


clean: $(_BUILDER_DIR)
	$(MAKE) -C $(_BUILDER_DIR) clean


clean-all:
	rm -rf $(_BLIKVM_SOURCE_DIR)
	- rmdir `dirname $(_BLIKVM_SOURCE_DIR)`
	- $(MAKE) -C $(_BUILDER_DIR) clean-all
	rm -rf $(_BUILDER_DIR)
	- rmdir `dirname $(_BUILDER_DIR)`
