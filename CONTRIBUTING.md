We welcome contributions to PYNQ.  Please first sign our <a href="https://www.clahub.com/agreements/Xilinx/PYNQ"> Contributor License Agreement</a>.

If you have an idea how to improve PYNQ:

1. Share your proposal via <a href="https://github.com/Xilinx/PYNQ/issues" target="_blank">Github issues</a>.

   A general set of rules on what to submit:

	 1. We welcome submissions to the pynq Python package, sdbuild flows and documentation.
   
	 2. For development boards, we only host boards that we officially support. To 
	 build new SDCard images for custom PYNQ enabled boards, we encourage users 
	 to build a new board-only repository.  For reference, please see the 
	 <a href="https://github.com/Avnet/Ultra96-PYNQ" target="_blank">Avnet Ultra96</a>
	 or <a href="https://github.com/Xilinx/ZCU111-PYNQ" target="_blank">Xilinx ZCU111</a> 
	 repositories. 
     
   3. For custom overlays, we only host overlays that we officially support. To 
   create new custom overlays, we encourage users to build a new overlay 
   repository. For reference, please see the 
   <a href="https://github.com/Xilinx/PYNQ-HelloWorld" target="_blank">PYNQ-HelloWorld</a> 
   and <a href="https://github.com/Xilinx/BNN-PYNQ" target="_blank">BNN-PYNQ</a> repositories.
   
   4. For Microblaze peripheral drivers, we encourage users to submit their C/C++ within 
   a Jupyter notebook using the microblaze IPython magic.  Please see 
   the <a href="https://github.com/Xilinx/PYNQ/tree/master/boards/Pynq-Z1/base/notebooks/microblaze" target="_blank">Microblaze example notebooks</a> 
   for how to write custom device drivers.
       

2. Submitting your pull request:

	1. Fork this repository to your own github account using the *fork* button above.

	2. Clone the fork to a local computer using *git clone*. Checkout the branch you want to work on.

	3. You can modify the Vivado projects, Python source code, or notebooks.

	4. Modify the documentation if necessary.

	5. Make sure your patch follows code standards:
		1. <a href="https://www.doc.ic.ac.uk/lab/cplus/cstyle.html" target="_blank">C/C++ code</a>
		2. <a href="https://www.python.org/dev/peps/pep-0008/" target="_blank">Python / Jupyter notebook</a>

	6. Use *git add*, *git commit*, *git push* to add changes to your fork.

	7. Submit a pull request by clicking the *pull request* button on your github repo:
		1. The <a href="https://github.com/Xilinx/PYNQ" target="_blank">master branch</a> should always be
		   treated as stable and clean. Only hot fixes are allowed to be pull-requested. The hot fix is supposed
           to be very important such that without this fix, a lot of things break.
        2. For new features, small bug fixes, doc updates, and many other fixes, users should pull request against
           the development branch, which has the newest image version. For example, if we have released 
           image v2.3 but you see a new branch `image_v2.4`, then you should pull request against 
           `image_v2.4` branch.

	Check the <a href="http://git.huit.harvard.edu/guide/" target="_blank">guide to git</a> for more information.
    
3. We will review your contribution and, if any additional fixes or modifications are 
necessary, may provide feedback to guide you. When accepted, your pull request will 
be merged to the repository.
