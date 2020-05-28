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

import cffi
import glob
import os
import threading
import time
import warnings

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"


_c_header = R"""
extern const char *libsensors_version;

typedef struct sensors_bus_id {
 short type;
 short nr;
} sensors_bus_id;

typedef struct sensors_chip_name {
 char *prefix;
 sensors_bus_id bus;
 int addr;
 char *path;
} sensors_chip_name;

int sensors_init(FILE *input);
void sensors_cleanup(void);
int sensors_parse_chip_name(const char *orig_name, sensors_chip_name *res);
void sensors_free_chip_name(sensors_chip_name *chip);
int sensors_snprintf_chip_name(char *str, size_t size,
          const sensors_chip_name *chip);
const char *sensors_get_adapter_name(const sensors_bus_id *bus);

typedef struct sensors_feature sensors_feature;
char *sensors_get_label(const sensors_chip_name *name,
   const sensors_feature *feature);

int sensors_get_value(const sensors_chip_name *name, int subfeat_nr,
        double *value);

int sensors_set_value(const sensors_chip_name *name, int subfeat_nr,
        double value);

int sensors_do_chip_sets(const sensors_chip_name *name);

const sensors_chip_name *sensors_get_detected_chips(const sensors_chip_name
          *match, int *nr);

typedef enum sensors_feature_type {
 SENSORS_FEATURE_IN = 0x00,
 SENSORS_FEATURE_FAN = 0x01,
 SENSORS_FEATURE_TEMP = 0x02,
 SENSORS_FEATURE_POWER = 0x03,
 SENSORS_FEATURE_ENERGY = 0x04,
 SENSORS_FEATURE_CURR = 0x05,
 SENSORS_FEATURE_HUMIDITY = 0x06,
 SENSORS_FEATURE_MAX_MAIN,
 SENSORS_FEATURE_VID = 0x10,
 SENSORS_FEATURE_INTRUSION = 0x11,
 SENSORS_FEATURE_MAX_OTHER,
 SENSORS_FEATURE_BEEP_ENABLE = 0x18,
 SENSORS_FEATURE_MAX,
 SENSORS_FEATURE_UNKNOWN = 0x7fffffff,
} sensors_feature_type;

typedef enum sensors_subfeature_type {
 SENSORS_SUBFEATURE_IN_INPUT = 0,
 SENSORS_SUBFEATURE_IN_MIN,
 SENSORS_SUBFEATURE_IN_MAX,
 SENSORS_SUBFEATURE_IN_LCRIT,
 SENSORS_SUBFEATURE_IN_CRIT,
 SENSORS_SUBFEATURE_IN_AVERAGE,
 SENSORS_SUBFEATURE_IN_LOWEST,
 SENSORS_SUBFEATURE_IN_HIGHEST,
 SENSORS_SUBFEATURE_IN_ALARM = 0x80,
 SENSORS_SUBFEATURE_IN_MIN_ALARM,
 SENSORS_SUBFEATURE_IN_MAX_ALARM,
 SENSORS_SUBFEATURE_IN_BEEP,
 SENSORS_SUBFEATURE_IN_LCRIT_ALARM,
 SENSORS_SUBFEATURE_IN_CRIT_ALARM,

 SENSORS_SUBFEATURE_FAN_INPUT = 0x100,
 SENSORS_SUBFEATURE_FAN_MIN,
 SENSORS_SUBFEATURE_FAN_MAX,
 SENSORS_SUBFEATURE_FAN_ALARM = 0x180,
 SENSORS_SUBFEATURE_FAN_FAULT,
 SENSORS_SUBFEATURE_FAN_DIV,
 SENSORS_SUBFEATURE_FAN_BEEP,
 SENSORS_SUBFEATURE_FAN_PULSES,
 SENSORS_SUBFEATURE_FAN_MIN_ALARM,
 SENSORS_SUBFEATURE_FAN_MAX_ALARM,

 SENSORS_SUBFEATURE_TEMP_INPUT = 0x200,
 SENSORS_SUBFEATURE_TEMP_MAX,
 SENSORS_SUBFEATURE_TEMP_MAX_HYST,
 SENSORS_SUBFEATURE_TEMP_MIN,
 SENSORS_SUBFEATURE_TEMP_CRIT,
 SENSORS_SUBFEATURE_TEMP_CRIT_HYST,
 SENSORS_SUBFEATURE_TEMP_LCRIT,
 SENSORS_SUBFEATURE_TEMP_EMERGENCY,
 SENSORS_SUBFEATURE_TEMP_EMERGENCY_HYST,
 SENSORS_SUBFEATURE_TEMP_LOWEST,
 SENSORS_SUBFEATURE_TEMP_HIGHEST,
 SENSORS_SUBFEATURE_TEMP_MIN_HYST,
 SENSORS_SUBFEATURE_TEMP_LCRIT_HYST,
 SENSORS_SUBFEATURE_TEMP_ALARM = 0x280,
 SENSORS_SUBFEATURE_TEMP_MAX_ALARM,
 SENSORS_SUBFEATURE_TEMP_MIN_ALARM,
 SENSORS_SUBFEATURE_TEMP_CRIT_ALARM,
 SENSORS_SUBFEATURE_TEMP_FAULT,
 SENSORS_SUBFEATURE_TEMP_TYPE,
 SENSORS_SUBFEATURE_TEMP_OFFSET,
 SENSORS_SUBFEATURE_TEMP_BEEP,
 SENSORS_SUBFEATURE_TEMP_EMERGENCY_ALARM,
 SENSORS_SUBFEATURE_TEMP_LCRIT_ALARM,

 SENSORS_SUBFEATURE_POWER_AVERAGE = 0x300,
 SENSORS_SUBFEATURE_POWER_AVERAGE_HIGHEST,
 SENSORS_SUBFEATURE_POWER_AVERAGE_LOWEST,
 SENSORS_SUBFEATURE_POWER_INPUT,
 SENSORS_SUBFEATURE_POWER_INPUT_HIGHEST,
 SENSORS_SUBFEATURE_POWER_INPUT_LOWEST,
 SENSORS_SUBFEATURE_POWER_CAP,
 SENSORS_SUBFEATURE_POWER_CAP_HYST,
 SENSORS_SUBFEATURE_POWER_MAX,
 SENSORS_SUBFEATURE_POWER_CRIT,
 SENSORS_SUBFEATURE_POWER_AVERAGE_INTERVAL = 0x380,
 SENSORS_SUBFEATURE_POWER_ALARM,
 SENSORS_SUBFEATURE_POWER_CAP_ALARM,
 SENSORS_SUBFEATURE_POWER_MAX_ALARM,
 SENSORS_SUBFEATURE_POWER_CRIT_ALARM,

 SENSORS_SUBFEATURE_ENERGY_INPUT = 0x400,

 SENSORS_SUBFEATURE_CURR_INPUT = 0x500,
 SENSORS_SUBFEATURE_CURR_MIN,
 SENSORS_SUBFEATURE_CURR_MAX,
 SENSORS_SUBFEATURE_CURR_LCRIT,
 SENSORS_SUBFEATURE_CURR_CRIT,
 SENSORS_SUBFEATURE_CURR_AVERAGE,
 SENSORS_SUBFEATURE_CURR_LOWEST,
 SENSORS_SUBFEATURE_CURR_HIGHEST,
 SENSORS_SUBFEATURE_CURR_ALARM = 0x580,
 SENSORS_SUBFEATURE_CURR_MIN_ALARM,
 SENSORS_SUBFEATURE_CURR_MAX_ALARM,
 SENSORS_SUBFEATURE_CURR_BEEP,
 SENSORS_SUBFEATURE_CURR_LCRIT_ALARM,
 SENSORS_SUBFEATURE_CURR_CRIT_ALARM,

 SENSORS_SUBFEATURE_HUMIDITY_INPUT = 0x600,

 SENSORS_SUBFEATURE_VID = 0x1000,

 SENSORS_SUBFEATURE_INTRUSION_ALARM = 0x1100,
 SENSORS_SUBFEATURE_INTRUSION_BEEP,

 SENSORS_SUBFEATURE_BEEP_ENABLE = 0x1800,

 SENSORS_SUBFEATURE_UNKNOWN = 0x7fffffff,
} sensors_subfeature_type;


struct sensors_feature {
 char *name;
 int number;
 sensors_feature_type type;

 int first_subfeature;
 int padding1;
};

typedef struct sensors_subfeature {
 char *name;
 int number;
 sensors_subfeature_type type;
 int mapping;
 unsigned int flags;
} sensors_subfeature;

const sensors_feature *
sensors_get_features(const sensors_chip_name *name, int *nr);

const sensors_subfeature *
sensors_get_all_subfeatures(const sensors_chip_name *name,
       const sensors_feature *feature, int *nr);

const sensors_subfeature *
sensors_get_subfeature(const sensors_chip_name *name,
         const sensors_feature *feature,
         sensors_subfeature_type type);
"""

