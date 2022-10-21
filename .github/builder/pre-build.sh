#!/bin/bash

mkdir .workdir

cd .workdir

function build_m1n1() {
    git clone --recursive https://github.com/AsahiLinux/m1n1.git
    cd m1n1
    make -j$(nproc)
}

function build_uboot() {
    git clone --recursive https://github.com/AsahiLinux/u-boot.git
    cd u-boot
    make apple_m1_defconfig
    make -j$(nproc)
}

build_m1n1
build_uboot

cat m1n1/build/m1n1.bin /path/to/dtbs/*.dtb /path/to/uboot/u-boot-nodtb.bin > /boot/efi/m1n1/boot.bin
