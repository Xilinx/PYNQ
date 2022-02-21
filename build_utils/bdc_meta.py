# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

"""
    A collection of classes that are used to store the metadata of the BDC, IP, and Registers
"""
def print_n_tabs(n):
    for i in range(0,n):
        #print("\t", end="")
        print(" ", end="")

class BdcField:
    """
        simple filed class to hold bitwise information about a register
    """
    def __init__(self, name, bit_offset, bit_width, desc, access):
        self.name = name
        self.bit_offset = bit_offset
        self.bit_width = bit_width
        self.desc = desc
        self.access = access

    def print(self, tabdepth=0):
        print_n_tabs(tabdepth)
        print(self.name+" bit_offset:"+str(self.bit_offset)+" bit_width:"+str(self.bit_width)+" access:"+str(self.access))
        #print_n_tabs(tabdepth+1)
        #print(self.desc)

    def render_as_json(self, jf):
        jf.write("\""+self.name+"\": {")
        jf.write("\"bit_offset\":"+str(self.bit_offset)+",")
        jf.write("\"bit_width\":"+str(self.bit_width)+",")
        jf.write("\"access\": \""+str(self.access)+"\"")
        #jf.write("\"description\":\""+str(self.desc)+"\"")
        jf.write("}")


class BdcRegister:
    """
        simple register class to hold information like name and offset
    """
    def __init__(self, name, offset, size, desc, access) -> None:
        self.name = name
        self.offset = offset 
        self.size = size 
        self.desc = desc
        self.access = access
        self.fields = []  

    def add(self, field):
        self.fields.append(field)

    def print(self, tabdepth=0):
        print_n_tabs(tabdepth)
        print(self.name+": "+"offset:"+str(self.offset)+" size:"+str(self.size)+" access:"+self.access)
        print_n_tabs(tabdepth+1)
        print(self.desc)
        print_n_tabs(tabdepth+1)
        print("fields:")
        for f in self.fields:
            f.print(tabdepth+2)
    
    def render_as_json(self, jf):
        """
            Renders all the registers and fields as a JSON file for parsing later
        """
        jf.write("\""+self.name+"\": {")
        jf.write("\"offset\":\""+str(self.offset)+"\",")
        jf.write("\"size\":"+str(self.size)+",")
        jf.write("\"description\":\""+str(self.desc)+"\",")
        jf.write("\"access\": \""+str(self.access)+"\"")
        if(len(self.fields) > 0):
            jf.write(",\"fields\": {")
            for i in self.fields:
                i.render_as_json(jf)
                if i != self.fields[-1]:
                    jf.write(",")
            jf.write("}")

        jf.write("}")


class BdcRegMap:
    def __init__(self, name, base_address, addr_range) -> None:
        self.name = name
        self.base_address = base_address
        self.addr_range = addr_range
        self.registers = []

    def add(self, reg) -> None:
        self.registers.append(reg)

    def print(self, tabdepth=0):
        print_n_tabs(tabdepth)
        print(self.name+":")
        for r in self.registers:
            r.print(tabdepth+1)

    def render_as_json(self, jf):
        """
            Renders the entire regmap as json that can be parsed later
        """
        jf.write("\""+self.name+"\": {")        
        if(len(self.registers) > 0):
            jf.write("\"registers\": {")
            for i in self.registers:
                i.render_as_json(jf)
                if i != self.registers[-1]:
                    jf.write(",")
            jf.write("}")
        jf.write("}")        

class BdcIpInterface:
    """
        A class to keep track of the interfaces that a BdcIp might have
        each interface will have a register map associated with it
    """
    def __init__(self, name) -> None:
        self.name = name
        self.regmaps = []

    def add_regmap(self,regmap) -> None:
        self.regmaps.append(regmap)

    def print(self, tabdepth=0) -> None:
        print_n_tabs(tabdepth)
        print(self.name + ":")
        for r in self.regmaps:
            r.print(tabdepth+1)
        
    def render_as_json(self, jf) -> None:
        """
            Renders the entire interface in a json file for later parsing
        """
        jf.write("\""+self.name+"\" : {")
        if(len(self.regmaps) > 0):
            jf.write("\"regmap\": {")
            for i in self.regmaps:
                i.render_as_json(jf)
                if i != self.regmaps[-1]:
                    jf.write(",")
            jf.write("}")
        jf.write("}")
    
class BdcParam:
    """
        A class for a parameter within a block design container.
    """
    def __init__(self, name, value) -> None:
        self.name = name
        self.value = value

    def render_as_json(self, jf) -> None:
        """
        Renders the parameter as json
        """
        jf.write("\""+self.name+"\":\""+self.value+"\"")


class BdcIp:
    """
        A class to keep track of an IP core in a BDC
    """
    def __init__(self, name) -> None:
        self.name = name 
        self.interfaces = []
        self.parameters = []

    def add_parameter(self, parameter) -> None:
        self.parameters.append(parameter)

    def add_interface(self, interface) -> None:
        self.interfaces.append(interface)

    def print(self, tabdepth=0) -> None:
        print_n_tabs(tabdepth)
        print(self.name +":")
        for i in self.interfaces:
            i.print(tabdepth+1)

    def render_as_json(self, jf) -> None:
        """ 
            Renders the IP metadata into a json format
        """
        jf.write("\""+self.name+"\" : {")
        jf.write("\"parameters\": {")

        for p in self.parameters:
            p.render_as_json(jf)
            if p != self.parameters[-1]:
                jf.write(",")
        jf.write("},")

        if(len(self.interfaces) > 0):
            jf.write("\"interfaces\": {")
            for i in self.interfaces:
                i.render_as_json(jf)
                if i != self.interfaces[-1]:
                    jf.write(",")
            jf.write("}")
        jf.write("}")

class Bdc:
    """
        A class for the block design container
    """
    def __init__(self, name) -> None:
        self.name = name;
        self.ip_list = []

    def add_ip(self, ip) -> None:
        """
            Adds a BdcIP to the IP

            Parameters:
            -----------
            ip : BdcIP
                A BDC IP that contains the register map
        """
        self.ip_list.append(ip)

    def render_as_json(self, json_file) -> None:
        """
            Renders the internal metadata file as json file for shipping in the XSA
        """
        json_file.write("{ \"name\": \""+self.name+"\",")
        if(len(self.ip_list) > 0):
            json_file.write("\"ip\" : {")
            for i in self.ip_list:
                i.render_as_json(json_file)
                if i != self.ip_list[-1]:
                    json_file.write(",")
            json_file.write("}")
        json_file.write("}\n\n")



