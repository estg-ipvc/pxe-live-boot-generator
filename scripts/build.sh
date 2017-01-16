#!/bin/bash

BUILD_DEPS="debootstrap squashfs-tools"
PACKAGES="ifupdown,ifupdown-extra,isc-dhcp-client,openssh-server,less,nano,picocom,htop,live-boot,live-boot-initramfs-tools,linux-image-586"
MIRROR="http://ftp.pt.debian.org/debian"
#MIRROR="http://httpredir.debian.org/debian"

set -e

WORK_DIR="/build"
mkdir "${WORK_DIR}"

apt-get update
apt-get install -y ${BUILD_DEPS}

debootstrap --verbose --variant=minbase --arch=i386 --include=$PACKAGES jessie "${WORK_DIR}" $MIRROR

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

# Hosts files
cat >>"${WORK_DIR}/etc/hosts" <<'EOF'
127.0.0.1 localhost
127.0.1.1 live-boot

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF

# Implement insecurity
chroot "${WORK_DIR}" passwd -d root # remove password on root account
sed -i 's/pam_unix.so nullok_secure/pam_unix.so nullok/' "${WORK_DIR}/etc/pam.d/common-auth"
sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' "${WORK_DIR}/etc/ssh/sshd_config"
sed -i 's/PermitEmptyPasswords no/PermitEmptyPasswords yes/' "${WORK_DIR}/etc/ssh/sshd_config"

# Clean up temporary files
rm -rf "${WORK_DIR}"/var/cache/apt/*
rm -rf "${WORK_DIR}"/tmp/*


# Extract the accompanying kernel and initramfs
cp -p "${WORK_DIR}/boot"/vmlinuz-* vmlinuz.new; mv vmlinuz.new /tftp/vmlinuz
cp -p "${WORK_DIR}/boot"/initrd.img-* initrd.new; mv initrd.new /tftp/initrd.img


# Remove the boot directory, and build the root filesystem image
rm -rf "${WORK_DIR}/boot"/*
mksquashfs "${WORK_DIR}" sqashfs.new -noappend; mv sqashfs.new /tftp/filesystem.squashfs
