from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Iterable as _Iterable, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class FindDevicesRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class FindDevicesResponse(_message.Message):
    __slots__ = ("lmk_device", "lmx_device")
    LMK_DEVICE_FIELD_NUMBER: _ClassVar[int]
    LMX_DEVICE_FIELD_NUMBER: _ClassVar[int]
    lmk_device: str
    lmx_device: str
    def __init__(self, lmk_device: _Optional[str] = ..., lmx_device: _Optional[str] = ...) -> None: ...

class WriteLmkRegsRequest(_message.Message):
    __slots__ = ("reg_vals",)
    REG_VALS_FIELD_NUMBER: _ClassVar[int]
    reg_vals: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, reg_vals: _Optional[_Iterable[int]] = ...) -> None: ...

class WriteLmkRegsResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class WriteLmxRegsRequest(_message.Message):
    __slots__ = ("reg_vals",)
    REG_VALS_FIELD_NUMBER: _ClassVar[int]
    reg_vals: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, reg_vals: _Optional[_Iterable[int]] = ...) -> None: ...

class WriteLmxRegsResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class ProgramLmkRequest(_message.Message):
    __slots__ = ("freq",)
    FREQ_FIELD_NUMBER: _ClassVar[int]
    freq: float
    def __init__(self, freq: _Optional[float] = ...) -> None: ...

class ProgramLmkResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class ProgramLmxRequest(_message.Message):
    __slots__ = ("freq",)
    FREQ_FIELD_NUMBER: _ClassVar[int]
    freq: float
    def __init__(self, freq: _Optional[float] = ...) -> None: ...

class ProgramLmxResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...
