#!/bin/sh

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

## Subsection: Time zone
echo -ne "Setting time zone...\t"
ERROR=$(ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime 2>&1 1>/dev/null)
check_returncode $? $ERROR

echo -ne "Syncing hardware clock...\t"
ERROR=$(hwclock --systohc 2>&1 1>/dev/null)
check_returncode $? $ERROR

## Subsection: Localization
echo -ne "Uncommenting needed locales...\t"
ERROR=$(sed 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>&1 1>/etc/locale.gen)
check_returncode $? $ERROR

echo -ne "Creating /etc/locale.conf...\t"
echo "LANG=en_US.UTF-8" > /etc/locale.conf
check_returncode $? $ERROR

echo -ne "Making keyboard settings persistent...\t"
echo "KEYMAP=de-latin1" > /etc/vconsole.conf
check_returncode $? $ERROR

## Subsection: Network configuration
read -p "Enter hostname: " hostname
echo -ne "Creating hostname file...\t"
ERROR=$(echo "${hostname}" 2>&1 1>/etc/hostname)
check_returncode $? $ERROR

echo -ne "Add entry to hosts...\t"
ERROR=$(echo -e "127.0.0.1\t${hostname}.localdomain ${hostname}" >> /etc/hosts)
check_returncode $? $ERROR

## Subsection: Initramfs
## Needed later when encrypting hard drives

## Subsection: Root password
#echo -ne "Root password needed..."
