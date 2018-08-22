import pynq
import pynq.lib
import time
from pynq.lib.video.clocks import *
from pynq import MMIO

class BaseOverlay(pynq.Overlay):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.is_loaded():
            # Make sure this is set until we can do this automatically
            axi_config = MMIO(0xFF419000, 0x4)
            axi_config.write(0,0)
            # Wait for AXI reset to de-assert
            time.sleep(0.2)
            # Deassert HDMI clock reset
            self.reset_control.channel1[0].write(1)
            # Wait 200 ms for the clock to come out of reset
            time.sleep(0.2)
            self.iop_pmod0.mbtype = "Pmod"
            self.iop_pmod1.mbtype = "Pmod"
            self.video.hdmi_in.frontend.set_phy(
                    self.video.phy.vid_phy_controller)
            self.video.hdmi_out.frontend.set_phy(
                    self.video.phy.vid_phy_controller)
            dp159 = DP159(self.fmch_axi_iic, 0x5C)
            idt = IDT_8T49N24(self.fmch_axi_iic, 0x6C)
            self.video.hdmi_out.frontend.clocks.extend([dp159, idt])
            self.PMOD0 = self.iop_pmod0.mb_info
            self.PMOD1 = self.iop_pmod1.mb_info
            self.PMODA = self.PMOD0
            self.PMODB = self.PMOD1
