# PXE Live Boot Generator

Debian image files generator with test and simulation tools for PXE Booting environments.

## Architecture

```
 _______________________________________________
|										  Host	|
|	vnc://localhost:5950						|
|	hiface										|
|	   \										|
|		\___________________________________	|
|		|\								VM	|	|
|		| \									|	|
|		| giface							|	|
|		|	 _____________   _____________	|	|
|		|	| DHCP Server | | tftp Server |	|	|
|		|	| 10.0.0.0/24 | |	(Docker)  |	|	|
|		|	|_____________|	|_____________|	|	|
|		|				 \	/				|	|
|		|				  \/				|	|
|		|				 tap0 (10.0.0.1)	|	|
|		|	 ______________|____________	|	|
|		|	|	Qemu (pxe-rtl8139.rom)	|	|	|
|		|	|	vnc:5950 (giface)		|	|	|
|		|	|___________________________|	|	|
|		|___________________________________|	|
|_______________________________________________|
```

- `Host OS`: Machine running this project.

- `VM`: Vagrant Virtual Machine

- `hiface`: default host virtual interface (the actual name varies on different Host OSs)

- `giface`: Vagrant's VM default interface (the actual name varies on different Guest OSs)

The `5950` port is forwarded to the `Host` machine, so that you can attach to the `Qemu` display by connecting to [vnc://localhost:5950](vnc://localhost:5950).


## Procedure

This environment simulates a PXE server and a network booting i586 computer booting the generated boot images. 

1. The boot images need to be generated and present on the `tftp` directory. If not, to generate those: `make build`. This Starts a Docker machine to build a customized `Debian Live` images that are built following the script in `scripts/build.sh`.

2. The `default` file must be present in `tftp/pxelinux.cfg/default` and set up for those boot images.

3. `make start`, starts a Vagrant machine, provisioned by `vagrant/provisioning.sh`, and described on the previous topic. This machine contains a `dhcp server`, a `tftp server` docker image containing all the needed `syslinux`(`pxelinux`) boot files, a `qemu` network booting machine as a `systemd` unit and network configurations.


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
