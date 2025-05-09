# BeagleBone Black Buildroot Setup Guide

This guide provides step-by-step instructions for setting up a buildroot development environment specifically for the BeagleBone Black board.

## Quick Start Guide

1. Hardware Requirements:
   - BeagleBone Black board
   - SD card (4GB or larger)
   - USB to TTL Serial Cable
   - 5V/2A power supply

2. Software Prerequisites:
   - Linux development environment
   - Git
   - Required development packages
   - Serial terminal program (e.g., minicom)

3. Initial Setup:

```bash
# Clone and prepare repository
git clone <repository-url>
cd buildroot_project
git submodule update --init --recursive

# Create directory structure
mkdir -p base_external/{configs,package}
mkdir -p base_external/rootfs_overlay/etc
```

4. Build and Flash:

```bash
# Configure for BeagleBone Black
cd buildroot
make beaglebone_defconfig
cd ..

# Build the system
./build.sh

# Flash to SD card (replace sdX with your SD card device)
sudo dd if=buildroot/output/images/sdcard.img of=/dev/sdX bs=1M
sync
```

5. Boot and Connect:
   - Insert SD card into BeagleBone Black
   - Connect serial cable (GND→Pin 1, RX→Pin 4, TX→Pin 5)
   - Connect power
   - Access console: `sudo minicom -D /dev/ttyUSB0 -b 115200`

## Detailed Setup Instructions

### Prerequisites

- Linux development environment
- Git
- Required development packages
- SD card (4GB or larger)
- BeagleBone Black board
- USB to TTL Serial Cable (for console access)

### Initial Setup

1. Clone the repository and enter the project directory:

```bash
git clone <repository-url>
cd buildroot_project
```

2. Initialize and update submodules:

```bash
git submodule update --init --recursive
```

### Configuring for BeagleBone Black

1. Create the base external directory structure:

```bash
mkdir -p base_external/configs
mkdir -p base_external/package
mkdir -p base_external/rootfs_overlay/etc
```

2. Configure buildroot for BeagleBone Black:

```bash
cd buildroot
make beaglebone_defconfig
```

3. Customize the configuration (optional):

```bash
make menuconfig
```

Key configurations to consider:

- Target Options: ARM (little endian)
- Target Architecture Variant: cortex-A8
- Toolchain: External toolchain
- System Configuration: modify as needed
- Target packages: add required packages
- Filesystem images: ext4 root filesystem

4. Save your custom configuration:

```bash
cd ..
./save-config.sh
```

### Script Setup and Configuration

Before proceeding with the build, you need to create and configure several essential scripts:

1. First, create `shared.sh` for common variables:

```bash
#!/bin/bash
# Configuration paths and variables shared between scripts
AESD_MODIFIED_DEFCONFIG="base_external/configs/beaglebone_defconfig"
AESD_MODIFIED_DEFCONFIG_REL_BUILDROOT="../base_external/configs/beaglebone_defconfig"
AESD_DEFAULT_DEFCONFIG="configs/beaglebone_defconfig"
```

2. Create `build.sh` for managing the build process:

```bash
#!/bin/bash
#Script to build buildroot configuration

source shared.sh

EXTERNAL_REL_BUILDROOT=../base_external
git submodule init
git submodule sync
git submodule update

set -e 
cd `dirname $0`

if [ ! -e buildroot/.config ]
then
    echo "MISSING BUILDROOT CONFIGURATION FILE"

    if [ -e ${AESD_MODIFIED_DEFCONFIG} ]
    then
        echo "USING ${AESD_MODIFIED_DEFCONFIG}"
        make -C buildroot defconfig BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT} BR2_DEFCONFIG=${AESD_MODIFIED_DEFCONFIG_REL_BUILDROOT}
    else
        echo "Run ./save_config.sh to save this as the default configuration in ${AESD_MODIFIED_DEFCONFIG}"
        echo "Then add packages as needed to complete the installation, re-running ./save_config.sh as needed"
        make -C buildroot defconfig BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT} BR2_DEFCONFIG=${AESD_DEFAULT_DEFCONFIG}
    fi
else
    echo "USING EXISTING BUILDROOT CONFIG"
    echo "To force update, delete .config or make changes using make menuconfig and build again."
    make -C buildroot BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT}
fi
```

3. Create `save-config.sh` for saving configurations:

```bash
#!/bin/bash
#Script to save the modified configuration

cd `dirname $0`
source shared.sh
mkdir -p base_external/configs/
make -C buildroot savedefconfig BR2_DEFCONFIG=${AESD_MODIFIED_DEFCONFIG_REL_BUILDROOT}

if [ -e buildroot/.config ] && [ ls buildroot/output/build/linux-*/.config 1> /dev/null 2>&1 ]; then
    grep "BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE" buildroot/.config > /dev/null
    if [ $? -eq 0 ]; then
        echo "Saving linux defconfig"
        make -C buildroot linux-update-defconfig
    fi
fi
```

4. Create `clean.sh` for cleaning the build:

```bash
#!/bin/bash
#Script to clean buildroot configuration

make -C buildroot distclean

# Clean any external build artifacts
rm -rf base_external/build/
rm -rf base_external/target/
rm -rf base_external/rootfs_overlay/

# Delete any generated configs
rm -f buildroot/.config
```

5. Create `runqemu.sh` for testing (optional, for QEMU testing):

