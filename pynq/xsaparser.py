#   Copyright (c) 2016-2021, Xilinx, Inc.
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

import sys
import os
import argparse
from xml.dom.minidom import Element
import zipfile
import tempfile
import shutil
import json
from xml.etree import ElementTree
from typing import Union

__author__ = "Shane T. Fleming"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


class Xsa:
    """ 
    XSA zip archive reader class
    """

    def __init__(self, path) -> None:
        if not os.path.exists(path):
            raise RuntimeError(f"{path} does not exist")
        """ path to the XSA file"""
        self.__archive = path
        """ path to directory for extracted files """
        self.__extracted = tempfile.mkdtemp()
        with zipfile.ZipFile(self.__archive, 'r') as xsa:
            """ the set of members of the zip archive """
            self.__members = set(xsa.namelist())

        # I am assuming that sysdef.xml xsa.json, and xsa.xml are always members
        """ the root of the sysdef.xml element tree """
        self.__sysdef = ElementTree.parse(self.__path("sysdef.xml")).getroot()
        with open(self.__path("xsa.json")) as f:
            """ xsa.json as a dict"""
            self.__json = json.load(f)
        """ the root of  xsa.xml element tree"""
        self.__xml = ElementTree.parse(self.__path("xsa.xml")).getroot()
        

    def __path(self, members: Union[str, list]) -> Union[str, tuple]:
        """ 
        return OS path(s) to extracted archive member(s)
        files are extracted if not present in the  __extracted directory
        """
        if type(members) is str:
            members = [members]
            single = True
        else:
            single = False

        missing = set(members) - (self.__members & set(members))
        if missing:
            raise RuntimeError(f"{', '.join(missing)} not found in the XSA archive")

        os_paths = []
        with zipfile.ZipFile(self.__archive, 'r') as xsa:
            for member in members:
                os_path = os.path.join(self.__extracted, member)
                if not os.path.exists(os_path):
                    xsa.extract(member, self.__extracted)
                os_paths.append(os_path)
            if single:
                return os_paths[0]
            else:
                return tuple(os_paths)
                    

class XsaParser(Xsa):
    """
    XSA parsing
    """ 
    def __init__(self, path: str) -> None:
        super().__init__(path)

    @property
    def bitstreamPaths(self) -> tuple: 
        """ 
        return a tuple of paths to extracted bitstreams defined in sysdef.xml 

        """
        return self._Xsa__path([e.attrib['Name'] for e in self.__bitstreamElements()])

    @property
    def defaultHwhPaths(self) -> tuple:
        """ 
        return a tuple of paths to extracted HWHs with attribute 
        BD_TYPE=DEFAULT_BD in sysdef.xml 
        """
        return self._Xsa__path([e.attrib["Name"] for e in self.__hwhElements('DEFAULT_BD')])

    @property
    def referenceHwhPaths(self) -> tuple:
        """ 
        return a tuple of paths to extracted BDCs (attribute BD_TYPE=REFERENCE_BD) 
        in sysdef.xml 
        """
        return self._Xsa__path([e.attrib["Name"] for e in self.__hwhElements('REFERENCE_BD')])

    # ----------------------------------------------
    # Prints out an XML structure
    # ----------------------------------------------
    def print_xml_recurse(self, node):
        """ recursively walks down the XML structure """
        for c in node:
            print(c.tag, c.attrib)
            self.print_xml_recurse(c)

    def print_xml(self, root=None):
        """ Prints xml structure from root,  root=None prints sysdef.xml"""
        if root is None:
            root = self._Xsa__xml
        print(root.tag)
        print(root.attrib)
        for child in root:
            self.print_xml_recurse(child)
    # ----------------------------------------------

    def print_json(self):
        """ prints the xsa.json file in the XSA """
        print(json.dumps(self._Xsa__json, indent=2))


    def __hwhElements(self, bd_type=None) -> list:
        """
        return a list of elements in sysdef representing HWH files

        Assumes all File elements with a BD_TYPE attribute are HWH files 

        Parameters
        ----------
        bd_type : str
            filter the BD_TYPE attribute, None=any

        Returns
        -------
        list
            list of xml elements
        """
        if bd_type is None:
            return self._Xsa__sysdef.findall("File[@Type='HW_HANDOFF']")
        return self._Xsa__sysdef.findall(f"File[@BD_TYPE='{bd_type}']")
        
        
    def __bitstreamElements(self) -> list:
        """
        return a list of elements in sysdef representing bitstream files

        sysdef tag=File attributes Type=BIT
        """
        return self._Xsa__sysdef.findall("File[@Type='BIT']")


