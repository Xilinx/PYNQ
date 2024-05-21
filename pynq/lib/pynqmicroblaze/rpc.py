#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import collections
import functools
import itertools
import math
import os
import re
import struct
from copy import deepcopy

import pycparser
from pycparser import c_ast, c_generator
from pycparser.plyparser import ParseError

from pynq.ps import CPU_ARCH, ZU_ARCH, ZYNQ_ARCH
from . import MicroblazeProgram
from .compile import preprocess
from .streams import InterruptMBStream, SimpleMBStream

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
    """Wrapper for C primitives that can be represented by
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
    """Wrapper for a void* pointer that will refer to a
    physically contiguous chunk of memory.

    """

    def __init__(self, type_):
        self._type = type_
        self.typedefname = None
        self.blocks = False
        self._ptrstruct = struct.Struct("I")

    def param_encode(self, old_val):
        return self._ptrstruct.pack(old_val.physical_address)

    def param_decode(self, old_val, stream):
        pass

    def return_decode(self, stream):
        raise RuntimeError("Cannot return a void*")

    def pre_argument(self, name):
        commands = []
        commands.append(
            _generate_decl(
                name + "_int",
                c_ast.TypeDecl(
                    name + "_int", [], c_ast.IdentifierType(["unsigned", "int"])
                ),
            )
        )
        commands.append(_generate_read(name + "_int"))
        commands.append(
            c_ast.Assignment(
                "|=", c_ast.ID(name + "_int"), c_ast.Constant("int", PTR_OFFSET)
            )
        )
        commands.append(
            c_ast.Decl(
                name,
                [],
                [],
                [],
                c_ast.PtrDecl(
                    [],
                    c_ast.TypeDecl(name, [], c_ast.IdentifierType(["void"])),
                ),
                c_ast.Cast(
                    c_ast.Typename(
                        None,
                        [],
                        c_ast.PtrDecl(
                            [], c_ast.TypeDecl(None, [], c_ast.IdentifierType(["void"]))
                        ),
                    ),
                    c_ast.ID(name + "_int"),
                ),
                [],
            )
        )
        return commands

    def post_argument(self, name):
        return []


class ConstPointerWrapper:
    """Wrapper for const T pointers, transfers data in only
    one direction.

    """

    def __init__(self, type_, struct_string):
        self._lenstruct = struct.Struct("h")
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
                name + "_len",
                c_ast.TypeDecl(
                    name + "_len", [], c_ast.IdentifierType(["unsigned", "short"])
                ),
            )
        )
        commands.append(_generate_read(name + "_len"))
        commands.append(_generate_arraydecl(name, self._type, c_ast.ID(name + "_len")))
        commands.append(_generate_read(name, address=False))
        return commands

    def post_argument(self, name):
        return []


class ConstCharPointerWrapper(ConstPointerWrapper):
    """Wrapper for const char*s which accepts Python strings and
    makes sure they are NULL-terminated

    """

    def __init__(self, type_):
        super().__init__(type_, "b")

    def param_encode(self, old_val):
        if type(old_val) is str:
            val = bytearray(old_val.encode())
        else:
            val = bytearray(old_val)

        val.append(0)
        return super().param_encode(val)


class PointerWrapper:
    """Wrapper for non-const T pointers that retrieves any
    data modified by the called function.

    """

    def __init__(self, type_, struct_string):
        self._lenstruct = struct.Struct("h")
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
        assert length == len(old_val)
        data = stream.read(length * struct.calcsize(self._struct_string))
        old_val[:] = struct.unpack(self._struct_string * len(old_val), data)

    def return_decode(self, stream):
        raise RuntimeError("Cannot use a T* decoder as a return value")

    def pre_argument(self, name):
        commands = []
        commands.append(
            _generate_decl(
                name + "_len",
                c_ast.TypeDecl(
                    name + "_len", [], c_ast.IdentifierType(["unsigned", "short"])
                ),
            )
        )
        commands.append(_generate_read(name + "_len"))
        commands.append(_generate_arraydecl(name, self._type, c_ast.ID(name + "_len")))
        commands.append(_generate_read(name, address=False))
        return commands

    def post_argument(self, name):
        commands = []
        commands.append(_generate_write(name + "_len"))
        commands.append(_generate_write(name, address=False))
        return commands


class VoidWrapper:
    """Wraps void - only valid for return types"""

    def __init__(self):
        self.typedefname = None
        self.blocks = False

    def param_encode(self, old_val):
        return b""

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
        if names[0] == "unsigned":
            signed = False
        name = names[1]
    else:
        name = names[0]
    if name == "void":
        return ""
    if name in ["long", "int"]:
        if names.count("long") == 2:
            if signed:
                return "q"
            else:
                return "Q"
        else:
            if signed:
                return "i"
            else:
                return "I"
    if name == "short":
        if signed:
            return "h"
        else:
            return "H"
    if name == "char":
        if signed:
            return "b"
        else:
            return "B"
    if name == "float":
        return "f"
    raise RuntimeError("Unknown type {}".format(name))


class MicroblazeError(Exception):
    pass


class PyIntWrapper(PrimitiveWrapper):
    def __init__(self, type_):
        super().__init__("i", type_)

    def return_decode(self, stream):
        data = stream.read(self._struct.size)
        val = self._struct.unpack(data)[0]
        if val < 0:
            raise MicroblazeError(os.strerror(-val))
        return val


class PyVoidWrapper(PrimitiveWrapper):
    def __init__(self, type_):
        super().__init__("i", type_)

    def return_decode(self, stream):
        data = stream.read(self._struct.size)
        val = self._struct.unpack(data)[0]
        if val < 0:
            raise MicroblazeError(os.strerror(-val))
        # Swallow the return value


class PyBoolWrapper(PrimitiveWrapper):
    def __init__(self, type_):
        super().__init__("i", type_)

    def return_decode(self, stream):
        data = stream.read(self._struct.size)
        val = self._struct.unpack(data)[0]
        if val < 0:
            raise MicroblazeError(os.strerror(-val))
        return bool(val)


class PyFloatWrapper(PrimitiveWrapper):
    def __init__(self, type_):
        super().__init__("f", type_)

    def return_decode(self, stream):
        data = stream.read(self._struct.size)
        val = self._struct.unpack(data)[0]
        if math.isnan(val):
            raise MicroblazeError("An Unknown Error Occurred")
        return val


_interface_overrides = {
    "py_int": PyIntWrapper,
    "py_bool": PyBoolWrapper,
    "py_float": PyFloatWrapper,
    "py_void": PyVoidWrapper,
}


def _type_to_interface(tdecl, typedefs):
    """Returns a wrapper for a given C AST"""

    if type(tdecl) is c_ast.PtrDecl:
        nested_type = tdecl.type
        if type(nested_type) is not c_ast.TypeDecl:
            raise RuntimeError("Only single level pointers supported")
        struct_string = _type_to_struct_string(nested_type)
        if struct_string:
            if "const" in nested_type.quals:
                if struct_string == "b":
                    return ConstCharPointerWrapper(tdecl)
                else:
                    return ConstPointerWrapper(tdecl, struct_string)
            else:
                return PointerWrapper(tdecl, struct_string)
        else:
            return VoidPointerWrapper(tdecl)

    elif type(tdecl) is not c_ast.TypeDecl:
        raise RuntimeError("Unsupport Type")

    names = tdecl.type.names
    if len(names) == 1 and names[0] in typedefs:
        if names[0] in _interface_overrides:
            interface = _interface_overrides[names[0]](tdecl)
        else:
            interface = _type_to_interface(typedefs[names[0]], typedefs)
            interface.typedefname = names[0]
        return interface

    struct_string = _type_to_struct_string(tdecl)
    if struct_string:
        return PrimitiveWrapper(struct_string, tdecl)
    else:
        return VoidWrapper()


def _generate_read(name, size=None, address=True):
    """Helper function to generate read functions. size
    should be an AST fragment

    """
    if size is None:
        size = c_ast.UnaryOp("sizeof", c_ast.ID(name))
    if address:
        target = c_ast.UnaryOp("&", c_ast.ID(name))
    else:
        target = c_ast.ID(name)

    return c_ast.FuncCall(c_ast.ID("_rpc_read"), c_ast.ExprList([target, size]))


def _generate_write(name, address=True):
    """Helper function generate write functions"""
    if address:
        target = c_ast.UnaryOp("&", c_ast.ID(name))
    else:
        target = c_ast.ID(name)
    return c_ast.FuncCall(
        c_ast.ID("_rpc_write"),
        c_ast.ExprList([target, c_ast.UnaryOp("sizeof", c_ast.ID(name))]),
    )


def _generate_decl(name, decl):
    """Generates a new declaration with a difference name
    but same type as the provided decl.

    """
    typedecl = c_ast.TypeDecl(name, [], decl.type)
    return c_ast.Decl(name, [], [], [], typedecl, [], [])


def _generate_arraydecl(name, decl, length):
    """Generates a new declaration with an array type
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
        self.docstring = _get_docstring(decl.coord)
        self.arg_interfaces = []
        self.args = []
        self.blocks = False
        self.coord = decl.coord
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
                block_contents.extend(interface.pre_argument("arg" + str(i)))
                post_block_contents.extend(interface.post_argument("arg" + str(i)))
                func_args.append(c_ast.ID("arg" + str(i)))
                self.arg_interfaces.append(interface)
                self.blocks = self.blocks | interface.blocks
                if arg.name:
                    self.args.append(arg.name)
                else:
                    self.args.append(f"arg{len(self.args)}")

        function_call = c_ast.FuncCall(c_ast.ID(self.name), c_ast.ExprList(func_args))

        self.returns = type(self.return_interface) is not VoidWrapper
        if self.returns:
            ret_assign = c_ast.Decl(
                "ret",
                [],
                [],
                [],
                c_ast.TypeDecl("ret", [], decl.type.type),
                function_call,
                [],
            )
            block_contents.append(ret_assign)
            block_contents.append(_generate_write("return_command"))
            block_contents.extend(post_block_contents)
            block_contents.append(_generate_write("ret"))
            self.blocks = True
        else:
            block_contents.append(function_call)
            if self.blocks:
                block_contents.append(_generate_write("return_command"))
            else:
                block_contents.append(_generate_write("void_command"))
            block_contents.extend(post_block_contents)

        self.call_ast = c_ast.Compound(block_contents)
        self.filename = decl.coord.file

    def pack_args(self, *args):
        """Create a bytes of the provided arguments"""
        if len(args) != len(self.arg_interfaces):
            raise RuntimeError(
                "Wrong number of arguments: expected{0} got {1}".format(
                    len(self.arg_interfaces), len(args)
                )
            )
        return b"".join(
            [
                f.param_encode(a)
                for f, a in itertools.zip_longest(self.arg_interfaces, args)
            ]
        )

    def receive_response(self, stream, *args):
        """Reads the response stream, updates arguments and
        returns the value of the function call if applicable

        """
        if len(args) != len(self.arg_interfaces):
            raise RuntimeError(
                "Wrong number of arguments: expected{0} got {1}".format(
                    len(self.arg_interfaces), len(args)
                )
            )
        [
            f.param_decode(a, stream)
            for f, a in itertools.zip_longest(self.arg_interfaces, args)
        ]
        return_value = self.return_interface.return_decode(stream)
        return return_value