```bash
#!/bin/bash
#Script to run QEMU for testing

qemu-system-arm -M beaglebone -dtb buildroot/output/images/am335x-boneblack.dtb \
    -kernel buildroot/output/images/zImage \
    -drive file=buildroot/output/images/rootfs.ext4,if=sd,format=raw \
    -append "root=/dev/mmcblk0 rw console=ttyAMA0,115200n8" \
    -serial stdio -net nic,model=virtio -net user
```

6. Make all scripts executable:

```bash
chmod +x build.sh save-config.sh clean.sh runqemu.sh shared.sh
```

These scripts work together to manage the buildroot build process:

- `shared.sh` contains common variables used by other scripts
- `build.sh` manages the build process and configuration
- `save-config.sh` saves your buildroot and kernel configurations
- `clean.sh` cleans the build environment
- `runqemu.sh` provides QEMU testing capabilities

### Advanced Script Usage

#### BeagleBone Black Specific Configurations

1. Custom U-Boot Configuration:

```bash
# In shared.sh for custom U-Boot config
UBOOT_CUSTOM_CONFIG="configs/am335x_evm_defconfig"
```

2. BeagleBone Black Device Tree Options:

```bash
# In build.sh, add support for additional DTBs
BR2_LINUX_KERNEL_INTREE_DTS_NAME="am335x-boneblack am335x-bonegreen"
```

3. BeagleBone Black QEMU Testing:

```bash
# In runqemu.sh
# BeagleBone Black specific QEMU options
-M beaglebone \
-dtb buildroot/output/images/am335x-boneblack.dtb \
-sd buildroot/output/images/sdcard.img \
-serial stdio
```

#### Hardware-Specific Considerations

1. Boot Switch Configuration:

- S2 switch settings for SD boot
- Alternative eMMC boot options
- Boot sequence configuration

2. Pin Multiplexing:

- UART pin configuration
- GPIO setup
- Device tree overlays

3. Power Management:

- Power supply requirements
- Battery considerations
- Sleep mode configuration

#### Advanced Debugging

1. Serial Console:

- Multiple UART configurations
- Debug message levels
- Boot log analysis

2. Network Debugging:

- Ethernet interface setup
- TFTP boot options
- NFS root filesystem

3. Development Tools:

- Cross-compilation environment
- Remote debugging
- Performance profiling

#### Production Deployment

1. Image Customization:

- Minimal image configuration
- Security hardening
- Custom initialization

2. Bootloader Options:

- MLO customization
- U-Boot environment
- Boot script development

3. Factory Programming:

- Mass production setup
- Image verification
- Version control

### Building the Image

1. Run the build script:

```bash
./build.sh
```

The build process will create several files in `buildroot/output/images/`:

- `MLO` - First stage bootloader
- `u-boot.img` - U-Boot bootloader
- `zImage` - Linux kernel
- `am335x-boneblack.dtb` - Device Tree Blob
- `rootfs.ext4` - Root filesystem
- `sdcard.img` - Complete SD card image

### Creating the SD Card

1. Insert your SD card into your development machine

2. Write the image to the SD card (replace sdX with your SD card device):

```bash
sudo dd if=buildroot/output/images/sdcard.img of=/dev/sdX bs=1M
sync
```

### Booting the BeagleBone Black

1. Connect the USB to TTL Serial Cable:

- Connect GND to BeagleBone Black's GND (Pin 1)
- Connect RX to BeagleBone Black's TX (Pin 4)
- Connect TX to BeagleBone Black's RX (Pin 5)

2. Configure your serial terminal:

```bash
sudo minicom -D /dev/ttyUSB0 -b 115200
```

3. Insert the SD card and power up the board

4. Default login credentials:

- Username: root
- Password: (none)

### Installing Additional Software

To install universal-ctags or other packages:

1. Modify the configuration:

```bash
cd buildroot
make menuconfig
```

2. Navigate to:

- Target packages
- Development tools
- Select universal-ctags

3. Save and rebuild:

```bash
cd ..
./save-config.sh
./build.sh
```

### Network Configuration

The default configuration includes:

- Ethernet support
- DHCP client
- SSH server

To configure a static IP:

1. Edit `/etc/network/interfaces` in base_external/rootfs_overlay
2. Rebuild the image

### Troubleshooting

1. Boot Issues:

- Verify SD card is properly written
- Check serial console output
- Verify boot switches are set correctly for SD boot

2. Network Issues:

- Check ethernet cable connection
- Verify DHCP server is available
- Check IP configuration

3. Build Errors:

- Check build logs in buildroot/output/build/
- Verify toolchain installation
- Ensure all prerequisites are installed

### Development Workflow

1. Make changes to configuration:

```bash
make -C buildroot menuconfig
```

2. Save changes:

```bash
./save-config.sh
```

3. Rebuild:

```bash
./build.sh
```

4. Test changes:

- Write new image to SD card
- Boot and test on BeagleBone Black

## Support

For issues related to:

- Buildroot: Check buildroot documentation
- BeagleBone Black: Visit beagleboard.org
- Project specific: Contact course staff

## References

- BeagleBone Black System Reference Manual
- Buildroot Manual: <https://buildroot.org/downloads/manual/manual.html>
- U-Boot Documentation: <https://u-boot.readthedocs.io/>
