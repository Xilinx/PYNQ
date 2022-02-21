# pynq-bdc-patcher
""" When using BDCs in Vivado the resulting XSA is missing information that PYNQ needs. Importantly the REGISTER field information. This script takes the XSA file and a path to the root directory of the project that the XSA was generated from and generates a new XSA that contains the missing information."""

__author__ = "Shane T. Fleming"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"

import argparse
import os
import json
import tempfile
import zipfile
import shutil
import re
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


def get_all_component_xml_files_in(ip_locs, verbose=False) -> list:
    """
    Given a list of IP repositories return all the component.xml
    files within those repositories

    Paramters:
    ------------
    list : ip_locs

    Returns:
    ------------
    list
        list of all component.xml files
    """
    component_files = []
    for ip_loc in ip_locs:
        print("Searching IP location: " + ip_loc)
        for folders, dirs, files in os.walk(ip_loc):
            for f in files:
                if f == "component.xml":
                    component_files.append(os.path.join(folders, f))
                    if verbose:
                        print(folders + "/" + f)
    return component_files


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
    xci_files = []
    for folders, dirs, files in os.walk(project_dir):
        for f in files:
            if f.endswith(".xci"):
                xci_files.append(os.path.join(folders, f))
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


def filter_component_xml_files_for_ip(xml_files, ip_type_dict, verbose=False) -> dict:
    """
    filters a list of component.xml IP metadata files for the ones that
    have information on an ip in the ip_type_dict

    Parameters:
    ------------
    xml_files : list
        A list of paths to component.xml files containing IP metadata

    ip_type_dict: dict
        A dictionary that maps ip names to their vlnv type


    Returns:
    -------------
    dict
        A dictionary that maps the name of the IP to the xci file with the
        corresponding information about it.
    """
    ip_xml = {}
    namespaces = {
        "xilinx": "http://www.xilinx.com",
        "spirit": "http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
    }
    for ip_key in ip_type_dict:
        vlnv_split = re.split(":", ip_type_dict[ip_key])
        for xml in xml_files:
            try:
                parsed_xml = ElementTree.parse(xml)
                xml_root = parsed_xml.getroot()
                c_vendor = xml_root.find("spirit:vendor", namespaces).text
                c_library = xml_root.find("spirit:library", namespaces).text
                c_name = xml_root.find("spirit:name", namespaces).text
                c_version = xml_root.find("spirit:version", namespaces).text
                c_vlnv = [c_vendor, c_library, c_name, c_version]
                if c_vlnv == vlnv_split:
                    ip_xml[ip_key] = xml
                    if verbose:
                        print("Found metadata for " + ip_key + " at " + xml)
                    break
            except Exception:
                pass
    return ip_xml


def get_component_xml_files_for_ip(ip_repo_list, ip_type_dict, verbose=False) -> dict:
    """
    returns a dict of the component.xml files that contain the regmap information
    for the given IP.

    Parameters:
    -----------
    ip_repo_list : list
       a list to the paths of ip repositories
    ip_type_dict : dict
        a dictionary mapping the ip names to their vlnv types

    Returns:
    ----------
    dict
        a dictionary that maps ip names to their xml file paths in the project directory
    """
    xml_files = get_all_component_xml_files_in(ip_repo_list, verbose)
    ip_xml = filter_component_xml_files_for_ip(xml_files, ip_type_dict, verbose)

    for ip in ip_type_dict:
        if ip not in ip_xml:
            print(
                "[WARNING] unable to find metadata for IP core "
                + ip
                + " it will likely have missing data in the PYNQ ip_dict when the data is loaded"
            )

    return ip_xml


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


