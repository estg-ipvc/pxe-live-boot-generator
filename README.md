# PXE Live Boot Generator

Debian image files generator with test and simulation tools for PXE Booting environments.

## Description

Soon...

## Requirements

-   make
-   Docker
-   Vagrant and a VM Hypervisor (Virtualbox, Parallels, VMWare)

## Generating boot images

Build the squashfs root (`filesystem.squashfs`), linux image (`vmlinuz`) and initramfs (`initrd.img`):

```
make build
```

## Testing

Starting the Vagrant machine to test the boot images with qemu:

```
make start
```

Now connect to vnc://localhost:5950 with a vnc client.

To Stop the Vagrant machine:
```
make stop
```

To Destroy the Vagrant machine:
```
make destroy
```
