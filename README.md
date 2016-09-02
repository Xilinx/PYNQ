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

This is a recommended way to update the `pynq` package. The script will do the following:

- Back up the existing package on board.
- Git clone from the repository.
- Install the `pynq` package.
- Copy board-specific files into the `pynq` package.
- Copy the latest Jupyter notebooks into `/home/xilinx/jupyter_notebooks`.

For the first step, the folders getting backed up include:

- **docs**: the documentation files saved in `/home/xilinx/docs`.
- **jupyter_notebooks**: the original Jupyter notebooks saved in `/home/xilinx/jupyter_notebooks`.
- **root**: the scripts used during the boot sequence.
- **scripts**: the scripts saved in `/home/xilinx/scripts`.

To run this script, first verify the `$BOARD` environment variable has been set correctly:
```
echo $BOARD
```

* If `$BOARD` is not set, add `export BOARD=Pynq-Z1` to `/home/xilinx/.profile`.
Then either reboot the board, or run the following:

	```
	source /home/xilinx/.profile
	```

* If `$BOARD` has already been set, just run:
	```
	cd /home/xilinx/scripts
	sudo update_pynq.sh
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
sudo py.test –vsrw
```
