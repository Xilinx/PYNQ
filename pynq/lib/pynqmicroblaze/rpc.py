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

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "ogden@xilinx.com"

import pycparser
import struct
import functools
import itertools
from pycparser import c_ast
from pycparser import c_generator
from pycparser.plyparser import ParseError
from copy import deepcopy
from pynq.ps import ZU_ARCH, CPU_ARCH, ZYNQ_ARCH
from .compile import preprocess
from .streams import SimpleMBStream
from .streams import InterruptMBStream
from . import MicroblazeProgram

# Use a global parser and generator
_parser = pycparser.CParser()
_generator = c_generator.CGenerator()

if CPU_ARCH == ZYNQ_ARCH:
    PTR_OFFSET = "0x20000000"
elif CPU_ARCH == ZU_ARCH:
    PTR_OFFSET = "0x80000000"
else:
    PTR_OFFSET = "0x0"


# First we define a series of classes to represent types
# Each class is responsible for one particular type of C
# types
class PrimitiveWrapper:
    """ Wrapper for C primitives that can be represented by
    a single Struct string.

    """
    def __init__(self, struct_string, type_):
        self._struct = struct.Struct(struct_string)
        self.typedefname = None
        self.blocks = False
        self._type = type_

    def param_encode(self, old_val):
        return self._struct.pack(old_val)

    def param_decode(self, old_val, stream):
        pass

    def return_decode(self, stream):
        data = stream.read(self._struct.size)
        return self._struct.unpack(data)[0]

    def pre_argument(self, name):
        commands = []
        commands.append(_generate_decl(name, self._type))
        commands.append(_generate_read(name))
        return commands

    def post_argument(self, name):
        return []


class VoidPointerWrapper:
    """ Wrapper for a void* pointer that will refer to a
    physically contiguous chunk of memory.

    """
    def __init__(self, type_):
        self._type = type_
        self.typedefname = None
        self.blocks = False
        self._ptrstruct = struct.Struct('I')

    def param_encode(self, old_val):
        return self._ptrstruct.pack(old_val.physical_address)

    def param_decode(self, old_val, stream):
        pass

    def return_decode(self, stream):
        raise RuntimeError("Cannot return a void*")

    def pre_argument(self, name):
        commands = []
        commands.append(_generate_decl(
            name + '_int',
            c_ast.TypeDecl(name + '_int', [],
                           c_ast.IdentifierType(['unsigned', 'int']))))
        commands.append(_generate_read(name +'_int'))
        commands.append(c_ast.Assignment(
            '|=',
            c_ast.ID(name + '_int'),
            c_ast.Constant('int', PTR_OFFSET)))
        commands.append(
            c_ast.Decl(name, [], [], [],
                       c_ast.PtrDecl(
                            [], c_ast.TypeDecl(name, [],
                                               c_ast.IdentifierType(['void'])),
                       ),
                       c_ast.Cast(
                            c_ast.Typename(
                                 None, [], c_ast.PtrDecl(
                                     [], c_ast.TypeDecl(
                                          None, [],
                                          c_ast.IdentifierType(['void'])))),
                            c_ast.ID(name + '_int')),
                       []
                       ))
        return commands

    def post_argument(self, name):
        return []


class ConstPointerWrapper:
    """ Wrapper for const T pointers, transfers data in only
    one direction.

    """
    def __init__(self, type_, struct_string):
        self._lenstruct = struct.Struct('h')
        self._struct_string = struct_string
        self.typedefname = None
        self.blocks = False
        self._type = type_

    def param_encode(self, old_val):
        packed = struct.pack(self._struct_string * len(old_val), *old_val)
        return self._lenstruct.pack(len(old_val)) + packed

    def param_decode(self, old_val, stream):
        pass

    def return_decode(self, stream):
        raise RuntimeError("Cannot use a const T* decoder as a return value")

    def pre_argument(self, name):
        commands = []
        commands.append(
            _generate_decl(
                name + '_len',
                c_ast.TypeDecl(name + '_len', [],
                               c_ast.IdentifierType(['unsigned', 'short']))))
        commands.append(_generate_read(name + '_len'))
        commands.append(_generate_arraydecl(name,
                                            self._type,
                                            c_ast.ID(name + '_len')))
        commands.append(_generate_read(name, address=False))
        return commands

    def post_argument(self, name):
        return []


