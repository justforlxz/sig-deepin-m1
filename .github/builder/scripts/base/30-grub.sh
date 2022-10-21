#!/bin/bash
set -e

MODULES="ext2 part_gpt search"

UUID="$ROOT_UUID"

# FIXME: grub-mkconfig failed
INITRD=$(ls -1 /boot/ | grep initrd)
VMLINUZ=$(ls -1 /boot/ | grep vmlinuz)

echo "Gen grub-core.cfg..."
cat << EOF > /tmp/grub-core.cfg
search.fs_uuid $ROOT_UUID root
set prefix=(\$root)'/boot/grub'
EOF

# cat << EOF > /tmp/grub-core.cfg
# insmod part_msdos
# insmod fat
# search --no-floppy --fs-uuid --set=root ${UUID}

# menuentry "Start Deepin" {
# linux /boot/${VMLINUZ} root=UUID=${UUID} rw
# initrd /boot/${INITRD}
# EOF

# grub-install refuses to work without a mounted EFI partition... sigh.
echo "Installing GRUB..."
mkdir -p /boot/grub
touch /boot/grub/device.map
dd if=/dev/zero of=/boot/grub/grubenv bs=1024 count=1
cp -r /usr/share/grub/themes /boot/grub
cp -r /usr/lib/grub/arm64-efi /boot/grub/
rm -f /boot/grub/arm64-efi/*.module
mkdir -p /boot/grub/{fonts,locale}
cp /usr/share/grub/unicode.pf2 /boot/grub/fonts
for i in /usr/share/locale/*/LC_MESSAGES/grub.mo; do
    lc="$(echo "$i" | cut -d/ -f5)"
    cp "$i" /boot/grub/locale/"$lc".mo
done

echo "Generating GRUB image..."
grub-mkimage \
    --directory '/usr/lib/grub/arm64-efi' \
    -c /tmp/grub-core.cfg \
    --prefix "/boot/grub" \
    --output /boot/grub/arm64-efi/core.efi \
    --format arm64-efi \
    --compression auto \
    $MODULES

# This seems to be broken
rm -f /etc/grub.d/30_uefi-firmware

# mkdir -p /boot/efi/EFI
# grub-install --target=arm64-efi --efi-directory=/boot/efi --removable
grub-mkfont -s 24 -o /boot/grub/fonts/dejavu.pf2 /usr/share/fonts/ttf-dejavu/DejaVuSansMono.ttf
# update-grub

# echo 'GRUB_DISABLE_LINUX_PARTUUID=false' >> /etc/default/grub
echo 'GRUB_CMDLINE_LINUX="rootwait console=tty1"' >> /etc/default/grub
echo 'GRUB_TIMEOUT=10' >> /etc/default/grub
echo 'GRUB_FONT="/boot/grub/fonts/dejavu.pf2"' >> /etc/default/grub

# grub-mkconfig is run during image creation
