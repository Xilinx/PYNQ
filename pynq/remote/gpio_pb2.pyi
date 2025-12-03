from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class GetGpioRequest(_message.Message):
    __slots__ = ("index", "direction")
    INDEX_FIELD_NUMBER: _ClassVar[int]
    DIRECTION_FIELD_NUMBER: _ClassVar[int]
    index: int
    direction: str
    def __init__(self, index: _Optional[int] = ..., direction: _Optional[str] = ...) -> None: ...

class GetGpioResponse(_message.Message):
    __slots__ = ("message", "gpio_id")
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    GPIO_ID_FIELD_NUMBER: _ClassVar[int]
    message: str
    gpio_id: str
    def __init__(self, message: _Optional[str] = ..., gpio_id: _Optional[str] = ...) -> None: ...

class GpioReadRequest(_message.Message):
    __slots__ = ("gpio_id",)
    GPIO_ID_FIELD_NUMBER: _ClassVar[int]
    gpio_id: str
    def __init__(self, gpio_id: _Optional[str] = ...) -> None: ...

class GpioReadResponse(_message.Message):
    __slots__ = ("message", "value")
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    message: str
    value: int
    def __init__(self, message: _Optional[str] = ..., value: _Optional[int] = ...) -> None: ...

class GpioWriteRequest(_message.Message):
    __slots__ = ("gpio_id", "value")
    GPIO_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    gpio_id: str
    value: int
    def __init__(self, gpio_id: _Optional[str] = ..., value: _Optional[int] = ...) -> None: ...

class GpioWriteResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class GpioUnexportRequest(_message.Message):
    __slots__ = ("gpio_id",)
    GPIO_ID_FIELD_NUMBER: _ClassVar[int]
    gpio_id: str
    def __init__(self, gpio_id: _Optional[str] = ...) -> None: ...

class GpioUnexportResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class GpioIsExportedRequest(_message.Message):
    __slots__ = ("gpio_id",)
    GPIO_ID_FIELD_NUMBER: _ClassVar[int]
    gpio_id: str
    def __init__(self, gpio_id: _Optional[str] = ...) -> None: ...

class GpioIsExportedResponse(_message.Message):
    __slots__ = ("is_exported",)
    IS_EXPORTED_FIELD_NUMBER: _ClassVar[int]
    is_exported: bool
    def __init__(self, is_exported: bool = ...) -> None: ...

class GetGpioBasePathRequest(_message.Message):
    __slots__ = ("target_label",)
    TARGET_LABEL_FIELD_NUMBER: _ClassVar[int]
    target_label: str
    def __init__(self, target_label: _Optional[str] = ...) -> None: ...

class GetGpioBasePathResponse(_message.Message):
    __slots__ = ("base_path",)
    BASE_PATH_FIELD_NUMBER: _ClassVar[int]
    base_path: str
    def __init__(self, base_path: _Optional[str] = ...) -> None: ...

class GetGpioNPinsRequest(_message.Message):
    __slots__ = ("target_label",)
    TARGET_LABEL_FIELD_NUMBER: _ClassVar[int]
    target_label: str
    def __init__(self, target_label: _Optional[str] = ...) -> None: ...

class GetGpioNPinsResponse(_message.Message):
    __slots__ = ("npins",)
    NPINS_FIELD_NUMBER: _ClassVar[int]
    npins: int
    def __init__(self, npins: _Optional[int] = ...) -> None: ...