class PointerWrapper:
    """ Wrapper for non-const T pointers that retrieves any
    data modified by the called function.

    """
    def __init__(self, type_, struct_string):
        self._lenstruct = struct.Struct('h')
        self._struct_string = struct_string
        self.typedefname = None
        self.blocks = True
        self._type = type_

    def param_encode(self, old_val):
        packed = struct.pack(self._struct_string * len(old_val), *old_val)
        return self._lenstruct.pack(len(old_val)) + packed

    def param_decode(self, old_val, stream):
        data = stream.read(self._lenstruct.size)
        length = self._lenstruct.unpack(data)[0]
        assert(length == len(old_val))
        data = stream.read(length * struct.calcsize(self._struct_string))
        old_val[:] = struct.unpack(self._struct_string * len(old_val), data)

    def return_decode(self, stream):
        raise RuntimeError("Cannot use a T* decoder as a return value")

    def pre_argument(self, name):
        commands = []
        commands.append(
            _generate_decl(
                name + '_len',
                c_ast.TypeDecl(name + '_len', [],
                               c_ast.IdentifierType(['unsigned', 'short']))))
        commands.append(_generate_read(name + '_len'))
        commands.append(_generate_arraydecl(name,
                                            self._type,
                                            c_ast.ID(name + '_len')))
        commands.append(_generate_read(name, address=False))
        return commands

    def post_argument(self, name):
        commands = []
        commands.append(_generate_write(name + '_len'))
        commands.append(_generate_write(name, address=False))
        return commands


class VoidWrapper:
    """ Wraps void - only valid for return types

    """
    def __init__(self):
        self.typedefname = None
        self.blocks = False

    def param_encode(self, old_val):
        return b''

    def param_decode(self, old_val, stream):
        pass

    def return_decode(self, stream):
        return None

    def pre_argument(self, name):
        return []

    def post_argument(self, name):
        return []


def _type_to_struct_string(tdecl):
    if type(tdecl) is not c_ast.TypeDecl:
        raise RuntimeError("Unsupport Type")

    names = tdecl.type.names
    signed = True
    if len(names) > 1:
        if names[0] == 'unsigned':
            signed = False
        name = names[1]
    else:
        name = names[0]
    if name == 'void':
        return ''
    if name in ['long', 'int']:
        if names.count('long') == 2:
            if signed:
                return 'q'
            else:
                return 'Q'
        else:
            if signed:
                return 'i'
            else:
                return 'I'
    if name == 'short':
        if signed:
            return 'h'
        else:
            return 'H'
    if name == 'char':
        if signed:
            return 'b'
        else:
            return 'B'
    if name == 'float':
        return 'f'
    raise RuntimeError('Unknown type {}'.format(name))


def _type_to_interface(tdecl, typedefs):
    """ Returns a wrapper for a given C AST

    """

    if type(tdecl) is c_ast.PtrDecl:
        nested_type = tdecl.type
        if type(nested_type) is not c_ast.TypeDecl:
            raise RuntimeError("Only single level pointers supported")
        struct_string = _type_to_struct_string(nested_type)
        if struct_string:
            if 'const' in nested_type.quals:
                return ConstPointerWrapper(tdecl, struct_string)
            else:
                return PointerWrapper(tdecl, struct_string)
        else:
            return VoidPointerWrapper(tdecl)

    elif type(tdecl) is not c_ast.TypeDecl:
        raise RuntimeError("Unsupport Type")

    names = tdecl.type.names
    if len(names) == 1 and names[0] in typedefs:
        interface = _type_to_interface(typedefs[names[0]], typedefs)
        interface.typedefname = names[0]
        return interface

    struct_string = _type_to_struct_string(tdecl)
    if struct_string:
        return PrimitiveWrapper(struct_string, tdecl)
    else:
        return VoidWrapper()


