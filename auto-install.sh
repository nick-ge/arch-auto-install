#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide
# The following comments prefixed with "Section:" refer to the (sub)sections in the Arch Wiki's Installation Guide.

# Common variable for storing return texts of certain commands
ERROR=""

# Information for partitioning
SWAP="8G"
ROOT="25G"


# Util function which gets invoked after every command.
# It checks the given return code and prints the error message and the
# respective return code in case of an error.
check_returncode() {
    local RETURN=${1} ERRORTEXT=${2}
    if [ $RETURN -eq 0 ]; then
        echo "OK"
        return 0
    else
        echo "ERROR"
        echo -e "\n${ERROR}"
        echo "=> ERROR: Installation process aborted"
        exit $RETURN
    fi
}

# Section: Pre-Installation

## Subsection: Update the system clock
echo -ne "Synchronizing system clock...\t\t"
ERROR=$(timedatectl set-ntp true 2>&1 1>/dev/null)
check_returncode $? $ERROR

## Subsection: Partition the disk
echo -ne "Partition the disk...\t\t\t"

# sfdisk is a "scriptable" version of fdisk, it receives the "user input" from stdin.
# Here we're creating two partitions:
# 1. a swap partition of size SWAP
# 2. a root partition which takes the remaining available space on the hard drive as its size and marked as bootable
sfdisk /dev/sda 1>/dev/null 2>&1 << EOF
    , ${ROOT}, , *
    , ${SWAP}, S
EOF
check_returncode $? "Partitioning with sfdisk failed"

echo -ne "Verifing Partition table...\t\t"
# sfdisk -V: verifies the partition table of /dev/sda
ERROR=$(sfdisk -V /dev/sda 2>&1 1>/dev/null)
check_returncode $? $ERROR


## Subsection: Format the partitions
echo -ne "Formatting root partition...\t\t"
ERROR=$(mkfs.ext4 -q /dev/sda1 2>&1 1>/dev/null)
check_returncode $? $ERROR

echo -ne "Initializing swap partition...\t\t"
ERROR=$(mkswap /dev/sda2 2>&1 1>/dev/null)
check_returncode $? $ERROR

echo -ne "Enabling swap partition...\t\t"
ERROR=$(swapon /dev/sda2 2>&1 1>/dev/null)
check_returncode $? $ERROR


## Subsection: Mounting the file system
echo -ne "Mounting file system to /mnt...\t\t"
ERROR=$(mount /dev/sda1 /mnt 2>&1 1>/dev/null)
check_returncode $? $ERROR

# Section: Installation

## Subsection: Select the mirror
echo -ne "Downloading current mirrorlist...\t"
ERROR=$(curl --silent "https://www.archlinux.org/mirrorlist/?country=DE&protocol=http&protocol=https&ip_version=4&use_mirror_status=on" | sed 's/#Server/Server/' > /etc/pacman.d/mirrorlist)
check_returncode $? $ERROR

## Subsection: Install essential packages
echo -ne "Installing essential packages...\t"
ERROR=$(pacstrap /mnt $(cat packagelist) 2>&1 1>/dev/null)
check_returncode $? $ERROR

# Section: Configure the system

## Subsection: fstab
echo -ne "Generating an fstab file...\t\t"
ERROR=$(genfstab -U /mnt 2>&1 1>>/mnt/etc/fstab)
check_returncode $? $ERROR

## Subsection: Chroot

cp chrooted.sh /mnt/root/.
chmod +x /mnt/root/chrooted.sh
echo -ne "Chrooting into new system...\t"
arch-chroot /mnt /root/chrooted.sh

echo "=> Arch base installation successfully finished"
