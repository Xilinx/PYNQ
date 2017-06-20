import pynq
import pynq.lib
import pynq.lib.video
import pynq.lib.audio

class BaseOverlay(pynq.DefaultOverlay):
    """ The Base overlay for the Pynq-Z1

    This overlay is designed to interact with all of the on board peripherals
    and external interfaces of the Pynq-Z1 board. It exposes the following
    attributes:

    Attributes
    ----------
    pmoda : IOP
         IO processor connected to the PMODA interface
    pmodb : IOP
         IO processor connected to the PMODB interface
    arduino : IOP
         IO processor connected to the Arduino/ChipKit interface
    leds : AxiGPIO
         4-bit output GPIO for interacting with the green LEDs LD0-3
    buttons : AxiGPIO
         4-bit input GPIO for interacting with the buttons BTN0-3
    switches : AxiGPIO
         2-bit input GPIO for interacting with the switches SW0 and SW1
    rgbleds : [pynq.board.RGBLED]
         Wrapper for GPIO for LD4 and LD5 multicolour LEDs
    video : pynq.lib.video.HDMIWrapper
         HDMI input and output interfaces
    audio : pynq.lib.audio.Audio
         Headphone jack and on-board microphone

    """
    def __init__(self, bitfile, download):
        super().__init__(bitfile, download)
        if self.is_loaded():
            self.pmoda = self.iop1
            self.pmodb = self.iop2
            self.arduino = self.iop3

            self.pmoda.mbtype = "PMOD"
            self.pmodb.mbtype = "PMOD"
            self.arduino.mbtype = "Arduino"

            self.leds = self.swsleds_gpio.channel2
            self.switches = self.swsleds_gpio.channel1
            self.buttons = self.btns_gpio.channel1
            self.leds.setlength(4)
            self.switches.setlength(4)
            self.buttons.setlength(4)
            self.leds.setdirection(pynq.lib.AxiGPIO.Output)
            self.switches.setdirection(pynq.lib.AxiGPIO.Input)
            self.buttons.setdirection(pynq.lib.AxiGPIO.Input)

            self.rgbleds = ([None] * 4) + [pynq.lib.RGBLED(i) for i in range(4,6)]

Overlay = BaseOverlay