def _generate_read(name, size=None, address=True):
    """ Helper function to generate read functions. size
    should be an AST fragment

    """
    if size is None:
        size = c_ast.UnaryOp('sizeof', c_ast.ID(name))
    if address:
        target = c_ast.UnaryOp('&', c_ast.ID(name))
    else:
        target = c_ast.ID(name)

    return c_ast.FuncCall(
        c_ast.ID('_rpc_read'),
        c_ast.ExprList([target,
                        size]))


def _generate_write(name, address=True):
    """ Helper function generate write functions

    """
    if address:
        target = c_ast.UnaryOp('&', c_ast.ID(name))
    else:
        target = c_ast.ID(name)
    return c_ast.FuncCall(
        c_ast.ID('_rpc_write'),
        c_ast.ExprList([target,
                        c_ast.UnaryOp('sizeof', c_ast.ID(name))]))


def _generate_decl(name, decl):
    """ Generates a new declaration with a difference name
    but same type as the provided decl.

    """
    typedecl = c_ast.TypeDecl(name, [], decl.type)
    return c_ast.Decl(name, [], [], [], typedecl, [], [])


def _generate_arraydecl(name, decl, length):
    """ Generates a new declaration with an array type
    base on an existing declaration

    """
    typedecl = c_ast.TypeDecl(name, [], decl.type)
    arraydecl = c_ast.ArrayDecl(typedecl, length, [])
    return c_ast.Decl(name, [], [], [], arraydecl, [], [])


class FuncAdapter:
    """Provides the C and Python interfaces for a function declaration

    Attributes
    ----------
    return_interface : TypeWrapper
        The type wrapper for the return type
    arg_interfaces   : [TypeWrapper]
        An array of type wrappers for the arguments
    call_ast         : pycparser.c_ast
        Syntax tree for the wrapped function call

    """
    def __init__(self, decl, typedefs):
        self.return_interface = _type_to_interface(decl.type, typedefs)
        self.name = decl.type.declname
        self.docstring = ""
        self.arg_interfaces = []
        self.blocks = False
        block_contents = []
        post_block_contents = []
        func_args = []

        if decl.args:
            for i, arg in enumerate(decl.args.params):
                if type(arg) is c_ast.EllipsisParam:
                    raise RuntimeError("vararg functions not supported")
                interface = _type_to_interface(arg.type, typedefs)
                if type(interface) is VoidWrapper:
                    continue
                block_contents.extend(interface.pre_argument('arg' + str(i)))
                post_block_contents.extend(interface.post_argument(
                    'arg' + str(i)))
                func_args.append(c_ast.ID('arg' + str(i)))
                self.arg_interfaces.append(interface)
                self.blocks = self.blocks | interface.blocks

        function_call = c_ast.FuncCall(c_ast.ID(self.name),
                                       c_ast.ExprList(func_args))

        self.returns = type(self.return_interface) is not VoidWrapper
        if self.returns:
            ret_assign = c_ast.Decl(
                'ret', [], [], [],
                c_ast.TypeDecl('ret', [], decl.type.type),
                function_call, []
            )
            block_contents.append(ret_assign)
            block_contents.append(_generate_write('return_command'))
            block_contents.append(_generate_write('ret'))
            self.blocks = True
        else:
            block_contents.append(function_call)
            if self.blocks:
                block_contents.append(_generate_write('return_command'))
            else:
                block_contents.append(_generate_write('void_command'))

        block_contents.extend(post_block_contents)
        self.call_ast = c_ast.Compound(block_contents)
        self.filename = decl.coord.file

    def pack_args(self, *args):
        """Create a bytes of the provided arguments

        """
        if len(args) != len(self.arg_interfaces):
            raise RuntimeError(
                "Wrong number of arguments: expected{0} got {1}".format(
                    len(self.arg_interfaces), len(args)
                ))
        return b''.join(
            [f.param_encode(a) for f, a in itertools.zip_longest(
                self.arg_interfaces, args
            )]
        )

    def receive_response(self, stream, *args):
        """Reads the response stream, updates arguments and
        returns the value of the function call if applicable

        """
        return_value = self.return_interface.return_decode(stream)
        if len(args) != len(self.arg_interfaces):
            raise RuntimeError(
                "Wrong number of arguments: expected{0} got {1}".format(
                    len(self.arg_interfaces), len(args)
                ))
        [f.param_decode(a, stream) for f, a in itertools.zip_longest(
             self.arg_interfaces, args
        )]
        return return_value


