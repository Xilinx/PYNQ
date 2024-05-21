# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

from pynqmetadata import MetadataExtension
from pydantic import Field

class XrtExtension(MetadataExtension):
    """ extends the metadata to include XRT information"""
    xrt_mem_idx: int = Field(..., exclude=True, description="Index for the XRT reference")
    raw_type:str = Field(..., exclude=True, description="XRT type info")
    base_address:int = Field(..., exclude=True,description="Base address for XRT (for IP, should be the same as the physical address in the metadata") 
    size:int = Field(...,exclude=True,description="Size of the memory region (for IP, should be the same as the range)")
    streaming:bool = Field(...,exclude=True,description="True if this memory region accessed in a streaming fashion.")
    idx:int = Field(...,exclude=True,description="The XRT index of this memory region, I believe that this is always the same as xrt_mem_idx")
    tag:str = Field(...,exclude=True,description="A tag that is related to the XRT memory location")


