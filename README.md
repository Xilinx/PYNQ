# PYNQ
(PY)thon on Zy(NQ)


## SDCard Image Files

- All Pynq-Z1 images including the latest are available here: 
```
file://xsj-pvstd2t01-w/xrlabs/grahams/public/pynq-z1_images/
``` 

- After imaging, change the board's hostname to avoid network conflicts
```
sudo /home/xilinx/scripts/hostname.sh A_UNIQUE_HOSTNAME
```


## Updating `pynq` using `update_pynq.sh`

This is a recommended way to update the `pynq` package. The script usage can be checked using:
```
sudo ./update_pynq.sh -h
```
By default, The script will do the following:

- Update or clone Git repository in `/home/xilinx`.
- Checkout the latest stable release in Repo.
- Install the `pynq` package.
- Copy board-specific files into the `pynq` package.
- Copy the Jupyter notebooks into `/home/xilinx/jupyter_notebooks`.
- Copy Documentation into home directory.
- Update other useful scripts in `/home/xilinx/scripts` and itself before exiting.

To run this script, first verify the `$BOARD` environment variable has been set correctly:
```
echo $BOARD
```

* If `$BOARD` is not set, add `export BOARD=Pynq-Z1` to `/etc/environment`.
Then either reboot the board, or run the following:

	```
	source /etc/environment
	```

* If `$BOARD` has already been set, just run:
	```
	cd /home/xilinx/scripts
	# To get latest stable git updates
	sudo ./update_pynq.sh
	# To get latest git updates
	sudo ./update_pynq.sh -l (dev)
	# To Build Documentation from sources (dev)
	sudo ./update_pynq -d
	```

## Updating `pynq` using `pip` 

It is not recommended to update `pynq` using `pip`, since there are still many board-specific files to be copied from the repository.

The developer mode will pull entire github repository, but again, the board-specific files are not copied to `pynq`.

```
# (deprecated)
sudo -H pip install --upgrade 'git+https://github.com/Xilinx/PYNQ@master#egg=pynq&subdirectory=python'

# (deprecated) Developer mode
sudo -H pip install -e 'git+https://github.com/Xilinx/PYNQ@master#egg=pynq&subdirectory=python'
```

## Running Regression from Terminal

The pytests have to be run under root privilege:

```
cd /usr/local/lib/python3.4/dist-packages/pynq
sudo py.test -vsrw
```