class ParsedEnum:
    """Holds the values of an enum from the C source

    """
    def __init__(self):
        self.name = None
        self.items = {}


class FuncDefVisitor(pycparser.c_ast.NodeVisitor):
    """Primary visitor that parses out function definitions,
    typedes and enumerations from a syntax tree

    """
    def __init__(self):
        self.functions = {}
        self.typedefs = {}
        self.enums = []
        self.defined = []

    def visit_Typedef(self, node):
        self.typedefs[node.name] = node.type

    def visit_FuncDef(self, node):
        self.defined.append(node.decl.name)
        self.visit(node.decl)

    def visit_FuncDecl(self, node):
        if node.coord.file.startswith('/opt/microblaze'):
            return
        if type(node.type) is not c_ast.TypeDecl:
            # Ignore functions that are returning pointers
            return
        name = node.type.declname
        if 'static' in node.type.quals:
            # Don't process static functions
            return
        try:
            self.functions[name] = FuncAdapter(node, self.typedefs)
        except RuntimeError as e:
            if node.coord.file == '<stdin>':
                print("Could not create interface for funcion {}: {}".format(
                    name, e))

    def visit_Enum(self, node):
        enum = ParsedEnum()
        if node.name:
            enum.name = node.name
        cur_index = 0
        for entry in node.values.enumerators:
            if entry.value:
                cur_index = int(entry.value.value, 0)
            enum.items[entry.name] = cur_index
            cur_index += 1
        self.enums.append(enum)


def _build_case(functions):
    """ Builds the switch statement that will form the foundation
    of the RPC handler

    """
    cases = []
    for i, func in enumerate(functions.values()):
        case = c_ast.Case(
            c_ast.Constant('int', str(i)),
            [
                func.call_ast,
                c_ast.Break()
            ])
        cases.append(case)
    return c_ast.Switch(
        c_ast.ID('command'),
        c_ast.Compound(cases)
    )


def _build_handle_function(functions):
    """ Wraps the switch statement in a function definition

    """
    case_statement = _build_case(functions)
    available_check = c_ast.If(
        c_ast.BinaryOp(
            '<', c_ast.FuncCall(
                c_ast.ID('mailbox_available'),
                c_ast.ExprList([c_ast.Constant('int', '2')])
            ),
            c_ast.Constant('int', '4')
        ),
        c_ast.Return(None),
        None
    )
    handle_decl = c_ast.FuncDecl(
        None, c_ast.TypeDecl('_handle_events', [],
                             c_ast.IdentifierType(['void'])),
    )
    command_decl = c_ast.Decl('command', [], [], [],
                              c_ast.TypeDecl('command', [],
                                             c_ast.IdentifierType(['int'])),
                              [], [])
    command_read = _generate_read('command')
    body = c_ast.Compound([available_check,
                           command_decl,
                           command_read,
                           case_statement])
    return c_ast.FuncDef(handle_decl, [], body)


