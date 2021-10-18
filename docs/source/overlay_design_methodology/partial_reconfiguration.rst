.. _partial_reconfiguration:

***********************
Partial Reconfiguration
***********************

From image v2.4, PYNQ supports partial bitstream reconfiguration.
The partial bitstreams are managed by the *overlay* class. It is always 
recommended to use the *.hwh* file along with the *.bit* for the overlay class.

Preparing the Files
===================
There are many ways to prepare the bitstreams. Users can choose to follow
the project flow or the software flow to implement a partial reconfiguration
Vivado project. For more information, please refer to the `documentation page
on partial reconfiguration 
<https://www.xilinx.com/products/design-tools/vivado/implementation/partial-reconfiguration.html#documentation>`_.

After each reconfiguration, the PL status will update to reflect the changes
on the bitstream, so that new drivers can be assigned to the new blocks 
available in the bitstream. To achieve this, users have to provide the 
metadata file (*.hwh* file) along with each full / partial bitstream. 
The *.hwh* file is typically located at:
`<project_name>/<design_name>.srcs/sources_1/bd/<design_name>/hw_handoff/`.

Keep in mind that each partial bitstream need a *.hwh* file.


Loading Full Bitstream
======================
It is straightforward to download a full bitstream. By default, the bitstream
will be automatically downloaded onto the PL when users instantiate 
an overlay object.

.. code-block:: python
   
   from pynq import Overlay
   overlay = Overlay("full_bistream.bit')
   
To download the full bitstream again:

.. code-block:: python
   
   overlay.download()

Note that no argument is provided if a full bitstream is to be downloaded.

Another thing to note, is that if the Vivado project is configured as a 
partial reconfiguration project, the *.hwh* file for the full bitstream 
will not contain any information inside a partial region, even if the full 
bitstream always has a default *Reconfiguration Module* (RM) implemented. 
Instead, the *.hwh* file only provides the information on the interfaces 
connecting to the partial region. So for the full bitstream, don't be surprised
if you see an empty partial region in the *.hwh* file. The complete information
on the partial regions are revealed by the *.hwh* files of 
the partial bitstreams, where each *.hwh* file reveals one possible 
internal organization of the partial region.

Loading Partial Bitstream
=========================
Typically, the partial regions are hierarchies in the block design of the 
bitstream. In an *overlay* object, the hierarchical blocks are exposed as 
attributes of the object; users have to set the partial region for the overlay 
before they can reconfigure it. In the following example, let's assume there
is a hierarchical block called *block_0* in the design.

.. code-block:: python
   
   overlay.set_partial_region('block_0')

After the partial region is set, users can use the *download()* method 
for partial bitstreams. Note that an argument is now needed if a partial
bitstream is to be downloaded.

.. code-block:: python
   
   overlay.download('rm_0_partial.bit')
   
To load a different RM:

.. code-block:: python
   
   overlay.download('rm_1_partial.bit')
   
