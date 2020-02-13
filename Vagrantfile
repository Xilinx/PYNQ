# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

	# Based on Ubuntu Xenial 16.04; this is the default VM
	# run `vagrant up xenial`
	config.vm.define "xenial", primary: true do |xenial|
		xenial.vm.box = "ubuntu/xenial64"
		xenial.vm.synced_folder ".", "/pynq", 
			owner: "vagrant", group: "vagrant"
		xenial.vm.provider "virtualbox" do |vb|
			vb.gui = true
			vb.name = "pynq_ubuntu_16_04"
			vb.memory = "8192"
			vb.customize ["modifyvm", :id, "--vram", "128"]
			vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
			disk_image = File.join(File.dirname(File.expand_path(__FILE__)), 
				'ubuntu_16_04.vdi')
			unless File.exist?(disk_image)
			vb.customize ['createhd', 
						'--filename', disk_image, 
						'--size', 160 * 1024]
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

		xenial.vm.provision "shell", inline: <<-SHELL
			parted /dev/sdc mklabel msdos
			parted /dev/sdc mkpart primary 100 100%
			partprobe
			mkfs.xfs /dev/sdc1
			mkdir /workspace
			echo `blkid /dev/sdc1 | awk '{print$2}' | sed -e 's/"//g'` \
				/workspace   xfs   noatime,nobarrier   0   0 >> /etc/fstab
			mount /workspace
			chown -R vagrant:vagrant /workspace
			chmod 777 -R /workspace
		SHELL

		xenial.vm.provision "shell",
			inline: "apt-get update"

		xenial.vm.provision "shell", 
			inline: "/bin/bash /pynq/sdbuild/scripts/setup_host.sh"


		xenial.vm.provision "shell", 
			inline: "apt-get install -y --force-yes ubuntu-desktop"

		xenial.vm.provision "shell", inline: <<-SHELL
			cat /root/.profile | grep PATH >> /home/vagrant/.profile
		SHELL
	end

	# Based on Ubuntu Bionic 18.04
	# run `vagrant up bionic`
	config.vm.define "bionic", autostart: false do |bionic|
		bionic.vm.box = "ubuntu/bionic64"
		bionic.vm.synced_folder ".", "/pynq", 
			owner: "vagrant", group: "vagrant"
		bionic.vm.provider "virtualbox" do |vb|
			vb.gui = true
			vb.name = "pynq_ubuntu_18_04"
			vb.memory = "8192"
			vb.customize ["modifyvm", :id, "--vram", "128"]
			vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
			disk_image = File.join(File.dirname(File.expand_path(__FILE__)), 
				'ubuntu_18_04.vdi')
			unless File.exist?(disk_image)
			vb.customize ['createhd', 
						'--filename', disk_image, 
						'--size', 160 * 1024]
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

		bionic.vm.provision "shell", inline: <<-SHELL
			parted /dev/sdc mklabel msdos
			parted /dev/sdc mkpart primary 100 100%
			partprobe
			mkfs.xfs /dev/sdc1
			mkdir /workspace
			echo `blkid /dev/sdc1 | awk '{print$2}' | sed -e 's/"//g'` \
				/workspace   xfs   noatime,nobarrier   0   0 >> /etc/fstab
			mount /workspace
			chown -R vagrant:vagrant /workspace
			chmod 777 -R /workspace
		SHELL

		bionic.vm.provision "shell",
			inline: "apt-get update"

		bionic.vm.provision "shell", 
			inline: "/bin/bash /pynq/sdbuild/scripts/setup_host.sh"

		bionic.vm.provision "shell", 
			inline: "apt-get install -y --force-yes ubuntu-desktop"

		bionic.vm.provision "shell", inline: <<-SHELL
			cat /root/.profile | grep PATH >> /home/vagrant/.profile
		SHELL
	end

end
