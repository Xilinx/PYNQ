"""Shared gRPC session state passed between host-side remote test modules."""

from dataclasses import dataclass, field
from typing import Any, Optional

RF_BOARDS = frozenset({"zcu208", "zcu111", "rfsoc4x2"})


@dataclass
class Context:
    ip: str
    port: int
    bitstream: Optional[str] = None
    np: Any = None
    dev: Any = None
    overlay: Any = None
    board_kind: str = ""
    imports: dict = field(default_factory=dict)

    @property
    def rf_board(self) -> bool:
        return self.board_kind in RF_BOARDS
