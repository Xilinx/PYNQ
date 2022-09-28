#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import os
from subprocess import run, PIPE, Popen, check_output




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


