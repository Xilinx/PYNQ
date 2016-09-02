#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without 
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its 
#       contributors may be used to endorse or promote products derived from 
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

__author__ = "Patrick Lysaght"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

"""Script to overcome bug in current nbsphinx-Sphinx flow.

This file is modified on 13 April 2016

Note
----
nbsphinx only seems to recognize Jupyter notebook image references specified 
in "![](images/image.jpeg)" markdown format. 
 
This script post-processes Jupyter notebook (.ipynb) files prior to their 
being processed by npsphinx and Sphinx.

1. It removes a markdown reference to an image file WHICH MUST APPEAR AS THE 
LAST LINE IN A GIVEN MARKDOWN CELL.

2. It then inserts a RAW cell with reST annotation which includes a figure 
directive for the image with center alignment.

3. It repeats this for all markdown cells with markdown image references as 
their last line.

4. Finally it rewrites the <.ipynb> as files. The original files will be 
saved in a temporary folder. The new files can then be processed by 
the nbsphinx-Sphinx flow.

It is expected that the script will be run in the docs directory of the Sphinx
project (beside the makefile). The target_dir variable should be set to 
./source for nornmal operation.

"""


import os
import json
import re
import shutil

# Set target_directory and create list of *.ipynb files within it
target_dir = "./source"
temp_dir = "./source/temp"
if not os.path.exists(temp_dir):
    os.makedirs(temp_dir)

# Find all Jupyter notebook (.ipynb) files    
ipynb_files = [file for file in os.listdir(target_dir) \
                    if file.endswith(".ipynb")]
print('Found {} notebook (.ipynb) files in {}'.format(len(ipynb_files), \
                os.path.abspath(target_dir)))

# Regex for the image reference pattern within markdown cells in *.ipynb 
image_ref_pattern = "\!\[].*/((.*[png jpeg jpg JPG]))"

# Load each of the identified *.ipynb (JSON-formatted) files as a dict
for file in ipynb_files:
    # Make a copy
    file_name, file_ext = os.path.splitext(os.path.basename(file))
    temp_file = file_name + ".tmp"
    shutil.copyfile(target_dir + '/' + file, temp_dir + '/' + temp_file)
    with open(target_dir + '/' + file, 'r+', encoding='utf-8') as f:
        notebook = json.load(f)
        print('Scanning file {}'.format(file))
        
        # Build markdown_cells with a string matching image_ref_pattern
        match_count = 0
        for i, notebook_cell in enumerate(notebook['cells']):
            if notebook_cell['cell_type'] == 'markdown':
                for j, source_str in enumerate(notebook_cell['source']):
                    match = re.search(image_ref_pattern, source_str)
                    if match != None:
                        match_count += 1
                        if j != len(notebook_cell['source'])-1:
                            raise RuntimeError('{} was not the last entry '+ \
                                    'in the markdown cell'.format(source_str))
                        else:
                            del notebook_cell['source'][-1]
                            reST_figure_directive = ".. figure:: " + \
                                        "images/" + match.group(1) + " \n"
                            reST_cell = {
                                "cell_type": "raw",
                                "metadata": {
                                    "raw_mimetype": "text/restructuredtext"
                                },
                                "source": [
                                    reST_figure_directive,
                                    "   :align: center"
                                    ]
                            }
                            # Create new notebook cell after the current one
                            notebook['cells'].insert(i+1, reST_cell)
                            
        if match_count != 0:
            # Create the new post-processed ipynb file with updated JSON
            with open(target_dir + '/' + file, 'w') as f_pp:
                f_pp.write(json.dumps(notebook, indent = 1, sort_keys=True))
