################################################################################
#
# LDD
#
################################################################################

LDD_VERSION = main
LDD_SITE = git@github.com:cu-ecen-aeld/assignment-7-Ekpenyong-Esu.git
LDD_SITE_METHOD = git
LDD_GIT_SUBMODULES = YES

LDD_MODULE_SUBDIRS = misc-modules scull

define LDD_BUILD_CMDS
    # Build the scull driver
    $(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D)/scull EXTRA_CFLAGS="-I$(@D)/include" modules
    
    # Build the misc-modules drivers
    $(MAKE) $(LINUX_MAKE_FLAGS) -C $(LINUX_DIR) M=$(@D)/misc-modules EXTRA_CFLAGS="-I$(@D)/include" modules
endef


define LDD_INSTALL_TARGET_CMDS
    # Install scripts
    $(INSTALL) -m 0755 $(@D)/misc-modules/module_load $(TARGET_DIR)/usr/bin
    $(INSTALL) -m 0755 $(@D)/misc-modules/module_unload $(TARGET_DIR)/usr/bin
    $(INSTALL) -m 0755 $(@D)/scull/scull_load $(TARGET_DIR)/usr/bin
    $(INSTALL) -m 0755 $(@D)/scull/scull_unload $(TARGET_DIR)/usr/bin
    
    # Copy the modules to /usr/bin for easy access by load scripts
    $(INSTALL) -m 0755 $(@D)/misc-modules/hello.ko $(TARGET_DIR)/usr/bin
    $(INSTALL) -m 0755 $(@D)/misc-modules/faulty.ko $(TARGET_DIR)/usr/bin
    $(INSTALL) -m 0755 $(@D)/scull/scull.ko $(TARGET_DIR)/usr/bin
endef

$(eval $(kernel-module))
$(eval $(generic-package))