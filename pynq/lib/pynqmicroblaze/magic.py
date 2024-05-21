#   Copyright (c) 2018, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause



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
    import nest_asyncio
    nest_asyncio.apply()