def _build_main(program_text, functions):
    sections = []
    sections.append(R"""
    extern "C" {
    #include <unistd.h>
    #include <mailbox_io.h>
    }
    static const char return_command = 0;
    static const char void_command = 1;

    static void _rpc_read(void* data, int size) {
        int available = mailbox_available(2);
        while (available < size) {
            available = mailbox_available(2);
        }
        mailbox_read(2, data, size);
    }

    static void _rpc_write(const void* data, int size) {
        int available = mailbox_available(3);
        while (available < size) {
            available = mailbox_available(3);
        }
        mailbox_write(3, data, size);
    }
    """)

    sections.append(program_text)
    sections.append(_generator.visit(_build_handle_function(functions)))

    sections.append(R"""
    int main() {
        while (1) {
            _handle_events();
        }
    }
    """)

    return "\n".join(sections)


def _pyprintf(stream):
    format_string = stream.read_string()
    in_special = False
    args = []
    for i in range(len(format_string)):
        if in_special:
            if format_string[i:i+1] in [b'd']:
                args.append(stream.read_int32())
            elif format_string[i:i+1] in [b'x', b'X', b'o', b'u']:
                # perform unsigned conversion
                args.append(stream.read_uint32())
            elif format_string[i:i+1] in [b'f', b'F', b'g', b'G', b'e', b'E']:
                args.append(stream.read_float())
            elif format_string[i:i+1] == b's':
                args.append(stream.read_string().decode())
            elif format_string[i:i+1] == b'c':
                args.append(stream.read_byte())
            in_special = False
        elif format_string[i:i+1] == b'%':
            in_special = True

    print(format_string.decode() % tuple(args), end='')


def _handle_command(command, stream):
    if command == 1:  # Void return
        pass
    elif command == 2:  # print command
        _pyprintf(stream)
    else:
        raise RuntimeError('Unknown command {}'.format(command))


def _function_wrapper(stream, index, adapter, return_type, *args):
    """ Calls a function in the microblaze, designed to be used
    with functools.partial to build a new thing

    """
    arg_string = struct.pack('i', index)
    arg_string += adapter.pack_args(*args)
    stream.write(arg_string)
    if not adapter.returns:
        return None
    command = stream.read(1)[0]
    while command != 0:
        _handle_command(command, stream)
        command = stream.read(1)[0]
    response = adapter.receive_response(stream, *args)
    if return_type:
        return return_type(response)
    else:
        return response


def _create_typedef_classes(typedefs):
    """ Creates an anonymous class for each typedef in the C function

    """
    classes = {}
    for k, v in typedefs.items():
        class Wrapper:
            """Wrapper class for a C typedef

            The attributes are dynamically from the C definition using
            the functions name `type_`. If a function named this way
            takes `type` as the parameter it is added as a member function
            otherwise it is added as a static method.

            """
            def __init__(self, val):
                self.val = val

            def __index__(self):
                return self.val

            def __int__(self):
                return self.val

            def _call_func(self, function, *args):
                return function(self.val, *args)

            def __repr__(self):
                return "typedef {0} containing {1}".format(type(self).__name__,
                                                           repr(self.val))

        Wrapper.__name__ = k
        classes[k] = Wrapper
    return classes


def _filter_typedefs(typedefs, function_names):
    used_typedefs = set()
    for t in typedefs:
        if len([f for f in function_names if f.startswith(t + "_")]) > 0:
            used_typedefs.add(t)
    return used_typedefs


class MicroblazeFunction:
    """Calls a specific function

    """
    def __init__(self, stream, index, function, return_type):
        self.stream = stream
        self.index = index
        self.function = function
        self.return_type = return_type

    def _call_function(self, *args):
        arg_string = struct.pack('i', self.index)
        arg_string += self.function.pack_args(*args)
        self.stream.write(arg_string)

    def _handle_stream(self, *args):
        command = self.stream.read(1)[0]
        if command != 0:
            _handle_command(command, self.stream)
            return None, False
        return self.function.receive_response(self.stream, *args), True

    def __call__(self, *args):
        self._call_function(*args)
        if not self.function.blocks:
            return None
        return_value = None
        done = False
        while not done:
            return_value, done = self._handle_stream(*args)

        if self.return_type:
            return self.return_type(return_value)
        else:
            return return_value

    async def call_async(self, *args):
        self._call_function(*args)
        if not self.function.blocks:
            return None
        return_value = None
        done = False
        while return_value is None:
            await self.stream.wait_for_data_async()
            return_value, done = self._handle_stream(*args)

        if self.return_type:
            return self.return_type(return_value)
        else:
            return return_value


