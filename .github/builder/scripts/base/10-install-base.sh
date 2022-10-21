#!/bin/bash

set -e

echo "deb https://community-packages.deepin.com/beige/ beige main commercial community" > "$ROOT"/etc/apt/sources.list
# echo "deb https://pools.uniontech.com/deepin-beige beige main commercial community" > "$ROOT"/etc/apt/sources.list

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

apt-get update

mkdir -p /boot/efi
mkdir -p /boot/grub

base=(
    linux-image-5.10.0-arm64-desktop
    grub-efi
    grub-theme-starfield
    dmidecode
    initramfs-tools
    linux-firmware
    systemd
    systemd-sysv
    vim
    sudo
    )

apt-get -y install ${base[@]}

apt-get -y install deepin-desktop-environment-core

apt-get clean

update-initramfs -u -c -k all
