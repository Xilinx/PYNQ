## Ubuntu Core image for Zybo

All images including the latest are available at: [file://xsj-pvstd2t01-w/xrlabs/grahams/public/ubuntu-core-zybo/](file://xsj-pvstd2t01-w/xrlabs/grahams/public/ubuntu-core-zybo/)

```
LATEST CHANGELOG (for a full list, check full_img_changelog.txt):

05-05-2016 - <graham.schelle@xilinx.com>
             milan release v1.0
```


## Ubuntu Build Steps

Staging - to be added in next image

```
Use the new update_pynq.sh in /home/xpp/scripts
Update the pynq package by removing pmod_iic.old.py and pmod_iic.new.py in the symbolic link 'pynq'.
Pynq_git checkins should not cache user as schelleg
Add revision text in /home/xpp folder

```


04-15-2016
```
add back in chroot* scripts
pip install sphinx_rtd_theme
pip install nbsphinx

rm /etc/network/interfaces.d/wlx000f6002a692
sudo chown -R xpp:xpp /home/xpp/jupyter_notebooks

cd /home/xpp
ln -s /usr/local/lib/python3.4/dist-packages/pynq
chmod -R a+rw  /usr/local/lib/python3.4/dist-packages/pynq
chmod  a+x  /usr/local/lib/python3.4/dist-packages/pynq

# modified smb.conf to allow symlink-following
# C:\Users\grahams\Documents\PyXi\smb.conf

# Add cpufreq-utils to disable clock scaling
# http://askubuntu.com/questions/523640/how-i-can-disable-cpu-frequency-scaling-and-set-the-system-to-performance
# get trusty armhf debian packages below
dpkg -i libcpufreq0_008-1_armhf.deb
dpkg -i cpufrequtils_008-1_armhf.deb

# add line GOVERNOR="performance"
vi /etc/default/cpufrequtils
sudo update-rc.d ondemand disable
sudo shutdown -r now

cpufreq-info
  cpufreq stats: 325 MHz:0.00%, 650 MHz:100.00%

# modify jupyter start call to put jupyter terminal at /home/xpp
vi /root/2_jupyter_server.sh
su -c "cd ~xpp ; jupyter notebook 2> /root/jupyter.log &" -s /bin/bash root 


# seaborn for nice matplotlib
pip install seaborn


```

03-25-2016
```
# Microblaze cross compiler
# https://briolidz.wordpress.com/2012/02/07/building-embedded-arm-systems-with-crosstool-ng/ 
# http://crosstool-ng.org/download/crosstool-ng/ 

# use crosstool-ng version 1.20.0
# once downloaded onto Zybo
./configure --with-libtool=/usr/share/libtool
make
make install
./ct-ng menuconfig
   Enable Experimental Features
   Target: microblaze
   vendor: xilinx
   endinanness: little-endian

./ct-ng build
# will take 1.5 hours on Zybo

export PATH=/home/xpp/x-tools/microblazeel-xilinx-elf/bin:${PATH}
cd /home/xpp/x-tools/microblazeel-xilinx-elf/bin

# make symbolic link for each microblazeel-xilinx-elf-* to mb-*
#   this link will allow for SDK makefiles to run with alteration

```


03-15-2016
```

# cffi used for SDSoC interaction
pip install cffi

#usb wifi and webcam support - limited support for known USB chipsets (see notebooks usb_*
sudo apt-get install libusb-1.0-0-dev usbutils module-init-tools linux-firmware wpasupplicant 
<from Linux kernel build> copy kernel loadable modules to /lib/modules/3.17.0-xilinx

#samba support
# reference: https://www.howtoforge.com/tutorial/samba-server-ubuntu/
apt-get install samba
<modify samba settings for xpp user>  see /etc/samba/smb.conf for changes

#To get bash in the Jupyter terminal and consequently all the nice feature such as history and TAB autocompletion
<on target terminal>
sudo rm /bin/sh
sudo ln -s /bin/bash /bin/sh

# reveal.js
# https://github.com/hakimel/reveal.js/
<copy reveal.js into /home/xpp/jupyter_notebooks>

```


02-26-2016

```
<on target terminal>

# install Pillow to enable saving an AV frame as JPEG.
# First of all, install this packages
sudo apt-get install libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.5-dev python-tk

#Then install Pillow using pip
sudo -H pip install pillow
```


02-11-2016

```
<on target terminal>

# autologin XPP user
sudo sed -i.bak 's/ExecStart=-\/sbin\/agetty/ExecStart=-\/sbin\/agetty --autologin xpp/' /lib/systemd/system/serial-getty@.service

# fix date/time due to no RTC
sudo apt-get install ntp 
sudo sed -i.bak 's/\/var\/lib\/ntp\/ntp.conf.dhcp -nt \/etc\/ntp.conf/ -e \/var\/lib\/ntp\/ntp.conf.dhcp /' /etc/init.d/ntp 

# speed up boot when no network DHCP server
sudo sed -i.bak 's/timeout 300;/timeout 3;\nretry 3;\nreboot 3;\nselect-timeout 0;\ninitial-interval 2;\nlink-timeout 3;\n/' /etc/dhcp/dhclient.conf

# reboot
shutdown -r now 

```


02-03-2016

```
<from repository>

copy <Pynq Repo Head>/ubuntu/* --> <Zybo Linux Root>/home/xpp 

```


```
<on target terminal>

sudo mv 0_network.sh 1_jupyter_config.sh 2_jupyter_server.sh /root/
sudo mv rc.local /etc/rc.local
sudo chmod +x /root/0_network.sh /root/1_jupyter_config.sh  /root/2_jupyter_server.sh /etc/rc.local

sudo cp ~xpp/.bash* /root
sudo cp -r ~xpp/.jupyter /root
```


### Complete Steps to rebuild SDCard Boot Parition

#### Bitstream
```
source <Path to Vivado>/settings64.sh
cd <Path to the folder containing the .tcl file>
vivado -mode tcl
source pmod.tcl

write_sysdef -hwdef "./project_1.runs/impl_1/top.hwdef" -bitfile "./project_1.runs/impl_1/top.bit" \
    -meminfo "./project_1.runs/impl_1/top_bd.bmm" -file "./project_1.runs/impl_1/top.hdf"
exit
```
Note: This is an example using the "pmod.tcl" file.
The bitstream can also be generated using Vivado GUI.

#### FSBL
```
source <Path to Vivado>/settings64.sh
cd <Path to the workspace>
xsdk -batch
sdk set_workspace <Path to the workspace>
sdk create_hw_project -name hw_0 -hwspec ../mipy_zybo_video.runs/impl_1/top.hdf
sdk create_bsp_project -name bsp_0 -hwproject hw_0 -proc ps7_cortexa9_0 -os standalone
sdk create_project -type app -name zybo_fsbl -hwproject hw_0 -proc ps7_cortexa9_0 -os standalone -lang C -app {Zynq FSBL} -bsp bsp_0
sdk build -type bsp bsp_0
sdk build -type app zybo_fsbl
sdk clean -type bsp bsp_0
sdk clean -type all
sdk build -type all
exit
```
Note: This step should be done after the bitstream has been generated.
If Vivado GUI is used to generate the bitstream, first choose "export hardware" and "launch SDK".
Then create an application project with proper settings, using the "Zynq FSBL" as the template.

References:
- http://www.xilinx.com/support/documentation/sw_manuals/xilinx2014_3/SDK_Doc/reference/sdk_u_batch_mode_commands.htm#26190

#### U-boot
```
source <Path to Vivado>/settings64.sh
git clone https://github.com/xilinx/u-boot-xlnx

cd u-boot-xlnx
sed -i.bak '/ramdisk_image/d' include/configs/zynq-common.h
make clean zynq_zybo_config
make
mv u-boot u-boot.elf
```

#### Linux Kernel (uImage)
```
source <Path to Vivado>/settings64.sh
git clone https://github.com/Xilinx/linux-xlnx.git --branch xlnx_3.17 --single-branch

cd linux-xlnx
export PATH=${PATH}:`pwd`/../u-boot-xlnx/tools/
make ARCH=arm xilinx_zynq_defconfig 

make ARCH=arm menuconfig
   -- enable drivers

make ARCH=arm UIMAGE_LOADADDR=0x8000 CROSS_COMPILE=arm-xilinx-linux-gnueabi- uImage modules -j32

rm -rf ../linux_modules
make ARCH=arm INSTALL_MOD_PATH=../linux_modules CROSS_COMPILE=arm-xilinx-linux-gnueabi- modules_install 
make ARCH=arm headers_install
```

#### Boot Partition Assembly
``` 
source <Path to Vivado>/settings64.sh
mkdir sdcard

echo "image : {"                  > boot.bif
echo "[bootloader]fsbl/fsbl.elf"  >> boot.bif
echo "u-boot-xlnx/u-boot.elf"     >> boot.bif
echo "}"                          >> boot.bif  

bootgen -image boot.bif -w on -o i sdcard/boot.bin
cp linux-xlnx/arch/arm/boot/uImage sdcard/
cp devicetree/devicetree.dtb sdcard/
```
#### DeviceTree
```
TBD - Use standard Zybo Device Tree TBD
```
#### Partition Your MicroSD Card

Follow step 8 at link below to partition SDCard.  Many other online references exist as well on how to partition an SDCard.

References:
- http://www.dbrss.org/zybo/tutorial4.html (Step 8)


#### Ubuntu root filesystem building

References:
- http://hunterhu.com/1/post/2015/02/embedded-rootfs-from-ubuntu-core-rootfs.html
- http://gnu-linux.org/building-ubuntu-rootfs-for-arm.html


```
# These steps require root access from an Ubuntu machine
#    For corporate users - this typcailly means having a Virtual Machine

# All steps were done using VMWare and Ubuntu 32b 14.04.3 - ubuntu-14.04.3-desktop-i386.iso
# SDCard prepartitioned into BOOT (FAT32) and rootfs (EXT4) and accessible from VM

apt-get install qemu-user-static
export TGZ_PATH=<PATH_TO>/ubuntu-core-15.10-core-armhf.tar.gz
export CHROOT_IN_PATH=<PATH_TO>/chroot_in.sh
export CHROOT_OUT_PATH=/chroot_out.sh

tar -zxpf $TGZ_PATH

cp /usr/bin/qemu-arm-static usr/bin
cp $CHROOT_IN_PATH .
cp $CHROOT_OUT_PATH .

./chroot_in.sh

chmod 755 /
apt-get install apt-utils 
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

apt-get update
apt-get upgrade
apt-get install sudo net-tools build-essential ssh ethtool \
iputils-ping rsyslog language-pack-en-base bash-completion \
nano vim policykit-1 lsof resolvconf python3-dev \
python3-setuptools gfortran ntp vim lsof git sysstat imagemagick

adduser xpp; adduser xpp sudo
apt-get upgrade

echo "zybo" > /etc/hostname
echo "127.0.0.1       localhost" > /etc/hosts
echo "127.0.1.1       zybo"     >> /etc/hosts

./chroot_out.sh
exit
cd ..

# Disconnect the SDCard from VM
```

### Set up swap partition 
```
# a 1024MB swap partition will be created, but only if a swap partition has not been created yet
if ! grep -Fxq /swap /etc/fstab; then
    dd if=/dev/zero of=/swap bs=1M count=1024
    mkswap /swap
    echo '/swap none swap sw 0 0' >> /etc/fstab
else
    echo swap partition already configured
fi
```





## Installing armhf build of packages not in ubuntu mainline
Sometimes you may find that ubuntu official repos does not include certain pakcages for the armhf architecture - i.e. the usual `apt-get` will not work. However, it may be that these packages are available as a yet-unofficial build on ubuntu's development website: [https://launchpad.net/ubuntu/wily/armhf](https://launchpad.net/ubuntu/wily/armhf). If so, simply `wget` the `.deb` package and then install it using `dpkg`.
For instance, the `i2c-tools` and `libi2c-dev` are not available using normal `apt-get`, but there is still an armhf build for ubuntu 15.10:

- https://launchpad.net/ubuntu/wily/armhf/i2c-tools/3.1.1-1
- https://launchpad.net/ubuntu/wily/armhf/libi2c-dev/3.1.1-1

To install them, simply execute this commands
```
wget http://launchpadlibrarian.net/173848656/i2c-tools_3.1.1-1_armhf.deb
wget http://launchpadlibrarian.net/173859774/libi2c-dev_3.1.1-1_all.deb
dpkg -i i2c-tools*
dpkg -i libi2c-dev*
```
When you install packages in this way, you need to manually recursively resolve every dependency listed on the package website (the `depends on` list at the bottom of the package page, if present), possibly installing them using the same technique if they are not available with normal `apt-get`.

## Ubuntu Scripts

1. *configure_jupyter.sh* : set up the ethernet connection and configure Jupyter to be launched with the DHCP given IP address. A message at the end will provide further instructions

2. *xilinx_proxy.sh* : set or unset the Xilinx internal network proxy

3. *py_package.sh*: run this script to know where to put your packages to be used by Jupyter. The script will create the specified path if it does not exists. To copy the package, you can use [WinSCP](https://winscp.net/eng/download.php) creating a *New Site* with protocol *SFTP*, Host name the ip of the board (that you can get typing `hostname -I` from terminal or executing the *configure_jupyter.sh* script), Port number *22* and User name *xpp*. The password is also *xpp*. If you leave the password entry empty, it will be asked at every log in.
You can obviously copy the package using your method of choice instead.
In this repository, the *pynq* package is located under /python/pynq

Remember to run
```
chmod +x <selected_scritp.sh>
```
to make it executable before you launch it.

## Installing `pynq` easily using pip
An easy alternative to script #3 is to install the pynq package using `pip` directly (and avoid all the hassle of manually copying files). To do that, simply type from a terminal while being in the home directory (/home/xpp).
```
sudo -H pip install -e 'git+https://github.com/Xilinx/Pynq@master#egg=pynq&subdirectory=python'
```

------------------------------------------------------------------------------------------------------
