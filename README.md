# Build system for Linux and KVM on ARM platforms

This repository helps you to prepare and build a basic Linux Kernel and roofts with KVM virtualization stack.

The installation script **yocto-kvm-arm-env-setup.sh** will setup a ready-to-use poky-daisy Yocto distribution with meta layers for providing KVM on ARM:
 - *meta-virtualization*: support for building virtualization stack (KVM, libvirt, etc.)
 - *meta-ti*: basic support for TI boards (OMAP 5432)
 - *meta-kvm-arm*: add additional recipies / customize existing recipes to provide KVM/ARM on supported board

The supported boards until now are:
- TI OMAP 5432
- ODROID-XU
- ODROID-XU3

The generated images contain following elements:

|              | TI OMAP 5432 uEVM | ODROID-XU       |  ODROID-XU3     |
| ------------ | ----------------- | -------------   | -------------   |
| Machine name | omap5-evm-kvm     | odroidxu-kvm    | odroidxu3-kvm   |
| Linux Kernel | Patched 3.12      | Patched 3.13    | Patched 3.10    |
| U-Boot       | Patched 2013.07   | Patched 2012.07 | Patched 2012.07 |


The rootfs generated will contain following virtualization software stack:

- QEMU 1.7
- libvirt 1.2.2

## Prerequisites

Following packages have to be installed on Ubuntu before proceeding:

    apt-get install bc gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat libsdl1.2-dev xterm policykit-1-gnome

 **Note**: *policykit-1-gnome* package is required for libvirt compilation

## Installation

Use the following commands to get started:

    # clone this repository
    git clone https://forge.tic.eia-fr.ch/git/arm-virtualization/poky-kvm-arm.git

    # change directory
    cd poky-kvm-arm

    # execute initialization script
    ./yocto-kvm-arm-env-setup.sh

## Create image

After installing the required elements, you can generate your first kernel image with rootfs and u-boot:

    # go to poky-dora directory
    cd poky-daisy

    # configure build env
    source oe-init-build-env

    # build a minimal kvm image
    MACHINE=omap5-evm-kvm bitbake kvm-image-extended

Note that we use the **omap5-evm-kvm** machine, simply give another machine name to generate the image for other platforms.


## Deploy image

The generated images are available in this directory: BUILD_DIR/tmp/deploy/images/*machine-name*/

You can deploy these images to the target. The U-Boot image and MLO/SPL files have to be copied on the SD Card while Kernel and Rootfs can either be copied to the SD Card or accessed through NFS/TFTP.

The process for creating the bootable SD card depends on the board and is described below for each board.

### TI OMAP 5432 uEVM

A script initializing the SD-Card is provided as part of the meta-kvm-arm layer. It will:

* First clear the SD-Card
* Create two partitions: boot and rootfs
* Copy the following files from u-boot to the boot partition
 * MLO
 * u-boot.img
 * uImage
 * uImage-omap5-uevm.dtb -> omap5-uevm.dtb
 * u-boot-omap-kvm-boot.src.sd.3-12 -> boot.scr
* Extract the root file system (kvm-image-extended-omap5-evm-kvm.tar.gz) to the rootfs partition


#### Burn to SD-Card

The script is automatically copied to the omap5 image directory when you build with bitbake/hob, so you can simply call it with the device corresponding to the SD-Card:

    cd tmp/deploy/images/omap5-evm-kvm
    sudo ./install_on_sd_card.sh --device /dev/sdd


If the script succeeds, you should see this message at the end:

    Done. It is now safe to eject and remove your SD-Card.

You should now have a SD-Card with the software stack for KVM ready to be used.

### ODROID-XU and ODROID-XU3

A script initializing the SD-Card is provided as part of the meta-kvm-arm layer. It will:

* First clear the SD-Card
* Burn these files (signed by hardkernel) to the first sectors of the SD-Card:
 * bl1.hardkernel.bin.signed
 * bl2.u-boot-spl.bin.signed
 * u-boot.bin
 * tzsw.hardkernel.bin.signed
* Create two partitions: BOOT and rootfs
* Copy the following files from u-boot to the BOOT partition
 * uImage
 * exynos5410-odroidxu.dtb
 * boot.ini
* Extract the root file system (kvm-image-extended-odroidxu-kvm.tar.gz) to the rootfs partition

#### Burn to SD-Card

The script is automatically copied to the odroid image directory when you build with bitbake/hob, so you can simply call it with the device corresponding to the SD-Card:

**For ODROID-XU**

    cd tmp/deploy/images/odroidxu-kvm
    ./install_on_sd_card.sh /dev/sdd

**For ODROID-XU3**

    cd tmp/deploy/images/odroidxu3-kvm
    ./install_on_sd_card.sh /dev/sdd

If the script succeeds, you should see this message at the end:

    Done. It is now safe to eject and remove your SD-Card.

You should now have SD-Card with the software stack compiled previously ready to use.

## Clean

If you want to clean your local build / configuration, simply delete the poky-daisy folder and re-run the environment initialization script
    rm -rf poky-daisy
    ./yocto-kvm-arm-env-setup.sh
