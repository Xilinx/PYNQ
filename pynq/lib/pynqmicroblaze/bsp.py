#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from os import path, listdir
import re
import warnings


class Module:
    def __init__(self, root):
        self.include_path = [
            path.join(root, 'include')
        ]
        self.library_path = []
        self.libraries = []
        library_path = path.join(root, 'lib')
        if path.isdir(library_path):
            self.library_path.append(library_path)
            for f in listdir(self.library_path[0]):
                match = re.match(r'lib(.*)\.(?:a|so)', f)
                if match:
                    self.libraries.append(match.group(1))

        self.sources = []
        if path.isdir(path.join(root, 'src')):
            for f in listdir(path.join(root, 'src')):
                match = re.match(r'.*\.(c|cpp)$', f)
                if match:
                    self.sources.append(path.join(root, 'src', f))
        self.header = ""
        for f in listdir(path.join(root, 'include')):
            if re.match(r".*\.h$", f):
                with open(path.join(root, 'include', f), 'r') as data:
                    self.header += data.read()


class BSPInstance:
    def __init__(self, root):
        contents = listdir(root)
        if 'lscript.ld' not in contents:
            raise RuntimeError("No linker script found in " + root)
        subdirs = [x for x in contents if path.isdir(path.join(root, x))]
        if len(subdirs) == 0:
            raise RuntimeError("No subdirectory found in " + root)
        if len(subdirs) > 1:
            raise RuntimeError("Multiple subdirectories found in " + root)

        bsp_root = path.join(root, subdirs[0])

        self.include_path = [
            path.join(bsp_root, 'include')
        ]
        self.library_path = [
            path.join(bsp_root, 'lib')
        ]
        self.libraries = ['xil']

        self.linker_script = path.join(root, 'lscript.ld')
        self.mss = path.join(root, 'system.mss')

        self.cflags = ['-Os']
        extracflags = ['-mlittle-endian', '-mcpu=v11.0', '-mxl-soft-mul']

        try:
            found = False
            with open(self.mss) as fp:
                for line in fp:
                    words = line.strip().split()
                    if(len(words) > 2 and
                       words[0] == 'PARAMETER' and
                       words[1] == 'compiler_flags'):
                        extracflags = words[3:]
                        found = True
                        break
            if not found:
                message = "compiler_flags not found in {}: " \
                          "using default cflags".format(self.mss)
                warnings.warn(message, UserWarning)
        except FileNotFoundError:
            message = "{} not found: using default cflags".format(self.mss)
            warnings.warn(message, UserWarning)

        self.cflags.extend(extracflags)

        self.ldflags = {
            '-Wl,--no-relax'
        }
        self.sources = []
        if path.isdir(path.join(bsp_root, 'src')):
            for f in listdir(path.join(bsp_root, 'src')):
                match = re.match(r'.*\.(c|cpp)$', f)
                if match:
                    self.sources.append(path.join(bsp_root, 'src', f))


SCRIPT_DIR = path.dirname(path.realpath(__file__))
MODULE_DIR = path.join(SCRIPT_DIR, 'modules')

BSPs = {}
Modules = {}


def add_bsp(directory):
    BSPs[path.basename(directory)] = BSPInstance(directory)


def add_module_path(directory):
    for filename in listdir(directory):
        f = path.join(directory, filename)
        if path.isdir(f):
            Modules[filename] = Module(f)


add_module_path(MODULE_DIR)


