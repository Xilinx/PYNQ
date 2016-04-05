# Pynq
(Py)thon on Zy(nq)


## Zybo image files

- All images including the latest are available here: 
```
file://xsj-pvstd2t01-w/xrlabs/grahams/public/ubuntu-core-zybo/
```

- After imaging, change Zybo's hostname to avoid network conflicts
```
sudo /home/xpp/hostname.sh A_UNIQUE_HOSTNAME
```


## Updating `pynq` on Zybo using pip 

```
sudo -H pip install 'git+https://github.com/Xilinx/Pynq@master#egg=pynq&subdirectory=python'


# (deprecated) Developer Mode will pull entire github respository into `pwd`/src
sudo -H pip install -e 'git+https://github.com/Xilinx/Pynq@master#egg=pynq&subdirectory=python'
```

## Running Regression from terminal
```
cd /usr/local/lib/python3.4/dist-packages/pynq
py.test –vsrw
```
