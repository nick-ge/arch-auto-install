#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide
# The following comments prefixed with "Section:" refer to the (sub)sections in the Arch Wiki's Installation Guide.

# Common variable for storing return texts of certain commands
ERROR=""

# Some pseudo GUI variables
HORIZONTALE="=========================================================================="
SUBHORIZONTALE="====================================="


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
        echo -e "\n${ERRORTEXT}"
        echo "=> ERROR: Installation process aborted"
        exit $RETURN
    fi
}

echo -e "\n$HORIZONTALE"
echo -e "\t\t\tArch Linux Installation Script"
echo -e "$HORIZONTALE\n"

# Section: Pre-Installation

echo -ne "Synchronizing system clock...\t\t\t"
ERROR=$(timedatectl set-ntp true 2>&1 1>/dev/null)
check_returncode $? $ERROR

echo -e "\n$SUBHORIZONTALE"
echo -e "\tPartitioning"
echo -e "$SUBHORIZONTALE\n"

echo -ne "Reading partition table...\t\t\t"
PARTITIONTABLE=$(cat partition-table.conf 2>&1 1>/dev/null)
check_returncode $? $PARTITIONTABLE

echo -ne "Apply partition instructions...\t\t\t"
# sfdisk is a "scriptable" version of fdisk, it receives the "user input" from stdin.
sfdisk /dev/sda 1>/dev/null 2>&1 << EOF
    $PARTITIONTABLE
EOF
check_returncode $? "Partitioning with sfdisk failed"


echo -ne "Verifing Partition table...\t\t\t"
# sfdisk -V: verifies the partition table of /dev/sda
ERROR=$(sfdisk -V /dev/sda 2>&1 1>/dev/null)
check_returncode $? $ERROR


## Subsection: Format the partitions
echo -ne "Formatting root partition...\t\t\t"
ERROR=$(mkfs.ext4 -q /dev/sda1 2>&1 1>/dev/null)
check_returncode $? $ERROR

echo -ne "Initializing swap partition...\t\t\t"
ERROR=$(mkswap /dev/sda2 2>&1 1>/dev/null)
check_returncode $? $ERROR

echo -ne "Enabling swap partition...\t\t\t"
ERROR=$(swapon /dev/sda2 2>&1 1>/dev/null)
check_returncode $? $ERROR


## Subsection: Mounting the file system
echo -ne "Mounting file system to /mnt...\t\t\t"
ERROR=$(mount /dev/sda1 /mnt 2>&1 1>/dev/null)
check_returncode $? $ERROR

# Section: Installation

## Subsection: Select the mirror
echo -ne "Downloading current mirrorlist...\t\t"
ERROR=$(curl --silent "https://www.archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4" | sed 's/#Server/Server/' > /etc/pacman.d/mirrorlist)
check_returncode $? $ERROR

## Subsection: Install essential packages
echo -ne "Installing essential packages...\t\t"
ERROR=$(pacstrap /mnt $(cat packagelist) 2>&1 1>/dev/null)
check_returncode $? $ERROR

# Section: Configure the system

## Subsection: fstab
echo -ne "Generating an fstab file...\t\t\t"
ERROR=$(genfstab -U /mnt 2>&1 1>>/mnt/etc/fstab)
check_returncode $? $ERROR

## Subsection: Chroot

cp chrooted.sh /mnt/root/.
chmod +x /mnt/root/chrooted.sh
echo "Chrooting into new system..."
arch-chroot /mnt /root/chrooted.sh

if [ $? -eq 0 ]; then
    echo "=> Arch base installation successfully finished"
else
    echo "=> Arch base installation failed"
fi
