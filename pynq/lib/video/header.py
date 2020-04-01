#   Copyright (c) 2020, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

__author__ = "Parimal Patel"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


'''
/******************************************************************************
 * User settable defines that depend on the specific board design.
 * The defaults are for the Xilinx KC705 board.
 *****************************************************************************/

// The frequency of the crystal connected to the XA/XB pins of the Si5324 in Hz.
'''
SI5324_XTAL_FREQ=114285000
'''
/* Debug output enable. Set to TRUE to enable debug prints,
 * to FALSE to disable debug prints. */
'''
SI5324_DEBUG=0 #'FALSE'

'''
/** Low level debug. Set to TRUE to print computation output,
 * to FALSE to disable debug computation outpu prints. */
'''
SI5324_LOW_LEVEL_DEBUG=0 #'FALSE'

'''
/**The following constants are error codes generated by the functions in
 * this driver. */

 '''
SI5324_SUCCESS=0  #/**< Operation was successful */
SI5324_ERR_IIC=-1 #/**< IIC error occurred */
SI5324_ERR_FREQ=-2 #/**< Could not calculate frequency setting */
SI5324_ERR_PARM=-3 #/**< Invalid parameter */

'''
/** The following constants define the clock input select values. */
'''
SI5324_CLKSRC_CLK1=1  #/**< Use clock input 1 */
SI5324_CLKSRC_CLK2=2  #/**< Use clock input 2 */
SI5324_CLKSRC_XTAL=3  #/**< Use crystal (free running mode) */
'''
/** The following constants define the limits of the Si5324 frequencies.  */
'''
SI5324_FOSC_MIN=4850000000 #/**< Minimum oscillator frequency */
SI5324_FOSC_MAX=5670000000 #/**< Maximum oscillator frequency */
SI5324_F3_MIN=10000  #2000 /**< Minimum phase detector frequency */
SI5324_F3_MAX=2000000 #/**< Maximum phase detector frequency */
SI5324_FIN_MIN=2000 #/**< Minimum input frequency */
SI5324_FIN_MAX=710000000 #/**< Maximum input frequency */
SI5324_FOUT_MIN=2000 #/**< Minimum output frequency */
SI5324_FOUT_MAX=945000000 #/**< Maximum output frequency */
'''
/** The following constants define the limits of the divider settings. */
'''

SI5324_N1_HS_MIN=6        #/**< Minimum N1_HS setting (4 and 5 are for higher output frequencies than we support */
SI5324_N1_HS_MAX=11        #/**< Maximum N1_HS setting */
SI5324_NC_LS_MIN=1        #/**< Minimum NCn_LS setting (1 and even values) */
SI5324_NC_LS_MAX=0x100000  #/**< Maximum NCn_LS setting (1 and even values) */
SI5324_N2_HS_MIN=4        #/**< Minimum NC2_HS setting */
SI5324_N2_HS_MAX=11        #/**< Maximum NC2_HS setting */
SI5324_N2_LS_MIN=2        #/**< Minimum NC2_LS setting (even values only) */
SI5324_N2_LS_MAX=0x100000  #/**< Maximum NC2_LS setting (even values only) */
SI5324_N3_MIN=1        #/**< Minimum N3n setting */
SI5324_N3_MAX=0x080000  #/**< Maximum N3n setting */

