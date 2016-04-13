
# coding: utf-8

# In[60]:

"""
Author: P Lysaght
Date: 13 April 2016

Note:
Script to overcome bug in current nbsphinx-Sphinx flow
nbsphinx only seems to recognize Jupyter notebook image references specified in "![](images/image.jpeg)" markdown format
This script post-processes Jupyter notebook (.ipynb) files prior to their being processed by npsphinx and Sphinx
It removes a markdown reference to an image file WHICH MUST APPEAR AS THE LAST LINE IN A GIVEN MARKDOWN CELL
It then inserts a RAW cell with reST annotation which includes a figure directive for the image with center alignment
It repeats this for all markdown cells with markdown image references as their last line
Finally it writes out the <original_file.ipynb> as 
Files of type <original_file_pp.ipynb> are then processed by the nbsphinx-Sphinx flow

It is expected that the script will be run in the docs directory of teh Sphinx project (beside the makefile)
The target_dir variable should be set to ./source for nornmal operation
"""


import os
import json
import re


# Set target_directory and create list of *.ipynb files within it
target_dir = "./test"

# Remove all previously post-processed (_pp.ipynb) files from target directory
ipynb_pp_files = [file for file in os.listdir(target_dir) if file.endswith("_pp.ipynb")]
for file in ipynb_pp_files:
    os.remove(target_dir + '/' + file)

# Find all Jupyter notebook (.ipynb) files    
ipynb_files = [file for file in os.listdir(target_dir) if file.endswith(".ipynb")]
print('\nFound {} notebook (.ipynb) files in {}'.format(len(ipynb_files), os.path.abspath(target_dir)))

# Regex for the image reference pattern to be found within some markdown cells in *.ipynb files 
image_ref_pattern = "\!\[].*/((.*[png jpeg]))"

# Load each of the identified *.ipynb (JSON-formatted) files as a dict
for file in ipynb_files:
    with open(target_dir + '/' + file, 'r+', encoding='utf-8') as f:
        notebook = json.load(f)
        print('\nScanning ..... file "{}"'.format(file))
        f.close()
        
        # build list of markdown_cells thta contain a string matching the image_ref_pattern
        match_count = 0
        for i, notebook_cell in enumerate(notebook['cells']):
            if notebook_cell['cell_type'] == 'markdown':
                for j, source_str in enumerate(notebook_cell['source']):
                    match = re.search(image_ref_pattern, source_str)
                    if match != None:
                        match_count += 1
                        if j != len(notebook_cell['source'])-1:
                            print('ERROR: {} was not the last entry in the markdown cell'.format(source_str))
                        else:
                            print('\tDeleting {} in file "{}"'.format(source_str, file))
                            del notebook_cell['source'][-1]
                           
                            reST_figure_directive = ".. figure:: " + "images/" + match.group(1) + " \n"
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
                                                                                 
                            print ('\tInserting RAW reST cell for {}'.format(reST_figure_directive))
                            # Create new notebook cell after the current on of type RAW with reST figure directive 
                            notebook['cells'].insert(i+1, reST_cell)
        # For notebooks without any images
        if match_count == 0:
            print('No images found in file "{}"'.format(file))
        else:
            # Create the new post-processed ipynb file with updated JSON 
            file_name, file_ext = os.path.splitext( os.path.basename(file))
            post_processed_file = file_name + '_pp' + file_ext
            print('Writing changes to file: ..... "{}"'.format(post_processed_file))
            with open(target_dir + '/' + post_processed_file, 'a+') as f_pp:
                f_pp.write(json.dumps(notebook, indent = 1, sort_keys=True))
                f_pp.close()

