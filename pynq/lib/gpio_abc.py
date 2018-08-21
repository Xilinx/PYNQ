import asyncio
from abc import ABC


class GPIO_Input(ABC):
	
	methods = ['read', 'wait_for_value']

	def read(self):
		return

	def wait_for_value(self, value):
		pass

class GPIO_Output(ABC):

	methods = ['read', 'write', 'on', 'off', 'toggle']

	def read(self):
		return

	def write(self):
		pass

	def on(self):
		pass

	def off(self):
		pass

	def toggle(self):
		pass