class XSAParser:
    """ 
        A class for parsing the XSA format
    """
    def __init__(self, xsa):
        """ The constructor, accepts a string for xsa file location """
        self.__tdir = tempfile.mkdtemp()
        with zipfile.ZipFile(xsa, 'r') as zip_ref:
            zip_ref.extract("sysdef.xml", self.__tdir)
            self.__sysdef_xml = self.xml_parse_check("sysdef.xml")

            zip_ref.extract("xsa.json", self.__tdir)
            self.__xsa_json = self.json_parse_check("xsa.json")

            # Get the hardware handoff file
            zip_ref.extract(self.get_hwh_filename(), self.__tdir)
            self.__hwh_xml = self.xml_parse_check(self.get_hwh_filename())

            # Get the bitstream
            self.__bitstream_filename = self.get_bitstream_filename()             
            zip_ref.extract(self.__bitstream_filename, self.__tdir)

            if(os.path.splitext(self.__bitstream_filename)[0] != os.path.splitext(self.get_hwh_filename())[0]):
                shutil.copyfile(self.__tdir + "/" + self.__bitstream_filename, self.__tdir + "/" + os.path.splitext(self.get_hwh_filename())[0] + ".bit")
                self.__bitstream_filename = self.__tdir + "/" + os.path.splitext(self.get_hwh_filename())[0] + ".bit"
            

    def xml_parse_check(self,xmlfile):
        """ Checks if an XML file exists in the extracted temp XSA directory and parses it """ 
        if os.path.exists(self.__tdir+"/"+xmlfile):
            return ElementTree.parse(self.__tdir+"/"+xmlfile)
        else:
            raise RuntimeError("[Error] "+xmlfile+" file could not be found in the XSA")

    def json_parse_check(self,jsonfile):
        """ Checks if a json file exists in the extracted temp XSA directory and parses it """ 
        if os.path.exists(self.__tdir+"/"+jsonfile):
            with open(self.__tdir+"/"+jsonfile) as xsa_json_f:
                return json.load(xsa_json_f)
        else:
            raise RuntimeError("[Error] "+jsonfile+" file could not be found in the XSA")

    def print_json(self):
        """ prints the xsa.json file in the XSA """
        if self.__xsa_json is not None:
            print(self.__xsa_json)
        else:
            print("XSA json file has not been loaded")

    def get_temp_dir(self):
        """ Returns the temporary directory that the XSA has been extracted to """
        if self.__tdir is not None:
            return self.__tdir
        else:
            print("XSA json file has not been loaded or extracted")

    # ----------------------------------------------
    # Prints out an XML structure
    # ----------------------------------------------
    def print_xml_recurse(self, node):
        """ recursively walks down the XML structure """
        for c in node:
            print(c.tag, c.attrib)
            self.print_xml_recurse(c)

    def print_xml(self, xml):
        """ Prints the sysdef file """
        if xml is not None:
            root = xml.getroot()
            print(root.tag)
            print(root.attrib)
            for child in root:
                self.print_xml_recurse(child)
        else:
            print("XML file was empty")
    # ----------------------------------------------

    def get_hwh_xml(self):
        """ Returns the XML of the hardware handoff file """
        return self.__hwh_xml

    def get_hwh_filename(self):
        """ Looks through the sysdef.xml file to find the name of the hardware handoff file """
        if self.__sysdef_xml is not None:
            root = self.__sysdef_xml.getroot()
            for child in root: 
                if "Type" in child.attrib:
                    if child.attrib["Type"] == "HW_HANDOFF":
                        return child.attrib["Name"]
            raise RuntimeError("Error. Name of the hardware handoff file could not be found in sysdef.xml when parsing the XSA file")
        else:
            raise RuntimeError("Error. Attempting to gather HWH file details from XSA when no sysdef.xml has been parsed correctly")

    def get_bitstream_filename(self):
        """ Looks through the sysdef.xml file to find the name of the bitstream file """
        if self.__sysdef_xml is not None:
            root = self.__sysdef_xml.getroot()
            for child in root: 
                if "Type" in child.attrib:
                    if child.attrib["Type"] == "BIT":
                        return child.attrib["Name"]
            raise RuntimeError("Error. Name of the bitstream file could not be found in sysdef.xml when parsing the XSA file")
        else:
            raise RuntimeError("Error. Attempting to gather bitstream file details from XSA when no sysdef.xml has been parsed correctly")

    def get_full_bitstream_path(self):
        return self.__bitstream_filename

    def get_full_hwh_path(self):
        return self.__tdir + "/" + self.get_hwh_filename()
    

    __tdir = None
    __xsa_json = None
    __hwh_file = None
    __sysdef_xml = None
    __hwdef_xml = None
    __hwh_filename = None
    __hwh_xml = None
    __bitstream_filename = None



