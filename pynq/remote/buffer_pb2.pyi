from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class CacheableRequest(_message.Message):
    __slots__ = ("buffer_id",)
    BUFFER_ID_FIELD_NUMBER: _ClassVar[int]
    buffer_id: str
    def __init__(self, buffer_id: _Optional[str] = ...) -> None: ...

class CacheableResponse(_message.Message):
    __slots__ = ("msg", "cacheable")
    MSG_FIELD_NUMBER: _ClassVar[int]
    CACHEABLE_FIELD_NUMBER: _ClassVar[int]
    msg: str
    cacheable: bool
    def __init__(self, msg: _Optional[str] = ..., cacheable: bool = ...) -> None: ...

class AddressRequest(_message.Message):
    __slots__ = ("buffer_id",)
    BUFFER_ID_FIELD_NUMBER: _ClassVar[int]
    buffer_id: str
    def __init__(self, buffer_id: _Optional[str] = ...) -> None: ...

class AddressResponse(_message.Message):
    __slots__ = ("msg", "address")
    MSG_FIELD_NUMBER: _ClassVar[int]
    ADDRESS_FIELD_NUMBER: _ClassVar[int]
    msg: str
    address: int
    def __init__(self, msg: _Optional[str] = ..., address: _Optional[int] = ...) -> None: ...

class InvalidateRequest(_message.Message):
    __slots__ = ("buffer_id",)
    BUFFER_ID_FIELD_NUMBER: _ClassVar[int]
    buffer_id: str
    def __init__(self, buffer_id: _Optional[str] = ...) -> None: ...

class InvalidateResponse(_message.Message):
    __slots__ = ("msg",)
    MSG_FIELD_NUMBER: _ClassVar[int]
    msg: str
    def __init__(self, msg: _Optional[str] = ...) -> None: ...

class FlushRequest(_message.Message):
    __slots__ = ("buffer_id",)
    BUFFER_ID_FIELD_NUMBER: _ClassVar[int]
    buffer_id: str
    def __init__(self, buffer_id: _Optional[str] = ...) -> None: ...

class FlushResponse(_message.Message):
    __slots__ = ("msg",)
    MSG_FIELD_NUMBER: _ClassVar[int]
    msg: str
    def __init__(self, msg: _Optional[str] = ...) -> None: ...

class AllocateRequest(_message.Message):
    __slots__ = ("size", "dtype", "cacheable")
    SIZE_FIELD_NUMBER: _ClassVar[int]
    DTYPE_FIELD_NUMBER: _ClassVar[int]
    CACHEABLE_FIELD_NUMBER: _ClassVar[int]
    size: int
    dtype: str
    cacheable: bool
    def __init__(self, size: _Optional[int] = ..., dtype: _Optional[str] = ..., cacheable: bool = ...) -> None: ...

class AllocateResponse(_message.Message):
    __slots__ = ("msg", "buffer_id")
    MSG_FIELD_NUMBER: _ClassVar[int]
    BUFFER_ID_FIELD_NUMBER: _ClassVar[int]
    msg: str
    buffer_id: str
    def __init__(self, msg: _Optional[str] = ..., buffer_id: _Optional[str] = ...) -> None: ...

class BufferWriteRequest(_message.Message):
    __slots__ = ("buffer_id", "data", "start", "end")
    BUFFER_ID_FIELD_NUMBER: _ClassVar[int]
    DATA_FIELD_NUMBER: _ClassVar[int]
    START_FIELD_NUMBER: _ClassVar[int]
    END_FIELD_NUMBER: _ClassVar[int]
    buffer_id: str
    data: bytes
    start: int
    end: int
    def __init__(self, buffer_id: _Optional[str] = ..., data: _Optional[bytes] = ..., start: _Optional[int] = ..., end: _Optional[int] = ...) -> None: ...

class BufferWriteResponse(_message.Message):
    __slots__ = ("msg",)
    MSG_FIELD_NUMBER: _ClassVar[int]
    msg: str
    def __init__(self, msg: _Optional[str] = ...) -> None: ...

class BufferReadRequest(_message.Message):
    __slots__ = ("buffer_id", "start", "end")
    BUFFER_ID_FIELD_NUMBER: _ClassVar[int]
    START_FIELD_NUMBER: _ClassVar[int]
    END_FIELD_NUMBER: _ClassVar[int]
    buffer_id: str
    start: int
    end: int
    def __init__(self, buffer_id: _Optional[str] = ..., start: _Optional[int] = ..., end: _Optional[int] = ...) -> None: ...

class BufferReadResponse(_message.Message):
    __slots__ = ("msg", "data")
    MSG_FIELD_NUMBER: _ClassVar[int]
    DATA_FIELD_NUMBER: _ClassVar[int]
    msg: str
    data: bytes
    def __init__(self, msg: _Optional[str] = ..., data: _Optional[bytes] = ...) -> None: ...

class FreeBufferRequest(_message.Message):
    __slots__ = ("buffer_id",)
    BUFFER_ID_FIELD_NUMBER: _ClassVar[int]
    buffer_id: str
    def __init__(self, buffer_id: _Optional[str] = ...) -> None: ...

class FreeBufferResponse(_message.Message):
    __slots__ = ("msg",)
    MSG_FIELD_NUMBER: _ClassVar[int]
    msg: str
    def __init__(self, msg: _Optional[str] = ...) -> None: ...
