__author__ = "Kevin Anderson"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

from pynq.lib.gpio_abc import GPIO_Output

class LED(object):
	def __init__(self, device, length=1):
		if(isinstance(device, GPIO_Output)):
			self._impl = device
			self._length = length
		else:
		 	raise TypeError("Object must contain methods: " + str(GPIO_Output.methods))

	def on(self):
		self._impl.on()

	def off(self):
		self._impl.off()

	def toggle(self):
		self._impl.toggle()

	def __len__(self):
		return self._length;
