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

export PKGDEST="~/workspace/arch/packages"

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
    NAME=$(echo "$REPO" | awk -F '/' '{print substr($4, 1, length($4) - 4)}')

    echo -n "Cloning  '$NAME'..."
    ERROR=$(git clone -q "$REPO" ~/workspace/arch/"$NAME" 2>&1)
    check_returncode $? "$ERROR"

    cd ~/workspace/arch/"$NAME"

    echo -n "Building '$NAME'..."
    ERROR=$(PKGDEST="${HOME}/workspace/arch/packages" makepkg -rsc --nocolor --noconfirm --needed 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"
}

install_packages() {
    echo -n "Installing all built packages..."
    ERROR=$(sudo pacman -U --noconfirm ~/workspace/arch/packages/*.tar.xz 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"
}

echo -e "\n$SUBHORIZONTALE"
echo -e "\tAUR Packages"
echo -e "$SUBHORIZONTALE\n"

echo "=> Authentication required to install all AUR packages:"
sudo -v

if [ $? -ne 0 ]; then echo "=> Authentication failed" >&2; exit 1; fi

echo -ne "Creating directories..."
ERROR=$(mkdir -p ~/workspace/arch/packages 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

#for key in "${PUB_KEYS[@]}"; do
#    import_key "$key"
#done

for repo in "${AUR_REPOS[@]}"; do
    build "$repo"
done

# Install all packages in one step
install_packages

exit 0
