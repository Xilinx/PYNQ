import copy
import glob
import os
import pytest
import pynq

THIS_DIR = os.path.dirname(__file__)
HWH_PATH = os.path.join(THIS_DIR, 'data', '2016.4')

HWH_FILES = [os.path.basename(f) for f in glob.glob(os.path.join(HWH_PATH, "*.hwh"))]

@pytest.mark.parametrize('hwh_file', HWH_FILES)
def test_complete_description(hwh_file):
    parser = pynq.pl_server.hwh_parser._HWHZynq(
        os.path.join(HWH_PATH, hwh_file)
    )
    description = pynq.overlay._complete_description(
        parser.ip_dict, parser.hierarchy_dict, False, parser.mem_dict, "device"
    )
    assert description['ip'].keys() == parser.ip_dict.keys()
    for ipname, desc in description['ip'].items():
        assert desc['device'] == 'device'
        assert desc['driver'] == pynq.DefaultIP
        assert desc.items() >= parser.ip_dict[ipname].items()
    for hiername, desc in description['hierarchies'].items():
        assert desc['device'] == 'device'
        #assert desc['driver'] == pynq.overlay.DefaultHierarchy
        assert desc['driver'] == pynq.overlay.DocumentHierarchy
        
simple_description = {
    'ip': {
         'test_ip': {'phys_addr': 0x80000000, 'addr_range': 65536, 
                     'type': 'xilinx.com:test:test_ip:1.0', 'registers': {},
                     'parameters': {}, 'fullpath': 'test_ip'
         },
    },
    'hierarchies': {},
    'gpio': {},
    'interrupts': {},
}

hier_description = {
    'ip': {
         'hier/test_ip': {'phys_addr': 0x80000000, 'addr_range': 65536, 
                     'type': 'xilinx.com:test:test_ip:1.0', 'registers': {},
                     'parameters': {}, 'fullpath': 'hier/test_ip'
         },
    },
    'hierarchies': { 'hier': { 
        'ip': {
             'test_ip': {'phys_addr': 0x80000000, 'addr_range': 65536, 
                         'type': 'xilinx.com:test:test_ip:1.0', 'registers': {},
                         'parameters': {}, 'fullpath': 'hier/test_ip'
             },
        },
        'hierarchies': {},
        'gpio': {},
        'interrupts': {},
    }},
    'gpio': {},
    'interrupts': {},
}

def _copy_assign(description, ignore_version=False, device='device'):
    completed = copy.deepcopy(description)
    pynq.overlay._assign_drivers(completed, ignore_version, device)
    return completed


def test_ip_unregister():
    class TestDriver(pynq.DefaultIP):
        bindto = ['xilinx.com:test:test_ip:1.0']
    desc = _copy_assign(simple_description)
    assert desc['ip']['test_ip']['driver'] == TestDriver
    TestDriver.unregister()
    desc = _copy_assign(simple_description)
    assert desc['ip']['test_ip']['driver'] == pynq.DefaultIP


def test_ip_driver_replace():
    class TestDriver(pynq.DefaultIP):
        bindto = ['xilinx.com:test:test_ip:1.0']
    desc = _copy_assign(simple_description)
    assert desc['ip']['test_ip']['driver'] == TestDriver
    class TestDriver2(pynq.DefaultIP):
        bindto = ['xilinx.com:test:test_ip:1.0']
    desc = _copy_assign(simple_description)
    assert desc['ip']['test_ip']['driver'] == TestDriver2
    TestDriver2.unregister()
    TestDriver.unregister()
    desc = _copy_assign(simple_description)
    assert desc['ip']['test_ip']['driver'] == pynq.DefaultIP


def test_ip_version_mismatch():
    class TestDriver(pynq.DefaultIP):
        bindto = ['xilinx.com:test:test_ip:1.1']
    with pytest.warns(UserWarning):
        desc = _copy_assign(simple_description)
    assert desc['ip']['test_ip']['driver'] == pynq.DefaultIP
    TestDriver.unregister()


def test_ip_version_ignore():
    class TestDriver(pynq.DefaultIP):
        bindto = ['xilinx.com:test:test_ip:1.1']
    desc = _copy_assign(simple_description, ignore_version=True)
    assert desc['ip']['test_ip']['driver'] == TestDriver
    TestDriver.unregister()


def test_hierarchy_bind():
    class HierarchyDriver(pynq.DefaultHierarchy):
        @staticmethod
        def checkhierarchy(description):
            return 'test_ip' in description['ip']
    desc = _copy_assign(hier_description)
    assert desc['hierarchies']['hier']['driver'] == HierarchyDriver
    HierarchyDriver.unregister()
    desc = _copy_assign(hier_description)
    assert desc['hierarchies']['hier']['driver'] == pynq.overlay.DocumentHierarchy
    # assert desc['hierarchies']['hier']['driver'] == pynq.DefaultHierarchy


def test_hierarchy_replace():
    class HierarchyDriver1(pynq.DefaultHierarchy):
        @staticmethod
        def checkhierarchy(description):
            return 'test_ip' in description['ip']
    class HierarchyDriver2(pynq.DefaultHierarchy):
        @staticmethod
        def checkhierarchy(description):
            return 'test_ip' in description['ip']
    desc = _copy_assign(hier_description)
    assert desc['hierarchies']['hier']['driver'] == HierarchyDriver2
    HierarchyDriver2.unregister()
    desc = _copy_assign(hier_description)
    assert desc['hierarchies']['hier']['driver'] == HierarchyDriver1
    HierarchyDriver1.unregister()
    desc = _copy_assign(hier_description)
    assert desc['hierarchies']['hier']['driver'] == pynq.overlay.DocumentHierarchy
    # assert desc['hierarchies']['hier']['driver'] == pynq.DefaultHierarchy
