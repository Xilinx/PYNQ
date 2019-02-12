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
import tempfile
import shutil
from subprocess import run, PIPE, Popen
from pynq import PL
from . import PynqMicroblaze
from . import BSPs
from . import Modules
from .streams import InterruptMBStream


__author__ = "Peter Ogden"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "ogden@xilinx.com"


def dependencies(source, bsp):
    args = ['mb-cpp', '-MM', '-D__attribute__(x)=',
            '-D__extension__=', '-D__asm__(x)=']
    for include_path in bsp.include_path:
        args.append('-I')
        args.append(include_path)
    paths = {}
    for name, module in Modules.items():
        for include_path in module.include_path:
            args.append('-I')
            args.append(include_path)
            paths[include_path] = name
    source = source.replace('__extension__', '')
    result = run(args, stdout=PIPE, stderr=PIPE, input=source.encode())
    if result.returncode:
        raise RuntimeError("Preprocessor failed: \n" + result.stderr.decode())
    dependent_paths = result.stdout.decode()
    dependent_modules = {v for k, v in paths.items()
                         if dependent_paths.find(k) != -1}
    return [Modules[k] for k in dependent_modules]


def _find_bsp(cell_name):
    target_bsp = "bsp_" + cell_name.replace('/', '_')
    matches = [bsp for bsp in BSPs.keys()
               if target_bsp.startswith(bsp)]
    if matches:
        return BSPs[max(matches, key=len)]
    raise RuntimeError("BSP not found for " + cell_name)


def preprocess(source, bsp=None, mb_info=None):
    if bsp is None:
        if hasattr(mb_info, 'mb_info'):
            mb_info = mb_info.mb_info
        if mb_info is None:
            raise RuntimeError("Must provide either a BSP or mb_info")
        bsp = _find_bsp(mb_info['name'])

    args = ['mb-cpp', '-D__attribute__(x)=',
            '-D__extension__=', '-D__asm__(x)=']
    for include_path in bsp.include_path:
        args.append('-I')
        args.append(include_path)
    for name, module in Modules.items():
        for include_path in module.include_path:
            args.append('-I')
            args.append(include_path)

    source = "typedef int __builtin_va_list;\n" + source
    result = run(args, stdout=PIPE, stderr=PIPE, input=source.encode())
    return result.stdout.decode()


class MicroblazeProgram(PynqMicroblaze):
    def __init__(self, mb_info, program_text, bsp=None):
        if hasattr(mb_info, 'mb_info'):
            mb_info = mb_info.mb_info
        if bsp is None:
            bsp = _find_bsp(mb_info['name'])

        ip_dict = PL.ip_dict
        ip_name = mb_info['ip_name']
        if ip_name not in ip_dict.keys():
            raise ValueError("No such IP {}.".format(ip_name))
        ip_state = ip_dict[ip_name]['state']
        force = False
        if ip_state and ip_state.startswith('/tmp/'):
            force = True

        modules = dependencies(program_text, bsp)
        lib_args = []
        with tempfile.TemporaryDirectory() as tempdir:
            files = [path.join(tempdir, 'main.c')]
            args = ['mb-g++', '-o', path.join(tempdir, 'a.out'),
                    '-Wno-multichar',
                    '-fno-exceptions',
                    '-ffunction-sections',
                    '-Wl,-gc-sections']
            args.extend(bsp.cflags)
            args.extend(bsp.sources)
            for include_path in bsp.include_path:
                args.append('-I{}'.format(include_path))
            for lib_path in bsp.library_path:
                lib_args.append('-L{}'.format(lib_path))
            for lib in bsp.libraries:
                lib_args.append('-l{}'.format(lib))
            args.append('-Wl,{}'.format(bsp.linker_script))
            args.extend(bsp.ldflags)

            for module in modules:
                files.extend(module.sources)
                for include_path in module.include_path:
                    args.append('-I{}'.format(include_path))
                for lib_path in module.library_path:
                    lib_args.append('-L{}'.format(lib_path))
                for lib in module.libraries:
                    lib_args.append('-l{}'.format(lib))

            with open(path.join(tempdir, 'main.c'), 'w') as f:
                f.write('#line 1 "cell_magic"\n')
                f.write(program_text)
            shutil.copy(path.join(tempdir, 'main.c'), '/tmp/last.c')
            result = run(args + files + lib_args, stdout=PIPE, stderr=PIPE)
            if result.returncode:
                raise RuntimeError(result.stderr.decode())
            _ = run(['size', path.join(tempdir, 'a.out')],
                    stdout=PIPE, stderr=PIPE)

            result = Popen(['nm', '-CSr', '--size-sort',
                            path.join(tempdir, 'a.out')],
                           stdout=PIPE, stderr=PIPE)
            _ = Popen(['head', '-10'],
                      stdin=result.stdout, stdout=PIPE, stderr=None)

            shutil.copy(path.join(tempdir, 'a.out'), '/tmp/last.elf')
            result = run(['mb-objcopy', '-O', 'binary',
                          path.join(tempdir, 'a.out'),
                          path.join(tempdir, 'a.bin')],
                         stderr=PIPE)
            if result.returncode:
                raise RuntimeError(
                    "Objcopy Failed: {}".format(result.stderr.decode()))

            super().__init__(mb_info, path.join(tempdir, 'a.bin'), force)
            self.stream = InterruptMBStream(self)
            self.read = self.stream.read
            self.write = self.stream.write
            self.read_async = self.stream.read_async
