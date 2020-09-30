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
from subprocess import run, PIPE, Popen, check_output


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


class Pybind11Compile:
    """Class to compile the C++ file into a shared object.

    This class will simply compile the program into a shared object based
    on Pybind11 binding. The file name and module name has to be consistent;
    i.e., file name should be `<module_name>.cpp`.

    """
    def __init__(self, module_name, flags, file_name):
        """Instantiate Pybind11Program instance.

        The program will be compiled during instantiation.
        The shared object after compilation will be copied to
        `lib<module_name>.so` so it can be linked by other C++ program.

        Parameters
        ----------
        module_name : str
            The name of the python module.
        flags : dict
            Optional compilation flags
        file_name : str
            Name of the program to compile.

        """
        try:
            import pybind11
        except ImportError:
            raise ImportError("Requires pybind11 to be installed.")

        self.module_name = module_name
        self.cflags = flags['cflags']
        self.ldflags = flags['ldflags']
        self.file_name = file_name

        result = self.compile_cpp()
        if result.returncode:
            raise RuntimeError(
                "Calling g++ Failed: {}".format(result.stderr.decode()))

    def compile_cpp(self):
        """Compile the C++ file for Pybind11 usage.

        The flags are added based on example from
        https://pybind11.readthedocs.io/en/stable/basics.html

        """
        if not os.path.isfile(self.file_name):
            raise RuntimeError("Must provide a source file (*.cpp extension).")

        include = check_output(
            'python3 -m pybind11 --includes'.split(' '),
            universal_newlines=True).rstrip('\n')
        include += ' -I/usr/include -I/usr/local/include'
        include += ' -I{}'.format(os.getcwd())
        link = check_output(
            'python3-config --ldflags'.split(' '),
            universal_newlines=True).rstrip('\n')
        link = ' '.join(link.split()) + ' -L/usr/lib -L/usr/local/lib'
        link += ' -L{}'.format(os.getcwd())
        extension = check_output(
            'python3-config --extension-suffix'.split(' '),
            universal_newlines=True).rstrip('\n')
        if not self.cflags:
            cflags = '-O3 -Wall -shared -std=c++11 -fPIC'
        else:
            cflags = self.cflags
        if not self.ldflags:
            ldflags = link
        else:
            ldflags = link + ' ' + self.ldflags

        cmd = 'c++ {0} {1} {2}.cpp -o {2}{3} {4}'.format(
                  cflags, include, self.module_name, extension, ldflags)
        return run(cmd.split(' '), stdout=PIPE, stderr=PIPE)
