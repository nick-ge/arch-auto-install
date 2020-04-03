#!/bin/sh

su nick -c /root/setup/get_dotfiles.sh
if [ $? -eq 0 ]; then
    echo -e "=> Configuring dotfiles finished successfully"
else
    echo "=> Configuring dotfiles failed" >&2
    exit 1
fi

su nick -c /root/setup/aur_packages.sh
if [ $? -eq 0 ]; then
    echo -ne "=> Installing AUR Packages finished successfully"
else
    echo "=> Installing AUR Packages failed" >&2
    exit 1
fi
