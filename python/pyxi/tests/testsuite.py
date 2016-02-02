"""This is the Test Suite for PyXi.

Usage
----------
1.  Tests must be developed using the unittest package, as specified in the 
    documentation available at https://docs.python.org/3/library/unittest.html.
2.  In addition to that, the test module must contain a 'test_<module_name>'
    function the module to be executed standalone as well as to be imported in
    the test suite. Inside this 'test_<module_name>' function, besides all 
    additional initialization code that could be specific to the test module, 
    there must be a call to 
    >>> unittest.main(__name__)
    To allow standalone execution, 'test_<module_name>()' must be called 
    in the "__main__" boilerplate, like so:
    >>> if __name__ == "__main__":
    >>>     test_<module_name>()
3.  It is adviced that for each pyxi subpackage a nested 'tests' subpackage is 
    created, containing all the unit tests. So for instance, if the 
    subpackage is 'pyxi.board' then all the tests for 'board' will go 
    into 'pyxi.board.tests'.
    In the test's __init__.py, all the 'test_<module_name>()' functions of each
    test module must be exported. Since by convention usually also test 
    modules' names begin with 'test_', we will have that this kind of syntax
    >>> from .test_module import test_module
    To give a concrete example, if the test module is called 'test_device' 
    (i.e. is the unit test of 'device'), in __init__.py this entry 
    must be added:
    >>> from .test_device import test_device
    given that you defined the 'test_device()' function as specified in 2.
4.  As last step, all the packages that need to be tested together in the test 
    suite must be listed in the *test_suite* list below. If done so, 
    tests will be automatically imported and executed from this script.
5.  To run the Test Suite, it is sufficient to call the 'run_tests()' function 
    (the working principle is the same of a single unit test) or execute 
    the whole script using the "__main__" boilerplate.

NOTE:
    When developing demoes, the guidelines are the same with the only exception
    that the function at 2 must be called 'demo_<module_name>' and must be
    exported in the __init__.py as well
    >>> from .demo_module import demo_module
    (the name of the module can obviously be arbitrary, even though in this
    example is named demo_module as the function itself).
"""

__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest

# List here all packages to test or demo(as strings)
test_suite = [
    'pyxi.board.tests',
    'pyxi.pmods.tests'
#    'pyxi.video.tests',
#    'pyxi.audio.tests'
]
"""List containing all the test packages of the Test Suite. They are executed
following the order in which they are inserted here."""

def run_tests():
    run('test')


def run(what):
    print('PYXI {} SUITE\n==============='.format(what.upper()))
    for package in test_suite:
        p = __import__(package, globals(), locals(), ['*'])
        for m in sorted(dir(p)):
            t = getattr(p, m)
            if m.startswith('{}_'.format(what.lower())) and callable(t):
                print(m.upper(), '\n........')               
                try:
                    t()
                except unittest.SkipTest:
                    print('skipped', m)
                print('---------------')    


if __name__ == "__main__":
    run_tests()
    
