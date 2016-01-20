# Ubuntu Scripts

1. *configure_jupyter.sh* : set up the ethernet connection and configure Jupyter to be launched with the DHCP given IP address. A message at the end will provide further instructions

2. *xilinx_proxy.sh* : set or unset the Xilinx internal network proxy

3. *py_package.sh*: run this script to know where to put your packages to be used by Jupyter. The script will create the specified path if it does not exists. To copy the package, you can use <a href="https://winscp.net/eng/download.php" target="_blank">WinSCP</a> creating a *New Site* with protocol *SFTP*, Host name the ip of the board (that you can get typing `hostname -I` from terminal or executing the *configure_jupyter.sh* script), Port number *22* and User name *xpp*. The password is also *xpp*. If you leave the password entry empty, it will be asked at every log in.
You can obviously copy the package using your method of choice instead.
In this repository, the *pyxi* package is located under /python/pyxi


Remember to run
```
chmod +x <selected_scritp.sh>
```
to make it executable before you launch it.