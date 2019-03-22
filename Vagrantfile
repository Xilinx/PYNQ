# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base on Ubuntu 16.04
  config.vm.box = "ubuntu/xenial64"

  # Import repository under /pynq
  # Always use `vagrant reload` to reboot, otherwise vagrant has no clue
  # whether the VM has been rebooted - will not be able to see synced_folder
  config.vm.synced_folder ".", "/pynq", owner: "vagrant", group: "vagrant"

  # Set up VM and disk image for VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
	vb.name = "pynq_vm"
	vb.memory = "4096"
	vb.customize ["modifyvm", :id, "--vram", "128"]
	vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    disk_image = File.join(File.dirname(File.expand_path(__FILE__)), 
		'sdbuild.vdi')
    unless File.exist?(disk_image)
      vb.customize ['createhd', '--filename', disk_image, '--size', 100 * 1024]
    end
    vb.customize ['storageattach', :id, 
				  '--storagectl', 'SCSI', 
				  '--port', 2, '--device', 0, 
				  '--type', 'hdd', 
				  '--medium', disk_image]
    vb.customize ['storageattach', :id, 
                  '--storagectl', 'IDE', 
                  '--port', '0', '--device', '1', 
                  '--type', 'dvddrive', 
                  '--medium', 'emptydrive']
  end

  # Mount disk image on first boot (provisioning)
  config.vm.provision "shell", inline: <<-SHELL
    parted /dev/sdc mklabel msdos
    parted /dev/sdc mkpart primary 100 100%
    partprobe
    mkfs.xfs /dev/sdc1
    mkdir /sdbuild
    echo `blkid /dev/sdc1 | awk '{print$2}' | sed -e 's/"//g'` \
		/sdbuild   xfs   noatime,nobarrier   0   0 >> /etc/fstab
    mount /sdbuild
	chown -R vagrant:vagrant /sdbuild
	chmod 777 -R /sdbuild
  SHELL

  # Initialize the apt database in the brand new Ubuntu VM
  config.vm.provision "shell",
    inline: "apt-get update"

  # Install prerequisites
  config.vm.provision "shell", 
	inline: "/bin/bash /pynq/sdbuild/scripts/setup_host.sh"

  # GUI is only required to install Xilinx tools
  # Otherwise comment the following lines out to use headless OS
  config.vm.provision "shell", 
    inline: "apt-get install -y --force-yes ubuntu-desktop"

  # Update VM user environment
  config.vm.provision "shell", inline: <<-SHELL
    cat /root/.profile | grep PATH >> /home/vagrant/.profile
  SHELL

end
