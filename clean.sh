#!/bin/bash
#Script to clean buildroot configuration
#Author: Your Name

make -C buildroot distclean

# Clean any external build artifacts
rm -rf base_external/build/
rm -rf base_external/target/
rm -rf rootfs_overlay/

# Delete any generated configs
rm -f buildroot/.config