def get_bdcip_from_component_xml(ipname, xml) -> BdcMeta.BdcIp:
    """
    Given a component xml file extract the regmap and parameters for that IP core.

    Parameters:
    -----------
        ipname : str
           the name of the IP

        xml : str
            the path to component.xml file for that IP

    Returns:
    -----------
        BdcIp
            An object containing the metadata for this block design container
    """
    bdcip = BdcMeta.BdcIp(ipname)

    ns = {
        "xilinx": "http://www.xilinx.com",
        "spirit": "http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
    }
    parsed_xml = ElementTree.parse(xml)
    root = parsed_xml.getroot()

    # Getting the parameters
    parameters = root.find("spirit:parameters", ns)
    for parameter in parameters.iter(
        "{http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009}parameter"
    ):
        param_name = parameter.find("spirit:name", ns).text
        param_value = parameter.find("spirit:value", ns).text
        new_param = BdcMeta.BdcParam(param_name, param_value)
        bdcip.add_parameter(new_param)

    # Getting the memory maps
    for memmap in root.iter(
        "{http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009}memoryMap"
    ):
        intf_name = memmap.find("spirit:name", ns).text
        rendered_interface = BdcMeta.BdcIpInterface(intf_name)
        for addrblock in memmap.iter(
            "{http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009}addressBlock"
        ):
            regmap_name = addrblock.find("spirit:name", ns).text
            base_addr = addrblock.find("spirit:baseAddress", ns).text
            addr_range = addrblock.find("spirit:range", ns).text
            regmap = BdcMeta.RegMap(regmap_name, base_addr, addr_range)
            for registers in addrblock.iter(
                "{http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009}register"
            ):
                new_reg = BdcMeta.Register(
                    registers.find("spirit:name", ns).text,
                    registers.find("spirit:addressOffset", ns).text,
                    registers.find("spirit:size", ns).text,
                    registers.find("spirit:description", ns).text,
                    registers.find("spirit:access", ns).text,
                )
                for field in registers.iter(
                    "{http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009}field"
                ):
                    new_field = BdcMeta.Field(
                        field.find("spirit:name", ns).text,
                        field.find("spirit:bitOffset", ns).text,
                        field.find("spirit:bitWidth", ns).text,
                        field.find("spirit:description", ns).text,
                        field.find("spirit:access", ns).text,
                    )
                    new_reg.add(new_field)
                regmap.add(new_reg)
            rendered_interface.add_regmap(regmap)
        bdcip.add_interface(rendered_interface)
    return bdcip


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
    namespaces = {
        "xilinx": "http://www.xilinx.com",
        "spirit": "http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
    }
    parsed_xci = ElementTree.parse(xci.name)

    bdcip = BdcMeta.BdcIp(ipname)
    for ip in parsed_xci.findall(".//*[@xilinx:boundaryDescriptionJSON]", namespaces):
        for param in parsed_xci.iter(
            "{http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009}configurableElementValue"
        ):
            refid = param.get(
                "{http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009}referenceId"
            )
            if refid.startswith("MODELPARAM_VALUE.") or refid.startswith(
                "PARAM_VALUE."
            ):
                bdc_param = BdcMeta.BdcParam(refid, param.text)
                print(refid + " : " + param.text)
                bdcip.add_parameter(bdc_param)

        ip_xci_boundary_json = json.loads(
            ip.attrib["{http://www.xilinx.com}boundaryDescriptionJSON"]
        )
        for interface in ip_xci_boundary_json["boundary"]["memory_maps"]:
            rendered_interface = BdcMeta.BdcIpInterface(interface)
            interface_json = ip_xci_boundary_json["boundary"]["memory_maps"][interface][
                "address_blocks"
            ]
            for regblock in interface_json:
                regmap = BdcMeta.RegMap(
                    regblock,
                    interface_json[regblock]["base_address"],
                    interface_json[regblock]["range"],
                )
                registers = interface_json[regblock]["registers"]
                for reg in registers:
                    newreg = BdcMeta.Register(
                        reg,
                        registers[reg]["address_offset"],
                        registers[reg]["size"],
                        registers[reg]["description"],
                        registers[reg]["access"],
                    )
                    fields = registers[reg]["fields"]
                    for field in fields:
                        f = BdcMeta.Field(
                            field,
                            fields[field]["bit_offset"],
                            fields[field]["bit_width"],
                            fields[field]["description"],
                            fields[field]["access"],
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
    for sys in hwh.getroot().iter("SYSTEMINFO"):
        return sys.attrib["NAME"]


usage = (
    "python3 pynq_bdc_patcher.py -i input.xsa -d /project/directory/path -o output.xsa"
)

parser = argparse.ArgumentParser(description=usage)
parser.add_argument("-i", "--input_xsa", help="sets the XSA file input name")
parser.add_argument("-o", "--output_xsa", help="sets the output xsa filename")
parser.add_argument(
    "-l",
    "--ip_libraries",
    action="append",
    help="add a location to search for IP metadata",
)
parser.add_argument(
    "-V", "--verbose", help="increase the verbosity of the output", action="store_true"
)

args = parser.parse_args()

if not args.input_xsa:
    raise RuntimeError("We require an input XSA specified with the -i option")

if not args.output_xsa:
    print("[Warning] no output XSA specified using the default output.xsa")

if args.verbose:
    print("Parsing: " + args.input_xsa)
xsa_in = XsaParser(args.input_xsa)

temp_directory = tempfile.mkdtemp()
if args.verbose:
    print("Extracting XSA to: " + temp_directory)
with zipfile.ZipFile(args.input_xsa, "r") as zip_ref:
    zip_ref.extractall(temp_directory)
if args.verbose:
    print("XSA fully extracted at: " + temp_directory)

parsed_hwhs = parse_all_bdc_hwh_files_from(xsa_in)

for p in parsed_hwhs:
    bdc_name = get_bdc_name_from_hwh(p)

    if args.verbose:
        print("Getting metadata for BDC: " + bdc_name)

    bdc = BdcMeta.Bdc(bdc_name)
    ip_types = get_all_ip_vlnv_from_parsed(p)

    if args.verbose:
        print("Searching for metadata for the following IP...")
        for ip in ip_types:
            print("\t" + ip)

    if args.verbose:
        print("Searching the following locations for metadata:")
        for l in args.ip_libraries:
            print(l)

    ip_xml = get_component_xml_files_for_ip(args.ip_libraries, ip_types, args.verbose)
    if args.verbose:
        print("done\n")
        print(
            "The following component.xml files have been located for all BDC IP files."
        )
        print(ip_xml)

    for ip in ip_xml:
        bdc.add_ip(get_bdcip_from_component_xml(ip, ip_xml[ip]))

    bdc_json_metadata_filename = (
        temp_directory + "/" + bdc_name + "_pynq_bdc_metadata.json"
    )
    bdc_json_metadata = open(bdc_json_metadata_filename, "w")
    bdc.render_as_json(bdc_json_metadata)
    bdc_json_metadata.close()
    if args.verbose:
        print("Writing Metadata file: " + bdc_json_metadata_filename)

shutil.make_archive(args.output_xsa, "zip", temp_directory)
os.rename(args.output_xsa + ".zip", args.output_xsa)
if args.verbose:
    print("Compressed the modified XSA file into :" + args.output_xsa)
