from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class GetMmioRequest(_message.Message):
    __slots__ = ("base_addr", "length")
    BASE_ADDR_FIELD_NUMBER: _ClassVar[int]
    LENGTH_FIELD_NUMBER: _ClassVar[int]
    base_addr: int
    length: int
    def __init__(self, base_addr: _Optional[int] = ..., length: _Optional[int] = ...) -> None: ...

class GetMmioResponse(_message.Message):
    __slots__ = ("status", "msg", "mmio_id")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    MSG_FIELD_NUMBER: _ClassVar[int]
    MMIO_ID_FIELD_NUMBER: _ClassVar[int]
    status: bool
    msg: str
    mmio_id: str
    def __init__(self, status: bool = ..., msg: _Optional[str] = ..., mmio_id: _Optional[str] = ...) -> None: ...

class ReadRequest(_message.Message):
    __slots__ = ("mmio_id", "length", "offset", "word_order")
    MMIO_ID_FIELD_NUMBER: _ClassVar[int]
    LENGTH_FIELD_NUMBER: _ClassVar[int]
    OFFSET_FIELD_NUMBER: _ClassVar[int]
    WORD_ORDER_FIELD_NUMBER: _ClassVar[int]
    mmio_id: str
    length: int
    offset: int
    word_order: str
    def __init__(self, mmio_id: _Optional[str] = ..., length: _Optional[int] = ..., offset: _Optional[int] = ..., word_order: _Optional[str] = ...) -> None: ...

class ReadResponse(_message.Message):
    __slots__ = ("status", "msg", "data")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    MSG_FIELD_NUMBER: _ClassVar[int]
    DATA_FIELD_NUMBER: _ClassVar[int]
    status: bool
    msg: str
    data: int
    def __init__(self, status: bool = ..., msg: _Optional[str] = ..., data: _Optional[int] = ...) -> None: ...

class WriteRequest(_message.Message):
    __slots__ = ("mmio_id", "offset", "data")
    MMIO_ID_FIELD_NUMBER: _ClassVar[int]
    OFFSET_FIELD_NUMBER: _ClassVar[int]
    DATA_FIELD_NUMBER: _ClassVar[int]
    mmio_id: str
    offset: int
    data: bytes
    def __init__(self, mmio_id: _Optional[str] = ..., offset: _Optional[int] = ..., data: _Optional[bytes] = ...) -> None: ...

class WriteResponse(_message.Message):
    __slots__ = ("status", "msg")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    MSG_FIELD_NUMBER: _ClassVar[int]
    status: bool
    msg: str
    def __init__(self, status: bool = ..., msg: _Optional[str] = ...) -> None: ...
