#   Copyright (c) 2018, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from IPython.core.magic import cell_magic, Magics, magics_class
from IPython import get_ipython
from IPython.display import HTML, display_javascript
from .proc import Pybind11Processor




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


