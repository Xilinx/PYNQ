# pynq-bdc-patcher
""" When using BDCs in Vivado the resulting XSA is missing information that PYNQ needs. Importantly the REGISTER field information. This script takes the XSA file and a path to the root directory of the project that the XSA was generated from and generates a new XSA that contains the missing information."""

__author__ = "Shane T. Fleming"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"

import argparse
import os
import json
from pynq import XsaParser
from xml.etree import ElementTree
import bdc_meta as BdcMeta

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

def get_all_xci_files_in(project_dir) -> list:
    """
        returns a list of all xci files in a project directory

        Parameters:
        -----------
        project_dir : str
            A string with the path to the project directory

        Returns:
        ----------
        list
            a list of all the xci files in the project directory
    """
    # Get a list of all .xci files in the project
    xci_files =[]
    for folders, dirs, files in os.walk(project_dir):
        for f in files:
            if f.endswith('.xci'):
                xci_files.append(os.path.join(folders, f));
    return xci_files
    
def filter_xci_files_for_ip(xci_files, ip_type_dict) -> dict:
    """
        filters a list of xci files for the ones that have information on an ip in the ip_type_dict

        Parameters:
        ------------
        xci_files : list
            A list of paths to xci files in the project directory

        ip_type_dict: dict
            A dictionary that maps ip names to their vlnv type

        Returns:
        -----------
        dict
            A dictionary that maps the name of the IP to the xci file with the 
            corresponding information about it.
    """
    ip_xci = {}
    for ip_key in ip_type_dict:
        for xci in xci_files:
            searchfile = open(xci, "r")
            for line in searchfile:
                if ip_type_dict[ip_key] in line:
                    ip_xci[ip_key] = searchfile
                    break
    return ip_xci


def get_xci_file_for_ip(project_dir, ip_type_dict) -> dict:
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
    xci_files = get_all_xci_files_in(project_dir)
    ip_xci = filter_xci_files_for_ip(xci_files, ip_type_dict) 
    return ip_xci
    
def get_bdcip_from_xci(ipname, xci) -> BdcMeta.BdcIp:
    """
        Given an xci file extract the regmap for that IP core.

        Parameters:
        -----------
            xci : os.path to the xci file 

        Returns:
        ----------
            BdcIP
                An object containing the metadata for this block design container IP
    """
    namespaces = {'xilinx': "http://www.xilinx.com", 'spirit' : "http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009", 'xsi' : "http://www.w3.org/2001/XMLSchema-instance"}
    parsed_xci = ElementTree.parse(xci.name)

    bdcip = BdcMeta.BdcIp(ipname)
    for ip in parsed_xci.findall(".//*[@xilinx:boundaryDescriptionJSON]", namespaces):
        ip_xci_boundary_json = json.loads(ip.attrib["{http://www.xilinx.com}boundaryDescriptionJSON"])

        for interface in ip_xci_boundary_json["boundary"]["memory_maps"]:
            rendered_interface = BdcMeta.BdcIpInterface(interface)   
            interface_json = ip_xci_boundary_json["boundary"]["memory_maps"][interface]["address_blocks"]
            for regblock in interface_json:
                regmap = BdcMeta.RegMap(regblock, interface_json[regblock]["base_address"], interface_json[regblock]["range"])
                registers = interface_json[regblock]["registers"]
                for reg in registers:
                    newreg = BdcMeta.Register(reg, 
                                              registers[reg]["address_offset"], 
                                              registers[reg]["size"],
                                              registers[reg]["description"],
                                              registers[reg]["access"]
                                              )
                    fields = registers[reg]["fields"]
                    for field in fields:
                        f = BdcMeta.Field(field, 
                                          fields[field]["bit_offset"], 
                                          fields[field]["bit_width"],
                                          fields[field]["description"],
                                          fields[field]["access"]
                                          )
                        newreg.add(f)
                    regmap.add(newreg)
                rendered_interface.add_regmap(regmap)
            bdcip.add_interface(rendered_interface)
    return bdcip


def get_regmaps_for_ip(project_dir, ip_types):
    """
        Given a project directory and a set of ip in a BDC with their types return a 
        dictionary of BdcIP objects for the ip names. 

        Paramters:
        -----------
        project_dir : str
            A path to the project directory

        ip_types : dict
            A dictionary mapping the name of an ip to the vlnv type
            
        Returns:
        -----------
        dict
            A dictionary that maps the name of an IP to a BdcIP object containing the RegMap 
            information
    """
    ip_to_xci = get_xci_file_for_ip(project_dir, ip_types)
    for ip in ip_to_xci:
        get_bdcip_from_xci(ip, ip_to_xci[ip])

def get_bdc_name_from_hwh(hwh):
    """
    From a parsed HWH file return the name of the BDC.

    Parameters:
    -----------
    hwh : xml.etree.ElementTree.ElementTree object

    Returns:
    ---------
    str:
        the name of the BDC
    """
    for sys in hwh.getroot().iter('SYSTEMINFO'):
        return sys.attrib['NAME']


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
    bdc_name = get_bdc_name_from_hwh(p)
    bdc = BdcMeta.Bdc(bdc_name)
    ip_types = get_all_ip_vlnv_from_parsed(p)

    ip_to_xci = get_xci_file_for_ip(args.project_directory, ip_types)
    for ip in ip_to_xci:
        bdc.add_ip(get_bdcip_from_xci(ip, ip_to_xci[ip]))
    bdc.render_as_json()