_ffi = cffi.FFI()

try:
    _ffi.cdef(_c_header)
    _lib = _ffi.dlopen("libsensors.so.4")
except Exception as e:
    _lib = None


class SysFSSensor:
    def __init__(self, path, unit, name, scale):
        self._path = path
        self._unit = unit
        self.name = name
        self._scale = scale
        self.parents = tuple()

    @property
    def value(self):
        with open(self._path, "r") as f:
            raw_value = float(f.read())
        return raw_value * self._scale

    def get_value(self, parents=None):
        return self.value

    def __repr__(self):
        return "Sensor {{name={}, value={}{}}}".format(
            self.name, self.value, self._unit)

class DerivedPowerSensor:
    def __init__(self, name, voltage, current):
        parents = (voltage, current)
        self.voltage_sensor = voltage
        self.current_sensor = current
        self.name = name
        self.parents = (voltage, current)

    def get_value(self, parents=None):
        if parents is None:
            return self.voltage_sensor.value * self.current_sensor.value
        else:
            return parents[0] * parents[1]

    @property
    def value(self):
        return self.get_value()

    def __repr__(self):
        return "Sensor {{name={}, value={}W}}".format(
            self.name, self.value)

class Sensor:
    """Interacts with a sensor exposed by libsensors

    The value of the sensor is determined by the unit of the
    underlying sensor API - that is generally Volts for potential
    difference, Amperes for current, Watts for power and degrees
    Centigrade for temperature

    Attributes
    ----------
    name : str
        The name of the sensor
    value : float
        The current value of the sensor

    """
    def __init__(self, chip, number, unit, name):
        """Create a new sensor object wrapping a libsensors chip and feature

        Parameters
        ----------
        chip : FFI sensors_chip_name*
            The chip the sensor is on
        number : int
            The number of sensor on the chip
        unit : str
            Unit to append to the value when creating a string representation
        name : str
            Name of the sensor

        """
        self._chip = chip
        self._number = number
        self._value = _ffi.new("double [1]")
        self._unit = unit
        self.name = name
        self.parents = tuple()

    @property
    def value(self):
        """Read the current value of the sensor

        """
        if _lib:
            _lib.sensors_get_value(self._chip, self._number, self._value)
            return self._value[0]
        else:
            return 0

    def get_value(self, parents=None):
        return self.value

    def __repr__(self):
        return "Sensor {{name={}, value={}{}}}".format(
            self.name, self.value, self._unit)

