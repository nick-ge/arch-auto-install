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
    local REPO={1} NAME=$(echo "$REPO" | awk -F '/' '{print $5}')
    
    echo -ne "Cloning '$NAME'...\t" 
    ERROR=$(git clone "$repo" ~/"$NAME")
    check_returncode $? "$ERROR"
   
    echo -ne "Installing '$NAME'...\t" 
    ERROR=$(makepkg -ir ~/"$NAME")
    check_returncode $? "$ERROR"
    return $?
}

echo -e "\n$SUBHORIZONTALE"
echo -e "\tAUR Packages"
echo -e "$SUBHORIZONTALE\n"

install_aurpkg "https://github.com/zsh-users/zsh-syntax-highlighting"