class ParsedEnum:
    """Holds the values of an enum from the C source"""

    def __init__(self):
        self.name = None
        self.file = None
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
        self.typedef_coords = {}
        self.function_coords = {}

    def visit_Typedef(self, node):
        self.typedefs[node.name] = node.type
        self.typedef_coords[node.name] = node.coord

    def visit_FuncDef(self, node):
        self.defined.append(node.decl.name)
        self.visit(node.decl)

    def visit_FuncDecl(self, node):
        if node.coord.file.startswith("/opt/microblaze"):
            return
        if type(node.type) is not c_ast.TypeDecl:
            # Ignore functions that are returning pointers
            return
        name = node.type.declname
        if "static" in node.type.quals:
            # Don't process static functions
            return
        try:
            self.functions[name] = FuncAdapter(node, self.typedefs)
            self.function_coords[name] = node.coord
        except RuntimeError as e:
            if node.coord.file == "<stdin>":
                print("Could not create interface for funcion {}: {}".format(name, e))

    def visit_Enum(self, node):
        enum = ParsedEnum()
        if node.name:
            enum.name = node.name
        enum.file = node.coord.file
        cur_index = 0
        for entry in node.values.enumerators:
            if entry.value:
                cur_index = int(entry.value.value, 0)
            enum.items[entry.name] = cur_index
            cur_index += 1
        self.enums.append(enum)


