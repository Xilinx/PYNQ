# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

from pynqmetadata import Module
from pynqmetadata.errors import FeatureNotYetImplemented
from typing import Dict
import json

def _default_repr(obj):
    return repr(obj)

class MetadataView:
    """ a base class for all the view objects onto the metadata.
        Contains commen operations across all the view classes,
        such as __getitem__ and iterators.
     """

    def __init__(self, module:Module)->None:
        self._md = module

    @property
    def view(self) -> Dict:
        """ Returns the dictionary view of the metadata,
        this should be overloaded in the subclass to actually 
        implement the view """
        return {}

    def items(self):
        return self.view.items()

    def __len__(self):
        return len(self.view)

    def __iter__(self):
        for item in self.view:
            yield item

    def _repr_json_(self) -> Dict:
        return json.loads(json.dumps(self.view, default=_default_repr))

    def __getitem__(self, key:str):
        return self.view[key]
        
    def keys(self):
        return self.view.keys()

    def __setitem__(self, key:str, value: object)->None:
        """ TODO: needs to send a value into the metadata model, bypassing ip_dict, 
        this will require translation in the other direction """
        raise FeatureNotYetImplemented("MetadataDictViews are currently only read only")