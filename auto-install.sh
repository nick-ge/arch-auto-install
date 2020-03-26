#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide
# The following comments prefixed with "Section:" refer to the (sub)sections in the Arch Wiki's Installation Guide.

# Common variable for storing return texts of certain commands
STATUS=""
# Common variable for storing return codes of certain commands
RETURN=0


# Information for partitioning
SWAP="7.8G"
ROOT="7.2G"


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
        echo -e "\n${STATUS}"
        echo "=> ERROR: Installation process aborted"
        exit $RETURN
    fi
}

# Section: Pre-Installation

## Subsection: Update the system clock
echo -ne "Synchronizing system clock...\t\t"
STATUS=$(timedatectl set-ntp true)
check_returncode $? $STATUS

## Subsection: Partition the disk
echo -ne "Partition the disk...\t\t\t"

# sfdisk is a "scriptable" version of fdisk, it receives the "user input" from stdin.
# Here we're creating two partitions:
# 1. a swap partition of size SWAP
# 2. a root partition which takes the remaining available space on the hard drive as its size and marked as bootable
sfdisk /dev/sda 2>&1 1> /dev/null << EOF
    , ${ROOT}, , *
    , ${SWAP}, S
EOF
check_returncode $? "Partitioning with sfdisk failed"

echo -ne "Verifing Partition table...\t\t"
# sfdisk -V: verifies the partition table of /dev/sda
STATUS=$(sfdisk -V /dev/sda)
check_returncode $? $STATUS


## Subsection: Format the partitions
echo -ne "Formatting root partition...\t\t"
STATUS=$(mkfs.ext4 -q /dev/sda2)
check_returncode $? $STATUS

echo -ne "Initializing swap partition...\t\t"
STATUS=$(mkswap /dev/sda1 > /dev/null)
check_returncode $? $STATUS

echo -ne "Enabling swap partition...\t\t"
STATUS=$(swapon /dev/sda1 > /dev/null)
check_returncode $? $STATUS


## Subsection: Mounting the file system
echo -ne "Mounting file system to /mnt...\t\t"
STATUS=$(mount /dev/sda2 /mnt)
check_returncode $? $STATUS


# Section: Installation

## Subsection: Select the mirror
echo -ne "Downloading current mirrorlist...\t"
STATUS=$(curl --silent "https://www.archlinux.org/mirrorlist/?country=DE&protocol=http&protocol=https&ip_version=4&use_mirror_status=on" | sed 's/#Server/Server/' > /etc/pacman.d/mirrorlist)
check_returncode $? $STATUS
