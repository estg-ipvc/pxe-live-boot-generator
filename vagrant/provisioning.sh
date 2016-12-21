#!/bin/bash
set -e

echo "Starting Provisioning..."

sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y
sudo apt-get install -y qemu apt-transport-https ca-certificates bridge-utils uml-utilities \
  linux-image-extra-$(uname -r) linux-image-extra-virtual docker-engine
sudo apt-get clean
echo "UML_SWITCH_OPTIONS="-tap tap0"" | sudo tee --append /etc/default/uml-utilities

sudo adduser vagrant uml-net
cat << EOF | sudo tee --append /etc/network/interfaces

auto tap0
iface tap0 inet manual
  tunctl_user uml-net
  up ifconfig tap0 promisc arp 0.0.0.0 up

auto virtbr0
iface virtbr0 inet static
  bridge_ports tap0
  bridge_stp off
  bridge_maxwait 5
  address 10.0.0.1
  netmask 255.255.255.0
  network 10.0.0.0
  broadcast 10.0.0.255

EOF

sudo systemctl restart networking

# DHCP Server
cat << EOF | sudo tee /etc/dhcp/dhcpd.conf
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.10 10.0.0.200;
    option routers 10.0.0.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    option broadcast-address 10.0.0.255;
    option subnet-mask 255.255.255.0;
    filename "pxelinux.0";
}
EOF

cat << EOF | sudo tee /etc/systemd/system/dhcp-server.service
[Unit]
Description=dhcp-server.service
After=docker.service
Requires=docker.service

[Service]
ExecStartPre=/bin/bash -c '/usr/bin/docker inspect %n &> /dev/null && /usr/bin/docker rm %n || :'
ExecStart=/usr/bin/docker run \
  --name %n \
  --net=host \
  -v /etc/dhcp:/data \
  networkboot/dhcpd:latest \
  virtbr0
ExecStop=/usr/bin/docker stop %n && /usr/bin/docker rm %n
RestartSec=5s
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable dhcp-server
sudo systemctl start dhcp-server

# Regenerate /tftp directory and add internet connection to tap0 on each boot

cat << EOF | sudo tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Wait a while so the /vagrant mount is available
sleep 8
systemctl restart tftp-hpa

## Provide internet to the tap0 interface
# get the default interface
IFACE=\$(route | grep '^default' | grep -o '[^ ]*$')
# enable nat
iptables -t nat -A POSTROUTING -o \${IFACE} -j MASQUERADE
# enable ipv4_forwarding
echo '1' > /proc/sys/net/ipv4/ip_forward

exit 0
EOF

# TFTP
cat << EOF | sudo tee /etc/systemd/system/tftp-hpa.service
[Unit]
Description=tftp-hpa.service
After=docker.service dhcp-server.service
Requires=docker.service

[Service]
ExecStartPre=/sbin/modprobe nf_conntrack_tftp
ExecStartPre=/sbin/modprobe nf_nat_tftp
ExecStartPre=/usr/bin/docker pull jumanjiman/tftp-hpa:latest
ExecStartPre=/bin/bash -c '/usr/bin/docker inspect %n &> /dev/null && /usr/bin/docker rm %n || :'
ExecStart=/usr/bin/docker run \
  --name %n \
  -p 69:69/udp \
  -v /vagrant/tftp/pxelinux.cfg:/tftpboot/pxelinux.cfg:ro \
  -v /vagrant/tftp/initrd.img:/tftpboot/initrd.img:ro \
  -v /vagrant/tftp/vmlinuz:/tftpboot/vmlinuz:ro \
  -v /vagrant/tftp/filesystem.squashfs:/tftpboot/filesystem.squashfs:ro \
  jumanjiman/tftp-hpa:latest
ExecStop=/usr/bin/docker stop %n
RestartSec=5s
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable tftp-hpa
sudo systemctl start tftp-hpa

# QEMU
cat << EOF | sudo tee /etc/systemd/system/qemu.service
[Unit]
Description=qemu.service
After=docker.service dhcp-server.service tftp-hpa.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/qemu-system-x86_64 \
  -m 512 -boot n \
  -option-rom /usr/share/qemu/pxe-rtl8139.rom \
  -net nic -net tap,ifname=tap0,script=no,downscript=no -vnc :50 -vga std

#ExecStop=/usr/bin/docker stop %n
RestartSec=5s
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Run rc.local to take effect on the first boot
/bin/bash /etc/rc.local

# Start qemu
sudo systemctl enable qemu
sudo systemctl start qemu

echo "Provisioning Done!"
