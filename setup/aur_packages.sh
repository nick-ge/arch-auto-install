#!/bin/sh

SUBHORIZONTALE="==========================="

PUB_KEYS=("EB774491D9FF06E2")

AUR_REPOS=("https://aur.archlinux.org/zsh-syntax-highlighting-git.git" \
           "https://aur.archlinux.org/polybar.git" \
          #"https://aur.archlinux.org/tor-browser.git" \
           "https://aur.archlinux.org/vim-plug.git" \
           "https://aur.archlinux.org/ttf-font-awesome-4.git" \
           "https://aur.archlinux.org/ttf-material-icons-git.git" \
           "https://aur.archlinux.org/ttf-dejavu-sans-code.git" \
           "https://aur.archlinux.org/noto-fonts-sc.git")

check_returncode() {
    local RETURN=${1} ERRORTEXT=${2}
    if [ $RETURN -eq 0 ]; then
        echo "OK"
        return 0
    else
        echo "ERROR"
        echo "${ERRORTEXT}" >&2
        return $RETURN
    fi
}

import_key() {
    KEY=$1
    echo -ne "Importing public key '$KEY'..."
    ERROR=$(gpg --recv-keys "$KEY" 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"
}

build() {
    # Saving URL to repository in a variable and using awk to extract the 'folder' name
    REPO=${1}
    NAME=$(echo "$REPO" | awk -F '/' '{print $4}')

    echo -ne "Cloning '$NAME'...\t"
    ERROR=$(git clone -q "$REPO" ~/workspace/arch/"$NAME" 2>&1)
    check_returncode $? "$ERROR"

    cd ~/workspace/arch/"$NAME"

    echo -ne "Building '$NAME'...\t"
    ERROR=$(makepkg -rsc --nocolor --noconfirm --needed 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"
    return $?
}

install_packages() {
    echo "Installing all built packages..."
    ERROR=$(sudo pacman -U ~/workspace/arch/packages/*.tar.xz 2>&1 1>/dev/null)
    RETURN=$?
    if [ $? -eq 0 ]; then
        echo "=> All packages installed successfully"
        return 0
    else
        echo "=> AUR Packages installation failed" >&2
        return $RETURN
    fi   
}

echo -e "\n$SUBHORIZONTALE"
echo -e "\tAUR Packages"
echo -e "$SUBHORIZONTALE\n"

echo -ne "Creating directories...\t\t\t\t"
ERROR=$(mkdir -p ~/workspace/arch/packages 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

#for key in "${PUB_KEYS[@]}"; do
#    import_key "$key"
#done

for repo in "${AUR_REPOS[@]}"; do
    build "$repo"
done

ls ~/workspace/arch/packages

install_packages

exit 0