def _build_case(functions):
    """Builds the switch statement that will form the foundation
    of the RPC handler

    """
    cases = []
    for i, func in enumerate(functions.values()):
        case = c_ast.Case(c_ast.Constant("int", str(i)), [func.call_ast, c_ast.Break()])
        cases.append(case)
    return c_ast.Switch(c_ast.ID("command"), c_ast.Compound(cases))


def _build_handle_function(functions):
    """Wraps the switch statement in a function definition"""
    case_statement = _build_case(functions)
    available_check = c_ast.If(
        c_ast.BinaryOp(
            "<",
            c_ast.FuncCall(
                c_ast.ID("mailbox_available"),
                c_ast.ExprList([c_ast.Constant("int", "2")]),
            ),
            c_ast.Constant("int", "4"),
        ),
        c_ast.Return(None),
        None,
    )
    handle_decl = c_ast.FuncDecl(
        None,
        c_ast.TypeDecl("_handle_events", [], c_ast.IdentifierType(["void"])),
    )
    command_decl = c_ast.Decl(
        "command",
        [],
        [],
        [],
        c_ast.TypeDecl("command", [], c_ast.IdentifierType(["int"])),
        [],
        [],
    )
    command_read = _generate_read("command")
    body = c_ast.Compound([available_check, command_decl, command_read, case_statement])
    return c_ast.FuncDef(handle_decl, [], body)


