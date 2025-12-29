#!/bin/bash
set -e

WORK_DIR="/tmp/rizzo-build"
ISO_OUTPUT="$GITHUB_WORKSPACE/iso/RizzoOS-1.0.iso"

mkdir -p "$WORK_DIR"/{chroot,iso/{boot/grub,live}}
mkdir -p "$(dirname "$ISO_OUTPUT")"

sudo debootstrap --arch=amd64 --variant=minbase bookworm "$WORK_DIR/chroot" http://deb.debian.org/debian

cat << 'EOF' | sudo tee "$WORK_DIR/chroot/etc/apt/sources.list"
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
EOF

sudo mount --bind /dev "$WORK_DIR/chroot/dev"
sudo mount --bind /dev/pts "$WORK_DIR/chroot/dev/pts"
sudo mount -t proc proc "$WORK_DIR/chroot/proc"
sudo mount -t sysfs sysfs "$WORK_DIR/chroot/sys"

sudo chroot "$WORK_DIR/chroot" /bin/bash << 'CHROOT'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y linux-image-amd64 live-boot systemd-sysv
apt-get install -y kde-plasma-desktop sddm dolphin konsole
apt-get clean
CHROOT

sudo umount -lf "$WORK_DIR/chroot/dev/pts" || true
sudo umount -lf "$WORK_DIR/chroot/dev" || true
sudo umount -lf "$WORK_DIR/chroot/proc" || true
sudo umount -lf "$WORK_DIR/chroot/sys" || true

sudo mksquashfs "$WORK_DIR/chroot" "$WORK_DIR/iso/live/filesystem.squashfs" -comp xz

sudo cp "$WORK_DIR/chroot/boot/vmlinuz-"* "$WORK_DIR/iso/boot/vmlinuz"
sudo cp "$WORK_DIR/chroot/boot/initrd.img-"* "$WORK_DIR/iso/boot/initrd"

cat << 'EOF' | sudo tee "$WORK_DIR/iso/boot/grub/grub.cfg"
set timeout=10
menuentry "RizzoOS" {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd
}
EOF

sudo grub-mkrescue -o "$ISO_OUTPUT" "$WORK_DIR/iso"

echo "ISO created: $ISO_OUTPUT"