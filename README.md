# PYNQ
(PY)thon on Zy(NQ)


## SDCard Image Files

- All Pynq-z1 images including the latest are available here: 
```
file://xsj-pvstd2t01-w/xrlabs/grahams/public/ubuntu-core-pynq-z1/
``` 

- All Zybo images including the latest are available here: 
```
file://xsj-pvstd2t01-w/xrlabs/grahams/public/ubuntu-core-zybo/
```

- After imaging, change Zybo's hostname to avoid network conflicts
```
sudo /home/xpp/hostname.sh A_UNIQUE_HOSTNAME
```


## Updating `pynq` using `update_pynq.sh`

This is a recommended way to update the `pynq` package. The script will do the following:

- Back up the existing package on board.
- Git clone from the repository.
- Install the `pynq` package.
- Copy board-specific files into the `pynq` package.
- Copy Jupyter notbooks.
- (Optional) Build the documentation.

To run this script, first verify the `$BOARD` environment variable has been set correctly:
```
echo $BOARD
```

* If `$BOARD` is not set, add `export BOARD=<board_name>` (e.g., `<board_name>` can be `Zybo` or `Pynq-z1`) to
`/home/xpp/.profile`.
Then either reboot the board, or run the following:
```
source /home/xpp/.profile
```

* If `$BOARD` has already been set, just run:
```
sudo /home/xpp/script/update_pynq.sh
```

## Updating `pynq` using `pip` 

It is not recommended to update `pynq` using `pip`, since there are still many board-specific files to be copied from the repository.

The developer mode will pull entire github repository into /src, but again, the board-specific files are not copied to `pynq`.

```
# (deprecated)
sudo -H pip install --upgrade 'git+https://github.com/Xilinx/PYNQ@master#egg=pynq&subdirectory=python'


# (deprecated) Developer mode
sudo -H pip install -e 'git+https://github.com/Xilinx/PYNQ@master#egg=pynq&subdirectory=python'
```

## Running Regression from Terminal
```
cd /usr/local/lib/python3.4/dist-packages/pynq
py.test –vsrw
```
