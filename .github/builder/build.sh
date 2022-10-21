#!/bin/bash

set -e

BASE_IMAGE_URL="https://github.com/deepin-community/sig-deepin-m1/releases/download/base/beige-arm64.tgz"
BASE_IMAGE="$(basename "$BASE_IMAGE_URL")"

DL="$PWD/dl"
ROOT="$PWD/root"
FILES="$PWD/files"
IMAGES="$PWD/images"
IMG="$PWD/img"

EFI_UUID=2ABF-9F91
ROOT_UUID=725346d2-f127-47bc-b464-9dd46155e8d6
export ROOT_UUID EFI_UUID

if [ "$(whoami)" != "root" ]; then
    echo "You must be root to run this script."
    exit 1
fi

clean_mounts() {
    umount -R "$ROOT"/proc || true
    umount -R "$ROOT"/dev || true
    umount -R "$ROOT"/sys || true
	while grep -q "$ROOT/[^ ]" /proc/mounts; do
		cat /proc/mounts | grep "$ROOT" | cut -d" " -f2 | xargs umount || true
		sleep 0.1
	done
}

clean_mounts

umount "$IMG" 2>/dev/null || true
mkdir -p "$DL" "$IMG"

if [ ! -e "$DL/$BASE_IMAGE" ]; then
    echo "## Downloading base image..."
    wget -c "$BASE_IMAGE_URL" -O "$DL/$BASE_IMAGE.part"
    mv "$DL/$BASE_IMAGE.part" "$DL/$BASE_IMAGE"
fi

umount "$ROOT" 2>/dev/null || true
rm -rf "$ROOT"
mkdir -p "$ROOT"

#echo "## Unpacking base image..."
#tar -xvzf "$DL/$BASE_IMAGE" -C "$ROOT"

# cp -r "$FILES" "$ROOT"
mkdir -p "$ROOT"/boot/efi/m1n1
cp boot.bin "$ROOT"/boot/efi/m1n1/

mount --bind "$ROOT" "$ROOT"

run_scripts() {
    group="$1"
    echo "## Running script group: $group"
    for i in "scripts/$group/"*; do
        echo "### Running $i"
        arch-chroot "$ROOT" /bin/bash <"$i"
	# Work around some devtmpfs shenanigans... something keeps that mount in use?
	clean_mounts
    done
}

make_image() {
    imgname="$1"
    img="$IMAGES/$imgname"
    mkdir -p "$img"
    echo "## Making image $imgname"
    echo "### Cleaning up..."
    rm -rf "$ROOT/var/cache/apt/archives"/*
    echo "### Calculating image size..."
    size="$(du -B M -s "$ROOT" | cut -dM -f1)"
    echo "### Image size: $size MiB"
    size=$(($size + ($size / 8) + 64))
    echo "### Padded size: $size MiB"
    rm -f "$img/root.img"
    truncate -s "${size}M" "$img/root.img"
    echo "### Making filesystem..."
    mkfs.ext4 -O '^metadata_csum' -U "$ROOT_UUID" -L "deepin-root" "$img/root.img"
    echo "### Loop mounting..."
    mount -o loop "$img/root.img" "$IMG"
    echo "### Copying files..."
    rsync -aHAX \
        --exclude /files \
        --exclude '/tmp/*' \
        --exclude /etc/machine-id \
        --exclude '/boot/efi/*' \
        --exclude /var/cache/apt/ \
        --exclude '/oem/' \
        "$ROOT/" "$IMG/"
    rsync -aHAX --exclude /oem "files/*" "$IMG"
    echo "### Unmounting..."
    umount -R "$IMG"
    echo "### Creating EFI system partition tree..."
    mkdir -p "$img/esp/EFI/BOOT"
    cp "$ROOT"/boot/grub/arm64-efi/core.efi "$img/esp/EFI/BOOT/BOOTAA64.EFI"
    cp -r "$ROOT"/boot/efi/m1n1 "$img/esp/"
    echo "### Compressing..."
    rm -f "$img".zip
    ( cd "$img"; zip -1 -r ../"$imgname".zip * )
    echo "### Done"
}

run_scripts base
make_image "deepin-base"

if [ -f $ROOT/var/lib/deepin/deepin_security_verify.whitelist ];then
    chattr -i $ROOT/var/lib/deepin/deepin_security_verify.whitelist
fi