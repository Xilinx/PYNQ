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

__author__ = "Shane T. Fleming, Geoff Gillett"
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

    def createNameMatchingDefaultHwh(self) -> None:
        """
        A temporary fix to rename the default bd to match the primary bitstream.
        TODO: make it so that the whole XsaParser object is passed down into the 

        Assumes that we have only one bitfile, need to test this with PR projects.
        """
        expected_hwh = os.path.splitext(self.bitstreamPaths[0])[0] + ".hwh" 
        if expected_hwh not in self.defaultHwhPaths:
            shutil.copyfile(self.defaultHwhPaths[0], expected_hwh)

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


