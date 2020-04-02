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

install_aurpkg() {
    # Saving URL to repository in a variable and using awk to extract the 'folder' name
    local REPO=${1}
    local NAME=$(echo "$REPO" | awk -F '/' '{print $5}')

    echo -ne "Cloning '$NAME'...\t"
    ERROR=$(git clone "$REPO" ~/"$NAME" 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

    echo -ne "Installing '$NAME'...\t"
    ERROR=$(makepkg -is --nocolor --no-confirm)
    check_returncode $? "$ERROR"
    return $?
}

echo -e "\n$SUBHORIZONTALE"
echo -e "\tAUR Packages"
echo -e "$SUBHORIZONTALE\n"

install_aurpkg "https://aur.archlinux.org/zsh-syntax-highlighting-git.git"
install_aurpkg "https://aur.archlinux.org/polybar.git"