class MicroblazeRPC:
    """ Provides a python interface to the Microblaze based on an RPC
    mechanism.

    The attributes of the class are generated dynamically from the
    typedefs, enumerations and functions given in the provided source.

    Functions are added as methods, the values in enumerations are
    added as constants to the class and types are added as classes.

    """
    def __init__(self, iop, program_text):
        """ Create a new RPC instance

        Parameters
        ----------
        iop          : MicroblazeHierarchy or mb_info
            Microblaze instance to run the RPC server on
        program_text : str
            Source of the program to extract functions from

        """
        preprocessed = preprocess(program_text, mb_info=iop)
        try:
            ast = _parser.parse(preprocessed, filename='program_text')
        except ParseError as e:
            raise RuntimeError("Error parsing code\n" + str(e))
        visitor = FuncDefVisitor()
        visitor.visit(ast)
        main_text = _build_main(program_text, visitor.functions)
        used_typedefs = _filter_typedefs(visitor.typedefs,
                                         visitor.functions.keys())
        typedef_classes = _create_typedef_classes(visitor.typedefs)
        self._mb = MicroblazeProgram(iop, main_text)
        self._rpc_stream = InterruptMBStream(
            self._mb, read_offset=0xFC00, write_offset=0xF800)
        self._build_functions(visitor.functions, typedef_classes)
        self._build_constants(visitor.enums)
        self._populate_typedefs(typedef_classes, visitor.functions)
        self.visitor = visitor
        self.active_functions = 0

    def _build_constants(self, enums):
        for enum in enums:
            for name, value in enum.items.items():
                setattr(self, name, value)

    def _build_functions(self, functions, typedef_classes):
        index = 0
        for k, v in functions.items():
            return_type = None
            if v.return_interface.typedefname:
                return_type = typedef_classes[v.return_interface.typedefname]
            setattr(self, k,
                    MicroblazeFunction(
                        self._rpc_stream,
                        index, v, return_type)
                    )
            index += 1

    def _populate_typedefs(self, typedef_classes, functions):
        for name, cls in typedef_classes.items():
            for fname, func in functions.items():
                if fname.startswith(name + "_"):
                    subname = fname[len(name)+1:]
                    if (len(func.arg_interfaces) > 0 and
                            func.arg_interfaces[0].typedefname == name):
                        setattr(cls, subname,
                                functools.partialmethod(
                                    cls._call_func, getattr(self, fname)))
                    else:
                        setattr(cls, subname, getattr(self, fname))

    def reset(self):
        """Reset and free the microblaze for use by other programs

        """
        self._mb.reset()

    def release(self):
        """Alias for `reset()`

        """
        self.reset()


class MicroblazeLibrary(MicroblazeRPC):
    """Provides simple Python-only access to a set of Microblaze libraries.

    The members of this class are determined by the libraries chosen and can
    determined either by using ``dir`` on the instance or the ``?`` operator
    inside of IPython


    """
    def __init__(self, iop, libraries):
        """Create a Python API for a list of C libraries

        Libraries should be passed as the name of the header file containing
        the desired functions but without the ``.h`` extension

        Parameters
        ----------
        iop : mb_info / MicroblazeHierarchy
             The IOP to load the libraries on
        libraries : list
             List of the names of the libraries to load

        """
        source_text = "\n".join(['#include <{}.h>'.format(lib)
                                 for lib in libraries])
        super().__init__(iop, source_text)
