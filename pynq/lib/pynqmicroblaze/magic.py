#   Copyright (c) 2018, Xilinx, Inc.
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
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"


from IPython.core.magic import cell_magic, Magics, magics_class
from IPython import get_ipython
from IPython.display import display, HTML
from IPython.display import display_javascript
from .rpc import MicroblazeRPC


class _DataHolder:
    pass


class _FunctionWrapper:
    def __init__(self, function, program):
        self.library = program
        self.stdio = program._mb.stream
        self._mb = program._mb
        self._function = function

    def __call__(self, *args):
        return self._function(*args)

    async def call_async(self, *args):
         return await self._function.call_async(*args)

    def reset(self):
        self._mb.reset()

    def release(self):
        self.reset()


@magics_class
class MicroblazeMagics(Magics):
    def name2obj(self, name):
        _proxy = _DataHolder()
        exec("_proxy.obj = {}".format(name), locals(), self.shell.user_ns)
        return _proxy.obj

    @cell_magic
    def microblaze(self, line, cell):
        mb_info = self.name2obj(line)
        try:
            program = MicroblazeRPC(mb_info, '#line 1 "cell_magic"\n\n' + cell)
        except RuntimeError as r:
            return HTML("<pre>Compile FAILED\n" + r.args[0] + "</pre>")
        for name, adapter in program.visitor.functions.items():
            if adapter.filename == "cell_magic":
                self.shell.user_ns.update(
                    {name: _FunctionWrapper(getattr(program, name), program)})


js = """
try {
require(['notebook/js/codecell'], function(codecell) {
  codecell.CodeCell.options_default.highlight_modes[
      'magic_text/x-csrc'] = {'reg':[/^%%microblaze/]};
  Jupyter.notebook.events.one('kernel_ready.Kernel', function(){
      Jupyter.notebook.get_cells().map(function(cell){
          if (cell.cell_type == 'code'){ cell.auto_highlight(); } }) ;
  });
});
} catch (e) {};
"""

instance = get_ipython()

if instance:
    get_ipython().register_magics(MicroblazeMagics)
    display_javascript(js, raw=True)
