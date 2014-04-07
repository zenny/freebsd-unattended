#!/bin/bash

# Temporary Root
FREEBSD_UNATTENDED="$HOME/.freebsd-unattended"

test -d $FREEBSD_UNATTENDED || mkdir $FREEBSD_UNATTENDED

# Install Prerequisites
sudo apt-get install kvm genisoimage -y

# Get ISO if you don't have it already
# TO DO: Multiple FreeBSD versions
ISO_CACHE_DIR="$FREEBSD_UNATTENDED/cache"
ISO="$ISO_CACHE_DIR/FreeBSD-10.0-RELEASE-amd64-disc1.iso"

test -d $ISO_CACHE_DIR || mkdir $ISO_CACHE_DIR
test -f $ISO || wget -O $ISO ftp://ftp1.de.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/10.0/FreeBSD-10.0-RELEASE-amd64-disc1.iso

# ISO Temporary Directory
ISO_TEMP=$FREEBSD_UNATTENDED/tmp/iso
test -d $ISO_TEMP || mkdir -p $ISO_TEMP

# Extract ISO
ISO_MOUNT=$FREEBSD_UNATTENDED/tmp/mount
test -d $ISO_MOUNT || mkdir -p $ISO_MOUNT
sudo mount -o loop $ISO $ISO_MOUNT

# tar -C $ISO_TEMP -pvxf FreeBSD-10.0-RELEASE-amd64-disc1.iso <- ON FREEBSD ONLY

# Copy files to ISO_TEMP
sudo cp -Rp $ISO_MOUNT/* $ISO_TEMP

# Umount ISO
sudo umount $ISO_MOUNT
rm -rf $ISO_MOUNT

# Apply vanilla installer config if $1
# TO DO: Check for file existence
FLAVOR=$1

if test -n "$FLAVOR" ; then 
    CONFIG=$FLAVOR
else
    CONFIG=vanilla
fi

sudo cp installerconfigs/$CONFIG $ISO_TEMP/etc/installerconfig

# Rebuild ISO
OLD_PWD=`pwd`
cd $ISO_TEMP
ISO_UNATTENDED=$OLD_PWD/$CONFIG-FreeBSD-10.0-RELEASE-amd64-disc1.iso
sudo genisoimage -v -b boot/cdboot -no-emul-boot -r -J -V "FREEBSD_INSTALL" -o $ISO_UNATTENDED $ISO_TEMP
cd $OLD_PWD

# Create QCOW2 Image
# TO DO: Image size
IMAGE=$CONFIG-FreeBSD-10.0-RELEASE.qcow2
qemu-img create -f qcow2 $IMAGE 100G

# Start Install
kvm -m 1024 -smp 1 -cdrom $ISO_UNATTENDED $IMAGE -boot d -vga std -k en-us -vnc :10

# Clean up
# TO DO: Keep or not the ISO
sudo rm -rf $ISO_TEMP $ISO_UNATTENDED
