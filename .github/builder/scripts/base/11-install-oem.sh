#!/bin/bash

set -e

# Install OEM
while IFS=read -r line;do
    curl -fsSL -o $line.deb https://github.com/deepin-community/sig-deepin-m1/releases/download/oem/$line
done < $(curl -fsSL https://github.com/deepin-community/sig-deepin-m1/releases/download/oem/oem.list)

apt-get install *.deb

apt-get clean

update-initramfs -u -c -k all
