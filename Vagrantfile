# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
	config.vm.box = "parallels/ubuntu-16.04"
	config.vm.box_check_update = true

	# Set your guest specs here
	config.vm.provider "parallels" do |v|
		v.update_guest_tools = true
		v.memory = 1024
		v.cpus = 2
	end

	config.vm.network "forwarded_port", guest: 5950, host: 5950
	config.vm.box_check_update = true
	config.vm.provision "shell", path: "vagrant/provisioning.sh"
	config.vm.post_up_message = "Now you can use a vnc client to connect to vnc://localhost:5950
On macOS, we recommend the usage of 'Chicken of The VNC'"
end
