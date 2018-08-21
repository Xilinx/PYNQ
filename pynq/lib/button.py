__author__ = "Kevin Anderson"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

import asyncio

class Button(object):
	def __init__(self, device, length=1):
		methods = ['read', 'wait_for_value_async', 'wait_for_value']
		if(all(m in dir(device) for m in methods)):
			self._impl = device
		else:
			raise TypeError("Object must contain LED methods: %s", methods)
	
	def read(self):
		return self._impl.read()

	def wait_for_value(self, value):
		self._impl.wait_for_value(value)
