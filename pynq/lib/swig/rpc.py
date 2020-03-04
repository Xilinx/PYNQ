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


import pycparser
import struct
import re
from subprocess import check_output
from pycparser import c_ast
from pycparser.plyparser import ParseError
from .compile import SwigProgram


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


class _Parser(pycparser.CParser):
    def p_pp_directive(self, p):
        """Overwrites the original method.

        Ignore error `Directives not supported yet`.

        """
        pass


_parser = _Parser()


class FuncDefVisitor(pycparser.c_ast.NodeVisitor):
    """Primary visitor that parses out components from a syntax tree

    The function signatures will be parsed and ported later to the header file.
    Note the functions that return pointers are not supported yet; such
    functions will be ignored during parsing.

    Also, the final header file should only consist of the function signatures
    declared by users; so functions declared in system headers should be
    ignored.

    """
    def __init__(self):
        self.user_functions = []

    def visit_FuncDecl(self, node):
        if node.coord.file != "_tmp.c":
            return
        if type(node.type) is not c_ast.TypeDecl:
            return
        ret_type = ' '.join(node.type.type.names)
        fun_id = node.type.declname
        args = list()
        if hasattr(node.args, 'params'):
            for i in node.args.params:
                if type(i.type) is c_ast.TypeDecl:
                    arg = i.type.declname
                    args.append(' '.join(i.type.type.names) + ' ' + arg)
                elif type(i.type) is c_ast.ArrayDecl:
                    arg = i.type.type.declname
                    dtype = ' '.join(i.type.type.type.names)
                    dim = i.type.dim if i.type.dim else ''
                    args.append('{}[{}] {}'.format(dtype, dim, arg))
                elif type(i.type) is c_ast.PtrDecl:
                    arg = i.type.type.declname
                    dtype = ' '.join(i.type.type.type.names)
                    args.append('{} *{}'.format(dtype, arg))
        signature = '{} {}({});'.format(ret_type, fun_id, ', '.join(args))
        self.user_functions.append(signature)


def parse_header(program_text):
    """Parse the header out from the program.

    Separate headers from the program.

    Parameters
    ----------
    program_text: str
        The program text.

    Returns
    -------
    tuple
        The header list, and the text after removing the headers.

    """
    header_list = list()
    text_no_header = ''
    for line in iter(program_text.splitlines()):
        if line.startswith('#include'):
            header_list.append(line)
        else:
            text_no_header += (line+'\n')
    return header_list, text_no_header


def preprocess(program_text):
    """Preprocess the file using cpp.

    Will preprocess the file and add `#define` to extension, attribute,
    and a few other primitives to avoid parsing errors.
    This is because pycparser only knows how to parse ISO C99,
    and doesn't support compiler-specific extensions.

    We will also invoke dummy typedefs to avoid parsing errors.

    Parameters
    ----------
    program_text: str
        The program text.

    Returns
    -------
    str
        The program text after pre-processing.

    """
    tmp_file = "_tmp.c"
    with open(tmp_file, 'w') as f:
        f.write(program_text)

    path_list = ['gcc']
    path_list += ['-E', '-I/usr/include', '-I/usr/local/include']
    path_list += [tmp_file]

    try:
        text = check_output(path_list, universal_newlines=True)
    except OSError as e:
        raise RuntimeError("Unable to invoke C pre-processing.\n" + str(e))

    processed_text = ''
    attr_regex = r'__attribute__(\s?)\(.*\)'
    tdef_regex1 = r'typedef\s(.*)\s([\S]+)(\s?);'
    tdef_regex2 = r'typedef\s(.*)\s([\S]+)(\s?)\('
    asm_regex = r'__asm__(\s?)\((.*)\)'
    for ii in text.splitlines():
        m1 = re.search(attr_regex, ii)
        if m1:
            ii = ii.replace(m1.group(0), '')
        if '(' in ii:
            m2 = re.search(tdef_regex2, ii)
        else:
            m2 = re.search(tdef_regex1, ii)
        if m2:
            ii = ii.replace(m2.group(1), 'int')
        m3 = re.search(asm_regex, ii)
        if m3:
            ii = ii.replace(m3.group(0), '')
        ii = ii.replace('__extension__', '')
        ii = ii.replace('*__restrict', '*')
        processed_text += (ii + '\n')

    return processed_text


def build_interface(module_name):
    """Build the interface file.

    The interface file has an extension of `i`.

    Parameters
    ----------
    module_name: str
        The name of the python module.

    """
    sections = list()
    sections.append('/* File : {}.i */'.format(module_name))
    sections.append('%module {}'.format(module_name))
    sections.append('%{')
    sections.append('#include "{}.h"'.format(module_name))
    sections.append('%}')
    sections.append('%include "{}.h"'.format(module_name))
    sections.append('%include "cpointer.i"')
    sections.append('%include "carrays.i"')
    for i in ['int', 'double']:
        sections.append('%pointer_functions({0}, {0}p);'.format(i))
        sections.append('%array_functions({0}, {0}Array);'.format(i))

    with open("{}.i".format(module_name), "w") as f:
        f.write("\n".join(sections))


def build_header(module_name, header_list, visitor):
    """Build the header file.

    The header file has an extension of `h`. The header contains all the
    includes, as well as the function signatures.

    Parameters
    ----------
    module_name: str
        The name of the python module.
    header_list: list
        A list of header includes from the program text.
    visitor: list
        The function visitor which contains the function signatures.

    """
    new_header = header_list + visitor.user_functions

    with open("{}.h".format(module_name), "w") as f:
        f.write("\n".join(new_header))


class SwigRPC:
    """ Provides a python interface to the SWIG program based on an RPC
    mechanism.

    The attributes of the class are generated dynamically from the
    typedefs, enumerations and functions given in the provided source.

    Functions are added as methods, the values in enumerations are
    added as constants to the class and types are added as classes.

    """
    def __init__(self, module_name, program_text):
        """ Create a new RPC instance

        Parameters
        ----------
        module_name : str
            The name of the python module.
        program_text : str
            Source of the program to extract functions from.

        """
        header_list, program_no_header = parse_header(program_text)
        processed_text = preprocess(program_text)
        try:
            ast = _parser.parse(processed_text, filename='processed_text')
        except ParseError as e:
            raise RuntimeError("Error parsing code.\n" + str(e))
        visitor = FuncDefVisitor()
        visitor.visit(ast)
        build_interface(module_name)
        build_header(module_name, header_list, visitor)

        self._prog = SwigProgram(module_name, program_no_header)
        self.visitor = visitor