class Rail:
    """Bundles up to three sensors monitoring the same power rail

    Represents a power rail in the system monitored by up to three
    sensors for voltage, current and power.

    Attributes
    ----------
    name : str
        Name of the power rail
    voltage : Sensor or None
        Voltage sensor for the rail or None if not available
    current : Sensor or None
        Current sensor for the rail or None if not available
    power : Sensor or None
        Power sensor for the rail or None if not available

    """
    def __init__(self, name):
        """Create a new Rail with the specified rail

        """
        self.name = name
        self.voltage = None
        self.current = None
        self.power = None

    def __repr__(self):
        args = ["name=" + self.name]
        if self.voltage:
            args.append("voltage=" + repr(self.voltage))
        if self.current:
            args.append("current=" + repr(self.current))
        if self.power:
            args.append("power=" + repr(self.power))
        return "Rail {{{}}}".format(', '.join(args))


class XrtInfoDump:
    def __init__(self, device):
        self._device = device
        self.parents = tuple()

    def get_value(self, parents=None):
        info = self._device.device_info
        return {
            "0v85_v": info.m0v85,
            "12v_aux_v": info.m12VAux,
            "12v_aux_i": info.mAuxCurr,
            "12v_pex_v": info.m12VPex,
            "12v_pex_i": info.mPexCurr,
            "12v_sw_v": info.m12vSW,
            "1v8_v": info.m1v8Top,
            "3v3_aux_v": info.m3v3Aux,
            "3v3_pex_v": info.m3v3Pex,
            "mgt0v9avcc_v": info.mMgt0v9,
            "mgtavtt_v": info.mMgtVtt,
            "sys_5v5_v": info.mSys5v5,
            "vccint_v": info.mVccIntVol,
            "vccint_i": info.mCurrent
        }

