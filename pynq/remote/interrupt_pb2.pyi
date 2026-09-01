from google.protobuf.internal import enum_type_wrapper as _enum_type_wrapper
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class RegisterRequest(_message.Message):
    __slots__ = ("pin_name", "pin_index", "raw_irq", "controller_phys_addr")
    PIN_NAME_FIELD_NUMBER: _ClassVar[int]
    PIN_INDEX_FIELD_NUMBER: _ClassVar[int]
    RAW_IRQ_FIELD_NUMBER: _ClassVar[int]
    CONTROLLER_PHYS_ADDR_FIELD_NUMBER: _ClassVar[int]
    pin_name: str
    pin_index: int
    raw_irq: int
    controller_phys_addr: int
    def __init__(self, pin_name: _Optional[str] = ..., pin_index: _Optional[int] = ..., raw_irq: _Optional[int] = ..., controller_phys_addr: _Optional[int] = ...) -> None: ...

class RegisterResponse(_message.Message):
    __slots__ = ("msg", "interrupt_id")
    MSG_FIELD_NUMBER: _ClassVar[int]
    INTERRUPT_ID_FIELD_NUMBER: _ClassVar[int]
    msg: str
    interrupt_id: str
    def __init__(self, msg: _Optional[str] = ..., interrupt_id: _Optional[str] = ...) -> None: ...

class WaitRequest(_message.Message):
    __slots__ = ("interrupt_id", "timeout_ms")
    INTERRUPT_ID_FIELD_NUMBER: _ClassVar[int]
    TIMEOUT_MS_FIELD_NUMBER: _ClassVar[int]
    interrupt_id: str
    timeout_ms: int
    def __init__(self, interrupt_id: _Optional[str] = ..., timeout_ms: _Optional[int] = ...) -> None: ...

class WaitResponse(_message.Message):
    __slots__ = ("status", "msg")
    class Status(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
        __slots__ = ()
        FIRED: _ClassVar[WaitResponse.Status]
        TIMEOUT: _ClassVar[WaitResponse.Status]
        ERROR: _ClassVar[WaitResponse.Status]
    FIRED: WaitResponse.Status
    TIMEOUT: WaitResponse.Status
    ERROR: WaitResponse.Status
    STATUS_FIELD_NUMBER: _ClassVar[int]
    MSG_FIELD_NUMBER: _ClassVar[int]
    status: WaitResponse.Status
    msg: str
    def __init__(self, status: _Optional[_Union[WaitResponse.Status, str]] = ..., msg: _Optional[str] = ...) -> None: ...

class ReleaseRequest(_message.Message):
    __slots__ = ("interrupt_id",)
    INTERRUPT_ID_FIELD_NUMBER: _ClassVar[int]
    interrupt_id: str
    def __init__(self, interrupt_id: _Optional[str] = ...) -> None: ...

class ReleaseResponse(_message.Message):
    __slots__ = ("msg",)
    MSG_FIELD_NUMBER: _ClassVar[int]
    msg: str
    def __init__(self, msg: _Optional[str] = ...) -> None: ...
