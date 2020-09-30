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


import os
from .compile import Pybind11Compile


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


class CppProgram:
    """Primary processor that construct the C++ program.

    This class leverages the CppHeader parser so we get a list of functions
    and classes to be considered. Multiple sections will be added to the
    Pybind11 binding during this process.

    The `process()` method is called upon the instantiation of the class.

    After the processing is complete, a `<module_name>.cpp` should be
    available to users, integrated with required Pybind11 bindings.

    If the original program does not include a header file that has the same
    name as the module (e.g. `<module_name>.hpp`), a header will be generated.
    This helps users compile other C++ modules with this header file.

    """
    def __init__(self, module_name, original_text):
        try:
            from CppHeaderParser import CppHeader
        except ImportError:
            raise ImportError("Requires CppHeaderParser to be installed.")

        self.module_name = module_name
        self.original_text = original_text
        self.use_generated_header = True
        with open('temp.c', 'w') as f:
            f.write(original_text)
        self.cpp_header = CppHeader('temp.c')
        self.cpp_file = "{}.cpp".format(module_name)
        if os.path.isfile(self.cpp_file):
            os.remove(self.cpp_file)
        self.hpp_file = "{}.hpp".format(module_name)
        if os.path.isfile(self.hpp_file):
            os.remove(self.hpp_file)
        self.generate_cpp()
        self.generate_hpp()

    def add_header(self):
        with open(self.cpp_file, 'a') as f:
            f.write('#include <pybind11/pybind11.h>\n')
            f.write('namespace py = pybind11;\n')

    def add_cpp_program(self):
        with open(self.cpp_file, 'a') as f:
            f.write(self.original_text + '\n')

    def add_dummy_main(self):
        with open(self.cpp_file, 'a') as f:
            f.write('int main(){return 0;}\n')

    def add_pybind11_head(self):
        with open(self.cpp_file, 'a') as f:
            f.write('PYBIND11_MODULE({0}, m) {{\n'.format(self.module_name))

    def add_doc(self):
        with open(self.cpp_file, 'a') as f:
            f.write('m.doc() = "Pybind11 module {}";\n'.format(
                self.module_name))

    def add_def(self):
        with open(self.cpp_file, 'a') as f:
            for i in self.cpp_header.functions:
                f.write('m.def("{0}", &{0},\n'.format(i['name']))
                for arg in i['parameters']:
                    f.write('py::arg("{0}"),\n'.format(arg['name']))
                f.write('"A function with name {}");\n'.format(i['name']))

    def add_attr(self):
        with open(self.cpp_file, 'a') as f:
            for v in self.cpp_header.variables:
                f.write('m.attr("{0}") = py::cast({0});\n'.format(v['name']))

    def add_class(self):
        with open(self.cpp_file, 'a') as f:
            for i in self.cpp_header.classes:
                parent_class_list = [i]
                if self.cpp_header.classes[i]['inherits']:
                    for j in self.cpp_header.classes[i]['inherits']:
                        parent_class_list.append(j['class'])
                f.write('py::class_<{0}>(m, "{1}")\n'.format(
                    ','.join(parent_class_list), i))

                for j in self.cpp_header.classes[i]['methods']['public']:
                    if j['constructor']:
                        init_arg_list = [k['type'] for k in j['parameters']]
                        init_args = ','.join(init_arg_list)
                        f.write('.def(py::init<{0}>())\n'.format(init_args))
                    else:
                        f.write('.def("{0}", &{1}::{0})\n'.format(j['name'], i))
                f.write(';\n')

    def add_pybind11_tail(self):
        with open(self.cpp_file, 'a') as f:
            f.write('}\n')

    def generate_cpp(self):
        """Process the entire program context to add Pybind11 bindings.

        The `add_header()` call will add 2 lines to enable the Pybind11.
        All the methods between `add_pybind11_head()` and `add_pybind11_tail()`
        are just break-down of the binding code.

        To debug, users can just check the generated `<module_name>.cpp`.

        """
        self.add_header()
        self.add_cpp_program()
        self.add_dummy_main()
        self.add_pybind11_head()
        self.add_doc()
        self.add_def()
        self.add_attr()
        self.add_class()
        self.add_pybind11_tail()

    def generate_hpp(self):
        """This method will generate the C++ header.

        This is often needed when the shared object is referenced by another
        shared object.

        If users have prepared a `<module_name>.hpp` file already and included
        that in the C++ program, the generation process will be skipped. In
        other words, we only generate header file when the file does not
        already exist.

        """
        if '"{}"'.format(self.module_name) not in self.cpp_header.includes:
            self.use_generated_header = True
        else:
            self.use_generated_header = False

        if self.use_generated_header:
            with open(self.hpp_file, 'w') as f:
                f.write('#ifndef {}_H\n'.format(self.module_name.upper()))
                f.write('#define {}_H\n'.format(self.module_name.upper()))
                for i in self.cpp_header.includes:
                    f.write('#include {}\n'.format(i))
                for i in self.cpp_header.defines:
                    f.write('#define {}\n'.format(i))
                for i in self.cpp_header.functions:
                    f.write(i['debug'].rstrip('{') + ';\n')
                f.write('#endif\n')


class Pybind11Processor:
    """ Provides a python interface to the Pybind11 program.

    Based on the program user provides, this class will add necessary
    Pybind11 bindings to it so a modified cpp file is generated. This file
    will be passed to the C++ compiler.

    """
    def __init__(self, module_name, flags, program_text):
        """ Create a new Pybind11Processor instance

        Parameters
        ----------
        module_name : str
            The name of the python module.
        flags : dict
            Optional compilation flags in a dictionary
        program_text : str
            Source of the program to examine.

        """
        try:
            _ = CppProgram(module_name, program_text)
        except Exception as e:
            raise RuntimeError("Error parsing code.\n" + str(e))

        _ = Pybind11Compile(module_name, flags, "{}.cpp".format(module_name))
        os.remove("temp.c")
        os.remove("{}.cpp".format(module_name))
        os.remove("{}.hpp".format(module_name))