class XrtSensor:
    def __init__(self, unit, name, scale, parent, field):
        self.parents = (parent,)
        self._unit = unit
        self.name = name
        self._scale = scale
        self._field = field

    def get_value(self, parents=None):
        if parents is None:
            parents = (self.parents[0].get_value(),)
        return parents[0][self._field] * self._scale

    @property
    def value(self):
        return self.get_value()

    def __repr__(self):
        return "Sensor {{name={}, value={}{}}}".format(
            self.name, self.value, self._unit)


class XrtRail:
    def __init__(self, name, sample_dict, parent):
       self.name = name
       if name + "_v" in sample_dict:
           self.voltage = XrtSensor("V", name + "_vol", 0.001, parent, name + "_v")
       else:
           self.voltage = None

       if name + "_i" in sample_dict:
           self.current = XrtSensor("A", name + "_curr", 0.001, parent, name + "_i")
       else:
           self.current = None

       if self.voltage and self.current:
           self.power = DerivedPowerSensor(name + "_power",
               self.voltage, self.current)
       else:
           self.power = None


    def __repr__(self):
        args = ["name=" + self.name]
        if self.voltage:
            args.append("voltage=" + repr(self.voltage))
        if self.current:
            args.append("current=" + repr(self.current))
        if self.power:
            args.append("power=" + repr(self.power))
        return "XrtRail {{{}}}".format(', '.join(args))


def get_xrt_sysfs_rails(device=None):
    if device is None:
        from pynq.pl_server import Device
        device = Device.active_device

    rail_names = ["0v85", "12v_aux", "12v_pex", "12v_sw", "1v8", "3v3_aux",
                  "3v3_pex", "mgt0v9avcc", "mgtavtt", "sys_5v5", "vccint" ]

    infodump = XrtInfoDump(device)
    sample_dict = infodump.get_value()

    rails = {}
    for n in rail_names:
        rails[n] = XrtRail(n, sample_dict, infodump)

    return rails


