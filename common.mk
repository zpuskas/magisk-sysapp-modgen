# Copyright (C) 2024  Zoltan Puskas
# License: GPLv3

# Overrideable configuration
NIKG_RELEASE ?= 28-Jul-2024
AUTHOR ?= Anonymous Coward

# Internal definitions
REQUIRED_BINS := sed unzip zipinfo wget 7z
BUILD_DIR := build-$(APP)
DOWNLOAD_DIR := cache

# Derived variables
MODULE_DIR := $(BUILD_DIR)/module
APK_DIR := $(BUILD_DIR)/apk
NIKG_BIN := $(DOWNLOAD_DIR)/NikG-$(APP).zip
APK_BIN := $(BUILD_DIR)/$(APP).zip
RELEASE_DATE := $(shell date -d$(NIKG_RELEASE) +%Y%m%d)

# Helpers
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))
check_command = \
	$(if $(shell command -v $(bin) 2> /dev/null),$(info Found `$(bin)`),$(error Please install `$(bin)`))

# Targets
.PHONY: module prepare clean mrporper app overlay priv-app etc-permissions properties

# High level targets
module: | prepare $(APP)_system_installer.zip

prepare: $(DOWNLOAD_DIR) $(BUILD_DIR)
	@:$(call check_defined, APP, Android application name)
	@:$(call check_defined, NIKG_RELEASE, NikGapps release version)
	@:$(call check_defined, MODULE_NAME, Name of the Magisk module)
	$(foreach bin,$(REQUIRED_BINS),$(call check_command,$(bin)))

$(APP)_system_installer.zip: app overlay priv-app etc-permissions properties
	7z a $(APP)_system_installer.zip ./$(MODULE_DIR)/*

clean:
	rm -rf $(BUILD_DIR)
	rm -rf *.zip

mrproper: clean
	rm -rf $(DOWNLOAD_DIR)

# Details
$(DOWNLOAD_DIR):
	mkdir -p $(DOWNLOAD_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

## Download NikGapps binary package
$(NIKG_BIN):
	wget "https://sourceforge.net/projects/nikgapps/files/Releases/Android-14/$(NIKG_RELEASE)/Addons/NikGapps-Addon-14-$(APP)-$(RELEASE_DATE)-signed.zip" -O $@

# Module skeleton
$(MODULE_DIR):
	mkdir -p $@
	cp -R --reflink module_template/* $@

## Obtain package application content
$(APK_BIN): $(NIKG_BIN)
	mkdir -p $(APK_DIR)
	unzip -p $(NIKG_BIN) AppSet/$(APP)/$(APP).zip > $@

## Extract binary and configuration content
$(APK_DIR): $(APK_BIN)
	mkdir -p $@
	unzip $(APK_BIN) -d $(APK_DIR) -x "*.sh"

## Create module content
app: name = $(subst $(APK_DIR)/___app___,,$(wildcard $(APK_DIR)/___app___*))
app: $(MODULE_DIR) $(APK_DIR)
	@if [ -d $(APK_DIR)/___app___$(name) ]; then\
		mkdir -p $(MODULE_DIR)/system/product/app/$(name) ;\
		cp -R --reflink $(APK_DIR)/___app___$(name)/* $(MODULE_DIR)/system/product/app/$(name)/ ;\
	fi

overlay: $(MODULE_DIR) $(APK_DIR)
	@if [ -d $(APK_DIR)/___overlay ]; then\
		mkdir -p $(MODULE_DIR)/system/product/overlay ;\
		cp -R --reflink $(APK_DIR)/___overlay/* $(MODULE_DIR)/system/product/overlay/ ;\
	fi

priv-app: name = $(subst $(APK_DIR)/___priv-app___,,$(wildcard $(APK_DIR)/___priv-app___*))
priv-app: $(MODULE_DIR) $(APK_DIR)
	@if [ -d $(APK_DIR)/___priv-app___$(name) ]; then\
		mkdir -p $(MODULE_DIR)/system/product/priv-app/$(name) ;\
		cp -R --reflink $(APK_DIR)/___priv-app___$(name)/* $(MODULE_DIR)/system/product/priv-app/$(name)/ ;\
	fi

etc-permissions: $(MODULE_DIR) $(APK_DIR)
	@if [ -d $(APK_DIR)/___etc___permissions ]; then\
		mkdir -p $(MODULE_DIR)/system/product/etc/permissions ;\
		cp -R --reflink $(APK_DIR)/___etc___permissions/* $(MODULE_DIR)/system/product/etc/permissions/ ;\
	fi

properties: $(MODULE_DIR)
	$(shell sed -i -e 's/@ID@/$(APP)_system_installer/' $(MODULE_DIR)/module.prop)
	$(shell sed -i -e 's/@NAME@/$(MODULE_NAME)/' $(MODULE_DIR)/module.prop)
	$(shell sed -i -e 's/@VERSION@/$(RELEASE_DATE)/' $(MODULE_DIR)/module.prop)
	$(shell sed -i -e 's/@AUTHOR@/$(AUTHOR)/' $(MODULE_DIR)/module.prop)
	$(shell sed -i -e 's/@DESC@/Module that installs $(APP) as a system application/' $(MODULE_DIR)/module.prop)
