"""
Welcome to XilinxPythonProject

Press Preferences button above to select COM port for your Zybo board
Press Connect button above to access your MicroPython enabled Zybo board

Once Connected, Press Execute button above to run this script
                                                             --- OR ---
                                Enter Python code directly into terminal below
"""

# Print to Terminal
print("hello Xilinx Python")

# Turn on a single LED
from pyxi.board import LED
LED(0).on()
