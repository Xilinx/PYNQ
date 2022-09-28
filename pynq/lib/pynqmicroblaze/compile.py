#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import shutil
import tempfile
from os import path
from subprocess import PIPE, Popen, run

from pynq import PL
from . import BSPs, Modules, PynqMicroblaze
from .streams import InterruptMBStream



def dependencies(source, bsp):
    args = ["mb-cpp", "-MM", "-D__attribute__(x)=", "-D__extension__=", "-D__asm__(x)="]
    for include_path in bsp.include_path:
        args.append("-I")
        args.append(include_path)
    paths = {}
    for name, module in Modules.items():
        for include_path in module.include_path:
            args.append("-I")
            args.append(include_path)
            paths[include_path] = name
    source = source.replace("__extension__", "")
    result = run(args, stdout=PIPE, stderr=PIPE, input=source.encode())
    if result.returncode:
        raise RuntimeError("Preprocessor failed: \n" + result.stderr.decode())
    dependent_paths = result.stdout.decode()
    dependent_modules = {v for k, v in paths.items() if dependent_paths.find(k) != -1}
    return [Modules[k] for k in dependent_modules]


def recursive_dependencies(source, bsp, current_set=None):
    if current_set is None:
        current_set = set()
    modules = dependencies(source, bsp)
    for m in modules:
        if m not in current_set:
            current_set.add(m)
            for s in m.sources:
                with open(s, "r") as f:
                    recursive_dependencies(f.read(), bsp, current_set)
    return list(current_set)


def _find_bsp(cell_name):
    target_bsp = "bsp_" + cell_name.replace("/", "_")
    matches = [bsp for bsp in BSPs.keys() if target_bsp.startswith(bsp)]
    if matches:
        return BSPs[max(matches, key=len)]
    raise RuntimeError("BSP not found for " + cell_name)


def preprocess(source, bsp=None, mb_info=None):
    if bsp is None:
        if hasattr(mb_info, "mb_info"):
            mb_info = mb_info.mb_info
        if mb_info is None:
            raise RuntimeError("Must provide either a BSP or mb_info")
        bsp = _find_bsp(mb_info["name"])

    args = ["mb-cpp", "-D__attribute__(x)=", "-D__extension__=", "-D__asm__(x)="]
    for include_path in bsp.include_path:
        args.append("-I")
        args.append(include_path)
    for name, module in Modules.items():
        for include_path in module.include_path:
            args.append("-I")
            args.append(include_path)

    source = "typedef int __builtin_va_list;\n" + source
    result = run(args, stdout=PIPE, stderr=PIPE, input=source.encode())
    if result.returncode:
        raise RuntimeError("Preprocessor failed: \n" + result.stderr.decode())
    return result.stdout.decode()


def checkmodule(name, mb_info):
    try:
        preprocess(f"#include <{name}.h>", mb_info=mb_info)
    except RuntimeError as exc:
        return False
    return True


class MicroblazeProgram(PynqMicroblaze):
    def __init__(self, mb_info, program_text, bsp=None):
        if hasattr(mb_info, "mb_info"):
            mb_info = mb_info.mb_info
        if bsp is None:
            bsp = _find_bsp(mb_info["name"])

        mem_dict = PL.mem_dict
        ip_name = mb_info["ip_name"]
        if ip_name not in mem_dict.keys():
            raise ValueError("No such IP {}.".format(ip_name))
        ip_state = mem_dict[ip_name]["state"]
        force = False
        if ip_state and ip_state.startswith("/tmp/"):
            force = True

        modules = recursive_dependencies(program_text, bsp)
        lib_args = []
        with tempfile.TemporaryDirectory() as tempdir:
            files = [path.join(tempdir, "main.c")]
            args = [
                "mb-g++",
                "-o",
                path.join(tempdir, "a.out"),
                "-Wno-multichar",
                "-fno-exceptions",
                "-ffunction-sections",
                "-Wl,-gc-sections",
            ]
            args.extend(bsp.cflags)
            args.extend(bsp.sources)
            for include_path in bsp.include_path:
                args.append("-I{}".format(include_path))
            for lib_path in bsp.library_path:
                lib_args.append("-L{}".format(lib_path))
            for lib in bsp.libraries:
                lib_args.append("-l{}".format(lib))
            args.append("-Wl,{}".format(bsp.linker_script))
            args.extend(bsp.ldflags)

            for module in modules:
                files.extend(module.sources)
                for include_path in module.include_path:
                    args.append("-I{}".format(include_path))
                for lib_path in module.library_path:
                    lib_args.append("-L{}".format(lib_path))
                for lib in module.libraries:
                    lib_args.append("-l{}".format(lib))

            with open(path.join(tempdir, "main.c"), "w") as f:
                f.write('#line 1 "cell_magic"\n')
                f.write(program_text)
            shutil.copy(path.join(tempdir, "main.c"), "/tmp/last.c")
            result = run(args + files + lib_args, stdout=PIPE, stderr=PIPE)
            if result.returncode:
                raise RuntimeError(result.stderr.decode())
            _ = run(["size", path.join(tempdir, "a.out")], stdout=PIPE, stderr=PIPE)

            result = Popen(
                ["nm", "-CSr", "--size-sort", path.join(tempdir, "a.out")],
                stdout=PIPE,
                stderr=PIPE,
            )
            _ = Popen(["head", "-10"], stdin=result.stdout, stdout=PIPE, stderr=None)

            shutil.copy(path.join(tempdir, "a.out"), "/tmp/last.elf")
            result = run(
                [
                    "mb-objcopy",
                    "-O",
                    "binary",
                    path.join(tempdir, "a.out"),
                    path.join(tempdir, "a.bin"),
                ],
                stderr=PIPE,
            )
            if result.returncode:
                raise RuntimeError("Objcopy Failed: {}".format(result.stderr.decode()))

            super().__init__(mb_info, path.join(tempdir, "a.bin"), force)
            self.stream = InterruptMBStream(self)
            self.read = self.stream.read
            self.write = self.stream.write
            self.read_async = self.stream.read_async


