"""
    A collection of classes that are used to store the metadata of the BDC, IP, and Registers
"""

__author__ = "Shane T. Fleming"
__copyright__ = "Copyright 2022, AMD"
__email__ = "pynq_support@xilinx.com"

def print_n_tabs(n):
    for i in range(0,n):
        print("\t", end="")

class Field:
    """
        simple filed class to hold bitwise information about a register
    """
    def __init__(self, name, offset, bitwidth):
        self.name = name
        self.offset = offset
        self.bitwidth = bitwidth

    def print(self, tabdepth=0):
        print_n_tabs(tabdepth)
        print(self.name)

class Register:
    """
        simple register class to hold information like name and offset
    """
    def __init__(self, name, offset, size) -> None:
        self.name = name;
        self.offset = offset; 
        self.size = size; 
        self.fields = []  

    def add(self, field):
        self.fields.append(field)

    def print(self, tabdepth=0):
        print_n_tabs(tabdepth)
        print(self.name+":")
        for f in self.fields:
            f.print(tabdepth+1)
    

class RegMap:
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
        

class BdcIp:
    """
        A class to keep track of an IP core in a BDC
    """
    def __init__(self, name) -> None:
        self.name = name 
        self.interfaces = []

    def add_interface(self, interface) -> None:
        self.interfaces.append(interface)

    def print(self, tabdepth=0) -> None:
        print_n_tabs(tabdepth)
        print(self.name +":")
        for i in self.interfaces:
            i.print(tabdepth+1)


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

