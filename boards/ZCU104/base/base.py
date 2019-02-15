import pynq
import pynq.lib
import time
from pynq.lib.video.clocks import *


class BaseOverlay(pynq.Overlay):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.is_loaded():
            self.iop_pmod0.mbtype = "Pmod"
            self.iop_pmod1.mbtype = "Pmod"
            self.PMOD0 = self.iop_pmod0.mb_info
            self.PMOD1 = self.iop_pmod1.mb_info
            self.PMODA = self.PMOD0
            self.PMODB = self.PMOD1
            self.leds = self.gpio_leds.channel1
            self.leds.setdirection('out')
            self.leds.setlength(4)
            self.buttons = self.gpio_btns.channel1
            self.buttons.setdirection('in')
            self.buttons.setlength(4)
            self.switches = self.gpio_sws.channel1
            self.switches.setdirection('in')
            self.switches.setlength(4)

    def download(self):
        super().download()
        self._init_clocks()

    def _init_clocks(self):
        # Wait for AXI reset to de-assert
        time.sleep(0.2)
        # Deassert HDMI clock reset
        self.reset_control.channel1[0].write(1)
        # Wait 200 ms for the clock to come out of reset
        time.sleep(0.2)

        self.video.phy.vid_phy_controller.initialize()
        self.video.hdmi_in.frontend.set_phy(
                self.video.phy.vid_phy_controller)
        self.video.hdmi_out.frontend.set_phy(
                self.video.phy.vid_phy_controller)
        dp159 = DP159(self.fmch_axi_iic, 0x5C)
        idt = IDT_8T49N24(self.fmch_axi_iic, 0x6C)
        self.video.hdmi_out.frontend.clocks = [dp159, idt]
