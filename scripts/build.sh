#!/bin/bash

BUILD_DEPS="debootstrap squashfs-tools"
PACKAGES="ifupdown,ifupdown-extra,isc-dhcp-client,openssh-server,less,nano,picocom,htop"

set -e

WORK_DIR="/build"
mkdir "${WORK_DIR}"

apt-get update
apt-get install -y ${BUILD_DEPS}

debootstrap --variant=minbase --arch=i386 --include=$PACKAGES jessie "${WORK_DIR}" http://httpredir.debian.org/debian

## Post debootstrap customization
# Clean up file with misleading information from host
rm "${WORK_DIR}/etc/hostname"

# Disable installation of recommended packages
echo 'APT::Install-Recommends "false";' >"${WORK_DIR}/etc/apt/apt.conf.d/50norecommends"

# Configure networking
cat >>"${WORK_DIR}/etc/network/interfaces" <<'EOF'
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
EOF

# Implement insecurity
chroot "${WORK_DIR}" passwd -d root # remove password on root account
sed -i 's/pam_unix.so nullok_secure/pam_unix.so nullok/' "${WORK_DIR}/etc/pam.d/common-auth"
sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' "${WORK_DIR}/etc/ssh/sshd_config"
sed -i 's/PermitEmptyPasswords no/PermitEmptyPasswords yes/' "${WORK_DIR}/etc/ssh/sshd_config"

# Clean up temporary files
rm -rf "${WORK_DIR}"/var/cache/apt/*
rm -rf "${WORK_DIR}"/tmp/*

# Build the root filesystem image, and extract the accompanying kernel and initramfs
mksquashfs "${WORK_DIR}" sqashfs.new -noappend; mv sqashfs.new /tftp/filesystem.squashfs

chroot "${WORK_DIR}" apt-get install -y linux-image-586 live-boot live-boot-initramfs-tools
cp -p "${WORK_DIR}/boot"/vmlinuz-* vmlinuz.new; mv vmlinuz.new /tftp/vmlinuz
cp -p "${WORK_DIR}/boot"/initrd.img-* initrd.new; mv initrd.new /tftp/initrd.img
