__author__ = "Kevin Anderson"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

class LED(object):
	def __init__(self, device, length=1):
		methods = ['on', 'off', 'toggle']
		if(all(m in dir(device) for m in methods)):
			self._impl = device
		else:
		 	raise TypeError("Object must contain LED methods: %s", dir(self))  # <<<  Should it raise an Exception????

	def on(self):
		self._impl.on()

	def off(self):
		self._impl.off()

	def toggle(self):
		self._impl.toggle()

	def __len__(self):
		return 1;
