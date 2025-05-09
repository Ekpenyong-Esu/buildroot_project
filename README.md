# Buildroot Project Setup Guide

This repository contains assignment starter code for buildroot based assignments for the course Advanced Embedded Software Design, ECEN 5713. It provides a framework for building embedded Linux systems using Buildroot.

## Quick Start Guide

1. Prerequisites:
   - Linux development environment
   - Git
   - Required development packages
   - QEMU for ARM64 emulation

2. Initial Setup:

```bash
# Clone the repository
git clone <repository-url>
cd buildroot_project

# Initialize submodules
git submodule update --init --recursive

# Create necessary directories
mkdir -p base_external/{configs,package}
mkdir -p base_external/rootfs_overlay/etc
```

3. Set up Build Scripts:
   - Follow the "Creating Build Scripts" section below
   - Make scripts executable with: `chmod +x *.sh`

4. Configure and Build:

```bash
cd buildroot
make clean
make BR2_EXTERNAL=../base_external aesd_qemu_defconfig
cd ..
./build.sh
```

5. Run the System:

```bash
./runqemu.sh
```

## Detailed Setup Instructions

### Creating Build Scripts

First, create these essential scripts in your project root:

1. `shared.sh` - Configuration Variables:

```bash
#!/bin/bash
# Configuration paths and variables shared between scripts
AESD_MODIFIED_DEFCONFIG="base_external/configs/aesd_qemu_defconfig"
AESD_MODIFIED_DEFCONFIG_REL_BUILDROOT="../base_external/configs/aesd_qemu_defconfig"
AESD_DEFAULT_DEFCONFIG="configs/qemu_aarch64_virt_defconfig"
```

2. `build.sh` - Build Management:

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

3. `save-config.sh` - Configuration Management:

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

4. `clean.sh` - Cleanup:

```bash
#!/bin/bash
#Script to clean buildroot configuration

make -C buildroot distclean

# Clean any external build artifacts
rm -rf base_external/build/
rm -rf base_external/target/
rm -rf rootfs_overlay/

# Delete any generated configs
rm -f buildroot/.config
```

### Project Structure

- `base_external/` - Custom configurations and packages
  - `configs/` - Custom defconfig files
  - `package/` - Custom package definitions
  - `rootfs_overlay/` - Custom root filesystem overlays
- `buildroot/` - Main buildroot source tree
- `assignment-autotest/` - Test framework

### Configuration Management

1. Modifying Buildroot Configuration:

```bash
cd buildroot
make menuconfig
```

2. Saving Changes:

```bash
cd ..
./save-config.sh
```

### Installing Additional Packages

Example: Installing universal-ctags

1. Configure buildroot packages:

```bash
cd buildroot
make menuconfig
```

- Navigate to: Target packages → Development tools
- Select: universal-ctags
- Save and exit

2. Update configuration:

```bash
cd ..
./save-config.sh
./build.sh
```

## Advanced Usage

### Script Dependencies and Requirements

Each script has specific dependencies and requirements:

1. `shared.sh`:

- Must be sourced by other scripts
- Defines configuration paths used by build and save scripts
- Can be customized for different boards by modifying the defconfig paths

2. `build.sh`:

- Requires git for submodule management
- Depends on shared.sh for configuration paths
- Handles both initial and subsequent builds
- Key features:
  - Automatic submodule initialization
  - Configuration file management
  - Support for external buildroot trees
  - Error handling with set -e

3. `save-config.sh`:

- Depends on shared.sh for paths
- Creates necessary directories if missing
- Handles both buildroot and kernel configurations
- Features:
  - Automatic directory creation
  - Linux kernel config preservation
  - Safe config backup

4. `clean.sh`:

- Independent operation (no dependencies)
- Comprehensive cleanup:
  - Buildroot distclean
  - External build artifacts
  - Generated configs
  - Temporary files

5. `runqemu.sh`:

- Requires QEMU installation
- Configures virtual hardware
- Network setup included
- Customizable parameters:
  - Memory size
  - Network configuration
  - Serial port settings
  - Display options

### Advanced Usage Examples

1. Custom Configuration Paths:

```bash
# In shared.sh
AESD_MODIFIED_DEFCONFIG="path/to/custom/defconfig"
AESD_DEFAULT_DEFCONFIG="configs/custom_board_defconfig"
```

2. Build with Custom External Tree:

```bash
# In build.sh
make -C buildroot BR2_EXTERNAL=/path/to/external defconfig
```

3. Selective Cleaning:

```bash
# In clean.sh
# Add selective cleaning options
make -C buildroot clean # Instead of distclean
rm -rf buildroot/output/target # Clean only target
```

4. Advanced QEMU Options:

```bash
# In runqemu.sh
# Add custom QEMU parameters
-m 1024M # More memory
-smp 2 # Multiple cores
-display none # Headless mode
```

### Script Troubleshooting

1. Build Script Issues:

- Check git submodule status
- Verify buildroot/.config exists
- Confirm BR2_EXTERNAL path is correct
- Check build logs in buildroot/output/build/

2. Save Config Issues:

- Verify directory permissions
- Check for existing configs
- Ensure proper path structure
- Validate config file syntax

3. Clean Script:

- Handle permission issues
- Protect custom configurations
- Manage linked files
- Handle locked files

4. QEMU Script:

- Network configuration
- Device emulation
- Resource allocation
- Display settings

## Best Practices

1. Version Control:

- Keep scripts in version control
- Document changes in comments
- Use meaningful commit messages
- Tag stable versions

2. Configuration Management:

- Use consistent naming
- Document custom changes
- Back up configurations
- Use relative paths

3. Error Handling:

- Check return codes
- Log errors appropriately
- Provide meaningful messages
- Handle cleanup on failure

4. Maintenance:

- Regular testing
- Update dependencies
- Document modifications
- Monitor resource usage

## Support and References

- For buildroot issues: Check buildroot documentation
- For project issues: Contact course staff
- Buildroot Manual: <https://buildroot.org/downloads/manual/manual.html>
