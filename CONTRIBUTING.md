## Contributing to PYNQ

We welcome contributions to PYNQ - please see our guidelines below for preparing your pull request.  

### 1. A general set of rules on what to submit
   
- We welcome submissions to the pynq Python package, sdbuild flows and documentation.
   
- For development boards, we only host boards that we officially support. To 
build new SDCard images for custom PYNQ enabled boards, we encourage users 
to build a new board-only repository.  For reference, please see the 
<a href="https://github.com/Avnet/Ultra96-PYNQ" target="_blank">Avnet Ultra96</a>
or <a href="https://github.com/Xilinx/ZCU111-PYNQ" target="_blank">Xilinx ZCU111</a> 
repositories. 
     
- For custom overlays, we only host overlays that we officially support. To 
create new custom overlays, we encourage users to build a new overlay 
repository. For reference, please see the 
<a href="https://github.com/Xilinx/PYNQ-HelloWorld" target="_blank">PYNQ-HelloWorld</a> 
and <a href="https://github.com/Xilinx/BNN-PYNQ" target="_blank">BNN-PYNQ</a> repositories.
   
- For Microblaze peripheral device drivers, we encourage users to submit their C/C++ within 
a Jupyter notebook using the microblaze IPython magic.  Please see 
the <a href="https://github.com/Xilinx/PYNQ/tree/master/boards/Pynq-Z1/base/notebooks/microblaze" target="_blank">Microblaze example notebooks</a> 
for how to write custom device drivers.
       

### 2. Submit your patch using a pull request

Please use GitHub Pull Requests for sending code contributions. When sending code sign your 
work as described below. Be sure to use the same license for your contributions as the current 
license of the PYNQ.


### 3. Sign Your Work

Please use the *Signed-off-by* line at the end of your patch which indicates that you accept the Developer Certificate of Origin (DCO) defined by https://developercertificate.org/ reproduced below::

```
  Developer Certificate of Origin
  Version 1.1

  Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
  1 Letterman Drive
  Suite D4700
  San Francisco, CA, 94129

  Everyone is permitted to copy and distribute verbatim copies of this
  license document, but changing it is not allowed.


  Developer's Certificate of Origin 1.1

  By making a contribution to this project, I certify that:

  (a) The contribution was created in whole or in part by me and I
      have the right to submit it under the open source license
      indicated in the file; or

  (b) The contribution is based upon previous work that, to the best
      of my knowledge, is covered under an appropriate open source
      license and I have the right under that license to submit that
      work with modifications, whether created in whole or in part
      by me, under the same open source license (unless I am
      permitted to submit under a different license), as indicated
      in the file; or

  (c) The contribution was provided directly to me by some other
      person who certified (a), (b) or (c) and I have not modified
      it.

  (d) I understand and agree that this project and the contribution
      are public and that a record of the contribution (including all
      personal information I submit with it, including my sign-off) is
      maintained indefinitely and may be redistributed consistent with
      this project or the open source license(s) involved.
```

Here is an example Signed-off-by line which indicates that the contributor accepts DCO::

```
  This is my commit message

  Signed-off-by: Jane Doe <jane.doe@example.com>
```


### 4. We will review your contribution 

If any additional fixes or modifications are necessary, we may provide feedback to guide 
you. When accepted, your pull request will be merged to the repository.