def _build_main(program_text, functions):
    sections = []
    sections.append(
        R"""
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
    """
    )

    sections.append(program_text)
    sections.append(_generator.visit(_build_handle_function(functions)))

    sections.append(
        R"""
    int main() {
        while (1) {
            _handle_events();
        }
    }
    """
    )

    return "\n".join(sections)


def _pyprintf(stream):
    format_string = stream.read_string()
    in_special = False
    args = []
    for i in range(len(format_string)):
        if in_special:
            if format_string[i : i + 1] in [b"d"]:
                args.append(stream.read_int32())
            elif format_string[i : i + 1] in [b"x", b"X", b"o", b"u"]:
                # perform unsigned conversion
                args.append(stream.read_uint32())
            elif format_string[i : i + 1] in [b"f", b"F", b"g", b"G", b"e", b"E"]:
                args.append(stream.read_float())
            elif format_string[i : i + 1] == b"s":
                args.append(stream.read_string().decode())
            elif format_string[i : i + 1] == b"c":
                args.append(stream.read_byte())
            in_special = False
        elif format_string[i : i + 1] == b"%":
            in_special = True

    print(format_string.decode() % tuple(args), end="")


def _handle_command(command, stream):
    if command == 1:  # Void return
        pass
    elif command == 2:  # print command
        _pyprintf(stream)
    else:
        raise RuntimeError("Unknown command {}".format(command))


def _function_wrapper(stream, index, adapter, return_type, *args):
    """Calls a function in the microblaze, designed to be used
    with functools.partial to build a new thing

    """
    arg_string = struct.pack("i", index)
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


def _create_typedef_classes(typedefs, typedef_coords):
    """Creates an anonymous class for each typedef in the C function"""
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
                self._val = val

            def __index__(self):
                return self._val

            def __int__(self):
                return self._val

            def _call_func(self, function, *args):
                return function(self._val, *args)

            def __repr__(self):
                return "typedef {0} containing {1}".format(
                    type(self).__name__, repr(self._val)
                )

            _file = typedef_coords[k].file

        Wrapper.__name__ = k
        if k in typedef_coords:
            doc = _get_docstring(typedef_coords[k])
            if doc:
                Wrapper.__doc__ = doc
        classes[k] = Wrapper
    return classes


def _filter_typedefs(typedefs, function_names):
    used_typedefs = set()
    for t in typedefs:
        if len([f for f in function_names if f.startswith(t + "_")]) > 0:
            used_typedefs.add(t)
    return used_typedefs


def _get_docstring(coord):
    try:
        with open(coord.file) as f:
            lines = f.readlines()
    except:
        return None
    # We need to subtract 2 as coord is 1-indexed
    keyline = lines[coord.line - 2].rstrip()
    comment_lines = collections.deque()
    if keyline.startswith("// "):
        i = coord.line - 2
        while i >= 0 and lines[i].startswith("// "):
            comment_lines.appendleft(lines[i][3:].rstrip())
            i -= 1
    elif keyline.endswith("*/"):
        i = coord.line - 2
        # Strip comment close
        line = re.sub(r"\W*\*+/\W*", "", lines[i])
        if line:
            comment_lines.appendleft(line.rstrip())
        i -= 1
        # Add Intermediate lines
        while i >= 0 and not lines[i].startswith("/*"):
            line = lines[i].rstrip()
            line = re.sub(r" \* ?", "", line)
            comment_lines.appendleft(line)
            i -= 1
        line = re.sub(r"/\*+\W*", "", lines[i].rstrip())
        if line:
            comment_lines.appendleft(line)

    else:
        return None
    return "\n".join(comment_lines)


