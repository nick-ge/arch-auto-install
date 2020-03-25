#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide
# The following comments prefixed with "Section:" refer to the (sub)sections in the Arch Wiki's Installation Guide.

# Common variable for storing return values of certain commands
STATUS=""

# Information for Partitioning
SWAP="8G"

abort() {
    echo -e "\n${STATUS}"
    echo "Installation process aborted."
    exit -1
}

# Section: Pre-installation

# Subsection: Update the system clock
echo -n "Synchronizing system clock..."
STATUS=$(timedatectl set-ntp true)
if [ -z $STATUS ]; then
   echo "DONE"
else
    abort
fi



# Subsection: Partition the disk
echo -n "Partition the disk..."

# sfdisk is a "scriptable" version of fdisk, it receives the "user input" from stdin.
# Here we're creating two partitions:
# 1. a swap partition of size SWAP
# 2. a root partition which takes the remaining available space on the hard drive as its size and is marked as bootable
sfdisk /dev/sda > /dev/null << EOF
    , ${SWAP}, S
    , , , *
EOF

# sfdisk -V: verifies the partition table of /dev/sda
STATUS=$(sfdisk -V /dev/sda)
if [ "$STATUS" = "/dev/sda:" ]; then
    echo "DONE"
else
    abort
fi



# Subsection: Format the partitions
echo -n "Formatting partitions..."
mkfs.ext4 -q /dev/sda2
mkswap /dev/sda1 > /dev/null
swapon /dev/sda1 > /dev/null
echo "DONE"



# Subsection: Mounting the file system
echo -n "Mounting file system to /mnt..."
STATUS=$(mount /dev/sda2 /mnt)
if [ -z $STATUS ]; then
    echo "DONE"
else
    abort
fi