def _enumerate_sensors(config_file=None):
    if _lib is None:
        warnings.warn("Could not initialise libsensors library")
        return {}

    if config_file:
        with open(config_file, 'r') as handle:
            _lib.sensors_init(handle);
    else:
        _lib.sensors_init(_ffi.NULL)

    chip_nr = _ffi.new("int [1]")
    feature_nr = _ffi.new("int [1]")
    rails = {}
    chip_nr[0] = 0
    cn = _lib.sensors_get_detected_chips(_ffi.NULL, chip_nr)
    while cn:
        feature_nr[0] = 0
        feature = _lib.sensors_get_features(cn, feature_nr)
        while feature:
            name = _ffi.string(_lib.sensors_get_label(cn, feature)).decode()
            subfeature = None
            if feature.type == _lib.SENSORS_FEATURE_POWER:
                subfeature = _lib.sensors_get_subfeature(
                        cn, feature, _lib.SENSORS_SUBFEATURE_POWER_INPUT)
                feature_type = "power"
                unit = "W"
            elif feature.type == _lib.SENSORS_FEATURE_IN:
                subfeature = _lib.sensors_get_subfeature(
                        cn, feature, _lib.SENSORS_SUBFEATURE_IN_INPUT)
                feature_type = "voltage"
                unit = "V"
            elif feature.type == _lib.SENSORS_FEATURE_CURR:
                subfeature = _lib.sensors_get_subfeature(
                        cn, feature, _lib.SENSORS_SUBFEATURE_CURR_INPUT)
                feature_type = "current"
                unit = "A"
            if subfeature:
                if name not in rails:
                    rails[name] = Rail(name)
                setattr(rails[name], feature_type,
                        Sensor(cn, subfeature.number, unit, "{}_{}".format(
                            name, feature_type)))
            feature = _lib.sensors_get_features(cn, feature_nr)
        cn = _lib.sensors_get_detected_chips(_ffi.NULL, chip_nr)
    return rails


def get_rails(config_file=None):
    """Returns a dictionary of power rails

    Parameters
    ----------
    config_file : str
        Path to a configuration file for libsensors to use
        in place of the the system-wide default

    Returns
    -------
    dict {str : Rail}
        Dictionary of power rails with the name of the rail as
        the key and a Rail object as the value

    """
    return _enumerate_sensors(config_file)


class MultiSensor:
    """Class for efficiently collecting the readings from multiple sensors

    """
    def __init__(self, sensors):
        self._sensors = sensors

    def get_values(self):
        stored = {}
        return tuple((self._get_value(s, stored) for s in self._sensors))

    def _get_value(self, sensor, stored):
        if sensor in stored:
            return stored[sensor]
        value = sensor.get_value([self._get_value(p, stored) for p in sensor.parents])
        stored[sensor] = value
        return value

class DataRecorder:
    """Class to record sensors during an execution
    The DataRecorder provides a way of recording sensor data using a
    `with` block.
    """
    def __init__(self, *sensors):
        """Create a new DataRecorder attached to the specified sensors
        """
        import pandas as pd

        self._record_index = -1
        self._sensors = sensors
        self._getter = MultiSensor(sensors)
        self._columns = ['Mark']
        self._times = []
        self._columns.extend([s.name for s in sensors])
        self._frame = pd.DataFrame(columns=self._columns,
                                   index = pd.DatetimeIndex([]),
                                   dtype='f4')
        self._callbacks = []
        self._data = []
        self._thread = None

    def __del__(self):
        if self._thread:
            self.stop()

    def reset(self):
        """Clear the internal state of the data recorder without
        forgetting which sensors to record
        """
        self._frame.drop(self._frame.index, inplace=True)
        self._record_index = -1

    def record(self, interval):
        """Start recording
        """
        if self._thread:
            raise RuntimeError("DataRecorder is already recording")
        self._thread = threading.Thread(
                target=DataRecorder._thread_func, args=[self])
        self._interval = interval
        self._done = False
        self._record_index += 1
        self._thread.start()
        return self

    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        self.stop()
        return

    def stop(self):
        """Stops recording
        """
        self._done = True
        self._thread.join()
        self._thread = None

    def mark(self):
        """Increment the Invocation count
        """
        self._record_index += 1
        return self._record_index

    def _thread_func(self):
        import pandas as pd

        while not self._done:
            row = [self._record_index]
            row.extend(self._getter.get_values())
            self._frame.loc[pd.Timestamp.now()] = row
            time.sleep(self._interval)

    @property
    def frame(self):
        """Return a pandas DataFrame of the recorded data
        The frame consists of the following fields
        Index : The timestamp of the measurement
        Mark : counts the number of times that record or mark was called
        Sensors* : one column per sensor
        """
        return self._frame
