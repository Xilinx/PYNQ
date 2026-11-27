from google.protobuf.internal import containers as _containers
from google.protobuf.internal import enum_type_wrapper as _enum_type_wrapper
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Iterable as _Iterable, Mapping as _Mapping, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class InterruptStateRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class InterruptStateResponse(_message.Message):
    __slots__ = ("generation",)
    GENERATION_FIELD_NUMBER: _ClassVar[int]
    generation: str
    def __init__(self, generation: _Optional[str] = ...) -> None: ...

class CompleteDownloadRequest(_message.Message):
    __slots__ = ("generation",)
    GENERATION_FIELD_NUMBER: _ClassVar[int]
    generation: str
    def __init__(self, generation: _Optional[str] = ...) -> None: ...

class CompleteDownloadResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class InterruptRoute(_message.Message):
    __slots__ = ("address", "index")
    ADDRESS_FIELD_NUMBER: _ClassVar[int]
    INDEX_FIELD_NUMBER: _ClassVar[int]
    address: int
    index: int
    def __init__(self, address: _Optional[int] = ..., index: _Optional[int] = ...) -> None: ...

class InterruptRequest(_message.Message):
    __slots__ = ("operation", "subscription", "sequence", "generation", "raw_irq", "route")
    class Operation(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
        __slots__ = ()
        ACQUIRE: _ClassVar[InterruptRequest.Operation]
        ARM: _ClassVar[InterruptRequest.Operation]
        CANCEL: _ClassVar[InterruptRequest.Operation]
        RELEASE: _ClassVar[InterruptRequest.Operation]
    ACQUIRE: InterruptRequest.Operation
    ARM: InterruptRequest.Operation
    CANCEL: InterruptRequest.Operation
    RELEASE: InterruptRequest.Operation
    OPERATION_FIELD_NUMBER: _ClassVar[int]
    SUBSCRIPTION_FIELD_NUMBER: _ClassVar[int]
    SEQUENCE_FIELD_NUMBER: _ClassVar[int]
    GENERATION_FIELD_NUMBER: _ClassVar[int]
    RAW_IRQ_FIELD_NUMBER: _ClassVar[int]
    ROUTE_FIELD_NUMBER: _ClassVar[int]
    operation: InterruptRequest.Operation
    subscription: int
    sequence: int
    generation: str
    raw_irq: int
    route: _containers.RepeatedCompositeFieldContainer[InterruptRoute]
    def __init__(self, operation: _Optional[_Union[InterruptRequest.Operation, str]] = ..., subscription: _Optional[int] = ..., sequence: _Optional[int] = ..., generation: _Optional[str] = ..., raw_irq: _Optional[int] = ..., route: _Optional[_Iterable[_Union[InterruptRoute, _Mapping]]] = ...) -> None: ...

class InterruptResponse(_message.Message):
    __slots__ = ("event", "subscription", "sequence", "message")
    class Event(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
        __slots__ = ()
        ACQUIRED: _ClassVar[InterruptResponse.Event]
        ARMED: _ClassVar[InterruptResponse.Event]
        CANCELLED: _ClassVar[InterruptResponse.Event]
        RELEASED: _ClassVar[InterruptResponse.Event]
        FIRED: _ClassVar[InterruptResponse.Event]
        ERROR: _ClassVar[InterruptResponse.Event]
    ACQUIRED: InterruptResponse.Event
    ARMED: InterruptResponse.Event
    CANCELLED: InterruptResponse.Event
    RELEASED: InterruptResponse.Event
    FIRED: InterruptResponse.Event
    ERROR: InterruptResponse.Event
    EVENT_FIELD_NUMBER: _ClassVar[int]
    SUBSCRIPTION_FIELD_NUMBER: _ClassVar[int]
    SEQUENCE_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    event: InterruptResponse.Event
    subscription: int
    sequence: int
    message: str
    def __init__(self, event: _Optional[_Union[InterruptResponse.Event, str]] = ..., subscription: _Optional[int] = ..., sequence: _Optional[int] = ..., message: _Optional[str] = ...) -> None: ...

class ReadFileRequest(_message.Message):
    __slots__ = ("file_path",)
    FILE_PATH_FIELD_NUMBER: _ClassVar[int]
    file_path: str
    def __init__(self, file_path: _Optional[str] = ...) -> None: ...

class ReadFileResponse(_message.Message):
    __slots__ = ("data",)
    DATA_FIELD_NUMBER: _ClassVar[int]
    data: bytes
    def __init__(self, data: _Optional[bytes] = ...) -> None: ...

class WriteFileRequest(_message.Message):
    __slots__ = ("file_path", "data", "defer_interrupts")
    FILE_PATH_FIELD_NUMBER: _ClassVar[int]
    DATA_FIELD_NUMBER: _ClassVar[int]
    DEFER_INTERRUPTS_FIELD_NUMBER: _ClassVar[int]
    file_path: str
    data: bytes
    defer_interrupts: bool
    def __init__(self, file_path: _Optional[str] = ..., data: _Optional[bytes] = ..., defer_interrupts: bool = ...) -> None: ...

class WriteFileResponse(_message.Message):
    __slots__ = ("interrupt_generation",)
    INTERRUPT_GENERATION_FIELD_NUMBER: _ClassVar[int]
    interrupt_generation: str
    def __init__(self, interrupt_generation: _Optional[str] = ...) -> None: ...

class ExistsFileRequest(_message.Message):
    __slots__ = ("file_path",)
    FILE_PATH_FIELD_NUMBER: _ClassVar[int]
    file_path: str
    def __init__(self, file_path: _Optional[str] = ...) -> None: ...

class ExistsFileResponse(_message.Message):
    __slots__ = ("exists",)
    EXISTS_FIELD_NUMBER: _ClassVar[int]
    exists: bool
    def __init__(self, exists: bool = ...) -> None: ...

class MakeDirRequest(_message.Message):
    __slots__ = ("dir_path",)
    DIR_PATH_FIELD_NUMBER: _ClassVar[int]
    dir_path: str
    def __init__(self, dir_path: _Optional[str] = ...) -> None: ...

class MakeDirResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class RemoveDirRequest(_message.Message):
    __slots__ = ("dir_path",)
    DIR_PATH_FIELD_NUMBER: _ClassVar[int]
    dir_path: str
    def __init__(self, dir_path: _Optional[str] = ...) -> None: ...

class RemoveDirResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class SetBitstreamAttrsRequest(_message.Message):
    __slots__ = ("binfile_name", "partial")
    BINFILE_NAME_FIELD_NUMBER: _ClassVar[int]
    PARTIAL_FIELD_NUMBER: _ClassVar[int]
    binfile_name: str
    partial: bool
    def __init__(self, binfile_name: _Optional[str] = ..., partial: bool = ...) -> None: ...

class SetBitstreamAttrsResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: bool
    def __init__(self, status: bool = ...) -> None: ...

class ShutdownRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class ShutdownResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: bool
    def __init__(self, status: bool = ...) -> None: ...

class SetPlClkRequest(_message.Message):
    __slots__ = ("i", "div0", "div1", "clk_mhz")
    I_FIELD_NUMBER: _ClassVar[int]
    DIV0_FIELD_NUMBER: _ClassVar[int]
    DIV1_FIELD_NUMBER: _ClassVar[int]
    CLK_MHZ_FIELD_NUMBER: _ClassVar[int]
    i: int
    div0: int
    div1: int
    clk_mhz: int
    def __init__(self, i: _Optional[int] = ..., div0: _Optional[int] = ..., div1: _Optional[int] = ..., clk_mhz: _Optional[int] = ...) -> None: ...

class SetPlClkResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: bool
    def __init__(self, status: bool = ...) -> None: ...

class DownloadRequest(_message.Message):
    __slots__ = ("buffer",)
    BUFFER_FIELD_NUMBER: _ClassVar[int]
    buffer: bytes
    def __init__(self, buffer: _Optional[bytes] = ...) -> None: ...

class DownloadResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: bool
    def __init__(self, status: bool = ...) -> None: ...

class DeviceTreeRequest(_message.Message):
    __slots__ = ("name", "data", "remove", "clear")
    NAME_FIELD_NUMBER: _ClassVar[int]
    DATA_FIELD_NUMBER: _ClassVar[int]
    REMOVE_FIELD_NUMBER: _ClassVar[int]
    CLEAR_FIELD_NUMBER: _ClassVar[int]
    name: str
    data: bytes
    remove: bool
    clear: bool
    def __init__(self, name: _Optional[str] = ..., data: _Optional[bytes] = ..., remove: bool = ..., clear: bool = ...) -> None: ...

class DeviceTreeResponse(_message.Message):
    __slots__ = ("applied",)
    APPLIED_FIELD_NUMBER: _ClassVar[int]
    applied: bool
    def __init__(self, applied: bool = ...) -> None: ...
