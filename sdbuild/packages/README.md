# Additional RootFS packages

Additional packages to be installed in the rootfs can be placed in this folder. Each package can have up to three bash scripts for installation:
 * `pre.sh` is the first to run and should copy any required files into the chroot
 * `qemu.sh` is run in the chroot under qemu starting the root of the chroot
 * `post.sh` is run last and should perform any required tidying up

`pre.sh` and `post.sh` take the location of the chroot as the first argument. The PWD should not be touched during this process. `$WORKDIR` will be set as in the makefile.

Additionally a Makefile can be added which should add any dependecies to the `PACKAGE_BUILD` variable and place all files into a subfolder of `$WORKDIR`
