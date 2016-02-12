




## Ubuntu Core image for Zybo

All images including the latest are available at: [file://xsjeng1/group/xrlabs/gnatale/public/ubuntu-core-zybo/](file://xsjeng1/group/xrlabs/gnatale/public/ubuntu-core-zybo/)

```
LATEST CHANGELOG (for a full list, check full_img_changelog.txt):

02-11-2016 - <giuseppe.natale@xilinx.com>
             1) upgraded pip to latest version (8.0.1)
             2) upgraded pyxi package from repository
             3) solved issue #3
             4) updated devicetree in preparation to AV overlay. Tested 
                current version of the audio bindings on this build and it works.
             5) installed i2c-tools and libi2c-dev needed to use i2c linux drivers

```


## Ubuntu Build Steps

Staging - to be added in next image

```
<on target terminal>

pip install pytest
pip install pytest-ordering


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

copy <Pyxi Repo Head>/ubuntu/* --> <Zybo Linux Root>/home/xpp 

```


```
<on target terminal>

sudo mv 0_network.sh 1_jupyter_config.sh 2_jupyter_server.sh /root/
sudo mv rc.local /etc/rc.local
sudo chmod +x /root/0_network.sh /root/1_jupyter_config.sh  /root/2_jupyter_server.sh /etc/rc.local

sudo cp ~xpp/.bash* /root
sudo cp -r ~xpp/.jupyter /root


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
In this repository, the *pyxi* package is located under /python/pyxi

Remember to run
```
chmod +x <selected_scritp.sh>
```
to make it executable before you launch it.

## Installing `pyxi` easily using pip
An easy alternative to script #3 is to install the pyxi package using `pip` directly (and avoid all the hassle of manually copying files). To do that, simply type from a terminal while being in the home directory (/home/xpp).
```
sudo -H pip install -e 'git+https://github.com/Xilinx/Pyxi@master#egg=pyxi&subdirectory=python'
```

------------------------------------------------------------------------------------------------------
