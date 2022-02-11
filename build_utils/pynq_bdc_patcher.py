# pynq-bdc-patcher
""" When using BDCs in Vivado the resulting XSA is missing information that PYNQ needs. Importantly the REGISTER field information. This script takes the XSA file and a path to the root directory of the project that the XSA was generated from and generates a new XSA that contains the missing information."""

__author__ = "Shane T. Fleming"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"

import argparse
from pynq import XsaParser
from xml.etree import ElementTree

def parse_all_bdc_hwh_files_from(xsa) -> list:
    """ 
        returns a list of parsed BDC HWH files

        Parameters
        ----------
        xsa : XSAParser object
    """
    return map(ElementTree.parse, xsa.referenceHwhPaths)

def get_all_ip_vlnv_from_parsed(hwh) -> dict:
    """
        returns a dict of IP types from a hwh file that we can search for in
        the project directory.

        Parameters
        ----------
        hwh : an ElementTree parsed HWH file for the BDC

        Returns
        ----------
        dict
            a dict mapping all the ip to their vlnv in a BDC
    """
    ip_type = {}
    for ip in hwh.findall(".//*[@IPTYPE]"):
        ip_type[ip.attrib["FULLNAME"]] = ip.attrib["VLNV"]
    return ip_type

def search_for_xci_files_for(project_dir, ip_type_dict) -> dict:
    """
        returns a dict of the xci files that contain the regmap information 
        for the given IP.
        
        Parameters:
        -----------
        project_dir : str 
           a string to the path of the project directory 
        ip_type_dict : dict
            a dictionary mapping the ip names to their vlnv types

        Returns:
        ----------
        dict
            a dictionary that maps ip names to their xci file paths in the project directory
    """
    ip_xci_path = {}



usage = "python3 pynq_bdc_patcher.py -i input.xsa -d /project/directory/path -o output.xsa"

parser = argparse.ArgumentParser(description=usage)
parser.add_argument("-i", "--input_xsa", help="sets the XSA file input name")
parser.add_argument("-d", "--project_directory", help="sets the vivado project directory")
parser.add_argument("-o", "--output_xsa", help="sets the output xsa filename")
parser.add_argument("-V", "--verbose", help="increase the verbosity of the output", action="store_true")

args = parser.parse_args()

if not args.input_xsa:
    raise RuntimeError("We require an input XSA specified with the -i option");

if not args.project_directory:
    raise RuntimeError("We require the location of the original project directory specified with the -d option");

if not args.output_xsa:
    print("[Warning] no output XSA specified using the default output.xsa");

if args.verbose:
    print("Parsing: "+args.input_xsa)
xsa_in = XsaParser(args.input_xsa)

parsed_hwhs = parse_all_bdc_hwh_files_from(xsa_in)

for p in parsed_hwhs:
    ip_types = get_all_ip_vlnv_from_parsed(p)
    print(ip_types)


