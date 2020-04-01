#!/bin/sh

SUBHORIZONTALE="==========================="

check_returncode() {
    local RETURN=${1} ERRORTEXT=${2}
    if [ $RETURN -eq 0 ]; then
        echo "OK"
        return 0
    else
        echo "${ERRORTEXT}" >&2
        exit $RETURN
    fi
}

echo -e "\n$SUBHORIZONTALE"
echo -e " Chrooting into new system"
echo -e "$SUBHORIZONTALE\n"

## Subsection: Time zone
echo -ne "Setting time zone...\t\t\t\t"
ERROR=$(ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

echo -ne "Syncing hardware clock...\t\t\t"
ERROR=$(hwclock --systohc 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

## Subsection: Localization
echo -ne "Uncommenting needed locales...\t\t\t"
ERROR=$(sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>&1)
check_returncode $? "$ERROR"

echo -ne "Generating locales...\t\t\t\t"
ERROR=$(locale-gen 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

echo -ne "Creating /etc/locale.conf...\t\t\t"
echo "LANG=en_US.UTF-8" > /etc/locale.conf
check_returncode $? "$ERROR"

echo -ne "Making keyboard settings persistent...\t\t"
echo "KEYMAP=de" > /etc/vconsole.conf
check_returncode $? "$ERROR"

## Subsection: Network configuration
read -p "Enter hostname: " hostname
echo -ne "Creating hostname file...\t\t\t"
ERROR=$(echo "${hostname}" 2>&1 1>/etc/hostname)
check_returncode $? "$ERROR"

echo -ne "Add entry to hosts...\t\t\t\t"
ERROR=$(echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.0.1\t${hostname}.localdomain ${hostname}" >> /etc/hosts)
check_returncode $? "$ERROR"

## Subsection: Initramfs
## Needed later when encrypting hard drives

## Subsection: Root password
echo "Root password needed"
passwd
if [ $? -ne 0 ]; then
    echo "Setting root password failed" >&2
    exit 1
fi

## Subsection: Boot loader
echo -ne "Installing grub...\t\t\t\t"
ERROR=$(grub-install --target=i386-pc /dev/sda 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

echo -ne "Generating main config...\t\t\t"
ERROR=$(grub-mkconfig -o /boot/grub/grub.cfg 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

/root/chrooted/create_user.sh
if [ $? -eq 0 ]; then
    echo -e "=> Creating user finished successfully\n"
else
    echo "=> Creating user failed" >&2
    exit 1
fi

exit 0
