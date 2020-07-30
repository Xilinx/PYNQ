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


from os import path
import shutil
from sysconfig import get_paths
from subprocess import run, PIPE, Popen, check_output


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


def get_python_include_path():
    return get_paths()['include']


def get_module_name(full_name):
    return full_name.split('.')[0]


def process_swig(i_file):
    if i_file is None:
        raise RuntimeError("Must provide an interface file (*.i extension).")

    args = ['swig', '-python', i_file]
    return run(args, stdout=PIPE, stderr=PIPE)


def process_gcc(c_file):
    if c_file is None:
        raise RuntimeError("Must provide a source file (*.c extension).")

    module_name = get_module_name(c_file)
    args = ['gcc', '-c',
            c_file, '{}_wrap.c'.format(module_name),
            '-fPIC', '-I{}'.format(get_python_include_path())]

    return run(args, stdout=PIPE, stderr=PIPE)


def process_ld(o_file):
    if o_file is None:
        raise RuntimeError("Must provide an object file (*.o extension).")

    module_name = get_module_name(o_file)
    args = ['ld', '-shared',
            o_file, '{}_wrap.o'.format(module_name),
            '-o', '_{}.so'.format(module_name)]

    return run(args, stdout=PIPE, stderr=PIPE)


class SwigProgram:
    def __init__(self, module_name, program_text):
        c_file = '{}.c'.format(module_name)
        with open(c_file, 'w') as f:
            f.write('#line 1 "cell_magic"\n\n')
            f.write('#include "{}.h"\n'.format(module_name))
            f.write(program_text)

        result = process_swig('{}.i'.format(module_name))
        if result.returncode:
            raise RuntimeError(
                "Calling swig Failed: {}".format(result.stderr.decode()))

        result = process_gcc('{}.c'.format(module_name))
        if result.returncode:
            raise RuntimeError(
                "Calling gcc Failed: {}".format(result.stderr.decode()))

        result = process_ld('{}.o'.format(module_name))
        if result.returncode:
            raise RuntimeError(
                "Calling ld Failed: {}".format(result.stderr.decode()))
