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


from IPython.core.magic import cell_magic, Magics, magics_class
from IPython import get_ipython
from IPython.display import HTML, display_javascript
from .proc import Pybind11Processor


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


@magics_class
class Pybind11Magics(Magics):
    @cell_magic
    def pybind11(self, line, cell):
        """IPython magic inside Jupyter environment.

        For the entire line provided in the magic, the first element will be
        taken as the module name, while the additional elements will be taken
        as optional building flags.

        """
        line_list = line.split(';')
        module_name = line_list[0]
        cflags = None
        ldflags = None
        if len(line_list) > 1:
            cflags = ' '.join(line_list[1].split())
        if len(line_list) > 2:
            ldflags = ' '.join(line_list[2].split())
        flags = {'cflags': cflags,
                 'ldflags': ldflags}
        try:
            _ = Pybind11Processor(module_name, flags, cell)
        except RuntimeError as r:
            return HTML("<pre>Compile FAILED\n" + r.args[0] + "</pre>")


js = """
try {
require(['notebook/js/codecell'], function(codecell) {
  codecell.CodeCell.options_default.highlight_modes[
      'magic_text/x-csrc'] = {'reg':[/^%%pybind11/]};
  Jupyter.notebook.events.one('kernel_ready.Kernel', function(){
      Jupyter.notebook.get_cells().map(function(cell){
          if (cell.cell_type == 'code'){ cell.auto_highlight(); } }) ;
  });
});
} catch (e) {};
"""

instance = get_ipython()

if instance:
    get_ipython().register_magics(Pybind11Magics)
    display_javascript(js, raw=True)