class MicroblazeFunction:
    """Calls a specific function"""

    def __init__(self, stream, index, function, return_type):
        self.stream = stream
        self.index = index
        self.function = function
        self.return_type = return_type

    def _call_function(self, *args):
        arg_string = struct.pack("i", self.index)
        arg_string += self.function.pack_args(*args)
        self.stream.write(arg_string)

    def _handle_stream(self, *args):
        command = self.stream.read(1)[0]
        if command != 0:
            _handle_command(command, self.stream)
            return None, False
        return self.function.receive_response(self.stream, *args), True

    def __repr__(self):
        return "<MicroblazeFunction for " + self.function.name + ">"

    def call(self, *args):
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

    def __call__(self, *args):
        return self.call(*args)

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


def _create_function_class(function):
    call_func = f"""def call(self, {', '.join(function.args)}):
        {repr(function.docstring)}
        return self.call({', '.join(function.args)})
    """
    scope = {}
    exec(call_func, scope)
    derived = type(
        "MicroblazeFuncion_" + function.name,
        (MicroblazeFunction,),
        {"__call__": scope["call"], "__doc__": function.docstring},
    )
    return derived


def _create_instance_function(function):
    args = function.function.args
    func_string = f"""def wrapped({', '.join(['self'] + args[1:])}):
        {repr(function.__doc__)}
        return self._call_func(function, {', '.join(args[1:])})
    """
    scope = {"function": function}
    exec(func_string, scope)
    wrapped = scope["wrapped"]
    return wrapped


class MicroblazeRPC:
    """Provides a python interface to the Microblaze based on an RPC
    mechanism.

    The attributes of the class are generated dynamically from the
    typedefs, enumerations and functions given in the provided source.

    Functions are added as methods, the values in enumerations are
    added as constants to the class and types are added as classes.

    """

    def __init__(self, iop, program_text):
        """Create a new RPC instance

        Parameters
        ----------
        iop          : MicroblazeHierarchy or mb_info
            Microblaze instance to run the RPC server on
        program_text : str
            Source of the program to extract functions from

        """
        preprocessed = preprocess(program_text, mb_info=iop)
        try:
            ast = _parser.parse(preprocessed, filename="program_text")
        except ParseError as e:
            raise RuntimeError("Error parsing code\n" + str(e))
        visitor = FuncDefVisitor()
        visitor.visit(ast)
        main_text = _build_main(program_text, visitor.functions)
        used_typedefs = _filter_typedefs(visitor.typedefs, visitor.functions.keys())
        typedef_classes = _create_typedef_classes(
            visitor.typedefs, visitor.typedef_coords
        )
        self._mb = MicroblazeProgram(iop, main_text)
        self._rpc_stream = InterruptMBStream(
            self._mb, read_offset=0xFC00, write_offset=0xF800
        )
        self._build_functions(visitor.functions, typedef_classes)
        self._build_constants(visitor.enums, typedef_classes)
        self._populate_typedefs(typedef_classes, visitor.functions)
        self.visitor = visitor
        self.active_functions = 0

    def _build_constants(self, enums, classes):
        byfile = collections.defaultdict(list)
        for enum in enums:
            for name, value in enum.items.items():
                setattr(self, name, value)
                byfile[enum.file].append((name, value))
        for c in classes.values():
            if c._file in byfile:
                for k, v in byfile[c._file]:
                    setattr(c, k, v)

    def _build_functions(self, functions, typedef_classes):
        index = 0
        for k, v in functions.items():
            return_type = None
            if v.return_interface.typedefname:
                return_type = typedef_classes[v.return_interface.typedefname]
            FunctionType = _create_function_class(v)
            setattr(self, k, FunctionType(self._rpc_stream, index, v, return_type))
            index += 1

    def _populate_typedefs(self, typedef_classes, functions):
        for name, cls in typedef_classes.items():
            for fname, func in functions.items():
                if fname.startswith(name + "_"):
                    subname = fname[len(name) + 1 :]
                    if (
                        len(func.arg_interfaces) > 0
                        and func.arg_interfaces[0].typedefname == name
                    ):
                        setattr(
                            cls,
                            subname,
                            _create_instance_function(getattr(self, fname)),
                        )
            getters = [s for s in dir(cls) if s.startswith("get_")]
            for g in getters:
                p = g[4:]  # Strip the get_ off the front for the name
                setattr(
                    cls,
                    p,
                    property(getattr(cls, "get_" + p), getattr(cls, "set_" + p, None)),
                )

    def reset(self):
        """Reset and free the microblaze for use by other programs"""
        self._mb.reset()

    def release(self):
        """Alias for `reset()`"""
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
        source_text = "\n".join(["#include <{}.h>".format(lib) for lib in libraries])
        super().__init__(iop, source_text)


