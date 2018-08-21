__author__ = "Kevin Anderson"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

from pynq.lib.gpio_abc import GPIO_Input

class Button(object):
	def __init__(self, device, length=1):
		if(isinstance(device, GPIO_Input)):
			self._impl = device
			self._length = length
		else:
			raise TypeError("Object must contain methods: " + str(GPIO_Input.methods))
	
	def read(self):
		return self._impl.read()

	def wait_for_value(self, value):
		self._impl.wait_for_value(value)

	def __len__(self):
		return self._length;
