# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
	## Use the following config when using the virtualbox provider
	## get the vagrant VirtualBox Guest Additions auto updater plugin:
	## $ vagrant plugin install vagrant-vbguest
	##
	## Uncomment the following, replacing the existing the existing one:
	##
	#config.vm.box = "ubuntu/xenial64"
	#config.vm.box_check_update = true
  #	Set your guest specs here
 	# Replace the provider with your own, for example:
 	#config.vm.provider "virtualbox" do |v|
	# 	v.update_guest_tools = true
	# 	v.memory = 1024
	# 	v.cpus = 2
 	#end

	## Use the following config when using the virtualbox provider
	## get the vagrant paralles provider plugin:
	## $ vagrant plugin install vagrant-parallels
	##
	## Uncomment the following, replacing the existing the existing one:
	##
	config.vm.box = "parallels/ubuntu-16.04"
	config.vm.box_check_update = true

	# Set your guest specs here
	# Replace the provider with your own, for example:
	#config.vm.provider "virtualbox" do |v|
	config.vm.provider "parallels" do |v|
		v.update_guest_tools = true
		v.memory = 1024
		v.cpus = 2
	end

	## DO NOT TOUCH THE FOLLOWING CONFIGS:
	config.vm.network "forwarded_port", guest: 5950, host: 5950
	config.vm.provision "shell", path: "vagrant/provisioning.sh"
	config.vm.post_up_message = "Now you can use a vnc client to connect to vnc://localhost:5950
On macOS, we recommend the usage of 'Chicken of The VNC'"
end
