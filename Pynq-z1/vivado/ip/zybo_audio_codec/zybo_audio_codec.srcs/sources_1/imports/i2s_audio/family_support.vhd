--------------------------------------------------------------------------------
-- $Id: family_support.vhd,v 1.5.2.55 2010/12/16 15:10:57 ostlerf Exp $
--------------------------------------------------------------------------------
-- family_support.vhd - package
--------------------------------------------------------------------------------
--
-- *************************************************************************
-- **                                                                     **
-- ** DISCLAIMER OF LIABILITY                                             **
-- **                                                                     **
-- ** This text/file contains proprietary, confidential                   **
-- ** information of Xilinx, Inc., is distributed under                   **
-- ** license from Xilinx, Inc., and may be used, copied                  **
-- ** and/or disclosed only pursuant to the terms of a valid              **
-- ** license agreement with Xilinx, Inc. Xilinx hereby                   **
-- ** grants you a license to use this text/file solely for               **
-- ** design, simulation, implementation and creation of                  **
-- ** design files limited to Xilinx devices or technologies.             **
-- ** Use with non-Xilinx devices or technologies is expressly            **
-- ** prohibited and immediately terminates your license unless           **
-- ** covered by a separate agreement.                                    **
-- **                                                                     **
-- ** Xilinx is providing this design, code, or information               **
-- ** "as-is" solely for use in developing programs and                   **
-- ** solutions for Xilinx devices, with no obligation on the             **
-- ** part of Xilinx to provide support. By providing this design,        **
-- ** code, or information as one possible implementation of              **
-- ** this feature, application or standard, Xilinx is making no          **
-- ** representation that this implementation is free from any            **
-- ** claims of infringement. You are responsible for obtaining           **
-- ** any rights you may require for your implementation.                 **
-- ** Xilinx expressly disclaims any warranty whatsoever with             **
-- ** respect to the adequacy of the implementation, including            **
-- ** but not limited to any warranties or representations that this      **
-- ** implementation is free from claims of infringement, implied         **
-- ** warranties of merchantability or fitness for a particular           **
-- ** purpose.                                                            **
-- **                                                                     **
-- ** Xilinx products are not intended for use in life support            **
-- ** appliances, devices, or systems. Use in such applications is        **
-- ** expressly prohibited.                                               **
-- **                                                                     **
-- ** Any modifications that are made to the Source Code are              **
-- ** done at the user’s sole risk and will be unsupported.               **
-- ** The Xilinx Support Hotline does not have access to source           **
-- ** code and therefore cannot answer specific questions related         **
-- ** to source HDL. The Xilinx Hotline support of original source        **
-- ** code IP shall only address issues and questions related             **
-- ** to the standard Netlist version of the core (and thus               **
-- ** indirectly, the original core source).                              **
-- **                                                                     **
-- ** Copyright (c) 2005-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
--------------------------------------------------------------------------------
-- Filename:   family_support.vhd
--
-- Description: 
--
--      FAMILIES, PRIMITIVES and PRIMITIVE AVAILABILITY GUARDS
--
--              This package allows to determine whether a given primitive
--              or set of primitives is available in an FPGA family of interest.
--
--              The key element is the function, 'supported', which is
--              available in four variants (overloads). Here are examples
--              of each:
--
--                supported(virtex2, u_RAMB16_S2)
--    
--                supported("Virtex2", u_RAMB16_S2)
--    
--                supported(spartan3, (u_MUXCY, u_XORCY, u_FD))
--
--                supported("spartan3", (u_MUXCY, u_XORCY, u_FD))
--
--              The 'supported' function returns true if and only
--              if all of the primitives being tested, as given in the
--              second argument, are available in the FPGA family that
--              is given in the first argument.
--
--              The first argument can be either one of the FPGA family
--              names from the enumeration type, 'families_type', or a
--              (case insensitive) string giving the same information.
--              The family name 'nofamily' is special and supports
--              none of the primitives.
--
--              The second argument is either a primitive or a list of
--              primitives. The set of primitive names that can be
--              tested is defined by the declaration of the
--              enumeration type, 'primitives_type'. The names are
--              the UNISIM-library names for the primitives, prefixed
--              by "u_". (The prefix avoids introducing a name that
--              conflicts with the component declaration for the primitive.)
--               
--              The array type, 'primitive_array_type' is the basis for
--              forming lists of primitives. Typically, a fixed list
--              of primitves is expressed as a VHDL aggregate, a
--              comma separated list of primitives enclosed in
--              parentheses. (See the last two examples, above.)
--
--              The 'supported' function can be used as a guard
--              condition for a piece of code that depends on primitives
--              (primitive availability guard). Here is an example:
--
--
--                  GEN : if supported(C_FAMILY, (u_MUXCY, u_XORCY)) generate
--                  begin
--                        ... Here, an implementation that depends on
--                        ... MUXCY and XORCY.
--                  end generate;
--
--
--              It can also be used in an assertion statement
--              to give warnings about problems that can arise from
--              attempting to implement into a family that does not
--              support all of the required primitives:
--
--
--                  assert supported(C_FAMILY, <primtive list>)
--                    report "This module cannot be implemnted " &
--                           "into family, " & C_FAMILY &
--                           ", because one or more of the primitives, " &
--                           "<primitive_list>" & ", is not supported."
--                    severity error;
--
--
--      A NOTE ON USAGE
--
--              It is probably best to take an exception to the coding
--              guidelines and make the names that are needed
--              from this package visible to a VHDL compilation unit by
--
--                  library <libname>;
--                  use     <libname>.family_support.all;
--
--              rather than by calling out individual names in use clauses.
--              (VHDL tools do not have a common interpretation at present
--              on whether
--
--                  use <libname>.family_support.primitives_type"
--
--              makes the enumeration literals visible.)

--
--      ADDITIONAL FEATURES
--
--            - A function, native_lut_size, is available to allow
--              the caller to query the largest sized LUT available in a given
--              FPGA family.
--
--            - A function, equalIgnoringCase, is available to compare strings
--              with case insensitivity. While this can be used to establish
--              whether the target family is some particular family, such
--              usage is discouraged and should be limited to legacy
--              situations or the rare situations where primitive
--              availability guards will not suffice.
--
--------------------------------------------------------------------------------
-- Author:     FLO
-- History:
-- FLO         2005Mar24         - First Version
--
-- FLO         11/30/05
-- ^^^^^^   
-- Virtex5 added.
-- ~~~~~~
-- TK          03/17/06          Corrected a Spartan3e issue in myimage
-- ~~~~~~
-- FLO         04/26/06
-- ^^^^^^   
--   Added the native_lut_size function.
-- ~~~~~~
-- FLO         08/10/06
-- ^^^^^^
--   Added support for families virtex, spartan2 and spartan2e.
-- ~~~~~~
-- FLO         08/25/06
-- ^^^^^^
--   Enhanced the warning in function str2fam. Now when a string that is
--   passed in the call as a parameter does not correspond to a supported fpga
--   family, the string value of the passed string is mentioned in the warning
--   and it is explicitly stated that the returned value is 'nofamily'.
-- ~~~~~~
-- FLO         08/26/06
-- ^^^^^^
--   - Updated the virtex5 primitive set to a more recent list and
--     removed primitives (TEMAC, PCIE, etc.) that are not present
--     in all virtex5 family members.
--   - Added function equalIgnoringCase and an admonition to use it
--     as little as possible.
--   - Made some improvements to descriptions inside comments.
-- ~~~~~~
-- FLO         08/28/06
-- ^^^^^^
--   Added support for families spartan3a and spartan3an. These are initially
--   taken to have the same primitives as spartan3e.
-- ~~~~~~
-- FLO         10/28/06
-- ^^^^^^
--   Changed function str2fam so that it no longer depends on the VHDL
--   attribute, 'VAL. This is an XST workaround.
-- ~~~~~~
-- FLO         03/08/07
-- ^^^^^^
--   Updated spartan3a and sparan3an.
--   Added spartan3adsp.
-- ~~~~~~
-- FLO         08/31/07
-- ^^^^^^
--   A performance XST workaround was implemented to address slowness
--   associated with primitive availability guards. The workaround changes
--   the way that the fam_has_prim constant is initialized (aggregate
--   rather than a system of function and procedure calls).
-- ~~~~~~
-- FLO         04/11/08
-- ^^^^^^
--   Added these families: aspartan3e, aspartan3a, aspartan3an, aspartan3adsp
-- ~~~~~~
-- FLO         04/14/08
-- ^^^^^^
--   Removed family: aspartan3an
-- ~~~~~~
-- FLO         06/25/08
-- ^^^^^^
--   Added these families: qvirtex4, qrvirtex4
-- ~~~~~~
-- FLO         07/26/08
-- ^^^^^^
--   The BSCAN primitive for spartan3e is now BSCAN_SPARTAN3 instead
--   of BSCAN_SPARTAN3E.
-- ~~~~~~
-- FLO         09/02/06
-- ^^^^^^
--   Added an initial approximation of primitives for spartan6 and virtex6.
-- ~~~~~~
-- FLO         09/04/28
-- ^^^^^^
--  -Removed primitive u_BSCAN_SPARTAN3A from spartan6.
--  -Added the 5 and 6 LUTs to spartan6.
-- ~~~~~~
-- FLO         02/09/10  (back to MM/DD/YY)
-- ^^^^^^
--  -Removed primitive u_BSCAN_VIRTEX5 from virtex6.
--  -Added families spartan6l, qspartan6, aspartan6 and virtex6l.
-- ~~~~~~
-- FLO         04/26/10  (MM/DD/YY)
-- ^^^^^^
--  -Added families qspartan6l, qvirtex5 and qvirtex6.
-- ~~~~~~
-- FLO         06/21/10  (MM/DD/YY)
-- ^^^^^^
--  -Added family qrvirtex5.
-- ~~~~~~
--
--     DET     9/7/2010     For 12.4
-- ~~~~~~
--    -- Per CR573867
--     - Added the function get_root_family() as part of the derivative part
--       support improvements.
--     - Added the Virtex7 and Kintex7 device families
-- ^^^^^^
-- ~~~~~~
-- FLO         10/28/10  (MM/DD/YY)
-- ^^^^^^
--  -Added u_SRLC32E as supported for spartan6 (and its derivatives).  (CR 575828)
-- ~~~~~~
-- FLO         12/15/10  (MM/DD/YY)
-- ^^^^^^
--  -Changed virtex6cx to be equal to virtex6 (instead of virtex5)
--  -Move kintex7 and virtex7 to the primitives in the Rodin unisim.btl file
--  -Added artix7 from the primitives in the Rodin unisim.btl file
-- ~~~~~~
--
--     DET     3/2/2011     EDk 13.2
-- ~~~~~~
--    -- Per CR595477
--     - Added zynq support in the get_root_family function.
-- ^^^^^^
--
-- DET         03/18/2011
-- ^^^^^^
--   Per CR602290
--  - Added u_RAMB16_S4_S36 for kintex7, virtex7, artix7 to grandfather axi_ethernetlite_v1_00_a.
--  - This change was lost from 13.1 O.40d to 13.2 branch.
--  - Copied the Virtex7 primitive info to zynq primitive entry (instead of the artix7 info) 
-- ~~~~~~
--
--     DET     4/4/2011     EDK 13.2
-- ~~~~~~
--    -- Per CR604652
--     - Added kintex7l and virtex7l 
-- ^^^^^^
--
--------------------------------------------------------------------------------
-- Naming Conventions:
--    active low signals: "*_n"
--    clock signals: "clk", "clk_div#", "clk_#x"
--    reset signals: "rst", "rst_n"
--    generics: "C_*"
--    user defined types: "*_TYPE"
--    state machine next state: "*_ns"
--    state machine current state: "*_cs"
--    combinational signals: "*_cmb"
--    pipelined or register delay signals: "*_d#"
--    counter signals: "*cnt*"
--    clock enable signals: "*_ce"
--    internal version of output port: "*_i"
--    device pins: "*_pin"
--    ports:- Names begin with Uppercase
--    processes: "*_PROCESS"
--    component instantiations: "<ENTITY_>I_<#|FUNC>
--------------------------------------------------------------------------------

package family_support is

    type families_type is
    (
       nofamily
     , virtex
     , spartan2
     , spartan2e
     , virtexe
     , virtex2
     , qvirtex2    -- Taken to be identical to the virtex2 primitive set.
     , qrvirtex2   -- Taken to be identical to the virtex2 primitive set.
     , virtex2p
     , spartan3
     , aspartan3
     , virtex4
     , virtex4lx
     , virtex4fx
     , virtex4sx
     , spartan3e
     , virtex5
     , spartan3a
     , spartan3an
     , spartan3adsp
     , aspartan3e
     , aspartan3a
     , aspartan3adsp
     , qvirtex4
     , qrvirtex4
     , spartan6
     , virtex6
     , spartan6l
     , qspartan6
     , aspartan6
     , virtex6l
     , qspartan6l
     , qvirtex5
     , qvirtex6
     , qrvirtex5
     , virtex5tx
     , virtex5fx
     , virtex6cx
     , kintex7
     , kintex7l
     , qkintex7
     , qkintex7l
     , virtex7
     , virtex7l
     , qvirtex7
     , qvirtex7l
     , artix7
     , aartix7
     , artix7l
     , qartix7
     , qartix7l
     , zynq
     , azynq
     , qzynq
    );


    type primitives_type is range 0 to 798;

    constant u_AND2: primitives_type := 0;
    constant u_AND2B1L: primitives_type :=  u_AND2 + 1;
    constant u_AND3: primitives_type :=  u_AND2B1L + 1;
    constant u_AND4: primitives_type :=  u_AND3 + 1;
    constant u_AUTOBUF: primitives_type :=  u_AND4 + 1;
    constant u_BSCAN_SPARTAN2: primitives_type :=  u_AUTOBUF + 1;
    constant u_BSCAN_SPARTAN3: primitives_type :=  u_BSCAN_SPARTAN2 + 1;
    constant u_BSCAN_SPARTAN3A: primitives_type :=  u_BSCAN_SPARTAN3 + 1;
    constant u_BSCAN_SPARTAN3E: primitives_type :=  u_BSCAN_SPARTAN3A + 1;
    constant u_BSCAN_SPARTAN6: primitives_type :=  u_BSCAN_SPARTAN3E + 1;
    constant u_BSCAN_VIRTEX: primitives_type :=  u_BSCAN_SPARTAN6 + 1;
    constant u_BSCAN_VIRTEX2: primitives_type :=  u_BSCAN_VIRTEX + 1;
    constant u_BSCAN_VIRTEX4: primitives_type :=  u_BSCAN_VIRTEX2 + 1;
    constant u_BSCAN_VIRTEX5: primitives_type :=  u_BSCAN_VIRTEX4 + 1;
    constant u_BSCAN_VIRTEX6: primitives_type :=  u_BSCAN_VIRTEX5 + 1;
    constant u_BUF: primitives_type :=  u_BSCAN_VIRTEX6 + 1;
    constant u_BUFCF: primitives_type :=  u_BUF + 1;
    constant u_BUFE: primitives_type :=  u_BUFCF + 1;
    constant u_BUFG: primitives_type :=  u_BUFE + 1;
    constant u_BUFGCE: primitives_type :=  u_BUFG + 1;
    constant u_BUFGCE_1: primitives_type :=  u_BUFGCE + 1;
    constant u_BUFGCTRL: primitives_type :=  u_BUFGCE_1 + 1;
    constant u_BUFGDLL: primitives_type :=  u_BUFGCTRL + 1;
    constant u_BUFGMUX: primitives_type :=  u_BUFGDLL + 1;
    constant u_BUFGMUX_1: primitives_type :=  u_BUFGMUX + 1;
    constant u_BUFGMUX_CTRL: primitives_type :=  u_BUFGMUX_1 + 1;
    constant u_BUFGMUX_VIRTEX4: primitives_type :=  u_BUFGMUX_CTRL + 1;
    constant u_BUFGP: primitives_type :=  u_BUFGMUX_VIRTEX4 + 1;
    constant u_BUFH: primitives_type :=  u_BUFGP + 1;
    constant u_BUFHCE: primitives_type :=  u_BUFH + 1;
    constant u_BUFIO: primitives_type :=  u_BUFHCE + 1;
    constant u_BUFIO2: primitives_type :=  u_BUFIO + 1;
    constant u_BUFIO2_2CLK: primitives_type :=  u_BUFIO2 + 1;
    constant u_BUFIO2FB: primitives_type :=  u_BUFIO2_2CLK + 1;
    constant u_BUFIO2FB_2CLK: primitives_type :=  u_BUFIO2FB + 1;
    constant u_BUFIODQS: primitives_type :=  u_BUFIO2FB_2CLK + 1;
    constant u_BUFPLL: primitives_type :=  u_BUFIODQS + 1;
    constant u_BUFPLL_MCB: primitives_type :=  u_BUFPLL + 1;
    constant u_BUFR: primitives_type :=  u_BUFPLL_MCB + 1;
    constant u_BUFT: primitives_type :=  u_BUFR + 1;
    constant u_CAPTURE_SPARTAN2: primitives_type :=  u_BUFT + 1;
    constant u_CAPTURE_SPARTAN3: primitives_type :=  u_CAPTURE_SPARTAN2 + 1;
    constant u_CAPTURE_SPARTAN3A: primitives_type :=  u_CAPTURE_SPARTAN3 + 1;
    constant u_CAPTURE_SPARTAN3E: primitives_type :=  u_CAPTURE_SPARTAN3A + 1;
    constant u_CAPTURE_VIRTEX: primitives_type :=  u_CAPTURE_SPARTAN3E + 1;
    constant u_CAPTURE_VIRTEX2: primitives_type :=  u_CAPTURE_VIRTEX + 1;
    constant u_CAPTURE_VIRTEX4: primitives_type :=  u_CAPTURE_VIRTEX2 + 1;
    constant u_CAPTURE_VIRTEX5: primitives_type :=  u_CAPTURE_VIRTEX4 + 1;
    constant u_CAPTURE_VIRTEX6: primitives_type :=  u_CAPTURE_VIRTEX5 + 1;
    constant u_CARRY4: primitives_type :=  u_CAPTURE_VIRTEX6 + 1;
    constant u_CFGLUT5: primitives_type :=  u_CARRY4 + 1;
    constant u_CLKDLL: primitives_type :=  u_CFGLUT5 + 1;
    constant u_CLKDLLE: primitives_type :=  u_CLKDLL + 1;
    constant u_CLKDLLHF: primitives_type :=  u_CLKDLLE + 1;
    constant u_CRC32: primitives_type :=  u_CLKDLLHF + 1;
    constant u_CRC64: primitives_type :=  u_CRC32 + 1;
    constant u_DCIRESET: primitives_type :=  u_CRC64 + 1;
    constant u_DCM: primitives_type :=  u_DCIRESET + 1;
    constant u_DCM_ADV: primitives_type :=  u_DCM + 1;
    constant u_DCM_BASE: primitives_type :=  u_DCM_ADV + 1;
    constant u_DCM_CLKGEN: primitives_type :=  u_DCM_BASE + 1;
    constant u_DCM_PS: primitives_type :=  u_DCM_CLKGEN + 1;
    constant u_DNA_PORT: primitives_type :=  u_DCM_PS + 1;
    constant u_DSP48: primitives_type :=  u_DNA_PORT + 1;
    constant u_DSP48A: primitives_type :=  u_DSP48 + 1;
    constant u_DSP48A1: primitives_type :=  u_DSP48A + 1;
    constant u_DSP48E: primitives_type :=  u_DSP48A1 + 1;
    constant u_DSP48E1: primitives_type :=  u_DSP48E + 1;
    constant u_DUMMY_INV: primitives_type :=  u_DSP48E1 + 1;
    constant u_DUMMY_NOR2: primitives_type :=  u_DUMMY_INV + 1;
    constant u_EFUSE_USR: primitives_type :=  u_DUMMY_NOR2 + 1;
    constant u_EMAC: primitives_type :=  u_EFUSE_USR + 1;
    constant u_FD: primitives_type :=  u_EMAC + 1;
    constant u_FD_1: primitives_type :=  u_FD + 1;
    constant u_FDC: primitives_type :=  u_FD_1 + 1;
    constant u_FDC_1: primitives_type :=  u_FDC + 1;
    constant u_FDCE: primitives_type :=  u_FDC_1 + 1;
    constant u_FDCE_1: primitives_type :=  u_FDCE + 1;
    constant u_FDCP: primitives_type :=  u_FDCE_1 + 1;
    constant u_FDCP_1: primitives_type :=  u_FDCP + 1;
    constant u_FDCPE: primitives_type :=  u_FDCP_1 + 1;
    constant u_FDCPE_1: primitives_type :=  u_FDCPE + 1;
    constant u_FDDRCPE: primitives_type :=  u_FDCPE_1 + 1;
    constant u_FDDRRSE: primitives_type :=  u_FDDRCPE + 1;
    constant u_FDE: primitives_type :=  u_FDDRRSE + 1;
    constant u_FDE_1: primitives_type :=  u_FDE + 1;
    constant u_FDP: primitives_type :=  u_FDE_1 + 1;
    constant u_FDP_1: primitives_type :=  u_FDP + 1;
    constant u_FDPE: primitives_type :=  u_FDP_1 + 1;
    constant u_FDPE_1: primitives_type :=  u_FDPE + 1;
    constant u_FDR: primitives_type :=  u_FDPE_1 + 1;
    constant u_FDR_1: primitives_type :=  u_FDR + 1;
    constant u_FDRE: primitives_type :=  u_FDR_1 + 1;
    constant u_FDRE_1: primitives_type :=  u_FDRE + 1;
    constant u_FDRS: primitives_type :=  u_FDRE_1 + 1;
    constant u_FDRS_1: primitives_type :=  u_FDRS + 1;
    constant u_FDRSE: primitives_type :=  u_FDRS_1 + 1;
    constant u_FDRSE_1: primitives_type :=  u_FDRSE + 1;
    constant u_FDS: primitives_type :=  u_FDRSE_1 + 1;
    constant u_FDS_1: primitives_type :=  u_FDS + 1;
    constant u_FDSE: primitives_type :=  u_FDS_1 + 1;
    constant u_FDSE_1: primitives_type :=  u_FDSE + 1;
    constant u_FIFO16: primitives_type :=  u_FDSE_1 + 1;
    constant u_FIFO18: primitives_type :=  u_FIFO16 + 1;
    constant u_FIFO18_36: primitives_type :=  u_FIFO18 + 1;
    constant u_FIFO18E1: primitives_type :=  u_FIFO18_36 + 1;
    constant u_FIFO36: primitives_type :=  u_FIFO18E1 + 1;
    constant u_FIFO36_72: primitives_type :=  u_FIFO36 + 1;
    constant u_FIFO36E1: primitives_type :=  u_FIFO36_72 + 1;
    constant u_FMAP: primitives_type :=  u_FIFO36E1 + 1;
    constant u_FRAME_ECC_VIRTEX4: primitives_type :=  u_FMAP + 1;
    constant u_FRAME_ECC_VIRTEX5: primitives_type :=  u_FRAME_ECC_VIRTEX4 + 1;
    constant u_FRAME_ECC_VIRTEX6: primitives_type :=  u_FRAME_ECC_VIRTEX5 + 1;
    constant u_GND: primitives_type :=  u_FRAME_ECC_VIRTEX6 + 1;
    constant u_GT10_10GE_4: primitives_type :=  u_GND + 1;
    constant u_GT10_10GE_8: primitives_type :=  u_GT10_10GE_4 + 1;
    constant u_GT10_10GFC_4: primitives_type :=  u_GT10_10GE_8 + 1;
    constant u_GT10_10GFC_8: primitives_type :=  u_GT10_10GFC_4 + 1;
    constant u_GT10_AURORA_1: primitives_type :=  u_GT10_10GFC_8 + 1;
    constant u_GT10_AURORA_2: primitives_type :=  u_GT10_AURORA_1 + 1;
    constant u_GT10_AURORA_4: primitives_type :=  u_GT10_AURORA_2 + 1;
    constant u_GT10_AURORAX_4: primitives_type :=  u_GT10_AURORA_4 + 1;
    constant u_GT10_AURORAX_8: primitives_type :=  u_GT10_AURORAX_4 + 1;
    constant u_GT10_CUSTOM: primitives_type :=  u_GT10_AURORAX_8 + 1;
    constant u_GT10_INFINIBAND_1: primitives_type :=  u_GT10_CUSTOM + 1;
    constant u_GT10_INFINIBAND_2: primitives_type :=  u_GT10_INFINIBAND_1 + 1;
    constant u_GT10_INFINIBAND_4: primitives_type :=  u_GT10_INFINIBAND_2 + 1;
    constant u_GT10_OC192_4: primitives_type :=  u_GT10_INFINIBAND_4 + 1;
    constant u_GT10_OC192_8: primitives_type :=  u_GT10_OC192_4 + 1;
    constant u_GT10_OC48_1: primitives_type :=  u_GT10_OC192_8 + 1;
    constant u_GT10_OC48_2: primitives_type :=  u_GT10_OC48_1 + 1;
    constant u_GT10_OC48_4: primitives_type :=  u_GT10_OC48_2 + 1;
    constant u_GT10_PCI_EXPRESS_1: primitives_type :=  u_GT10_OC48_4 + 1;
    constant u_GT10_PCI_EXPRESS_2: primitives_type :=  u_GT10_PCI_EXPRESS_1 + 1;
    constant u_GT10_PCI_EXPRESS_4: primitives_type :=  u_GT10_PCI_EXPRESS_2 + 1;
    constant u_GT10_XAUI_1: primitives_type :=  u_GT10_PCI_EXPRESS_4 + 1;
    constant u_GT10_XAUI_2: primitives_type :=  u_GT10_XAUI_1 + 1;
    constant u_GT10_XAUI_4: primitives_type :=  u_GT10_XAUI_2 + 1;
    constant u_GT11CLK: primitives_type :=  u_GT10_XAUI_4 + 1;
    constant u_GT11CLK_MGT: primitives_type :=  u_GT11CLK + 1;
    constant u_GT11_CUSTOM: primitives_type :=  u_GT11CLK_MGT + 1;
    constant u_GT_AURORA_1: primitives_type :=  u_GT11_CUSTOM + 1;
    constant u_GT_AURORA_2: primitives_type :=  u_GT_AURORA_1 + 1;
    constant u_GT_AURORA_4: primitives_type :=  u_GT_AURORA_2 + 1;
    constant u_GT_CUSTOM: primitives_type :=  u_GT_AURORA_4 + 1;
    constant u_GT_ETHERNET_1: primitives_type :=  u_GT_CUSTOM + 1;
    constant u_GT_ETHERNET_2: primitives_type :=  u_GT_ETHERNET_1 + 1;
    constant u_GT_ETHERNET_4: primitives_type :=  u_GT_ETHERNET_2 + 1;
    constant u_GT_FIBRE_CHAN_1: primitives_type :=  u_GT_ETHERNET_4 + 1;
    constant u_GT_FIBRE_CHAN_2: primitives_type :=  u_GT_FIBRE_CHAN_1 + 1;
    constant u_GT_FIBRE_CHAN_4: primitives_type :=  u_GT_FIBRE_CHAN_2 + 1;
    constant u_GT_INFINIBAND_1: primitives_type :=  u_GT_FIBRE_CHAN_4 + 1;
    constant u_GT_INFINIBAND_2: primitives_type :=  u_GT_INFINIBAND_1 + 1;
    constant u_GT_INFINIBAND_4: primitives_type :=  u_GT_INFINIBAND_2 + 1;
    constant u_GTPA1_DUAL: primitives_type :=  u_GT_INFINIBAND_4 + 1;
    constant u_GT_XAUI_1: primitives_type :=  u_GTPA1_DUAL + 1;
    constant u_GT_XAUI_2: primitives_type :=  u_GT_XAUI_1 + 1;
    constant u_GT_XAUI_4: primitives_type :=  u_GT_XAUI_2 + 1;
    constant u_GTXE1: primitives_type :=  u_GT_XAUI_4 + 1;
    constant u_IBUF: primitives_type :=  u_GTXE1 + 1;
    constant u_IBUF_AGP: primitives_type :=  u_IBUF + 1;
    constant u_IBUF_CTT: primitives_type :=  u_IBUF_AGP + 1;
    constant u_IBUF_DLY_ADJ: primitives_type :=  u_IBUF_CTT + 1;
    constant u_IBUFDS: primitives_type :=  u_IBUF_DLY_ADJ + 1;
    constant u_IBUFDS_DIFF_OUT: primitives_type :=  u_IBUFDS + 1;
    constant u_IBUFDS_DLY_ADJ: primitives_type :=  u_IBUFDS_DIFF_OUT + 1;
    constant u_IBUFDS_GTXE1: primitives_type :=  u_IBUFDS_DLY_ADJ + 1;
    constant u_IBUFG: primitives_type :=  u_IBUFDS_GTXE1 + 1;
    constant u_IBUFG_AGP: primitives_type :=  u_IBUFG + 1;
    constant u_IBUFG_CTT: primitives_type :=  u_IBUFG_AGP + 1;
    constant u_IBUFGDS: primitives_type :=  u_IBUFG_CTT + 1;
    constant u_IBUFGDS_DIFF_OUT: primitives_type :=  u_IBUFGDS + 1;
    constant u_IBUFG_GTL: primitives_type :=  u_IBUFGDS_DIFF_OUT + 1;
    constant u_IBUFG_GTLP: primitives_type :=  u_IBUFG_GTL + 1;
    constant u_IBUFG_HSTL_I: primitives_type :=  u_IBUFG_GTLP + 1;
    constant u_IBUFG_HSTL_III: primitives_type :=  u_IBUFG_HSTL_I + 1;
    constant u_IBUFG_HSTL_IV: primitives_type :=  u_IBUFG_HSTL_III + 1;
    constant u_IBUFG_LVCMOS18: primitives_type :=  u_IBUFG_HSTL_IV + 1;
    constant u_IBUFG_LVCMOS2: primitives_type :=  u_IBUFG_LVCMOS18 + 1;
    constant u_IBUFG_LVDS: primitives_type :=  u_IBUFG_LVCMOS2 + 1;
    constant u_IBUFG_LVPECL: primitives_type :=  u_IBUFG_LVDS + 1;
    constant u_IBUFG_PCI33_3: primitives_type :=  u_IBUFG_LVPECL + 1;
    constant u_IBUFG_PCI33_5: primitives_type :=  u_IBUFG_PCI33_3 + 1;
    constant u_IBUFG_PCI66_3: primitives_type :=  u_IBUFG_PCI33_5 + 1;
    constant u_IBUFG_PCIX66_3: primitives_type :=  u_IBUFG_PCI66_3 + 1;
    constant u_IBUFG_SSTL2_I: primitives_type :=  u_IBUFG_PCIX66_3 + 1;
    constant u_IBUFG_SSTL2_II: primitives_type :=  u_IBUFG_SSTL2_I + 1;
    constant u_IBUFG_SSTL3_I: primitives_type :=  u_IBUFG_SSTL2_II + 1;
    constant u_IBUFG_SSTL3_II: primitives_type :=  u_IBUFG_SSTL3_I + 1;
    constant u_IBUF_GTL: primitives_type :=  u_IBUFG_SSTL3_II + 1;
    constant u_IBUF_GTLP: primitives_type :=  u_IBUF_GTL + 1;
    constant u_IBUF_HSTL_I: primitives_type :=  u_IBUF_GTLP + 1;
    constant u_IBUF_HSTL_III: primitives_type :=  u_IBUF_HSTL_I + 1;
    constant u_IBUF_HSTL_IV: primitives_type :=  u_IBUF_HSTL_III + 1;
    constant u_IBUF_LVCMOS18: primitives_type :=  u_IBUF_HSTL_IV + 1;
    constant u_IBUF_LVCMOS2: primitives_type :=  u_IBUF_LVCMOS18 + 1;
    constant u_IBUF_LVDS: primitives_type :=  u_IBUF_LVCMOS2 + 1;
    constant u_IBUF_LVPECL: primitives_type :=  u_IBUF_LVDS + 1;
    constant u_IBUF_PCI33_3: primitives_type :=  u_IBUF_LVPECL + 1;
    constant u_IBUF_PCI33_5: primitives_type :=  u_IBUF_PCI33_3 + 1;
    constant u_IBUF_PCI66_3: primitives_type :=  u_IBUF_PCI33_5 + 1;
    constant u_IBUF_PCIX66_3: primitives_type :=  u_IBUF_PCI66_3 + 1;
    constant u_IBUF_SSTL2_I: primitives_type :=  u_IBUF_PCIX66_3 + 1;
    constant u_IBUF_SSTL2_II: primitives_type :=  u_IBUF_SSTL2_I + 1;
    constant u_IBUF_SSTL3_I: primitives_type :=  u_IBUF_SSTL2_II + 1;
    constant u_IBUF_SSTL3_II: primitives_type :=  u_IBUF_SSTL3_I + 1;
    constant u_ICAP_SPARTAN3A: primitives_type :=  u_IBUF_SSTL3_II + 1;
    constant u_ICAP_SPARTAN6: primitives_type :=  u_ICAP_SPARTAN3A + 1;
    constant u_ICAP_VIRTEX2: primitives_type :=  u_ICAP_SPARTAN6 + 1;
    constant u_ICAP_VIRTEX4: primitives_type :=  u_ICAP_VIRTEX2 + 1;
    constant u_ICAP_VIRTEX5: primitives_type :=  u_ICAP_VIRTEX4 + 1;
    constant u_ICAP_VIRTEX6: primitives_type :=  u_ICAP_VIRTEX5 + 1;
    constant u_IDDR: primitives_type :=  u_ICAP_VIRTEX6 + 1;
    constant u_IDDR2: primitives_type :=  u_IDDR + 1;
    constant u_IDDR_2CLK: primitives_type :=  u_IDDR2 + 1;
    constant u_IDELAY: primitives_type :=  u_IDDR_2CLK + 1;
    constant u_IDELAYCTRL: primitives_type :=  u_IDELAY + 1;
    constant u_IFDDRCPE: primitives_type :=  u_IDELAYCTRL + 1;
    constant u_IFDDRRSE: primitives_type :=  u_IFDDRCPE + 1;
    constant u_INV: primitives_type :=  u_IFDDRRSE + 1;
    constant u_IOBUF: primitives_type :=  u_INV + 1;
    constant u_IOBUF_AGP: primitives_type :=  u_IOBUF + 1;
    constant u_IOBUF_CTT: primitives_type :=  u_IOBUF_AGP + 1;
    constant u_IOBUFDS: primitives_type :=  u_IOBUF_CTT + 1;
    constant u_IOBUFDS_DIFF_OUT: primitives_type :=  u_IOBUFDS + 1;
    constant u_IOBUF_F_12: primitives_type :=  u_IOBUFDS_DIFF_OUT + 1;
    constant u_IOBUF_F_16: primitives_type :=  u_IOBUF_F_12 + 1;
    constant u_IOBUF_F_2: primitives_type :=  u_IOBUF_F_16 + 1;
    constant u_IOBUF_F_24: primitives_type :=  u_IOBUF_F_2 + 1;
    constant u_IOBUF_F_4: primitives_type :=  u_IOBUF_F_24 + 1;
    constant u_IOBUF_F_6: primitives_type :=  u_IOBUF_F_4 + 1;
    constant u_IOBUF_F_8: primitives_type :=  u_IOBUF_F_6 + 1;
    constant u_IOBUF_GTL: primitives_type :=  u_IOBUF_F_8 + 1;
    constant u_IOBUF_GTLP: primitives_type :=  u_IOBUF_GTL + 1;
    constant u_IOBUF_HSTL_I: primitives_type :=  u_IOBUF_GTLP + 1;
    constant u_IOBUF_HSTL_III: primitives_type :=  u_IOBUF_HSTL_I + 1;
    constant u_IOBUF_HSTL_IV: primitives_type :=  u_IOBUF_HSTL_III + 1;
    constant u_IOBUF_LVCMOS18: primitives_type :=  u_IOBUF_HSTL_IV + 1;
    constant u_IOBUF_LVCMOS2: primitives_type :=  u_IOBUF_LVCMOS18 + 1;
    constant u_IOBUF_LVDS: primitives_type :=  u_IOBUF_LVCMOS2 + 1;
    constant u_IOBUF_LVPECL: primitives_type :=  u_IOBUF_LVDS + 1;
    constant u_IOBUF_PCI33_3: primitives_type :=  u_IOBUF_LVPECL + 1;
    constant u_IOBUF_PCI33_5: primitives_type :=  u_IOBUF_PCI33_3 + 1;
    constant u_IOBUF_PCI66_3: primitives_type :=  u_IOBUF_PCI33_5 + 1;
    constant u_IOBUF_PCIX66_3: primitives_type :=  u_IOBUF_PCI66_3 + 1;
    constant u_IOBUF_S_12: primitives_type :=  u_IOBUF_PCIX66_3 + 1;
    constant u_IOBUF_S_16: primitives_type :=  u_IOBUF_S_12 + 1;
    constant u_IOBUF_S_2: primitives_type :=  u_IOBUF_S_16 + 1;
    constant u_IOBUF_S_24: primitives_type :=  u_IOBUF_S_2 + 1;
    constant u_IOBUF_S_4: primitives_type :=  u_IOBUF_S_24 + 1;
    constant u_IOBUF_S_6: primitives_type :=  u_IOBUF_S_4 + 1;
    constant u_IOBUF_S_8: primitives_type :=  u_IOBUF_S_6 + 1;
    constant u_IOBUF_SSTL2_I: primitives_type :=  u_IOBUF_S_8 + 1;
    constant u_IOBUF_SSTL2_II: primitives_type :=  u_IOBUF_SSTL2_I + 1;
    constant u_IOBUF_SSTL3_I: primitives_type :=  u_IOBUF_SSTL2_II + 1;
    constant u_IOBUF_SSTL3_II: primitives_type :=  u_IOBUF_SSTL3_I + 1;
    constant u_IODELAY: primitives_type :=  u_IOBUF_SSTL3_II + 1;
    constant u_IODELAY2: primitives_type :=  u_IODELAY + 1;
    constant u_IODELAYE1: primitives_type :=  u_IODELAY2 + 1;
    constant u_IODRP2: primitives_type :=  u_IODELAYE1 + 1;
    constant u_IODRP2_MCB: primitives_type :=  u_IODRP2 + 1;
    constant u_ISERDES: primitives_type :=  u_IODRP2_MCB + 1;
    constant u_ISERDES2: primitives_type :=  u_ISERDES + 1;
    constant u_ISERDESE1: primitives_type :=  u_ISERDES2 + 1;
    constant u_ISERDES_NODELAY: primitives_type :=  u_ISERDESE1 + 1;
    constant u_JTAGPPC: primitives_type :=  u_ISERDES_NODELAY + 1;
    constant u_JTAG_SIM_SPARTAN6: primitives_type :=  u_JTAGPPC + 1;
    constant u_JTAG_SIM_VIRTEX6: primitives_type :=  u_JTAG_SIM_SPARTAN6 + 1;
    constant u_KEEPER: primitives_type :=  u_JTAG_SIM_VIRTEX6 + 1;
    constant u_KEY_CLEAR: primitives_type :=  u_KEEPER + 1;
    constant u_LD: primitives_type :=  u_KEY_CLEAR + 1;
    constant u_LD_1: primitives_type :=  u_LD + 1;
    constant u_LDC: primitives_type :=  u_LD_1 + 1;
    constant u_LDC_1: primitives_type :=  u_LDC + 1;
    constant u_LDCE: primitives_type :=  u_LDC_1 + 1;
    constant u_LDCE_1: primitives_type :=  u_LDCE + 1;
    constant u_LDCP: primitives_type :=  u_LDCE_1 + 1;
    constant u_LDCP_1: primitives_type :=  u_LDCP + 1;
    constant u_LDCPE: primitives_type :=  u_LDCP_1 + 1;
    constant u_LDCPE_1: primitives_type :=  u_LDCPE + 1;
    constant u_LDE: primitives_type :=  u_LDCPE_1 + 1;
    constant u_LDE_1: primitives_type :=  u_LDE + 1;
    constant u_LDP: primitives_type :=  u_LDE_1 + 1;
    constant u_LDP_1: primitives_type :=  u_LDP + 1;
    constant u_LDPE: primitives_type :=  u_LDP_1 + 1;
    constant u_LDPE_1: primitives_type :=  u_LDPE + 1;
    constant u_LUT1: primitives_type :=  u_LDPE_1 + 1;
    constant u_LUT1_D: primitives_type :=  u_LUT1 + 1;
    constant u_LUT1_L: primitives_type :=  u_LUT1_D + 1;
    constant u_LUT2: primitives_type :=  u_LUT1_L + 1;
    constant u_LUT2_D: primitives_type :=  u_LUT2 + 1;
    constant u_LUT2_L: primitives_type :=  u_LUT2_D + 1;
    constant u_LUT3: primitives_type :=  u_LUT2_L + 1;
    constant u_LUT3_D: primitives_type :=  u_LUT3 + 1;
    constant u_LUT3_L: primitives_type :=  u_LUT3_D + 1;
    constant u_LUT4: primitives_type :=  u_LUT3_L + 1;
    constant u_LUT4_D: primitives_type :=  u_LUT4 + 1;
    constant u_LUT4_L: primitives_type :=  u_LUT4_D + 1;
    constant u_LUT5: primitives_type :=  u_LUT4_L + 1;
    constant u_LUT5_D: primitives_type :=  u_LUT5 + 1;
    constant u_LUT5_L: primitives_type :=  u_LUT5_D + 1;
    constant u_LUT6: primitives_type :=  u_LUT5_L + 1;
    constant u_LUT6_D: primitives_type :=  u_LUT6 + 1;
    constant u_LUT6_L: primitives_type :=  u_LUT6_D + 1;
    constant u_MCB: primitives_type :=  u_LUT6_L + 1;
    constant u_MMCM_ADV: primitives_type :=  u_MCB + 1;
    constant u_MMCM_BASE: primitives_type :=  u_MMCM_ADV + 1;
    constant u_MULT18X18: primitives_type :=  u_MMCM_BASE + 1;
    constant u_MULT18X18S: primitives_type :=  u_MULT18X18 + 1;
    constant u_MULT18X18SIO: primitives_type :=  u_MULT18X18S + 1;
    constant u_MULT_AND: primitives_type :=  u_MULT18X18SIO + 1;
    constant u_MUXCY: primitives_type :=  u_MULT_AND + 1;
    constant u_MUXCY_D: primitives_type :=  u_MUXCY + 1;
    constant u_MUXCY_L: primitives_type :=  u_MUXCY_D + 1;
    constant u_MUXF5: primitives_type :=  u_MUXCY_L + 1;
    constant u_MUXF5_D: primitives_type :=  u_MUXF5 + 1;
    constant u_MUXF5_L: primitives_type :=  u_MUXF5_D + 1;
    constant u_MUXF6: primitives_type :=  u_MUXF5_L + 1;
    constant u_MUXF6_D: primitives_type :=  u_MUXF6 + 1;
    constant u_MUXF6_L: primitives_type :=  u_MUXF6_D + 1;
    constant u_MUXF7: primitives_type :=  u_MUXF6_L + 1;
    constant u_MUXF7_D: primitives_type :=  u_MUXF7 + 1;
    constant u_MUXF7_L: primitives_type :=  u_MUXF7_D + 1;
    constant u_MUXF8: primitives_type :=  u_MUXF7_L + 1;
    constant u_MUXF8_D: primitives_type :=  u_MUXF8 + 1;
    constant u_MUXF8_L: primitives_type :=  u_MUXF8_D + 1;
    constant u_NAND2: primitives_type :=  u_MUXF8_L + 1;
    constant u_NAND3: primitives_type :=  u_NAND2 + 1;
    constant u_NAND4: primitives_type :=  u_NAND3 + 1;
    constant u_NOR2: primitives_type :=  u_NAND4 + 1;
    constant u_NOR3: primitives_type :=  u_NOR2 + 1;
    constant u_NOR4: primitives_type :=  u_NOR3 + 1;
    constant u_OBUF: primitives_type :=  u_NOR4 + 1;
    constant u_OBUF_AGP: primitives_type :=  u_OBUF + 1;
    constant u_OBUF_CTT: primitives_type :=  u_OBUF_AGP + 1;
    constant u_OBUFDS: primitives_type :=  u_OBUF_CTT + 1;
    constant u_OBUF_F_12: primitives_type :=  u_OBUFDS + 1;
    constant u_OBUF_F_16: primitives_type :=  u_OBUF_F_12 + 1;
    constant u_OBUF_F_2: primitives_type :=  u_OBUF_F_16 + 1;
    constant u_OBUF_F_24: primitives_type :=  u_OBUF_F_2 + 1;
    constant u_OBUF_F_4: primitives_type :=  u_OBUF_F_24 + 1;
    constant u_OBUF_F_6: primitives_type :=  u_OBUF_F_4 + 1;
    constant u_OBUF_F_8: primitives_type :=  u_OBUF_F_6 + 1;
    constant u_OBUF_GTL: primitives_type :=  u_OBUF_F_8 + 1;
    constant u_OBUF_GTLP: primitives_type :=  u_OBUF_GTL + 1;
    constant u_OBUF_HSTL_I: primitives_type :=  u_OBUF_GTLP + 1;
    constant u_OBUF_HSTL_III: primitives_type :=  u_OBUF_HSTL_I + 1;
    constant u_OBUF_HSTL_IV: primitives_type :=  u_OBUF_HSTL_III + 1;
    constant u_OBUF_LVCMOS18: primitives_type :=  u_OBUF_HSTL_IV + 1;
    constant u_OBUF_LVCMOS2: primitives_type :=  u_OBUF_LVCMOS18 + 1;
    constant u_OBUF_LVDS: primitives_type :=  u_OBUF_LVCMOS2 + 1;
    constant u_OBUF_LVPECL: primitives_type :=  u_OBUF_LVDS + 1;
    constant u_OBUF_PCI33_3: primitives_type :=  u_OBUF_LVPECL + 1;
    constant u_OBUF_PCI33_5: primitives_type :=  u_OBUF_PCI33_3 + 1;
    constant u_OBUF_PCI66_3: primitives_type :=  u_OBUF_PCI33_5 + 1;
    constant u_OBUF_PCIX66_3: primitives_type :=  u_OBUF_PCI66_3 + 1;
    constant u_OBUF_S_12: primitives_type :=  u_OBUF_PCIX66_3 + 1;
    constant u_OBUF_S_16: primitives_type :=  u_OBUF_S_12 + 1;
    constant u_OBUF_S_2: primitives_type :=  u_OBUF_S_16 + 1;
    constant u_OBUF_S_24: primitives_type :=  u_OBUF_S_2 + 1;
    constant u_OBUF_S_4: primitives_type :=  u_OBUF_S_24 + 1;
    constant u_OBUF_S_6: primitives_type :=  u_OBUF_S_4 + 1;
    constant u_OBUF_S_8: primitives_type :=  u_OBUF_S_6 + 1;
    constant u_OBUF_SSTL2_I: primitives_type :=  u_OBUF_S_8 + 1;
    constant u_OBUF_SSTL2_II: primitives_type :=  u_OBUF_SSTL2_I + 1;
    constant u_OBUF_SSTL3_I: primitives_type :=  u_OBUF_SSTL2_II + 1;
    constant u_OBUF_SSTL3_II: primitives_type :=  u_OBUF_SSTL3_I + 1;
    constant u_OBUFT: primitives_type :=  u_OBUF_SSTL3_II + 1;
    constant u_OBUFT_AGP: primitives_type :=  u_OBUFT + 1;
    constant u_OBUFT_CTT: primitives_type :=  u_OBUFT_AGP + 1;
    constant u_OBUFTDS: primitives_type :=  u_OBUFT_CTT + 1;
    constant u_OBUFT_F_12: primitives_type :=  u_OBUFTDS + 1;
    constant u_OBUFT_F_16: primitives_type :=  u_OBUFT_F_12 + 1;
    constant u_OBUFT_F_2: primitives_type :=  u_OBUFT_F_16 + 1;
    constant u_OBUFT_F_24: primitives_type :=  u_OBUFT_F_2 + 1;
    constant u_OBUFT_F_4: primitives_type :=  u_OBUFT_F_24 + 1;
    constant u_OBUFT_F_6: primitives_type :=  u_OBUFT_F_4 + 1;
    constant u_OBUFT_F_8: primitives_type :=  u_OBUFT_F_6 + 1;
    constant u_OBUFT_GTL: primitives_type :=  u_OBUFT_F_8 + 1;
    constant u_OBUFT_GTLP: primitives_type :=  u_OBUFT_GTL + 1;
    constant u_OBUFT_HSTL_I: primitives_type :=  u_OBUFT_GTLP + 1;
    constant u_OBUFT_HSTL_III: primitives_type :=  u_OBUFT_HSTL_I + 1;
    constant u_OBUFT_HSTL_IV: primitives_type :=  u_OBUFT_HSTL_III + 1;
    constant u_OBUFT_LVCMOS18: primitives_type :=  u_OBUFT_HSTL_IV + 1;
    constant u_OBUFT_LVCMOS2: primitives_type :=  u_OBUFT_LVCMOS18 + 1;
    constant u_OBUFT_LVDS: primitives_type :=  u_OBUFT_LVCMOS2 + 1;
    constant u_OBUFT_LVPECL: primitives_type :=  u_OBUFT_LVDS + 1;
    constant u_OBUFT_PCI33_3: primitives_type :=  u_OBUFT_LVPECL + 1;
    constant u_OBUFT_PCI33_5: primitives_type :=  u_OBUFT_PCI33_3 + 1;
    constant u_OBUFT_PCI66_3: primitives_type :=  u_OBUFT_PCI33_5 + 1;
    constant u_OBUFT_PCIX66_3: primitives_type :=  u_OBUFT_PCI66_3 + 1;
    constant u_OBUFT_S_12: primitives_type :=  u_OBUFT_PCIX66_3 + 1;
    constant u_OBUFT_S_16: primitives_type :=  u_OBUFT_S_12 + 1;
    constant u_OBUFT_S_2: primitives_type :=  u_OBUFT_S_16 + 1;
    constant u_OBUFT_S_24: primitives_type :=  u_OBUFT_S_2 + 1;
    constant u_OBUFT_S_4: primitives_type :=  u_OBUFT_S_24 + 1;
    constant u_OBUFT_S_6: primitives_type :=  u_OBUFT_S_4 + 1;
    constant u_OBUFT_S_8: primitives_type :=  u_OBUFT_S_6 + 1;
    constant u_OBUFT_SSTL2_I: primitives_type :=  u_OBUFT_S_8 + 1;
    constant u_OBUFT_SSTL2_II: primitives_type :=  u_OBUFT_SSTL2_I + 1;
    constant u_OBUFT_SSTL3_I: primitives_type :=  u_OBUFT_SSTL2_II + 1;
    constant u_OBUFT_SSTL3_II: primitives_type :=  u_OBUFT_SSTL3_I + 1;
    constant u_OCT_CALIBRATE: primitives_type :=  u_OBUFT_SSTL3_II + 1;
    constant u_ODDR: primitives_type :=  u_OCT_CALIBRATE + 1;
    constant u_ODDR2: primitives_type :=  u_ODDR + 1;
    constant u_OFDDRCPE: primitives_type :=  u_ODDR2 + 1;
    constant u_OFDDRRSE: primitives_type :=  u_OFDDRCPE + 1;
    constant u_OFDDRTCPE: primitives_type :=  u_OFDDRRSE + 1;
    constant u_OFDDRTRSE: primitives_type :=  u_OFDDRTCPE + 1;
    constant u_OR2: primitives_type :=  u_OFDDRTRSE + 1;
    constant u_OR2L: primitives_type :=  u_OR2 + 1;
    constant u_OR3: primitives_type :=  u_OR2L + 1;
    constant u_OR4: primitives_type :=  u_OR3 + 1;
    constant u_ORCY: primitives_type :=  u_OR4 + 1;
    constant u_OSERDES: primitives_type :=  u_ORCY + 1;
    constant u_OSERDES2: primitives_type :=  u_OSERDES + 1;
    constant u_OSERDESE1: primitives_type :=  u_OSERDES2 + 1;
    constant u_PCIE_2_0: primitives_type :=  u_OSERDESE1 + 1;
    constant u_PCIE_A1: primitives_type :=  u_PCIE_2_0 + 1;
    constant u_PLL_ADV: primitives_type :=  u_PCIE_A1 + 1;
    constant u_PLL_BASE: primitives_type :=  u_PLL_ADV + 1;
    constant u_PMCD: primitives_type :=  u_PLL_BASE + 1;
    constant u_POST_CRC_INTERNAL: primitives_type :=  u_PMCD + 1;
    constant u_PPC405: primitives_type :=  u_POST_CRC_INTERNAL + 1;
    constant u_PPC405_ADV: primitives_type :=  u_PPC405 + 1;
    constant u_PPR_FRAME: primitives_type :=  u_PPC405_ADV + 1;
    constant u_PULLDOWN: primitives_type :=  u_PPR_FRAME + 1;
    constant u_PULLUP: primitives_type :=  u_PULLDOWN + 1;
    constant u_RAM128X1D: primitives_type :=  u_PULLUP + 1;
    constant u_RAM128X1S: primitives_type :=  u_RAM128X1D + 1;
    constant u_RAM128X1S_1: primitives_type :=  u_RAM128X1S + 1;
    constant u_RAM16X1D: primitives_type :=  u_RAM128X1S_1 + 1;
    constant u_RAM16X1D_1: primitives_type :=  u_RAM16X1D + 1;
    constant u_RAM16X1S: primitives_type :=  u_RAM16X1D_1 + 1;
    constant u_RAM16X1S_1: primitives_type :=  u_RAM16X1S + 1;
    constant u_RAM16X2S: primitives_type :=  u_RAM16X1S_1 + 1;
    constant u_RAM16X4S: primitives_type :=  u_RAM16X2S + 1;
    constant u_RAM16X8S: primitives_type :=  u_RAM16X4S + 1;
    constant u_RAM256X1S: primitives_type :=  u_RAM16X8S + 1;
    constant u_RAM32M: primitives_type :=  u_RAM256X1S + 1;
    constant u_RAM32X1D: primitives_type :=  u_RAM32M + 1;
    constant u_RAM32X1D_1: primitives_type :=  u_RAM32X1D + 1;
    constant u_RAM32X1S: primitives_type :=  u_RAM32X1D_1 + 1;
    constant u_RAM32X1S_1: primitives_type :=  u_RAM32X1S + 1;
    constant u_RAM32X2S: primitives_type :=  u_RAM32X1S_1 + 1;
    constant u_RAM32X4S: primitives_type :=  u_RAM32X2S + 1;
    constant u_RAM32X8S: primitives_type :=  u_RAM32X4S + 1;
    constant u_RAM64M: primitives_type :=  u_RAM32X8S + 1;
    constant u_RAM64X1D: primitives_type :=  u_RAM64M + 1;
    constant u_RAM64X1D_1: primitives_type :=  u_RAM64X1D + 1;
    constant u_RAM64X1S: primitives_type :=  u_RAM64X1D_1 + 1;
    constant u_RAM64X1S_1: primitives_type :=  u_RAM64X1S + 1;
    constant u_RAM64X2S: primitives_type :=  u_RAM64X1S_1 + 1;
    constant u_RAMB16: primitives_type :=  u_RAM64X2S + 1;
    constant u_RAMB16BWE: primitives_type :=  u_RAMB16 + 1;
    constant u_RAMB16BWER: primitives_type :=  u_RAMB16BWE + 1;
    constant u_RAMB16BWE_S18: primitives_type :=  u_RAMB16BWER + 1;
    constant u_RAMB16BWE_S18_S18: primitives_type :=  u_RAMB16BWE_S18 + 1;
    constant u_RAMB16BWE_S18_S9: primitives_type :=  u_RAMB16BWE_S18_S18 + 1;
    constant u_RAMB16BWE_S36: primitives_type :=  u_RAMB16BWE_S18_S9 + 1;
    constant u_RAMB16BWE_S36_S18: primitives_type :=  u_RAMB16BWE_S36 + 1;
    constant u_RAMB16BWE_S36_S36: primitives_type :=  u_RAMB16BWE_S36_S18 + 1;
    constant u_RAMB16BWE_S36_S9: primitives_type :=  u_RAMB16BWE_S36_S36 + 1;
    constant u_RAMB16_S1: primitives_type :=  u_RAMB16BWE_S36_S9 + 1;
    constant u_RAMB16_S18: primitives_type :=  u_RAMB16_S1 + 1;
    constant u_RAMB16_S18_S18: primitives_type :=  u_RAMB16_S18 + 1;
    constant u_RAMB16_S18_S36: primitives_type :=  u_RAMB16_S18_S18 + 1;
    constant u_RAMB16_S1_S1: primitives_type :=  u_RAMB16_S18_S36 + 1;
    constant u_RAMB16_S1_S18: primitives_type :=  u_RAMB16_S1_S1 + 1;
    constant u_RAMB16_S1_S2: primitives_type :=  u_RAMB16_S1_S18 + 1;
    constant u_RAMB16_S1_S36: primitives_type :=  u_RAMB16_S1_S2 + 1;
    constant u_RAMB16_S1_S4: primitives_type :=  u_RAMB16_S1_S36 + 1;
    constant u_RAMB16_S1_S9: primitives_type :=  u_RAMB16_S1_S4 + 1;
    constant u_RAMB16_S2: primitives_type :=  u_RAMB16_S1_S9 + 1;
    constant u_RAMB16_S2_S18: primitives_type :=  u_RAMB16_S2 + 1;
    constant u_RAMB16_S2_S2: primitives_type :=  u_RAMB16_S2_S18 + 1;
    constant u_RAMB16_S2_S36: primitives_type :=  u_RAMB16_S2_S2 + 1;
    constant u_RAMB16_S2_S4: primitives_type :=  u_RAMB16_S2_S36 + 1;
    constant u_RAMB16_S2_S9: primitives_type :=  u_RAMB16_S2_S4 + 1;
    constant u_RAMB16_S36: primitives_type :=  u_RAMB16_S2_S9 + 1;
    constant u_RAMB16_S36_S36: primitives_type :=  u_RAMB16_S36 + 1;
    constant u_RAMB16_S4: primitives_type :=  u_RAMB16_S36_S36 + 1;
    constant u_RAMB16_S4_S18: primitives_type :=  u_RAMB16_S4 + 1;
    constant u_RAMB16_S4_S36: primitives_type :=  u_RAMB16_S4_S18 + 1;
    constant u_RAMB16_S4_S4: primitives_type :=  u_RAMB16_S4_S36 + 1;
    constant u_RAMB16_S4_S9: primitives_type :=  u_RAMB16_S4_S4 + 1;
    constant u_RAMB16_S9: primitives_type :=  u_RAMB16_S4_S9 + 1;
    constant u_RAMB16_S9_S18: primitives_type :=  u_RAMB16_S9 + 1;
    constant u_RAMB16_S9_S36: primitives_type :=  u_RAMB16_S9_S18 + 1;
    constant u_RAMB16_S9_S9: primitives_type :=  u_RAMB16_S9_S36 + 1;
    constant u_RAMB18: primitives_type :=  u_RAMB16_S9_S9 + 1;
    constant u_RAMB18E1: primitives_type :=  u_RAMB18 + 1;
    constant u_RAMB18SDP: primitives_type :=  u_RAMB18E1 + 1;
    constant u_RAMB32_S64_ECC: primitives_type :=  u_RAMB18SDP + 1;
    constant u_RAMB36: primitives_type :=  u_RAMB32_S64_ECC + 1;
    constant u_RAMB36E1: primitives_type :=  u_RAMB36 + 1;
    constant u_RAMB36_EXP: primitives_type :=  u_RAMB36E1 + 1;
    constant u_RAMB36SDP: primitives_type :=  u_RAMB36_EXP + 1;
    constant u_RAMB36SDP_EXP: primitives_type :=  u_RAMB36SDP + 1;
    constant u_RAMB4_S1: primitives_type :=  u_RAMB36SDP_EXP + 1;
    constant u_RAMB4_S16: primitives_type :=  u_RAMB4_S1 + 1;
    constant u_RAMB4_S16_S16: primitives_type :=  u_RAMB4_S16 + 1;
    constant u_RAMB4_S1_S1: primitives_type :=  u_RAMB4_S16_S16 + 1;
    constant u_RAMB4_S1_S16: primitives_type :=  u_RAMB4_S1_S1 + 1;
    constant u_RAMB4_S1_S2: primitives_type :=  u_RAMB4_S1_S16 + 1;
    constant u_RAMB4_S1_S4: primitives_type :=  u_RAMB4_S1_S2 + 1;
    constant u_RAMB4_S1_S8: primitives_type :=  u_RAMB4_S1_S4 + 1;
    constant u_RAMB4_S2: primitives_type :=  u_RAMB4_S1_S8 + 1;
    constant u_RAMB4_S2_S16: primitives_type :=  u_RAMB4_S2 + 1;
    constant u_RAMB4_S2_S2: primitives_type :=  u_RAMB4_S2_S16 + 1;
    constant u_RAMB4_S2_S4: primitives_type :=  u_RAMB4_S2_S2 + 1;
    constant u_RAMB4_S2_S8: primitives_type :=  u_RAMB4_S2_S4 + 1;
    constant u_RAMB4_S4: primitives_type :=  u_RAMB4_S2_S8 + 1;
    constant u_RAMB4_S4_S16: primitives_type :=  u_RAMB4_S4 + 1;
    constant u_RAMB4_S4_S4: primitives_type :=  u_RAMB4_S4_S16 + 1;
    constant u_RAMB4_S4_S8: primitives_type :=  u_RAMB4_S4_S4 + 1;
    constant u_RAMB4_S8: primitives_type :=  u_RAMB4_S4_S8 + 1;
    constant u_RAMB4_S8_S16: primitives_type :=  u_RAMB4_S8 + 1;
    constant u_RAMB4_S8_S8: primitives_type :=  u_RAMB4_S8_S16 + 1;
    constant u_RAMB8BWER: primitives_type :=  u_RAMB4_S8_S8 + 1;
    constant u_ROM128X1: primitives_type :=  u_RAMB8BWER + 1;
    constant u_ROM16X1: primitives_type :=  u_ROM128X1 + 1;
    constant u_ROM256X1: primitives_type :=  u_ROM16X1 + 1;
    constant u_ROM32X1: primitives_type :=  u_ROM256X1 + 1;
    constant u_ROM64X1: primitives_type :=  u_ROM32X1 + 1;
    constant u_SLAVE_SPI: primitives_type :=  u_ROM64X1 + 1;
    constant u_SPI_ACCESS: primitives_type :=  u_SLAVE_SPI + 1;
    constant u_SRL16: primitives_type :=  u_SPI_ACCESS + 1;
    constant u_SRL16_1: primitives_type :=  u_SRL16 + 1;
    constant u_SRL16E: primitives_type :=  u_SRL16_1 + 1;
    constant u_SRL16E_1: primitives_type :=  u_SRL16E + 1;
    constant u_SRLC16: primitives_type :=  u_SRL16E_1 + 1;
    constant u_SRLC16_1: primitives_type :=  u_SRLC16 + 1;
    constant u_SRLC16E: primitives_type :=  u_SRLC16_1 + 1;
    constant u_SRLC16E_1: primitives_type :=  u_SRLC16E + 1;
    constant u_SRLC32E: primitives_type :=  u_SRLC16E_1 + 1;
    constant u_STARTBUF_SPARTAN2: primitives_type :=  u_SRLC32E + 1;
    constant u_STARTBUF_SPARTAN3: primitives_type :=  u_STARTBUF_SPARTAN2 + 1;
    constant u_STARTBUF_SPARTAN3E: primitives_type :=  u_STARTBUF_SPARTAN3 + 1;
    constant u_STARTBUF_VIRTEX: primitives_type :=  u_STARTBUF_SPARTAN3E + 1;
    constant u_STARTBUF_VIRTEX2: primitives_type :=  u_STARTBUF_VIRTEX + 1;
    constant u_STARTBUF_VIRTEX4: primitives_type :=  u_STARTBUF_VIRTEX2 + 1;
    constant u_STARTUP_SPARTAN2: primitives_type :=  u_STARTBUF_VIRTEX4 + 1;
    constant u_STARTUP_SPARTAN3: primitives_type :=  u_STARTUP_SPARTAN2 + 1;
    constant u_STARTUP_SPARTAN3A: primitives_type :=  u_STARTUP_SPARTAN3 + 1;
    constant u_STARTUP_SPARTAN3E: primitives_type :=  u_STARTUP_SPARTAN3A + 1;
    constant u_STARTUP_SPARTAN6: primitives_type :=  u_STARTUP_SPARTAN3E + 1;
    constant u_STARTUP_VIRTEX: primitives_type :=  u_STARTUP_SPARTAN6 + 1;
    constant u_STARTUP_VIRTEX2: primitives_type :=  u_STARTUP_VIRTEX + 1;
    constant u_STARTUP_VIRTEX4: primitives_type :=  u_STARTUP_VIRTEX2 + 1;
    constant u_STARTUP_VIRTEX5: primitives_type :=  u_STARTUP_VIRTEX4 + 1;
    constant u_STARTUP_VIRTEX6: primitives_type :=  u_STARTUP_VIRTEX5 + 1;
    constant u_SUSPEND_SYNC: primitives_type :=  u_STARTUP_VIRTEX6 + 1;
    constant u_SYSMON: primitives_type :=  u_SUSPEND_SYNC + 1;
    constant u_TEMAC_SINGLE: primitives_type :=  u_SYSMON + 1;
    constant u_TOC: primitives_type :=  u_TEMAC_SINGLE + 1;
    constant u_TOCBUF: primitives_type :=  u_TOC + 1;
    constant u_USR_ACCESS_VIRTEX4: primitives_type :=  u_TOCBUF + 1;
    constant u_USR_ACCESS_VIRTEX5: primitives_type :=  u_USR_ACCESS_VIRTEX4 + 1;
    constant u_USR_ACCESS_VIRTEX6: primitives_type :=  u_USR_ACCESS_VIRTEX5 + 1;
    constant u_VCC: primitives_type :=  u_USR_ACCESS_VIRTEX6 + 1;
    constant u_XNOR2: primitives_type :=  u_VCC + 1;
    constant u_XNOR3: primitives_type :=  u_XNOR2 + 1;
    constant u_XNOR4: primitives_type :=  u_XNOR3 + 1;
    constant u_XOR2: primitives_type :=  u_XNOR4 + 1;
    constant u_XOR3: primitives_type :=  u_XOR2 + 1;
    constant u_XOR4: primitives_type :=  u_XOR3 + 1;
    constant u_XORCY: primitives_type :=  u_XOR4 + 1;
    constant u_XORCY_D: primitives_type :=  u_XORCY + 1;
    constant u_XORCY_L: primitives_type :=  u_XORCY_D + 1;
    -- Primitives added for artix7, kintex6, virtex7, and zynq 
    constant u_AND2B1: primitives_type :=  u_XORCY_L + 1;
    constant u_AND2B2: primitives_type :=  u_AND2B1 + 1;
    constant u_AND3B1: primitives_type :=  u_AND2B2 + 1;
    constant u_AND3B2: primitives_type :=  u_AND3B1 + 1;
    constant u_AND3B3: primitives_type :=  u_AND3B2 + 1;
    constant u_AND4B1: primitives_type :=  u_AND3B3 + 1;
    constant u_AND4B2: primitives_type :=  u_AND4B1 + 1;
    constant u_AND4B3: primitives_type :=  u_AND4B2 + 1;
    constant u_AND4B4: primitives_type :=  u_AND4B3 + 1;
    constant u_AND5: primitives_type :=  u_AND4B4 + 1;
    constant u_AND5B1: primitives_type :=  u_AND5 + 1;
    constant u_AND5B2: primitives_type :=  u_AND5B1 + 1;
    constant u_AND5B3: primitives_type :=  u_AND5B2 + 1;
    constant u_AND5B4: primitives_type :=  u_AND5B3 + 1;
    constant u_AND5B5: primitives_type :=  u_AND5B4 + 1;
    constant u_BSCANE2: primitives_type :=  u_AND5B5 + 1;
    constant u_BUFMR: primitives_type :=  u_BSCANE2 + 1;
    constant u_BUFMRCE: primitives_type :=  u_BUFMR + 1;
    constant u_CAPTUREE2: primitives_type :=  u_BUFMRCE + 1;
    constant u_CFG_IO_ACCESS: primitives_type :=  u_CAPTUREE2 + 1;
    constant u_FRAME_ECCE2: primitives_type :=  u_CFG_IO_ACCESS + 1;
    constant u_GTXE2_CHANNEL: primitives_type :=  u_FRAME_ECCE2 + 1;
    constant u_GTXE2_COMMON: primitives_type :=  u_GTXE2_CHANNEL + 1;
    constant u_IBUF_DCIEN: primitives_type :=  u_GTXE2_COMMON + 1;
    constant u_IBUFDS_BLVDS_25: primitives_type :=  u_IBUF_DCIEN + 1;
    constant u_IBUFDS_DCIEN: primitives_type :=  u_IBUFDS_BLVDS_25 + 1;
    constant u_IBUFDS_DIFF_OUT_DCIEN: primitives_type :=  u_IBUFDS_DCIEN + 1;
    constant u_IBUFDS_GTE2: primitives_type :=  u_IBUFDS_DIFF_OUT_DCIEN + 1;
    constant u_IBUFDS_LVDS_25: primitives_type :=  u_IBUFDS_GTE2 + 1;
    constant u_IBUFGDS_BLVDS_25: primitives_type :=  u_IBUFDS_LVDS_25 + 1;
    constant u_IBUFGDS_LVDS_25: primitives_type :=  u_IBUFGDS_BLVDS_25 + 1;
    constant u_IBUFG_HSTL_I_18: primitives_type :=  u_IBUFGDS_LVDS_25 + 1;
    constant u_IBUFG_HSTL_I_DCI: primitives_type :=  u_IBUFG_HSTL_I_18 + 1;
    constant u_IBUFG_HSTL_I_DCI_18: primitives_type :=  u_IBUFG_HSTL_I_DCI + 1;
    constant u_IBUFG_HSTL_II: primitives_type :=  u_IBUFG_HSTL_I_DCI_18 + 1;
    constant u_IBUFG_HSTL_II_18: primitives_type :=  u_IBUFG_HSTL_II + 1;
    constant u_IBUFG_HSTL_II_DCI: primitives_type :=  u_IBUFG_HSTL_II_18 + 1;
    constant u_IBUFG_HSTL_II_DCI_18: primitives_type :=  u_IBUFG_HSTL_II_DCI + 1;
    constant u_IBUFG_HSTL_III_18: primitives_type :=  u_IBUFG_HSTL_II_DCI_18 + 1;
    constant u_IBUFG_HSTL_III_DCI: primitives_type :=  u_IBUFG_HSTL_III_18 + 1;
    constant u_IBUFG_HSTL_III_DCI_18: primitives_type :=  u_IBUFG_HSTL_III_DCI + 1;
    constant u_IBUFG_LVCMOS12: primitives_type :=  u_IBUFG_HSTL_III_DCI_18 + 1;
    constant u_IBUFG_LVCMOS15: primitives_type :=  u_IBUFG_LVCMOS12 + 1;
    constant u_IBUFG_LVCMOS25: primitives_type :=  u_IBUFG_LVCMOS15 + 1;
    constant u_IBUFG_LVCMOS33: primitives_type :=  u_IBUFG_LVCMOS25 + 1;
    constant u_IBUFG_LVDCI_15: primitives_type :=  u_IBUFG_LVCMOS33 + 1;
    constant u_IBUFG_LVDCI_18: primitives_type :=  u_IBUFG_LVDCI_15 + 1;
    constant u_IBUFG_LVDCI_DV2_15: primitives_type :=  u_IBUFG_LVDCI_18 + 1;
    constant u_IBUFG_LVDCI_DV2_18: primitives_type :=  u_IBUFG_LVDCI_DV2_15 + 1;
    constant u_IBUFG_LVTTL: primitives_type :=  u_IBUFG_LVDCI_DV2_18 + 1;
    constant u_IBUFG_SSTL18_I: primitives_type :=  u_IBUFG_LVTTL + 1;
    constant u_IBUFG_SSTL18_I_DCI: primitives_type :=  u_IBUFG_SSTL18_I + 1;
    constant u_IBUFG_SSTL18_II: primitives_type :=  u_IBUFG_SSTL18_I_DCI + 1;
    constant u_IBUFG_SSTL18_II_DCI: primitives_type :=  u_IBUFG_SSTL18_II + 1;
    constant u_IBUF_HSTL_I_18: primitives_type :=  u_IBUFG_SSTL18_II_DCI + 1;
    constant u_IBUF_HSTL_I_DCI: primitives_type :=  u_IBUF_HSTL_I_18 + 1;
    constant u_IBUF_HSTL_I_DCI_18: primitives_type :=  u_IBUF_HSTL_I_DCI + 1;
    constant u_IBUF_HSTL_II: primitives_type :=  u_IBUF_HSTL_I_DCI_18 + 1;
    constant u_IBUF_HSTL_II_18: primitives_type :=  u_IBUF_HSTL_II + 1;
    constant u_IBUF_HSTL_II_DCI: primitives_type :=  u_IBUF_HSTL_II_18 + 1;
    constant u_IBUF_HSTL_II_DCI_18: primitives_type :=  u_IBUF_HSTL_II_DCI + 1;
    constant u_IBUF_HSTL_III_18: primitives_type :=  u_IBUF_HSTL_II_DCI_18 + 1;
    constant u_IBUF_HSTL_III_DCI: primitives_type :=  u_IBUF_HSTL_III_18 + 1;
    constant u_IBUF_HSTL_III_DCI_18: primitives_type :=  u_IBUF_HSTL_III_DCI + 1;
    constant u_IBUF_LVCMOS12: primitives_type :=  u_IBUF_HSTL_III_DCI_18 + 1;
    constant u_IBUF_LVCMOS15: primitives_type :=  u_IBUF_LVCMOS12 + 1;
    constant u_IBUF_LVCMOS25: primitives_type :=  u_IBUF_LVCMOS15 + 1;
    constant u_IBUF_LVCMOS33: primitives_type :=  u_IBUF_LVCMOS25 + 1;
    constant u_IBUF_LVDCI_15: primitives_type :=  u_IBUF_LVCMOS33 + 1;
    constant u_IBUF_LVDCI_18: primitives_type :=  u_IBUF_LVDCI_15 + 1;
    constant u_IBUF_LVDCI_DV2_15: primitives_type :=  u_IBUF_LVDCI_18 + 1;
    constant u_IBUF_LVDCI_DV2_18: primitives_type :=  u_IBUF_LVDCI_DV2_15 + 1;
    constant u_IBUF_LVTTL: primitives_type :=  u_IBUF_LVDCI_DV2_18 + 1;
    constant u_IBUF_SSTL18_I: primitives_type :=  u_IBUF_LVTTL + 1;
    constant u_IBUF_SSTL18_I_DCI: primitives_type :=  u_IBUF_SSTL18_I + 1;
    constant u_IBUF_SSTL18_II: primitives_type :=  u_IBUF_SSTL18_I_DCI + 1;
    constant u_IBUF_SSTL18_II_DCI: primitives_type :=  u_IBUF_SSTL18_II + 1;
    constant u_ICAPE2: primitives_type :=  u_IBUF_SSTL18_II_DCI + 1;
    constant u_IDELAYE2: primitives_type :=  u_ICAPE2 + 1;
    constant u_IN_FIFO: primitives_type :=  u_IDELAYE2 + 1;
    constant u_IOBUFDS_BLVDS_25: primitives_type :=  u_IN_FIFO + 1;
    constant u_IOBUFDS_DIFF_OUT_DCIEN: primitives_type :=  u_IOBUFDS_BLVDS_25 + 1;
    constant u_IOBUF_HSTL_I_18: primitives_type :=  u_IOBUFDS_DIFF_OUT_DCIEN + 1;
    constant u_IOBUF_HSTL_II: primitives_type :=  u_IOBUF_HSTL_I_18 + 1;
    constant u_IOBUF_HSTL_II_18: primitives_type :=  u_IOBUF_HSTL_II + 1;
    constant u_IOBUF_HSTL_II_DCI: primitives_type :=  u_IOBUF_HSTL_II_18 + 1;
    constant u_IOBUF_HSTL_II_DCI_18: primitives_type :=  u_IOBUF_HSTL_II_DCI + 1;
    constant u_IOBUF_HSTL_III_18: primitives_type :=  u_IOBUF_HSTL_II_DCI_18 + 1;
    constant u_IOBUF_LVCMOS12: primitives_type :=  u_IOBUF_HSTL_III_18 + 1;
    constant u_IOBUF_LVCMOS15: primitives_type :=  u_IOBUF_LVCMOS12 + 1;
    constant u_IOBUF_LVCMOS25: primitives_type :=  u_IOBUF_LVCMOS15 + 1;
    constant u_IOBUF_LVCMOS33: primitives_type :=  u_IOBUF_LVCMOS25 + 1;
    constant u_IOBUF_LVDCI_15: primitives_type :=  u_IOBUF_LVCMOS33 + 1;
    constant u_IOBUF_LVDCI_18: primitives_type :=  u_IOBUF_LVDCI_15 + 1;
    constant u_IOBUF_LVDCI_DV2_15: primitives_type :=  u_IOBUF_LVDCI_18 + 1;
    constant u_IOBUF_LVDCI_DV2_18: primitives_type :=  u_IOBUF_LVDCI_DV2_15 + 1;
    constant u_IOBUF_LVTTL: primitives_type :=  u_IOBUF_LVDCI_DV2_18 + 1;
    constant u_IOBUF_SSTL18_I: primitives_type :=  u_IOBUF_LVTTL + 1;
    constant u_IOBUF_SSTL18_II: primitives_type :=  u_IOBUF_SSTL18_I + 1;
    constant u_IOBUF_SSTL18_II_DCI: primitives_type :=  u_IOBUF_SSTL18_II + 1;
    constant u_ISERDESE2: primitives_type :=  u_IOBUF_SSTL18_II_DCI + 1;
    constant u_JTAG_SIME2: primitives_type :=  u_ISERDESE2 + 1;
    constant u_LUT6_2: primitives_type :=  u_JTAG_SIME2 + 1;
    constant u_MMCME2_ADV: primitives_type :=  u_LUT6_2 + 1;
    constant u_MMCME2_BASE: primitives_type :=  u_MMCME2_ADV + 1;
    constant u_NAND2B1: primitives_type :=  u_MMCME2_BASE + 1;
    constant u_NAND2B2: primitives_type :=  u_NAND2B1 + 1;
    constant u_NAND3B1: primitives_type :=  u_NAND2B2 + 1;
    constant u_NAND3B2: primitives_type :=  u_NAND3B1 + 1;
    constant u_NAND3B3: primitives_type :=  u_NAND3B2 + 1;
    constant u_NAND4B1: primitives_type :=  u_NAND3B3 + 1;
    constant u_NAND4B2: primitives_type :=  u_NAND4B1 + 1;
    constant u_NAND4B3: primitives_type :=  u_NAND4B2 + 1;
    constant u_NAND4B4: primitives_type :=  u_NAND4B3 + 1;
    constant u_NAND5: primitives_type :=  u_NAND4B4 + 1;
    constant u_NAND5B1: primitives_type :=  u_NAND5 + 1;
    constant u_NAND5B2: primitives_type :=  u_NAND5B1 + 1;
    constant u_NAND5B3: primitives_type :=  u_NAND5B2 + 1;
    constant u_NAND5B4: primitives_type :=  u_NAND5B3 + 1;
    constant u_NAND5B5: primitives_type :=  u_NAND5B4 + 1;
    constant u_NOR2B1: primitives_type :=  u_NAND5B5 + 1;
    constant u_NOR2B2: primitives_type :=  u_NOR2B1 + 1;
    constant u_NOR3B1: primitives_type :=  u_NOR2B2 + 1;
    constant u_NOR3B2: primitives_type :=  u_NOR3B1 + 1;
    constant u_NOR3B3: primitives_type :=  u_NOR3B2 + 1;
    constant u_NOR4B1: primitives_type :=  u_NOR3B3 + 1;
    constant u_NOR4B2: primitives_type :=  u_NOR4B1 + 1;
    constant u_NOR4B3: primitives_type :=  u_NOR4B2 + 1;
    constant u_NOR4B4: primitives_type :=  u_NOR4B3 + 1;
    constant u_NOR5: primitives_type :=  u_NOR4B4 + 1;
    constant u_NOR5B1: primitives_type :=  u_NOR5 + 1;
    constant u_NOR5B2: primitives_type :=  u_NOR5B1 + 1;
    constant u_NOR5B3: primitives_type :=  u_NOR5B2 + 1;
    constant u_NOR5B4: primitives_type :=  u_NOR5B3 + 1;
    constant u_NOR5B5: primitives_type :=  u_NOR5B4 + 1;
    constant u_OBUFDS_BLVDS_25: primitives_type :=  u_NOR5B5 + 1;
    constant u_OBUFDS_DUAL_BUF: primitives_type :=  u_OBUFDS_BLVDS_25 + 1;
    constant u_OBUFDS_LVDS_25: primitives_type :=  u_OBUFDS_DUAL_BUF + 1;
    constant u_OBUF_HSTL_I_18: primitives_type :=  u_OBUFDS_LVDS_25 + 1;
    constant u_OBUF_HSTL_I_DCI: primitives_type :=  u_OBUF_HSTL_I_18 + 1;
    constant u_OBUF_HSTL_I_DCI_18: primitives_type :=  u_OBUF_HSTL_I_DCI + 1;
    constant u_OBUF_HSTL_II: primitives_type :=  u_OBUF_HSTL_I_DCI_18 + 1;
    constant u_OBUF_HSTL_II_18: primitives_type :=  u_OBUF_HSTL_II + 1;
    constant u_OBUF_HSTL_II_DCI: primitives_type :=  u_OBUF_HSTL_II_18 + 1;
    constant u_OBUF_HSTL_II_DCI_18: primitives_type :=  u_OBUF_HSTL_II_DCI + 1;
    constant u_OBUF_HSTL_III_18: primitives_type :=  u_OBUF_HSTL_II_DCI_18 + 1;
    constant u_OBUF_HSTL_III_DCI: primitives_type :=  u_OBUF_HSTL_III_18 + 1;
    constant u_OBUF_HSTL_III_DCI_18: primitives_type :=  u_OBUF_HSTL_III_DCI + 1;
    constant u_OBUF_LVCMOS12: primitives_type :=  u_OBUF_HSTL_III_DCI_18 + 1;
    constant u_OBUF_LVCMOS15: primitives_type :=  u_OBUF_LVCMOS12 + 1;
    constant u_OBUF_LVCMOS25: primitives_type :=  u_OBUF_LVCMOS15 + 1;
    constant u_OBUF_LVCMOS33: primitives_type :=  u_OBUF_LVCMOS25 + 1;
    constant u_OBUF_LVDCI_15: primitives_type :=  u_OBUF_LVCMOS33 + 1;
    constant u_OBUF_LVDCI_18: primitives_type :=  u_OBUF_LVDCI_15 + 1;
    constant u_OBUF_LVDCI_DV2_15: primitives_type :=  u_OBUF_LVDCI_18 + 1;
    constant u_OBUF_LVDCI_DV2_18: primitives_type :=  u_OBUF_LVDCI_DV2_15 + 1;
    constant u_OBUF_LVTTL: primitives_type :=  u_OBUF_LVDCI_DV2_18 + 1;
    constant u_OBUF_SSTL18_I: primitives_type :=  u_OBUF_LVTTL + 1;
    constant u_OBUF_SSTL18_I_DCI: primitives_type :=  u_OBUF_SSTL18_I + 1;
    constant u_OBUF_SSTL18_II: primitives_type :=  u_OBUF_SSTL18_I_DCI + 1;
    constant u_OBUF_SSTL18_II_DCI: primitives_type :=  u_OBUF_SSTL18_II + 1;
    constant u_OBUFT_DCIEN: primitives_type :=  u_OBUF_SSTL18_II_DCI + 1;
    constant u_OBUFTDS_BLVDS_25: primitives_type :=  u_OBUFT_DCIEN + 1;
    constant u_OBUFTDS_DCIEN: primitives_type :=  u_OBUFTDS_BLVDS_25 + 1;
    constant u_OBUFTDS_DCIEN_DUAL_BUF: primitives_type :=  u_OBUFTDS_DCIEN + 1;
    constant u_OBUFTDS_DUAL_BUF: primitives_type :=  u_OBUFTDS_DCIEN_DUAL_BUF + 1;
    constant u_OBUFTDS_LVDS_25: primitives_type :=  u_OBUFTDS_DUAL_BUF + 1;
    constant u_OBUFT_HSTL_I_18: primitives_type :=  u_OBUFTDS_LVDS_25 + 1;
    constant u_OBUFT_HSTL_I_DCI: primitives_type :=  u_OBUFT_HSTL_I_18 + 1;
    constant u_OBUFT_HSTL_I_DCI_18: primitives_type :=  u_OBUFT_HSTL_I_DCI + 1;
    constant u_OBUFT_HSTL_II: primitives_type :=  u_OBUFT_HSTL_I_DCI_18 + 1;
    constant u_OBUFT_HSTL_II_18: primitives_type :=  u_OBUFT_HSTL_II + 1;
    constant u_OBUFT_HSTL_II_DCI: primitives_type :=  u_OBUFT_HSTL_II_18 + 1;
    constant u_OBUFT_HSTL_II_DCI_18: primitives_type :=  u_OBUFT_HSTL_II_DCI + 1;
    constant u_OBUFT_HSTL_III_18: primitives_type :=  u_OBUFT_HSTL_II_DCI_18 + 1;
    constant u_OBUFT_HSTL_III_DCI: primitives_type :=  u_OBUFT_HSTL_III_18 + 1;
    constant u_OBUFT_HSTL_III_DCI_18: primitives_type :=  u_OBUFT_HSTL_III_DCI + 1;
    constant u_OBUFT_LVCMOS12: primitives_type :=  u_OBUFT_HSTL_III_DCI_18 + 1;
    constant u_OBUFT_LVCMOS15: primitives_type :=  u_OBUFT_LVCMOS12 + 1;
    constant u_OBUFT_LVCMOS25: primitives_type :=  u_OBUFT_LVCMOS15 + 1;
    constant u_OBUFT_LVCMOS33: primitives_type :=  u_OBUFT_LVCMOS25 + 1;
    constant u_OBUFT_LVDCI_15: primitives_type :=  u_OBUFT_LVCMOS33 + 1;
    constant u_OBUFT_LVDCI_18: primitives_type :=  u_OBUFT_LVDCI_15 + 1;
    constant u_OBUFT_LVDCI_DV2_15: primitives_type :=  u_OBUFT_LVDCI_18 + 1;
    constant u_OBUFT_LVDCI_DV2_18: primitives_type :=  u_OBUFT_LVDCI_DV2_15 + 1;
    constant u_OBUFT_LVTTL: primitives_type :=  u_OBUFT_LVDCI_DV2_18 + 1;
    constant u_OBUFT_SSTL18_I: primitives_type :=  u_OBUFT_LVTTL + 1;
    constant u_OBUFT_SSTL18_I_DCI: primitives_type :=  u_OBUFT_SSTL18_I + 1;
    constant u_OBUFT_SSTL18_II: primitives_type :=  u_OBUFT_SSTL18_I_DCI + 1;
    constant u_OBUFT_SSTL18_II_DCI: primitives_type :=  u_OBUFT_SSTL18_II + 1;
    constant u_ODELAYE2: primitives_type :=  u_OBUFT_SSTL18_II_DCI + 1;
    constant u_OR2B1: primitives_type :=  u_ODELAYE2 + 1;
    constant u_OR2B2: primitives_type :=  u_OR2B1 + 1;
    constant u_OR3B1: primitives_type :=  u_OR2B2 + 1;
    constant u_OR3B2: primitives_type :=  u_OR3B1 + 1;
    constant u_OR3B3: primitives_type :=  u_OR3B2 + 1;
    constant u_OR4B1: primitives_type :=  u_OR3B3 + 1;
    constant u_OR4B2: primitives_type :=  u_OR4B1 + 1;
    constant u_OR4B3: primitives_type :=  u_OR4B2 + 1;
    constant u_OR4B4: primitives_type :=  u_OR4B3 + 1;
    constant u_OR5: primitives_type :=  u_OR4B4 + 1;
    constant u_OR5B1: primitives_type :=  u_OR5 + 1;
    constant u_OR5B2: primitives_type :=  u_OR5B1 + 1;
    constant u_OR5B3: primitives_type :=  u_OR5B2 + 1;
    constant u_OR5B4: primitives_type :=  u_OR5B3 + 1;
    constant u_OR5B5: primitives_type :=  u_OR5B4 + 1;
    constant u_OSERDESE2: primitives_type :=  u_OR5B5 + 1;
    constant u_OUT_FIFO: primitives_type :=  u_OSERDESE2 + 1;
    constant u_PCIE_2_1: primitives_type :=  u_OUT_FIFO + 1;
    constant u_PHASER_IN: primitives_type :=  u_PCIE_2_1 + 1;
    constant u_PHASER_IN_PHY: primitives_type :=  u_PHASER_IN + 1;
    constant u_PHASER_OUT: primitives_type :=  u_PHASER_IN_PHY + 1;
    constant u_PHASER_OUT_PHY: primitives_type :=  u_PHASER_OUT + 1;
    constant u_PHASER_REF: primitives_type :=  u_PHASER_OUT_PHY + 1;
    constant u_PHY_CONTROL: primitives_type :=  u_PHASER_REF + 1;
    constant u_PLLE2_ADV: primitives_type :=  u_PHY_CONTROL + 1;
    constant u_PLLE2_BASE: primitives_type :=  u_PLLE2_ADV + 1;
    constant u_PSS: primitives_type :=  u_PLLE2_BASE + 1;
    constant u_RAMD32: primitives_type :=  u_PSS + 1;
    constant u_RAMD64E: primitives_type :=  u_RAMD32 + 1;
    constant u_RAMS32: primitives_type :=  u_RAMD64E + 1;
    constant u_RAMS64E: primitives_type :=  u_RAMS32 + 1;
    constant u_SIM_CONFIGE2: primitives_type :=  u_RAMS64E + 1;
    constant u_STARTUPE2: primitives_type :=  u_SIM_CONFIGE2 + 1;
    constant u_USR_ACCESSE2: primitives_type :=  u_STARTUPE2 + 1;
    constant u_XADC: primitives_type :=  u_USR_ACCESSE2 + 1;
    constant u_XNOR5: primitives_type :=  u_XADC + 1;
    constant u_XOR5: primitives_type :=  u_XNOR5 + 1;
    constant u_ZHOLD_DELAY: primitives_type :=  u_XOR5 + 1;

    type primitive_array_type is array (natural range <>) of primitives_type;


    ---------------------------------------------------------------------------- 
    -- Returns true if primitive is available in family.
    --
    -- Examples:
    --
    --     supported(virtex2, u_RAMB16_S2) returns true because the RAMB16_S2
    --                                     primitive is available in the
    --                                     virtex2 family.
    --
    --     supported(spartan3, u_RAM4B_S4) returns false because the RAMB4_S4
    --                                     primitive is not available in the
    --                                     spartan3 family.
    ---------------------------------------------------------------------------- 
    function supported( family         : families_type;
                        primitive      : primitives_type
                      ) return boolean;


    ---------------------------------------------------------------------------- 
    -- This is an overload of function 'supported' (see above). It allows a list
    -- of primitives to be tested.
    --
    -- Returns true if all of primitives in the list are available in family.
    --
    -- Example:        supported(spartan3, (u_MUXCY, u_XORCY, u_FD))
    -- is
    -- equivalent to:  supported(spartan3, u_MUXCY) and
    --                 supported(spartan3, u_XORCY) and
    --                 supported(spartan3, u_FD);
    ---------------------------------------------------------------------------- 
    function supported( family         : families_type;
                        primitives     : primitive_array_type
                      ) return boolean;


    ---------------------------------------------------------------------------- 
    -- Below, are overloads of function 'supported' that allow the family
    -- parameter to be passed as a string. These correspond to the above two
    -- functions otherwise.
    ---------------------------------------------------------------------------- 
    function supported( fam_as_str     : string;
                        primitive      : primitives_type
                      ) return boolean;


    function supported( fam_as_str     : string;
                        primitives     : primitive_array_type
                      ) return boolean;



    ---------------------------------------------------------------------------- 
    -- Conversions from/to STRING to/from families_type.
    -- These are convenience functions that are not normally needed when
    -- using the 'supported' functions.
    ---------------------------------------------------------------------------- 
    function str2fam( fam_as_string  : string ) return families_type;


    function fam2str( fam :  families_type ) return string;

    ---------------------------------------------------------------------------- 
    -- Function: native_lut_size
    --
    -- Returns the largest LUT size available in FPGA family, fam.
    -- If no LUT is available in fam, then returns zero by default, unless
    -- the call specifies a no_lut_return_val, in which case this value
    -- is returned.
    --
    -- The function is available in two overload versions, one for each
    -- way of passing the fam argument.
    ---------------------------------------------------------------------------- 
    function native_lut_size( fam : families_type;
                              no_lut_return_val : natural := 0
                            ) return natural;

    function native_lut_size( fam_as_string : string;
                              no_lut_return_val : natural := 0
                            ) return natural;
                      

    ---------------------------------------------------------------------------- 
    -- Function: equalIgnoringCase
    --
    -- Compare one string against another for equality with case insensitivity.
    -- Can be used to test see if a family, C_FAMILY, is equal to some
    -- family. However such usage is discouraged. Use instead availability
    -- primitive guards based on the function, 'supported', wherever possible.
    ---------------------------------------------------------------------------- 
    function equalIgnoringCase( str1, str2 : string ) return boolean;
    
    
    
    ---------------------------------------------------------------------------- 
    -- Function: get_root_family
    --
    -- This function takes in the string for the desired FPGA family type and
    -- returns the root FPGA family type. This is used for derivative part 
    -- aliasing to the root family.
    ---------------------------------------------------------------------------- 
    function get_root_family( family_in : string ) return string;
    
    
    
    

end package family_support;



package body family_support is

    type     prim_status_type is (
                                    n  -- no
                                  , y  -- yes
                                  , u  -- unknown, not used. However, we use
                                       -- an enumeration to allow for
                                       -- possible future enhancement.
                                 );

    type     fam_prim_status is array (primitives_type) of prim_status_type;

    type     fam_has_prim_type is array (families_type) of fam_prim_status;

-- Performance workaround (XST procedure and function handling).
-- The fam_has_prim constant is initialized by an aggregate rather than by the
-- following function. A version of this file with this function not
-- commented was employed in building the aggregate. So, what is below still
-- defines the family-primitive matirix.
--#   ---------------------------------------------------------------------------- 
--#   --  This function is used to populate the matrix of family/primitive values. 
--#   ---------------------------------------------------------------------------- 
--#   ---( 
--#   function prim_population return fam_has_prim_type is 
--#       variable pp : fam_has_prim_type := (others => (others => n)); 
--#
--#       procedure set_to(  stat      : prim_status_type 
--#                        ; fam       : families_type 
--#                        ; prim_list : primitive_array_type 
--#                       ) is 
--#       begin 
--#           for i in prim_list'range loop 
--#               pp(fam)(prim_list(i)) := stat; 
--#           end loop; 
--#       end set_to; 
--#
--#   begin 
--#       set_to(y, virtex, ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_VIRTEX 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFE 
--#                           , u_BUFG 
--#                           , u_BUFGDLL 
--#                           , u_BUFGP 
--#                           , u_BUFT 
--#                           , u_CAPTURE_VIRTEX 
--#                           , u_CLKDLL 
--#                           , u_CLKDLLHF 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FMAP 
--#                           , u_GND 
--#                           , u_IBUF 
--#                           , u_IBUFG 
--#                           , u_IBUFG_AGP 
--#                           , u_IBUFG_CTT 
--#                           , u_IBUFG_GTL 
--#                           , u_IBUFG_GTLP 
--#                           , u_IBUFG_HSTL_I 
--#                           , u_IBUFG_HSTL_III 
--#                           , u_IBUFG_HSTL_IV 
--#                           , u_IBUFG_LVCMOS2 
--#                           , u_IBUFG_PCI33_3 
--#                           , u_IBUFG_PCI33_5 
--#                           , u_IBUFG_PCI66_3 
--#                           , u_IBUFG_SSTL2_I 
--#                           , u_IBUFG_SSTL2_II 
--#                           , u_IBUFG_SSTL3_I 
--#                           , u_IBUFG_SSTL3_II 
--#                           , u_IBUF_AGP 
--#                           , u_IBUF_CTT 
--#                           , u_IBUF_GTL 
--#                           , u_IBUF_GTLP 
--#                           , u_IBUF_HSTL_I 
--#                           , u_IBUF_HSTL_III 
--#                           , u_IBUF_HSTL_IV 
--#                           , u_IBUF_LVCMOS2 
--#                           , u_IBUF_PCI33_3 
--#                           , u_IBUF_PCI33_5 
--#                           , u_IBUF_PCI66_3 
--#                           , u_IBUF_SSTL2_I 
--#                           , u_IBUF_SSTL2_II 
--#                           , u_IBUF_SSTL3_I 
--#                           , u_IBUF_SSTL3_II 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUF_AGP 
--#                           , u_IOBUF_CTT 
--#                           , u_IOBUF_F_12 
--#                           , u_IOBUF_F_16 
--#                           , u_IOBUF_F_2 
--#                           , u_IOBUF_F_24 
--#                           , u_IOBUF_F_4 
--#                           , u_IOBUF_F_6 
--#                           , u_IOBUF_F_8 
--#                           , u_IOBUF_GTL 
--#                           , u_IOBUF_GTLP 
--#                           , u_IOBUF_HSTL_I 
--#                           , u_IOBUF_HSTL_III 
--#                           , u_IOBUF_HSTL_IV 
--#                           , u_IOBUF_LVCMOS2 
--#                           , u_IOBUF_PCI33_3 
--#                           , u_IOBUF_PCI33_5 
--#                           , u_IOBUF_PCI66_3 
--#                           , u_IOBUF_SSTL2_I 
--#                           , u_IOBUF_SSTL2_II 
--#                           , u_IOBUF_SSTL3_I 
--#                           , u_IOBUF_SSTL3_II 
--#                           , u_IOBUF_S_12 
--#                           , u_IOBUF_S_16 
--#                           , u_IOBUF_S_2 
--#                           , u_IOBUF_S_24 
--#                           , u_IOBUF_S_4 
--#                           , u_IOBUF_S_6 
--#                           , u_IOBUF_S_8 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFT 
--#                           , u_OBUFT_AGP 
--#                           , u_OBUFT_CTT 
--#                           , u_OBUFT_F_12 
--#                           , u_OBUFT_F_16 
--#                           , u_OBUFT_F_2 
--#                           , u_OBUFT_F_24 
--#                           , u_OBUFT_F_4 
--#                           , u_OBUFT_F_6 
--#                           , u_OBUFT_F_8 
--#                           , u_OBUFT_GTL 
--#                           , u_OBUFT_GTLP 
--#                           , u_OBUFT_HSTL_I 
--#                           , u_OBUFT_HSTL_III 
--#                           , u_OBUFT_HSTL_IV 
--#                           , u_OBUFT_LVCMOS2 
--#                           , u_OBUFT_PCI33_3 
--#                           , u_OBUFT_PCI33_5 
--#                           , u_OBUFT_PCI66_3 
--#                           , u_OBUFT_SSTL2_I 
--#                           , u_OBUFT_SSTL2_II 
--#                           , u_OBUFT_SSTL3_I 
--#                           , u_OBUFT_SSTL3_II 
--#                           , u_OBUFT_S_12 
--#                           , u_OBUFT_S_16 
--#                           , u_OBUFT_S_2 
--#                           , u_OBUFT_S_24 
--#                           , u_OBUFT_S_4 
--#                           , u_OBUFT_S_6 
--#                           , u_OBUFT_S_8 
--#                           , u_OBUF_AGP 
--#                           , u_OBUF_CTT 
--#                           , u_OBUF_F_12 
--#                           , u_OBUF_F_16 
--#                           , u_OBUF_F_2 
--#                           , u_OBUF_F_24 
--#                           , u_OBUF_F_4 
--#                           , u_OBUF_F_6 
--#                           , u_OBUF_F_8 
--#                           , u_OBUF_GTL 
--#                           , u_OBUF_GTLP 
--#                           , u_OBUF_HSTL_I 
--#                           , u_OBUF_HSTL_III 
--#                           , u_OBUF_HSTL_IV 
--#                           , u_OBUF_LVCMOS2 
--#                           , u_OBUF_PCI33_3 
--#                           , u_OBUF_PCI33_5 
--#                           , u_OBUF_PCI66_3 
--#                           , u_OBUF_SSTL2_I 
--#                           , u_OBUF_SSTL2_II 
--#                           , u_OBUF_SSTL3_I 
--#                           , u_OBUF_SSTL3_II 
--#                           , u_OBUF_S_12 
--#                           , u_OBUF_S_16 
--#                           , u_OBUF_S_2 
--#                           , u_OBUF_S_24 
--#                           , u_OBUF_S_4 
--#                           , u_OBUF_S_6 
--#                           , u_OBUF_S_8 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAMB4_S1 
--#                           , u_RAMB4_S16 
--#                           , u_RAMB4_S16_S16 
--#                           , u_RAMB4_S1_S1 
--#                           , u_RAMB4_S1_S16 
--#                           , u_RAMB4_S1_S2 
--#                           , u_RAMB4_S1_S4 
--#                           , u_RAMB4_S1_S8 
--#                           , u_RAMB4_S2 
--#                           , u_RAMB4_S2_S16 
--#                           , u_RAMB4_S2_S2 
--#                           , u_RAMB4_S2_S4 
--#                           , u_RAMB4_S2_S8 
--#                           , u_RAMB4_S4 
--#                           , u_RAMB4_S4_S16 
--#                           , u_RAMB4_S4_S4 
--#                           , u_RAMB4_S4_S8 
--#                           , u_RAMB4_S8 
--#                           , u_RAMB4_S8_S16 
--#                           , u_RAMB4_S8_S8 
--#                           , u_ROM16X1 
--#                           , u_ROM32X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_STARTBUF_VIRTEX 
--#                           , u_STARTUP_VIRTEX 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       set_to(y, spartan2, ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_SPARTAN2 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFE 
--#                           , u_BUFG 
--#                           , u_BUFGDLL 
--#                           , u_BUFGP 
--#                           , u_BUFT 
--#                           , u_CAPTURE_SPARTAN2 
--#                           , u_CLKDLL 
--#                           , u_CLKDLLHF 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FMAP 
--#                           , u_GND 
--#                           , u_IBUF 
--#                           , u_IBUFG 
--#                           , u_IBUFG_AGP 
--#                           , u_IBUFG_CTT 
--#                           , u_IBUFG_GTL 
--#                           , u_IBUFG_GTLP 
--#                           , u_IBUFG_HSTL_I 
--#                           , u_IBUFG_HSTL_III 
--#                           , u_IBUFG_HSTL_IV 
--#                           , u_IBUFG_LVCMOS2 
--#                           , u_IBUFG_PCI33_3 
--#                           , u_IBUFG_PCI33_5 
--#                           , u_IBUFG_PCI66_3 
--#                           , u_IBUFG_SSTL2_I 
--#                           , u_IBUFG_SSTL2_II 
--#                           , u_IBUFG_SSTL3_I 
--#                           , u_IBUFG_SSTL3_II 
--#                           , u_IBUF_AGP 
--#                           , u_IBUF_CTT 
--#                           , u_IBUF_GTL 
--#                           , u_IBUF_GTLP 
--#                           , u_IBUF_HSTL_I 
--#                           , u_IBUF_HSTL_III 
--#                           , u_IBUF_HSTL_IV 
--#                           , u_IBUF_LVCMOS2 
--#                           , u_IBUF_PCI33_3 
--#                           , u_IBUF_PCI33_5 
--#                           , u_IBUF_PCI66_3 
--#                           , u_IBUF_SSTL2_I 
--#                           , u_IBUF_SSTL2_II 
--#                           , u_IBUF_SSTL3_I 
--#                           , u_IBUF_SSTL3_II 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUF_AGP 
--#                           , u_IOBUF_CTT 
--#                           , u_IOBUF_F_12 
--#                           , u_IOBUF_F_16 
--#                           , u_IOBUF_F_2 
--#                           , u_IOBUF_F_24 
--#                           , u_IOBUF_F_4 
--#                           , u_IOBUF_F_6 
--#                           , u_IOBUF_F_8 
--#                           , u_IOBUF_GTL 
--#                           , u_IOBUF_GTLP 
--#                           , u_IOBUF_HSTL_I 
--#                           , u_IOBUF_HSTL_III 
--#                           , u_IOBUF_HSTL_IV 
--#                           , u_IOBUF_LVCMOS2 
--#                           , u_IOBUF_PCI33_3 
--#                           , u_IOBUF_PCI33_5 
--#                           , u_IOBUF_PCI66_3 
--#                           , u_IOBUF_SSTL2_I 
--#                           , u_IOBUF_SSTL2_II 
--#                           , u_IOBUF_SSTL3_I 
--#                           , u_IOBUF_SSTL3_II 
--#                           , u_IOBUF_S_12 
--#                           , u_IOBUF_S_16 
--#                           , u_IOBUF_S_2 
--#                           , u_IOBUF_S_24 
--#                           , u_IOBUF_S_4 
--#                           , u_IOBUF_S_6 
--#                           , u_IOBUF_S_8 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFT 
--#                           , u_OBUFT_AGP 
--#                           , u_OBUFT_CTT 
--#                           , u_OBUFT_F_12 
--#                           , u_OBUFT_F_16 
--#                           , u_OBUFT_F_2 
--#                           , u_OBUFT_F_24 
--#                           , u_OBUFT_F_4 
--#                           , u_OBUFT_F_6 
--#                           , u_OBUFT_F_8 
--#                           , u_OBUFT_GTL 
--#                           , u_OBUFT_GTLP 
--#                           , u_OBUFT_HSTL_I 
--#                           , u_OBUFT_HSTL_III 
--#                           , u_OBUFT_HSTL_IV 
--#                           , u_OBUFT_LVCMOS2 
--#                           , u_OBUFT_PCI33_3 
--#                           , u_OBUFT_PCI33_5 
--#                           , u_OBUFT_PCI66_3 
--#                           , u_OBUFT_SSTL2_I 
--#                           , u_OBUFT_SSTL2_II 
--#                           , u_OBUFT_SSTL3_I 
--#                           , u_OBUFT_SSTL3_II 
--#                           , u_OBUFT_S_12 
--#                           , u_OBUFT_S_16 
--#                           , u_OBUFT_S_2 
--#                           , u_OBUFT_S_24 
--#                           , u_OBUFT_S_4 
--#                           , u_OBUFT_S_6 
--#                           , u_OBUFT_S_8 
--#                           , u_OBUF_AGP 
--#                           , u_OBUF_CTT 
--#                           , u_OBUF_F_12 
--#                           , u_OBUF_F_16 
--#                           , u_OBUF_F_2 
--#                           , u_OBUF_F_24 
--#                           , u_OBUF_F_4 
--#                           , u_OBUF_F_6 
--#                           , u_OBUF_F_8 
--#                           , u_OBUF_GTL 
--#                           , u_OBUF_GTLP 
--#                           , u_OBUF_HSTL_I 
--#                           , u_OBUF_HSTL_III 
--#                           , u_OBUF_HSTL_IV 
--#                           , u_OBUF_LVCMOS2 
--#                           , u_OBUF_PCI33_3 
--#                           , u_OBUF_PCI33_5 
--#                           , u_OBUF_PCI66_3 
--#                           , u_OBUF_SSTL2_I 
--#                           , u_OBUF_SSTL2_II 
--#                           , u_OBUF_SSTL3_I 
--#                           , u_OBUF_SSTL3_II 
--#                           , u_OBUF_S_12 
--#                           , u_OBUF_S_16 
--#                           , u_OBUF_S_2 
--#                           , u_OBUF_S_24 
--#                           , u_OBUF_S_4 
--#                           , u_OBUF_S_6 
--#                           , u_OBUF_S_8 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAMB4_S1 
--#                           , u_RAMB4_S16 
--#                           , u_RAMB4_S16_S16 
--#                           , u_RAMB4_S1_S1 
--#                           , u_RAMB4_S1_S16 
--#                           , u_RAMB4_S1_S2 
--#                           , u_RAMB4_S1_S4 
--#                           , u_RAMB4_S1_S8 
--#                           , u_RAMB4_S2 
--#                           , u_RAMB4_S2_S16 
--#                           , u_RAMB4_S2_S2 
--#                           , u_RAMB4_S2_S4 
--#                           , u_RAMB4_S2_S8 
--#                           , u_RAMB4_S4 
--#                           , u_RAMB4_S4_S16 
--#                           , u_RAMB4_S4_S4 
--#                           , u_RAMB4_S4_S8 
--#                           , u_RAMB4_S8 
--#                           , u_RAMB4_S8_S16 
--#                           , u_RAMB4_S8_S8 
--#                           , u_ROM16X1 
--#                           , u_ROM32X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_STARTBUF_SPARTAN2 
--#                           , u_STARTUP_SPARTAN2 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       set_to(y, spartan2e, ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_SPARTAN2 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFE 
--#                           , u_BUFG 
--#                           , u_BUFGDLL 
--#                           , u_BUFGP 
--#                           , u_BUFT 
--#                           , u_CAPTURE_SPARTAN2 
--#                           , u_CLKDLL 
--#                           , u_CLKDLLE 
--#                           , u_CLKDLLHF 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FMAP 
--#                           , u_GND 
--#                           , u_IBUF 
--#                           , u_IBUFG 
--#                           , u_IBUFG_AGP 
--#                           , u_IBUFG_CTT 
--#                           , u_IBUFG_GTL 
--#                           , u_IBUFG_GTLP 
--#                           , u_IBUFG_HSTL_I 
--#                           , u_IBUFG_HSTL_III 
--#                           , u_IBUFG_HSTL_IV 
--#                           , u_IBUFG_LVCMOS18 
--#                           , u_IBUFG_LVCMOS2 
--#                           , u_IBUFG_LVDS 
--#                           , u_IBUFG_LVPECL 
--#                           , u_IBUFG_PCI33_3 
--#                           , u_IBUFG_PCI66_3 
--#                           , u_IBUFG_PCIX66_3 
--#                           , u_IBUFG_SSTL2_I 
--#                           , u_IBUFG_SSTL2_II 
--#                           , u_IBUFG_SSTL3_I 
--#                           , u_IBUFG_SSTL3_II 
--#                           , u_IBUF_AGP 
--#                           , u_IBUF_CTT 
--#                           , u_IBUF_GTL 
--#                           , u_IBUF_GTLP 
--#                           , u_IBUF_HSTL_I 
--#                           , u_IBUF_HSTL_III 
--#                           , u_IBUF_HSTL_IV 
--#                           , u_IBUF_LVCMOS18 
--#                           , u_IBUF_LVCMOS2 
--#                           , u_IBUF_LVDS 
--#                           , u_IBUF_LVPECL 
--#                           , u_IBUF_PCI33_3 
--#                           , u_IBUF_PCI66_3 
--#                           , u_IBUF_PCIX66_3 
--#                           , u_IBUF_SSTL2_I 
--#                           , u_IBUF_SSTL2_II 
--#                           , u_IBUF_SSTL3_I 
--#                           , u_IBUF_SSTL3_II 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUF_AGP 
--#                           , u_IOBUF_CTT 
--#                           , u_IOBUF_F_12 
--#                           , u_IOBUF_F_16 
--#                           , u_IOBUF_F_2 
--#                           , u_IOBUF_F_24 
--#                           , u_IOBUF_F_4 
--#                           , u_IOBUF_F_6 
--#                           , u_IOBUF_F_8 
--#                           , u_IOBUF_GTL 
--#                           , u_IOBUF_GTLP 
--#                           , u_IOBUF_HSTL_I 
--#                           , u_IOBUF_HSTL_III 
--#                           , u_IOBUF_HSTL_IV 
--#                           , u_IOBUF_LVCMOS18 
--#                           , u_IOBUF_LVCMOS2 
--#                           , u_IOBUF_LVDS 
--#                           , u_IOBUF_LVPECL 
--#                           , u_IOBUF_PCI33_3 
--#                           , u_IOBUF_PCI66_3 
--#                           , u_IOBUF_PCIX66_3 
--#                           , u_IOBUF_SSTL2_I 
--#                           , u_IOBUF_SSTL2_II 
--#                           , u_IOBUF_SSTL3_I 
--#                           , u_IOBUF_SSTL3_II 
--#                           , u_IOBUF_S_12 
--#                           , u_IOBUF_S_16 
--#                           , u_IOBUF_S_2 
--#                           , u_IOBUF_S_24 
--#                           , u_IOBUF_S_4 
--#                           , u_IOBUF_S_6 
--#                           , u_IOBUF_S_8 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFT 
--#                           , u_OBUFT_AGP 
--#                           , u_OBUFT_CTT 
--#                           , u_OBUFT_F_12 
--#                           , u_OBUFT_F_16 
--#                           , u_OBUFT_F_2 
--#                           , u_OBUFT_F_24 
--#                           , u_OBUFT_F_4 
--#                           , u_OBUFT_F_6 
--#                           , u_OBUFT_F_8 
--#                           , u_OBUFT_GTL 
--#                           , u_OBUFT_GTLP 
--#                           , u_OBUFT_HSTL_I 
--#                           , u_OBUFT_HSTL_III 
--#                           , u_OBUFT_HSTL_IV 
--#                           , u_OBUFT_LVCMOS18 
--#                           , u_OBUFT_LVCMOS2 
--#                           , u_OBUFT_LVDS 
--#                           , u_OBUFT_LVPECL 
--#                           , u_OBUFT_PCI33_3 
--#                           , u_OBUFT_PCI66_3 
--#                           , u_OBUFT_PCIX66_3 
--#                           , u_OBUFT_SSTL2_I 
--#                           , u_OBUFT_SSTL2_II 
--#                           , u_OBUFT_SSTL3_I 
--#                           , u_OBUFT_SSTL3_II 
--#                           , u_OBUFT_S_12 
--#                           , u_OBUFT_S_16 
--#                           , u_OBUFT_S_2 
--#                           , u_OBUFT_S_24 
--#                           , u_OBUFT_S_4 
--#                           , u_OBUFT_S_6 
--#                           , u_OBUFT_S_8 
--#                           , u_OBUF_AGP 
--#                           , u_OBUF_CTT 
--#                           , u_OBUF_F_12 
--#                           , u_OBUF_F_16 
--#                           , u_OBUF_F_2 
--#                           , u_OBUF_F_24 
--#                           , u_OBUF_F_4 
--#                           , u_OBUF_F_6 
--#                           , u_OBUF_F_8 
--#                           , u_OBUF_GTL 
--#                           , u_OBUF_GTLP 
--#                           , u_OBUF_HSTL_I 
--#                           , u_OBUF_HSTL_III 
--#                           , u_OBUF_HSTL_IV 
--#                           , u_OBUF_LVCMOS18 
--#                           , u_OBUF_LVCMOS2 
--#                           , u_OBUF_LVDS 
--#                           , u_OBUF_LVPECL 
--#                           , u_OBUF_PCI33_3 
--#                           , u_OBUF_PCI66_3 
--#                           , u_OBUF_PCIX66_3 
--#                           , u_OBUF_SSTL2_I 
--#                           , u_OBUF_SSTL2_II 
--#                           , u_OBUF_SSTL3_I 
--#                           , u_OBUF_SSTL3_II 
--#                           , u_OBUF_S_12 
--#                           , u_OBUF_S_16 
--#                           , u_OBUF_S_2 
--#                           , u_OBUF_S_24 
--#                           , u_OBUF_S_4 
--#                           , u_OBUF_S_6 
--#                           , u_OBUF_S_8 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAMB4_S1 
--#                           , u_RAMB4_S16 
--#                           , u_RAMB4_S16_S16 
--#                           , u_RAMB4_S1_S1 
--#                           , u_RAMB4_S1_S16 
--#                           , u_RAMB4_S1_S2 
--#                           , u_RAMB4_S1_S4 
--#                           , u_RAMB4_S1_S8 
--#                           , u_RAMB4_S2 
--#                           , u_RAMB4_S2_S16 
--#                           , u_RAMB4_S2_S2 
--#                           , u_RAMB4_S2_S4 
--#                           , u_RAMB4_S2_S8 
--#                           , u_RAMB4_S4 
--#                           , u_RAMB4_S4_S16 
--#                           , u_RAMB4_S4_S4 
--#                           , u_RAMB4_S4_S8 
--#                           , u_RAMB4_S8 
--#                           , u_RAMB4_S8_S16 
--#                           , u_RAMB4_S8_S8 
--#                           , u_ROM16X1 
--#                           , u_ROM32X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_STARTBUF_SPARTAN2 
--#                           , u_STARTUP_SPARTAN2 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       set_to(y, virtexe, ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_VIRTEX 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFE 
--#                           , u_BUFG 
--#                           , u_BUFGDLL 
--#                           , u_BUFGP 
--#                           , u_BUFT 
--#                           , u_CAPTURE_VIRTEX 
--#                           , u_CLKDLL 
--#                           , u_CLKDLLE 
--#                           , u_CLKDLLHF 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FMAP 
--#                           , u_GND 
--#                           , u_IBUF 
--#                           , u_IBUFG 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFT 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAMB4_S1 
--#                           , u_RAMB4_S16 
--#                           , u_RAMB4_S16_S16 
--#                           , u_RAMB4_S1_S1 
--#                           , u_RAMB4_S1_S16 
--#                           , u_RAMB4_S1_S2 
--#                           , u_RAMB4_S1_S4 
--#                           , u_RAMB4_S1_S8 
--#                           , u_RAMB4_S2 
--#                           , u_RAMB4_S2_S16 
--#                           , u_RAMB4_S2_S2 
--#                           , u_RAMB4_S2_S4 
--#                           , u_RAMB4_S2_S8 
--#                           , u_RAMB4_S4 
--#                           , u_RAMB4_S4_S16 
--#                           , u_RAMB4_S4_S4 
--#                           , u_RAMB4_S4_S8 
--#                           , u_RAMB4_S8 
--#                           , u_RAMB4_S8_S16 
--#                           , u_RAMB4_S8_S8 
--#                           , u_ROM16X1 
--#                           , u_ROM32X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_STARTBUF_VIRTEX 
--#                           , u_STARTUP_VIRTEX 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#               ); 
--#       -- 
--#       set_to(y, virtex2, ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_VIRTEX2 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFE 
--#                           , u_BUFG 
--#                           , u_BUFGCE 
--#                           , u_BUFGCE_1 
--#                           , u_BUFGDLL 
--#                           , u_BUFGMUX 
--#                           , u_BUFGMUX_1 
--#                           , u_BUFGP 
--#                           , u_BUFT 
--#                           , u_CAPTURE_VIRTEX2 
--#                           , u_CLKDLL 
--#                           , u_CLKDLLE 
--#                           , u_CLKDLLHF 
--#                           , u_DCM 
--#                           , u_DUMMY_INV 
--#                           , u_DUMMY_NOR2 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDDRCPE 
--#                           , u_FDDRRSE 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FMAP 
--#                           , u_GND 
--#                           , u_IBUF 
--#                           , u_IBUFDS 
--#                           , u_IBUFDS_DIFF_OUT 
--#                           , u_IBUFG 
--#                           , u_IBUFGDS 
--#                           , u_IBUFGDS_DIFF_OUT 
--#                           , u_ICAP_VIRTEX2 
--#                           , u_IFDDRCPE 
--#                           , u_IFDDRRSE 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUFDS 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT18X18 
--#                           , u_MULT18X18S 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_MUXF7 
--#                           , u_MUXF7_D 
--#                           , u_MUXF7_L 
--#                           , u_MUXF8 
--#                           , u_MUXF8_D 
--#                           , u_MUXF8_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFDS 
--#                           , u_OBUFT 
--#                           , u_OBUFTDS 
--#                           , u_OFDDRCPE 
--#                           , u_OFDDRRSE 
--#                           , u_OFDDRTCPE 
--#                           , u_OFDDRTRSE 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_ORCY 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM128X1S 
--#                           , u_RAM128X1S_1 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM16X2S 
--#                           , u_RAM16X4S 
--#                           , u_RAM16X8S 
--#                           , u_RAM32X1D 
--#                           , u_RAM32X1D_1 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAM32X2S 
--#                           , u_RAM32X4S 
--#                           , u_RAM32X8S 
--#                           , u_RAM64X1D 
--#                           , u_RAM64X1D_1 
--#                           , u_RAM64X1S 
--#                           , u_RAM64X1S_1 
--#                           , u_RAM64X2S 
--#                           , u_RAMB16_S1 
--#                           , u_RAMB16_S18 
--#                           , u_RAMB16_S18_S18 
--#                           , u_RAMB16_S18_S36 
--#                           , u_RAMB16_S1_S1 
--#                           , u_RAMB16_S1_S18 
--#                           , u_RAMB16_S1_S2 
--#                           , u_RAMB16_S1_S36 
--#                           , u_RAMB16_S1_S4 
--#                           , u_RAMB16_S1_S9 
--#                           , u_RAMB16_S2 
--#                           , u_RAMB16_S2_S18 
--#                           , u_RAMB16_S2_S2 
--#                           , u_RAMB16_S2_S36 
--#                           , u_RAMB16_S2_S4 
--#                           , u_RAMB16_S2_S9 
--#                           , u_RAMB16_S36 
--#                           , u_RAMB16_S36_S36 
--#                           , u_RAMB16_S4 
--#                           , u_RAMB16_S4_S18 
--#                           , u_RAMB16_S4_S36 
--#                           , u_RAMB16_S4_S4 
--#                           , u_RAMB16_S4_S9 
--#                           , u_RAMB16_S9 
--#                           , u_RAMB16_S9_S18 
--#                           , u_RAMB16_S9_S36 
--#                           , u_RAMB16_S9_S9 
--#                           , u_ROM128X1 
--#                           , u_ROM16X1 
--#                           , u_ROM256X1 
--#                           , u_ROM32X1 
--#                           , u_ROM64X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_SRLC16 
--#                           , u_SRLC16E 
--#                           , u_SRLC16E_1 
--#                           , u_SRLC16_1 
--#                           , u_STARTBUF_VIRTEX2 
--#                           , u_STARTUP_VIRTEX2 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       -- 
--#       pp(qvirtex2)   := pp(virtex2); 
--#       -- 
--#       pp(qrvirtex2)  := pp(virtex2); 
--#       -- 
--#       set_to(y, virtex2p, 
--#                          ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_VIRTEX2 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFE 
--#                           , u_BUFG 
--#                           , u_BUFGCE 
--#                           , u_BUFGCE_1 
--#                           , u_BUFGDLL 
--#                           , u_BUFGMUX 
--#                           , u_BUFGMUX_1 
--#                           , u_BUFGP 
--#                           , u_BUFT 
--#                           , u_CAPTURE_VIRTEX2 
--#                           , u_CLKDLL 
--#                           , u_CLKDLLE 
--#                           , u_CLKDLLHF 
--#                           , u_DCM 
--#                           , u_DUMMY_INV 
--#                           , u_DUMMY_NOR2 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDDRCPE 
--#                           , u_FDDRRSE 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FMAP 
--#                           , u_GND 
--#                           , u_GT10_10GE_4 
--#                           , u_GT10_10GE_8 
--#                           , u_GT10_10GFC_4 
--#                           , u_GT10_10GFC_8 
--#                           , u_GT10_AURORAX_4 
--#                           , u_GT10_AURORAX_8 
--#                           , u_GT10_AURORA_1 
--#                           , u_GT10_AURORA_2 
--#                           , u_GT10_AURORA_4 
--#                           , u_GT10_CUSTOM 
--#                           , u_GT10_INFINIBAND_1 
--#                           , u_GT10_INFINIBAND_2 
--#                           , u_GT10_INFINIBAND_4 
--#                           , u_GT10_OC192_4 
--#                           , u_GT10_OC192_8 
--#                           , u_GT10_OC48_1 
--#                           , u_GT10_OC48_2 
--#                           , u_GT10_OC48_4 
--#                           , u_GT10_PCI_EXPRESS_1 
--#                           , u_GT10_PCI_EXPRESS_2 
--#                           , u_GT10_PCI_EXPRESS_4 
--#                           , u_GT10_XAUI_1 
--#                           , u_GT10_XAUI_2 
--#                           , u_GT10_XAUI_4 
--#                           , u_GT_AURORA_1 
--#                           , u_GT_AURORA_2 
--#                           , u_GT_AURORA_4 
--#                           , u_GT_CUSTOM 
--#                           , u_GT_ETHERNET_1 
--#                           , u_GT_ETHERNET_2 
--#                           , u_GT_ETHERNET_4 
--#                           , u_GT_FIBRE_CHAN_1 
--#                           , u_GT_FIBRE_CHAN_2 
--#                           , u_GT_FIBRE_CHAN_4 
--#                           , u_GT_INFINIBAND_1 
--#                           , u_GT_INFINIBAND_2 
--#                           , u_GT_INFINIBAND_4 
--#                           , u_GT_XAUI_1 
--#                           , u_GT_XAUI_2 
--#                           , u_GT_XAUI_4 
--#                           , u_IBUF 
--#                           , u_IBUFDS 
--#                           , u_IBUFDS_DIFF_OUT 
--#                           , u_IBUFG 
--#                           , u_IBUFGDS 
--#                           , u_IBUFGDS_DIFF_OUT 
--#                           , u_ICAP_VIRTEX2 
--#                           , u_IFDDRCPE 
--#                           , u_IFDDRRSE 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUFDS 
--#                           , u_JTAGPPC 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT18X18 
--#                           , u_MULT18X18S 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_MUXF7 
--#                           , u_MUXF7_D 
--#                           , u_MUXF7_L 
--#                           , u_MUXF8 
--#                           , u_MUXF8_D 
--#                           , u_MUXF8_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFDS 
--#                           , u_OBUFT 
--#                           , u_OBUFTDS 
--#                           , u_OFDDRCPE 
--#                           , u_OFDDRRSE 
--#                           , u_OFDDRTCPE 
--#                           , u_OFDDRTRSE 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_ORCY 
--#                           , u_PPC405 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM128X1S 
--#                           , u_RAM128X1S_1 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM16X2S 
--#                           , u_RAM16X4S 
--#                           , u_RAM16X8S 
--#                           , u_RAM32X1D 
--#                           , u_RAM32X1D_1 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAM32X2S 
--#                           , u_RAM32X4S 
--#                           , u_RAM32X8S 
--#                           , u_RAM64X1D 
--#                           , u_RAM64X1D_1 
--#                           , u_RAM64X1S 
--#                           , u_RAM64X1S_1 
--#                           , u_RAM64X2S 
--#                           , u_RAMB16_S1 
--#                           , u_RAMB16_S18 
--#                           , u_RAMB16_S18_S18 
--#                           , u_RAMB16_S18_S36 
--#                           , u_RAMB16_S1_S1 
--#                           , u_RAMB16_S1_S18 
--#                           , u_RAMB16_S1_S2 
--#                           , u_RAMB16_S1_S36 
--#                           , u_RAMB16_S1_S4 
--#                           , u_RAMB16_S1_S9 
--#                           , u_RAMB16_S2 
--#                           , u_RAMB16_S2_S18 
--#                           , u_RAMB16_S2_S2 
--#                           , u_RAMB16_S2_S36 
--#                           , u_RAMB16_S2_S4 
--#                           , u_RAMB16_S2_S9 
--#                           , u_RAMB16_S36 
--#                           , u_RAMB16_S36_S36 
--#                           , u_RAMB16_S4 
--#                           , u_RAMB16_S4_S18 
--#                           , u_RAMB16_S4_S36 
--#                           , u_RAMB16_S4_S4 
--#                           , u_RAMB16_S4_S9 
--#                           , u_RAMB16_S9 
--#                           , u_RAMB16_S9_S18 
--#                           , u_RAMB16_S9_S36 
--#                           , u_RAMB16_S9_S9 
--#                           , u_ROM128X1 
--#                           , u_ROM16X1 
--#                           , u_ROM256X1 
--#                           , u_ROM32X1 
--#                           , u_ROM64X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_SRLC16 
--#                           , u_SRLC16E 
--#                           , u_SRLC16E_1 
--#                           , u_SRLC16_1 
--#                           , u_STARTBUF_VIRTEX2 
--#                           , u_STARTUP_VIRTEX2 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       -- 
--#       set_to(y, spartan3, 
--#                          ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_SPARTAN3 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFG 
--#                           , u_BUFGCE 
--#                           , u_BUFGCE_1 
--#                           , u_BUFGDLL 
--#                           , u_BUFGMUX 
--#                           , u_BUFGMUX_1 
--#                           , u_BUFGP 
--#                           , u_CAPTURE_SPARTAN3 
--#                           , u_DCM 
--#                           , u_DUMMY_INV 
--#                           , u_DUMMY_NOR2 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDDRCPE 
--#                           , u_FDDRRSE 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FMAP 
--#                           , u_GND 
--#                           , u_IBUF 
--#                           , u_IBUFDS 
--#                           , u_IBUFDS_DIFF_OUT 
--#                           , u_IBUFG 
--#                           , u_IBUFGDS 
--#                           , u_IBUFGDS_DIFF_OUT 
--#                           , u_IFDDRCPE 
--#                           , u_IFDDRRSE 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUFDS 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT18X18 
--#                           , u_MULT18X18S 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_MUXF7 
--#                           , u_MUXF7_D 
--#                           , u_MUXF7_L 
--#                           , u_MUXF8 
--#                           , u_MUXF8_D 
--#                           , u_MUXF8_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFDS 
--#                           , u_OBUFT 
--#                           , u_OBUFTDS 
--#                           , u_OFDDRCPE 
--#                           , u_OFDDRRSE 
--#                           , u_OFDDRTCPE 
--#                           , u_OFDDRTRSE 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_ORCY 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM16X2S 
--#                           , u_RAM16X4S 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAM32X2S 
--#                           , u_RAM64X1S 
--#                           , u_RAM64X1S_1 
--#                           , u_RAMB16_S1 
--#                           , u_RAMB16_S18 
--#                           , u_RAMB16_S18_S18 
--#                           , u_RAMB16_S18_S36 
--#                           , u_RAMB16_S1_S1 
--#                           , u_RAMB16_S1_S18 
--#                           , u_RAMB16_S1_S2 
--#                           , u_RAMB16_S1_S36 
--#                           , u_RAMB16_S1_S4 
--#                           , u_RAMB16_S1_S9 
--#                           , u_RAMB16_S2 
--#                           , u_RAMB16_S2_S18 
--#                           , u_RAMB16_S2_S2 
--#                           , u_RAMB16_S2_S36 
--#                           , u_RAMB16_S2_S4 
--#                           , u_RAMB16_S2_S9 
--#                           , u_RAMB16_S36 
--#                           , u_RAMB16_S36_S36 
--#                           , u_RAMB16_S4 
--#                           , u_RAMB16_S4_S18 
--#                           , u_RAMB16_S4_S36 
--#                           , u_RAMB16_S4_S4 
--#                           , u_RAMB16_S4_S9 
--#                           , u_RAMB16_S9 
--#                           , u_RAMB16_S9_S18 
--#                           , u_RAMB16_S9_S36 
--#                           , u_RAMB16_S9_S9 
--#                           , u_ROM128X1 
--#                           , u_ROM16X1 
--#                           , u_ROM256X1 
--#                           , u_ROM32X1 
--#                           , u_ROM64X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_SRLC16 
--#                           , u_SRLC16E 
--#                           , u_SRLC16E_1 
--#                           , u_SRLC16_1 
--#                           , u_STARTBUF_SPARTAN3 
--#                           , u_STARTUP_SPARTAN3 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       -- 
--#       pp(aspartan3)   := pp(spartan3); 
--#       -- 
--#       set_to(y, spartan3e, 
--#                          ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_SPARTAN3 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFG 
--#                           , u_BUFGCE 
--#                           , u_BUFGCE_1 
--#                           , u_BUFGDLL 
--#                           , u_BUFGMUX 
--#                           , u_BUFGMUX_1 
--#                           , u_BUFGP 
--#                           , u_CAPTURE_SPARTAN3E 
--#                           , u_DCM 
--#                           , u_DUMMY_INV 
--#                           , u_DUMMY_NOR2 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDDRCPE 
--#                           , u_FDDRRSE 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FMAP 
--#                           , u_GND 
--#                           , u_IBUF 
--#                           , u_IBUFDS 
--#                           , u_IBUFDS_DIFF_OUT 
--#                           , u_IBUFG 
--#                           , u_IBUFGDS 
--#                           , u_IBUFGDS_DIFF_OUT 
--#                           , u_IDDR2 
--#                           , u_IFDDRCPE 
--#                           , u_IFDDRRSE 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUFDS 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT18X18 
--#                           , u_MULT18X18S 
--#                           , u_MULT18X18SIO 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_MUXF7 
--#                           , u_MUXF7_D 
--#                           , u_MUXF7_L 
--#                           , u_MUXF8 
--#                           , u_MUXF8_D 
--#                           , u_MUXF8_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFDS 
--#                           , u_OBUFT 
--#                           , u_OBUFTDS 
--#                           , u_ODDR2 
--#                           , u_OFDDRCPE 
--#                           , u_OFDDRRSE 
--#                           , u_OFDDRTCPE 
--#                           , u_OFDDRTRSE 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_ORCY 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM16X2S 
--#                           , u_RAM16X4S 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAM32X2S 
--#                           , u_RAM64X1S 
--#                           , u_RAM64X1S_1 
--#                           , u_RAMB16_S1 
--#                           , u_RAMB16_S18 
--#                           , u_RAMB16_S18_S18 
--#                           , u_RAMB16_S18_S36 
--#                           , u_RAMB16_S1_S1 
--#                           , u_RAMB16_S1_S18 
--#                           , u_RAMB16_S1_S2 
--#                           , u_RAMB16_S1_S36 
--#                           , u_RAMB16_S1_S4 
--#                           , u_RAMB16_S1_S9 
--#                           , u_RAMB16_S2 
--#                           , u_RAMB16_S2_S18 
--#                           , u_RAMB16_S2_S2 
--#                           , u_RAMB16_S2_S36 
--#                           , u_RAMB16_S2_S4 
--#                           , u_RAMB16_S2_S9 
--#                           , u_RAMB16_S36 
--#                           , u_RAMB16_S36_S36 
--#                           , u_RAMB16_S4 
--#                           , u_RAMB16_S4_S18 
--#                           , u_RAMB16_S4_S36 
--#                           , u_RAMB16_S4_S4 
--#                           , u_RAMB16_S4_S9 
--#                           , u_RAMB16_S9 
--#                           , u_RAMB16_S9_S18 
--#                           , u_RAMB16_S9_S36 
--#                           , u_RAMB16_S9_S9 
--#                           , u_ROM128X1 
--#                           , u_ROM16X1 
--#                           , u_ROM256X1 
--#                           , u_ROM32X1 
--#                           , u_ROM64X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_SRLC16 
--#                           , u_SRLC16E 
--#                           , u_SRLC16E_1 
--#                           , u_SRLC16_1 
--#                           , u_STARTBUF_SPARTAN3E 
--#                           , u_STARTUP_SPARTAN3E 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       -- 
--#       pp(aspartan3e)   := pp(spartan3e); 
--#       -- 
--#       set_to(y, virtex4fx, 
--#                          ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_VIRTEX4 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFG 
--#                           , u_BUFGCE 
--#                           , u_BUFGCE_1 
--#                           , u_BUFGCTRL 
--#                           , u_BUFGMUX 
--#                           , u_BUFGMUX_1 
--#                           , u_BUFGMUX_VIRTEX4 
--#                           , u_BUFGP 
--#                           , u_BUFGP 
--#                           , u_BUFIO 
--#                           , u_BUFR 
--#                           , u_CAPTURE_VIRTEX4 
--#                           , u_DCIRESET 
--#                           , u_DCM 
--#                           , u_DCM_ADV 
--#                           , u_DCM_BASE 
--#                           , u_DCM_PS 
--#                           , u_DSP48 
--#                           , u_EMAC 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FIFO16 
--#                           , u_FMAP 
--#                           , u_FRAME_ECC_VIRTEX4 
--#                           , u_GND 
--#                           , u_GT11CLK 
--#                           , u_GT11CLK_MGT 
--#                           , u_GT11_CUSTOM 
--#                           , u_IBUF 
--#                           , u_IBUFDS 
--#                           , u_IBUFDS_DIFF_OUT 
--#                           , u_IBUFG 
--#                           , u_IBUFGDS 
--#                           , u_IBUFGDS_DIFF_OUT 
--#                           , u_ICAP_VIRTEX4 
--#                           , u_IDDR 
--#                           , u_IDELAY 
--#                           , u_IDELAYCTRL 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUFDS 
--#                           , u_ISERDES 
--#                           , u_JTAGPPC 
--#                           , u_KEEPER 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_MULT18X18 
--#                           , u_MULT18X18S 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_MUXF7 
--#                           , u_MUXF7_D 
--#                           , u_MUXF7_L 
--#                           , u_MUXF8 
--#                           , u_MUXF8_D 
--#                           , u_MUXF8_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFDS 
--#                           , u_OBUFT 
--#                           , u_OBUFTDS 
--#                           , u_ODDR 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_OSERDES 
--#                           , u_PMCD 
--#                           , u_PPC405 
--#                           , u_PPC405_ADV 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM16X2S 
--#                           , u_RAM16X4S 
--#                           , u_RAM16X8S 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAM32X2S 
--#                           , u_RAM32X4S 
--#                           , u_RAM32X8S 
--#                           , u_RAM64X1S 
--#                           , u_RAM64X1S_1 
--#                           , u_RAM64X2S 
--#                           , u_RAMB16 
--#                           , u_RAMB16_S1 
--#                           , u_RAMB16_S18 
--#                           , u_RAMB16_S18_S18 
--#                           , u_RAMB16_S18_S36 
--#                           , u_RAMB16_S1_S1 
--#                           , u_RAMB16_S1_S18 
--#                           , u_RAMB16_S1_S2 
--#                           , u_RAMB16_S1_S36 
--#                           , u_RAMB16_S1_S4 
--#                           , u_RAMB16_S1_S9 
--#                           , u_RAMB16_S2 
--#                           , u_RAMB16_S2_S18 
--#                           , u_RAMB16_S2_S2 
--#                           , u_RAMB16_S2_S36 
--#                           , u_RAMB16_S2_S4 
--#                           , u_RAMB16_S2_S9 
--#                           , u_RAMB16_S36 
--#                           , u_RAMB16_S36_S36 
--#                           , u_RAMB16_S4 
--#                           , u_RAMB16_S4_S18 
--#                           , u_RAMB16_S4_S36 
--#                           , u_RAMB16_S4_S4 
--#                           , u_RAMB16_S4_S9 
--#                           , u_RAMB16_S9 
--#                           , u_RAMB16_S9_S18 
--#                           , u_RAMB16_S9_S36 
--#                           , u_RAMB16_S9_S9 
--#                           , u_RAMB32_S64_ECC 
--#                           , u_ROM128X1 
--#                           , u_ROM16X1 
--#                           , u_ROM256X1 
--#                           , u_ROM32X1 
--#                           , u_ROM64X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_SRLC16 
--#                           , u_SRLC16E 
--#                           , u_SRLC16E_1 
--#                           , u_SRLC16_1 
--#                           , u_STARTBUF_VIRTEX4 
--#                           , u_STARTUP_VIRTEX4 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_USR_ACCESS_VIRTEX4 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       -- 
--#       pp(virtex4sx) := pp(virtex4fx); 
--#       -- 
--#       pp(virtex4lx) := pp(virtex4fx); 
--#       set_to(n, virtex4lx, (u_EMAC, 
--#                              u_GT11CLK, u_GT11CLK_MGT, u_GT11_CUSTOM, 
--#                              u_JTAGPPC, u_PPC405, u_PPC405_ADV 
--#             )               ); 
--#       -- 
--#       pp(virtex4) := pp(virtex4lx); -- virtex4 is defined as the largest set 
--#                                      -- of primitives that EVERY virtex4 
--#                                      -- device supports, i.e.. a design that uses 
--#                                      -- the virtex4 subset of primitives 
--#                                      -- is compatible with any variant of 
--#                                      -- the virtex4 family. 
--#       -- 
--#       pp(qvirtex4) := pp(virtex4); 
--#       -- 
--#       pp(qrvirtex4) := pp(virtex4); 
--#       -- 
--#       set_to(y, virtex5, 
--#                          ( 
--#                             u_AND2 
--#                           , u_AND3 
--#                           , u_AND4 
--#                           , u_BSCAN_VIRTEX5 
--#                           , u_BUF 
--#                           , u_BUFCF 
--#                           , u_BUFG 
--#                           , u_BUFGCE 
--#                           , u_BUFGCE_1 
--#                           , u_BUFGCTRL 
--#                           , u_BUFGMUX 
--#                           , u_BUFGMUX_1 
--#                           , u_BUFGMUX_CTRL 
--#                           , u_BUFGP 
--#                           , u_BUFIO 
--#                           , u_BUFR 
--#                           , u_CAPTURE_VIRTEX5 
--#                           , u_CARRY4 
--#                           , u_CFGLUT5 
--#                           , u_CRC32 
--#                           , u_CRC64 
--#                           , u_DCIRESET 
--#                           , u_DCM 
--#                           , u_DCM_ADV 
--#                           , u_DCM_BASE 
--#                           , u_DCM_PS 
--#                           , u_DSP48 
--#                           , u_DSP48E 
--#                           , u_EMAC 
--#                           , u_FD 
--#                           , u_FDC 
--#                           , u_FDCE 
--#                           , u_FDCE_1 
--#                           , u_FDCP 
--#                           , u_FDCPE 
--#                           , u_FDCPE_1 
--#                           , u_FDCP_1 
--#                           , u_FDC_1 
--#                           , u_FDDRCPE 
--#                           , u_FDDRRSE 
--#                           , u_FDE 
--#                           , u_FDE_1 
--#                           , u_FDP 
--#                           , u_FDPE 
--#                           , u_FDPE_1 
--#                           , u_FDP_1 
--#                           , u_FDR 
--#                           , u_FDRE 
--#                           , u_FDRE_1 
--#                           , u_FDRS 
--#                           , u_FDRSE 
--#                           , u_FDRSE_1 
--#                           , u_FDRS_1 
--#                           , u_FDR_1 
--#                           , u_FDS 
--#                           , u_FDSE 
--#                           , u_FDSE_1 
--#                           , u_FDS_1 
--#                           , u_FD_1 
--#                           , u_FIFO16 
--#                           , u_FIFO18 
--#                           , u_FIFO18_36 
--#                           , u_FIFO36 
--#                           , u_FIFO36_72 
--#                           , u_FMAP 
--#                           , u_FRAME_ECC_VIRTEX5 
--#                           , u_GND 
--#                           , u_GT11CLK 
--#                           , u_GT11CLK_MGT 
--#                           , u_GT11_CUSTOM 
--#                           , u_IBUF 
--#                           , u_IBUFDS 
--#                           , u_IBUFDS_DIFF_OUT 
--#                           , u_IBUFG 
--#                           , u_IBUFGDS 
--#                           , u_IBUFGDS_DIFF_OUT 
--#                           , u_ICAP_VIRTEX5 
--#                           , u_IDDR 
--#                           , u_IDDR_2CLK 
--#                           , u_IDELAY 
--#                           , u_IDELAYCTRL 
--#                           , u_IFDDRCPE 
--#                           , u_IFDDRRSE 
--#                           , u_INV 
--#                           , u_IOBUF 
--#                           , u_IOBUFDS 
--#                           , u_IODELAY 
--#                           , u_ISERDES 
--#                           , u_ISERDES_NODELAY 
--#                           , u_KEEPER 
--#                           , u_KEY_CLEAR 
--#                           , u_LD 
--#                           , u_LDC 
--#                           , u_LDCE 
--#                           , u_LDCE_1 
--#                           , u_LDCP 
--#                           , u_LDCPE 
--#                           , u_LDCPE_1 
--#                           , u_LDCP_1 
--#                           , u_LDC_1 
--#                           , u_LDE 
--#                           , u_LDE_1 
--#                           , u_LDP 
--#                           , u_LDPE 
--#                           , u_LDPE_1 
--#                           , u_LDP_1 
--#                           , u_LD_1 
--#                           , u_LUT1 
--#                           , u_LUT1_D 
--#                           , u_LUT1_L 
--#                           , u_LUT2 
--#                           , u_LUT2_D 
--#                           , u_LUT2_L 
--#                           , u_LUT3 
--#                           , u_LUT3_D 
--#                           , u_LUT3_L 
--#                           , u_LUT4 
--#                           , u_LUT4_D 
--#                           , u_LUT4_L 
--#                           , u_LUT5 
--#                           , u_LUT5_D 
--#                           , u_LUT5_L 
--#                           , u_LUT6 
--#                           , u_LUT6_D 
--#                           , u_LUT6_L 
--#                           , u_MULT18X18 
--#                           , u_MULT18X18S 
--#                           , u_MULT_AND 
--#                           , u_MUXCY 
--#                           , u_MUXCY_D 
--#                           , u_MUXCY_L 
--#                           , u_MUXF5 
--#                           , u_MUXF5_D 
--#                           , u_MUXF5_L 
--#                           , u_MUXF6 
--#                           , u_MUXF6_D 
--#                           , u_MUXF6_L 
--#                           , u_MUXF7 
--#                           , u_MUXF7_D 
--#                           , u_MUXF7_L 
--#                           , u_MUXF8 
--#                           , u_MUXF8_D 
--#                           , u_MUXF8_L 
--#                           , u_NAND2 
--#                           , u_NAND3 
--#                           , u_NAND4 
--#                           , u_NOR2 
--#                           , u_NOR3 
--#                           , u_NOR4 
--#                           , u_OBUF 
--#                           , u_OBUFDS 
--#                           , u_OBUFT 
--#                           , u_OBUFTDS 
--#                           , u_ODDR 
--#                           , u_OFDDRCPE 
--#                           , u_OFDDRRSE 
--#                           , u_OFDDRTCPE 
--#                           , u_OFDDRTRSE 
--#                           , u_OR2 
--#                           , u_OR3 
--#                           , u_OR4 
--#                           , u_OSERDES 
--#                           , u_PLL_ADV 
--#                           , u_PLL_BASE 
--#                           , u_PMCD 
--#                           , u_PULLDOWN 
--#                           , u_PULLUP 
--#                           , u_RAM128X1D 
--#                           , u_RAM128X1S 
--#                           , u_RAM16X1D 
--#                           , u_RAM16X1D_1 
--#                           , u_RAM16X1S 
--#                           , u_RAM16X1S_1 
--#                           , u_RAM16X2S 
--#                           , u_RAM16X4S 
--#                           , u_RAM16X8S 
--#                           , u_RAM256X1S 
--#                           , u_RAM32M 
--#                           , u_RAM32X1S 
--#                           , u_RAM32X1S_1 
--#                           , u_RAM32X2S 
--#                           , u_RAM32X4S 
--#                           , u_RAM32X8S 
--#                           , u_RAM64M 
--#                           , u_RAM64X1D 
--#                           , u_RAM64X1S 
--#                           , u_RAM64X1S_1 
--#                           , u_RAM64X2S 
--#                           , u_RAMB16 
--#                           , u_RAMB16_S1 
--#                           , u_RAMB16_S18 
--#                           , u_RAMB16_S18_S18 
--#                           , u_RAMB16_S18_S36 
--#                           , u_RAMB16_S1_S1 
--#                           , u_RAMB16_S1_S18 
--#                           , u_RAMB16_S1_S2 
--#                           , u_RAMB16_S1_S36 
--#                           , u_RAMB16_S1_S4 
--#                           , u_RAMB16_S1_S9 
--#                           , u_RAMB16_S2 
--#                           , u_RAMB16_S2_S18 
--#                           , u_RAMB16_S2_S2 
--#                           , u_RAMB16_S2_S36 
--#                           , u_RAMB16_S2_S4 
--#                           , u_RAMB16_S2_S9 
--#                           , u_RAMB16_S36 
--#                           , u_RAMB16_S36_S36 
--#                           , u_RAMB16_S4 
--#                           , u_RAMB16_S4_S18 
--#                           , u_RAMB16_S4_S36 
--#                           , u_RAMB16_S4_S4 
--#                           , u_RAMB16_S4_S9 
--#                           , u_RAMB16_S9 
--#                           , u_RAMB16_S9_S18 
--#                           , u_RAMB16_S9_S36 
--#                           , u_RAMB16_S9_S9 
--#                           , u_RAMB18 
--#                           , u_RAMB18SDP 
--#                           , u_RAMB32_S64_ECC 
--#                           , u_RAMB36 
--#                           , u_RAMB36SDP 
--#                           , u_RAMB36SDP_EXP 
--#                           , u_RAMB36_EXP 
--#                           , u_ROM128X1 
--#                           , u_ROM16X1 
--#                           , u_ROM256X1 
--#                           , u_ROM32X1 
--#                           , u_ROM64X1 
--#                           , u_SRL16 
--#                           , u_SRL16E 
--#                           , u_SRL16E_1 
--#                           , u_SRL16_1 
--#                           , u_SRLC16 
--#                           , u_SRLC16E 
--#                           , u_SRLC16E_1 
--#                           , u_SRLC16_1 
--#                           , u_SRLC32E 
--#                           , u_STARTUP_VIRTEX5 
--#                           , u_SYSMON 
--#                           , u_TOC 
--#                           , u_TOCBUF 
--#                           , u_USR_ACCESS_VIRTEX5 
--#                           , u_VCC 
--#                           , u_XNOR2 
--#                           , u_XNOR3 
--#                           , u_XNOR4 
--#                           , u_XOR2 
--#                           , u_XOR3 
--#                           , u_XOR4 
--#                           , u_XORCY 
--#                           , u_XORCY_D 
--#                           , u_XORCY_L 
--#                          ) 
--#             ); 
--#       -- 
--#       pp(spartan3a)  := pp(spartan3e); -- Populate spartan3a by taking 
--#                                        -- differences from spartan3e. 
--#       set_to(n, spartan3a, ( 
--#                              u_BSCAN_SPARTAN3 
--#                            , u_CAPTURE_SPARTAN3E 
--#                            , u_DUMMY_INV 
--#                            , u_DUMMY_NOR2 
--#                            , u_STARTBUF_SPARTAN3E 
--#                            , u_STARTUP_SPARTAN3E 
--#             )              ); 
--#       set_to(y, spartan3a, ( 
--#                              u_BSCAN_SPARTAN3A 
--#                            , u_CAPTURE_SPARTAN3A 
--#                            , u_DCM_PS 
--#                            , u_DNA_PORT 
--#                            , u_IBUF_DLY_ADJ 
--#                            , u_IBUFDS_DLY_ADJ 
--#                            , u_ICAP_SPARTAN3A 
--#                            , u_RAMB16BWE 
--#                            , u_RAMB16BWE_S18 
--#                            , u_RAMB16BWE_S18_S18 
--#                            , u_RAMB16BWE_S18_S9 
--#                            , u_RAMB16BWE_S36 
--#                            , u_RAMB16BWE_S36_S18 
--#                            , u_RAMB16BWE_S36_S36 
--#                            , u_RAMB16BWE_S36_S9 
--#                            , u_SPI_ACCESS 
--#                            , u_STARTUP_SPARTAN3A 
--#             )              ); 
--#
--#       -- 
--#       pp(aspartan3a)   := pp(spartan3a); 
--#       -- 
--#       pp(spartan3an) := pp(spartan3a); 
--#       -- 
--#       pp(spartan3adsp) := pp(spartan3a); 
--#       set_to(y, spartan3adsp, ( 
--#                                 u_DSP48A 
--#                               , u_RAMB16BWER 
--#             )                 ); 
--#       -- 
--#       pp(aspartan3adsp) := pp(spartan3adsp); 
--#       -- 
--#       set_to(y, spartan6,  ( 
--#                              u_AND2 
--#                            , u_AND2B1L 
--#                            , u_AND3 
--#                            , u_AND4 
--#                            , u_AUTOBUF 
--#                            , u_BSCAN_SPARTAN6 
--#                            , u_BUF 
--#                            , u_BUFCF 
--#                            , u_BUFG 
--#                            , u_BUFGCE 
--#                            , u_BUFGCE_1 
--#                            , u_BUFGDLL 
--#                            , u_BUFGMUX 
--#                            , u_BUFGMUX 
--#                            , u_BUFGMUX_1 
--#                            , u_BUFGMUX_1 
--#                            , u_BUFGP 
--#                            , u_BUFH 
--#                            , u_BUFIO2 
--#                            , u_BUFIO2_2CLK 
--#                            , u_BUFIO2FB 
--#                            , u_BUFIO2FB_2CLK 
--#                            , u_BUFPLL 
--#                            , u_BUFPLL_MCB 
--#                            , u_CAPTURE_SPARTAN3A 
--#                            , u_DCM 
--#                            , u_DCM_CLKGEN 
--#                            , u_DCM_PS 
--#                            , u_DNA_PORT 
--#                            , u_DSP48A1 
--#                            , u_FD 
--#                            , u_FD_1 
--#                            , u_FDC 
--#                            , u_FDC_1 
--#                            , u_FDCE 
--#                            , u_FDCE_1 
--#                            , u_FDCP 
--#                            , u_FDCP_1 
--#                            , u_FDCPE 
--#                            , u_FDCPE_1 
--#                            , u_FDDRCPE 
--#                            , u_FDDRRSE 
--#                            , u_FDE 
--#                            , u_FDE_1 
--#                            , u_FDP 
--#                            , u_FDP_1 
--#                            , u_FDPE 
--#                            , u_FDPE_1 
--#                            , u_FDR 
--#                            , u_FDR_1 
--#                            , u_FDRE 
--#                            , u_FDRE_1 
--#                            , u_FDRS 
--#                            , u_FDRS_1 
--#                            , u_FDRSE 
--#                            , u_FDRSE_1 
--#                            , u_FDS 
--#                            , u_FDS_1 
--#                            , u_FDSE 
--#                            , u_FDSE_1 
--#                            , u_FMAP 
--#                            , u_GND 
--#                            , u_GTPA1_DUAL 
--#                            , u_IBUF 
--#                            , u_IBUF_DLY_ADJ 
--#                            , u_IBUFDS 
--#                            , u_IBUFDS_DIFF_OUT 
--#                            , u_IBUFDS_DLY_ADJ 
--#                            , u_IBUFG 
--#                            , u_IBUFGDS 
--#                            , u_IBUFGDS_DIFF_OUT 
--#                            , u_ICAP_SPARTAN3A 
--#                            , u_ICAP_SPARTAN6 
--#                            , u_IDDR2 
--#                            , u_IFDDRCPE 
--#                            , u_IFDDRRSE 
--#                            , u_INV 
--#                            , u_IOBUF 
--#                            , u_IOBUFDS 
--#                            , u_IODELAY2 
--#                            , u_IODRP2 
--#                            , u_IODRP2_MCB 
--#                            , u_ISERDES2 
--#                            , u_JTAG_SIM_SPARTAN6 
--#                            , u_KEEPER 
--#                            , u_LD 
--#                            , u_LD_1 
--#                            , u_LDC 
--#                            , u_LDC_1 
--#                            , u_LDCE 
--#                            , u_LDCE_1 
--#                            , u_LDCP 
--#                            , u_LDCP_1 
--#                            , u_LDCPE 
--#                            , u_LDCPE_1 
--#                            , u_LDE 
--#                            , u_LDE_1 
--#                            , u_LDP 
--#                            , u_LDP_1 
--#                            , u_LDPE 
--#                            , u_LDPE_1 
--#                            , u_LUT1 
--#                            , u_LUT1_D 
--#                            , u_LUT1_L 
--#                            , u_LUT2 
--#                            , u_LUT2_D 
--#                            , u_LUT2_L 
--#                            , u_LUT3 
--#                            , u_LUT3_D 
--#                            , u_LUT3_L 
--#                            , u_LUT4 
--#                            , u_LUT4_D 
--#                            , u_LUT4_L 
--#                            , u_LUT5 
--#                            , u_LUT5_D 
--#                            , u_LUT5_L 
--#                            , u_LUT6 
--#                            , u_LUT6_D 
--#                            , u_LUT6_L 
--#                            , u_MCB 
--#                            , u_MULT18X18 
--#                            , u_MULT18X18S 
--#                            , u_MULT18X18SIO 
--#                            , u_MULT_AND 
--#                            , u_MUXCY 
--#                            , u_MUXCY_D 
--#                            , u_MUXCY_L 
--#                            , u_MUXF5 
--#                            , u_MUXF5_D 
--#                            , u_MUXF5_L 
--#                            , u_MUXF6 
--#                            , u_MUXF6_D 
--#                            , u_MUXF6_L 
--#                            , u_MUXF7 
--#                            , u_MUXF7_D 
--#                            , u_MUXF7_L 
--#                            , u_MUXF8 
--#                            , u_MUXF8_D 
--#                            , u_MUXF8_L 
--#                            , u_NAND2 
--#                            , u_NAND3 
--#                            , u_NAND4 
--#                            , u_NOR2 
--#                            , u_NOR3 
--#                            , u_NOR4 
--#                            , u_OBUF 
--#                            , u_OBUFDS 
--#                            , u_OBUFT 
--#                            , u_OBUFTDS 
--#                            , u_OCT_CALIBRATE 
--#                            , u_ODDR2 
--#                            , u_OFDDRCPE 
--#                            , u_OFDDRRSE 
--#                            , u_OFDDRTCPE 
--#                            , u_OFDDRTRSE 
--#                            , u_OR2 
--#                            , u_OR2L 
--#                            , u_OR3 
--#                            , u_OR4 
--#                            , u_ORCY 
--#                            , u_OSERDES2 
--#                            , u_PCIE_A1 
--#                            , u_PLL_ADV 
--#                            , u_POST_CRC_INTERNAL 
--#                            , u_PULLDOWN 
--#                            , u_PULLUP 
--#                            , u_RAM16X1D 
--#                            , u_RAM16X1D_1 
--#                            , u_RAM16X1S 
--#                            , u_RAM16X1S_1 
--#                            , u_RAM16X2S 
--#                            , u_RAM16X4S 
--#                            , u_RAM32X1S 
--#                            , u_RAM32X1S_1 
--#                            , u_RAM32X2S 
--#                            , u_RAM64X1S 
--#                            , u_RAM64X1S_1 
--#                            , u_RAMB16BWE 
--#                            , u_RAMB16BWE_S18 
--#                            , u_RAMB16BWE_S18_S18 
--#                            , u_RAMB16BWE_S18_S9 
--#                            , u_RAMB16BWE_S36 
--#                            , u_RAMB16BWE_S36_S18 
--#                            , u_RAMB16BWE_S36_S36 
--#                            , u_RAMB16BWE_S36_S9 
--#                            , u_RAMB16_S1 
--#                            , u_RAMB16_S18 
--#                            , u_RAMB16_S18_S18 
--#                            , u_RAMB16_S18_S36 
--#                            , u_RAMB16_S1_S1 
--#                            , u_RAMB16_S1_S18 
--#                            , u_RAMB16_S1_S2 
--#                            , u_RAMB16_S1_S36 
--#                            , u_RAMB16_S1_S4 
--#                            , u_RAMB16_S1_S9 
--#                            , u_RAMB16_S2 
--#                            , u_RAMB16_S2_S18 
--#                            , u_RAMB16_S2_S2 
--#                            , u_RAMB16_S2_S36 
--#                            , u_RAMB16_S2_S4 
--#                            , u_RAMB16_S2_S9 
--#                            , u_RAMB16_S36 
--#                            , u_RAMB16_S36_S36 
--#                            , u_RAMB16_S4 
--#                            , u_RAMB16_S4_S18 
--#                            , u_RAMB16_S4_S36 
--#                            , u_RAMB16_S4_S4 
--#                            , u_RAMB16_S4_S9 
--#                            , u_RAMB16_S9 
--#                            , u_RAMB16_S9_S18 
--#                            , u_RAMB16_S9_S36 
--#                            , u_RAMB16_S9_S9 
--#                            , u_RAMB8BWER 
--#                            , u_ROM128X1 
--#                            , u_ROM16X1 
--#                            , u_ROM256X1 
--#                            , u_ROM32X1 
--#                            , u_ROM64X1 
--#                            , u_SLAVE_SPI 
--#                            , u_SPI_ACCESS 
--#                            , u_SRL16 
--#                            , u_SRL16_1 
--#                            , u_SRL16E 
--#                            , u_SRL16E_1 
--#                            , u_SRLC16 
--#                            , u_SRLC16_1 
--#                            , u_SRLC16E 
--#                            , u_SRLC16E_1 
--#                            , u_SRLC32E 
--#                            , u_STARTUP_SPARTAN3A 
--#                            , u_STARTUP_SPARTAN6 
--#                            , u_SUSPEND_SYNC 
--#                            , u_TOC 
--#                            , u_TOCBUF 
--#                            , u_VCC 
--#                            , u_XNOR2 
--#                            , u_XNOR3 
--#                            , u_XNOR4 
--#                            , u_XOR2 
--#                            , u_XOR3 
--#                            , u_XOR4 
--#                            , u_XORCY 
--#                            , u_XORCY_D 
--#                            , u_XORCY_L 
--#             )              ); 
--#       -- 
--#       -- 
--#       set_to(y, virtex6,   ( 
--#                              u_AND2 
--#                            , u_AND2B1L 
--#                            , u_AND3 
--#                            , u_AND4 
--#                            , u_AUTOBUF 
--#                            , u_BSCAN_VIRTEX6 
--#                            , u_BUF 
--#                            , u_BUFCF 
--#                            , u_BUFG 
--#                            , u_BUFGCE 
--#                            , u_BUFGCE_1 
--#                            , u_BUFGCTRL 
--#                            , u_BUFGMUX 
--#                            , u_BUFGMUX_1 
--#                            , u_BUFGMUX_CTRL 
--#                            , u_BUFGP 
--#                            , u_BUFH 
--#                            , u_BUFHCE 
--#                            , u_BUFIO 
--#                            , u_BUFIODQS 
--#                            , u_BUFR 
--#                            , u_CAPTURE_VIRTEX5 
--#                            , u_CAPTURE_VIRTEX6 
--#                            , u_CARRY4 
--#                            , u_CFGLUT5 
--#                            , u_CRC32 
--#                            , u_CRC64 
--#                            , u_DCIRESET 
--#                            , u_DCIRESET 
--#                            , u_DCM 
--#                            , u_DCM_ADV 
--#                            , u_DCM_BASE 
--#                            , u_DCM_PS 
--#                            , u_DSP48 
--#                            , u_DSP48E 
--#                            , u_DSP48E1 
--#                            , u_EFUSE_USR 
--#                            , u_EMAC 
--#                            , u_FD 
--#                            , u_FD_1 
--#                            , u_FDC 
--#                            , u_FDC_1 
--#                            , u_FDCE 
--#                            , u_FDCE_1 
--#                            , u_FDCP 
--#                            , u_FDCP_1 
--#                            , u_FDCPE 
--#                            , u_FDCPE_1 
--#                            , u_FDDRCPE 
--#                            , u_FDDRRSE 
--#                            , u_FDE 
--#                            , u_FDE_1 
--#                            , u_FDP 
--#                            , u_FDP_1 
--#                            , u_FDPE 
--#                            , u_FDPE_1 
--#                            , u_FDR 
--#                            , u_FDR_1 
--#                            , u_FDRE 
--#                            , u_FDRE_1 
--#                            , u_FDRS 
--#                            , u_FDRS_1 
--#                            , u_FDRSE 
--#                            , u_FDRSE_1 
--#                            , u_FDS 
--#                            , u_FDS_1 
--#                            , u_FDSE 
--#                            , u_FDSE_1 
--#                            , u_FIFO16 
--#                            , u_FIFO18 
--#                            , u_FIFO18_36 
--#                            , u_FIFO18E1 
--#                            , u_FIFO36 
--#                            , u_FIFO36_72 
--#                            , u_FIFO36E1 
--#                            , u_FMAP 
--#                            , u_FRAME_ECC_VIRTEX5 
--#                            , u_FRAME_ECC_VIRTEX6 
--#                            , u_GND 
--#                            , u_GT11CLK 
--#                            , u_GT11CLK_MGT 
--#                            , u_GT11_CUSTOM 
--#                            , u_GTXE1 
--#                            , u_IBUF 
--#                            , u_IBUF 
--#                            , u_IBUFDS 
--#                            , u_IBUFDS 
--#                            , u_IBUFDS_DIFF_OUT 
--#                            , u_IBUFDS_GTXE1 
--#                            , u_IBUFG 
--#                            , u_IBUFG 
--#                            , u_IBUFGDS 
--#                            , u_IBUFGDS 
--#                            , u_IBUFGDS_DIFF_OUT 
--#                            , u_ICAP_VIRTEX5 
--#                            , u_ICAP_VIRTEX6 
--#                            , u_IDDR 
--#                            , u_IDDR_2CLK 
--#                            , u_IDELAY 
--#                            , u_IDELAYCTRL 
--#                            , u_IFDDRCPE 
--#                            , u_IFDDRRSE 
--#                            , u_INV 
--#                            , u_IOBUF 
--#                            , u_IOBUF 
--#                            , u_IOBUFDS 
--#                            , u_IOBUFDS 
--#                            , u_IOBUFDS_DIFF_OUT 
--#                            , u_IODELAY 
--#                            , u_IODELAYE1 
--#                            , u_ISERDES 
--#                            , u_ISERDESE1 
--#                            , u_ISERDES_NODELAY 
--#                            , u_JTAG_SIM_VIRTEX6 
--#                            , u_KEEPER 
--#                            , u_KEY_CLEAR 
--#                            , u_LD 
--#                            , u_LD_1 
--#                            , u_LDC 
--#                            , u_LDC_1 
--#                            , u_LDCE 
--#                            , u_LDCE_1 
--#                            , u_LDCP 
--#                            , u_LDCP_1 
--#                            , u_LDCPE 
--#                            , u_LDCPE_1 
--#                            , u_LDE 
--#                            , u_LDE_1 
--#                            , u_LDP 
--#                            , u_LDP_1 
--#                            , u_LDPE 
--#                            , u_LDPE_1 
--#                            , u_LUT1 
--#                            , u_LUT1_D 
--#                            , u_LUT1_L 
--#                            , u_LUT2 
--#                            , u_LUT2_D 
--#                            , u_LUT2_L 
--#                            , u_LUT3 
--#                            , u_LUT3_D 
--#                            , u_LUT3_L 
--#                            , u_LUT4 
--#                            , u_LUT4_D 
--#                            , u_LUT4_L 
--#                            , u_LUT5 
--#                            , u_LUT5_D 
--#                            , u_LUT5_L 
--#                            , u_LUT6 
--#                            , u_LUT6_D 
--#                            , u_LUT6_L 
--#                            , u_MMCM_ADV 
--#                            , u_MMCM_BASE 
--#                            , u_MULT18X18 
--#                            , u_MULT18X18S 
--#                            , u_MULT_AND 
--#                            , u_MUXCY 
--#                            , u_MUXCY_D 
--#                            , u_MUXCY_L 
--#                            , u_MUXF5 
--#                            , u_MUXF5_D 
--#                            , u_MUXF5_L 
--#                            , u_MUXF6 
--#                            , u_MUXF6_D 
--#                            , u_MUXF6_L 
--#                            , u_MUXF7 
--#                            , u_MUXF7_D 
--#                            , u_MUXF7_L 
--#                            , u_MUXF8 
--#                            , u_MUXF8_D 
--#                            , u_MUXF8_L 
--#                            , u_NAND2 
--#                            , u_NAND3 
--#                            , u_NAND4 
--#                            , u_NOR2 
--#                            , u_NOR3 
--#                            , u_NOR4 
--#                            , u_OBUF 
--#                            , u_OBUFDS 
--#                            , u_OBUFT 
--#                            , u_OBUFTDS 
--#                            , u_ODDR 
--#                            , u_OFDDRCPE 
--#                            , u_OFDDRRSE 
--#                            , u_OFDDRTCPE 
--#                            , u_OFDDRTRSE 
--#                            , u_OR2 
--#                            , u_OR2L 
--#                            , u_OR3 
--#                            , u_OR4 
--#                            , u_OSERDES 
--#                            , u_OSERDESE1 
--#                            , u_PCIE_2_0 
--#                            , u_PLL_ADV 
--#                            , u_PLL_BASE 
--#                            , u_PMCD 
--#                            , u_PPR_FRAME 
--#                            , u_PULLDOWN 
--#                            , u_PULLUP 
--#                            , u_RAM128X1D 
--#                            , u_RAM128X1S 
--#                            , u_RAM16X1D 
--#                            , u_RAM16X1D_1 
--#                            , u_RAM16X1S 
--#                            , u_RAM16X1S_1 
--#                            , u_RAM16X2S 
--#                            , u_RAM16X4S 
--#                            , u_RAM16X8S 
--#                            , u_RAM256X1S 
--#                            , u_RAM32M 
--#                            , u_RAM32X1S 
--#                            , u_RAM32X1S_1 
--#                            , u_RAM32X2S 
--#                            , u_RAM32X4S 
--#                            , u_RAM32X8S 
--#                            , u_RAM64M 
--#                            , u_RAM64X1D 
--#                            , u_RAM64X1S 
--#                            , u_RAM64X1S_1 
--#                            , u_RAM64X2S 
--#                            , u_RAMB16 
--#                            , u_RAMB16_S1 
--#                            , u_RAMB16_S18 
--#                            , u_RAMB16_S18_S18 
--#                            , u_RAMB16_S18_S36 
--#                            , u_RAMB16_S1_S1 
--#                            , u_RAMB16_S1_S18 
--#                            , u_RAMB16_S1_S2 
--#                            , u_RAMB16_S1_S36 
--#                            , u_RAMB16_S1_S4 
--#                            , u_RAMB16_S1_S9 
--#                            , u_RAMB16_S2 
--#                            , u_RAMB16_S2_S18 
--#                            , u_RAMB16_S2_S2 
--#                            , u_RAMB16_S2_S36 
--#                            , u_RAMB16_S2_S4 
--#                            , u_RAMB16_S2_S9 
--#                            , u_RAMB16_S36 
--#                            , u_RAMB16_S36_S36 
--#                            , u_RAMB16_S4 
--#                            , u_RAMB16_S4_S18 
--#                            , u_RAMB16_S4_S36 
--#                            , u_RAMB16_S4_S4 
--#                            , u_RAMB16_S4_S9 
--#                            , u_RAMB16_S9 
--#                            , u_RAMB16_S9_S18 
--#                            , u_RAMB16_S9_S36 
--#                            , u_RAMB16_S9_S9 
--#                            , u_RAMB18 
--#                            , u_RAMB18E1 
--#                            , u_RAMB18SDP 
--#                            , u_RAMB32_S64_ECC 
--#                            , u_RAMB36 
--#                            , u_RAMB36E1 
--#                            , u_RAMB36_EXP 
--#                            , u_RAMB36SDP 
--#                            , u_RAMB36SDP_EXP 
--#                            , u_ROM128X1 
--#                            , u_ROM16X1 
--#                            , u_ROM256X1 
--#                            , u_ROM32X1 
--#                            , u_ROM64X1 
--#                            , u_SRL16 
--#                            , u_SRL16_1 
--#                            , u_SRL16E 
--#                            , u_SRL16E_1 
--#                            , u_SRLC16 
--#                            , u_SRLC16_1 
--#                            , u_SRLC16E 
--#                            , u_SRLC16E_1 
--#                            , u_SRLC32E 
--#                            , u_STARTUP_VIRTEX5 
--#                            , u_STARTUP_VIRTEX6 
--#                            , u_SYSMON 
--#                            , u_SYSMON 
--#                            , u_TEMAC_SINGLE 
--#                            , u_TOC 
--#                            , u_TOCBUF 
--#                            , u_USR_ACCESS_VIRTEX5 
--#                            , u_USR_ACCESS_VIRTEX6 
--#                            , u_VCC 
--#                            , u_XNOR2 
--#                            , u_XNOR3 
--#                            , u_XNOR4 
--#                            , u_XOR2 
--#                            , u_XOR3 
--#                            , u_XOR4 
--#                            , u_XORCY 
--#                            , u_XORCY_D 
--#                            , u_XORCY_L 
--#             )              ); 
--#       -- 
--#       pp(spartan6l) := pp(spartan6); 
--#       -- 
--#       pp(qspartan6) := pp(spartan6); 
--#       -- 
--#       pp(aspartan6) := pp(spartan6); 
--#       -- 
--#       pp(virtex6l) := pp(virtex6); 
--#       -- 
--#       pp(qspartan6l) := pp(spartan6); 
--#       -- 
--#       pp(qvirtex5) := pp(virtex5); 
--#       -- 
--#       pp(qvirtex6) := pp(virtex6); 
--#       -- 
--#       pp(qrvirtex5) := pp(virtex5); 
--#       -- 
--#       pp(virtex5tx) := pp(virtex5); 
--#       -- 
--#       pp(virtex5fx) := pp(virtex5); 
--#       -- 
--#       pp(virtex6cx) := pp(virtex6); 
--#       -- 
--#       set_to(y, kintex7,   ( 
--#                              u_AND2
--#                            , u_AND2B1
--#                            , u_AND2B1L
--#                            , u_AND2B2
--#                            , u_AND3
--#                            , u_AND3B1
--#                            , u_AND3B2
--#                            , u_AND3B3
--#                            , u_AND4
--#                            , u_AND4B1
--#                            , u_AND4B2
--#                            , u_AND4B3
--#                            , u_AND4B4
--#                            , u_AND5
--#                            , u_AND5B1
--#                            , u_AND5B2
--#                            , u_AND5B3
--#                            , u_AND5B4
--#                            , u_AND5B5
--#                            , u_AUTOBUF
--#                            , u_BSCANE2
--#                            , u_BUF
--#                            , u_BUFCF
--#                            , u_BUFG
--#                            , u_BUFGCE
--#                            , u_BUFGCE_1
--#                            , u_BUFGCTRL
--#                            , u_BUFGMUX
--#                            , u_BUFGMUX_1
--#                            , u_BUFGP
--#                            , u_BUFH
--#                            , u_BUFHCE
--#                            , u_BUFIO
--#                            , u_BUFMR
--#                            , u_BUFMRCE
--#                            , u_BUFR
--#                            , u_BUFT
--#                            , u_CAPTUREE2
--#                            , u_CARRY4
--#                            , u_CFGLUT5
--#                            , u_DCIRESET
--#                            , u_DNA_PORT
--#                            , u_DSP48E1
--#                            , u_EFUSE_USR
--#                            , u_FD
--#                            , u_FD_1
--#                            , u_FDC
--#                            , u_FDC_1
--#                            , u_FDCE
--#                            , u_FDCE_1
--#                            , u_FDCP
--#                            , u_FDCP_1
--#                            , u_FDCPE
--#                            , u_FDCPE_1
--#                            , u_FDE
--#                            , u_FDE_1
--#                            , u_FDP
--#                            , u_FDP_1
--#                            , u_FDPE
--#                            , u_FDPE_1
--#                            , u_FDR
--#                            , u_FDR_1
--#                            , u_FDRE
--#                            , u_FDRE_1
--#                            , u_FDRS
--#                            , u_FDRS_1
--#                            , u_FDRSE
--#                            , u_FDRSE_1
--#                            , u_FDS
--#                            , u_FDS_1
--#                            , u_FDSE
--#                            , u_FDSE_1
--#                            , u_FIFO18E1
--#                            , u_FIFO36E1
--#                            , u_FMAP
--#                            , u_FRAME_ECCE2
--#                            , u_GND
--#                            , u_GTXE2_CHANNEL
--#                            , u_GTXE2_COMMON
--#                            , u_IBUF
--#                            , u_IBUF_DCIEN
--#                            , u_IBUFDS
--#                            , u_IBUFDS_BLVDS_25
--#                            , u_IBUFDS_DCIEN
--#                            , u_IBUFDS_DIFF_OUT
--#                            , u_IBUFDS_DIFF_OUT_DCIEN
--#                            , u_IBUFDS_GTE2
--#                            , u_IBUFDS_LVDS_25
--#                            , u_IBUFG
--#                            , u_IBUFGDS
--#                            , u_IBUFGDS_BLVDS_25
--#                            , u_IBUFGDS_DIFF_OUT
--#                            , u_IBUFGDS_LVDS_25
--#                            , u_IBUFG_HSTL_I
--#                            , u_IBUFG_HSTL_I_18
--#                            , u_IBUFG_HSTL_I_DCI
--#                            , u_IBUFG_HSTL_I_DCI_18
--#                            , u_IBUFG_HSTL_II
--#                            , u_IBUFG_HSTL_II_18
--#                            , u_IBUFG_HSTL_II_DCI
--#                            , u_IBUFG_HSTL_II_DCI_18
--#                            , u_IBUFG_HSTL_III
--#                            , u_IBUFG_HSTL_III_18
--#                            , u_IBUFG_HSTL_III_DCI
--#                            , u_IBUFG_HSTL_III_DCI_18
--#                            , u_IBUFG_LVCMOS12
--#                            , u_IBUFG_LVCMOS15
--#                            , u_IBUFG_LVCMOS18
--#                            , u_IBUFG_LVCMOS25
--#                            , u_IBUFG_LVCMOS33
--#                            , u_IBUFG_LVDCI_15
--#                            , u_IBUFG_LVDCI_18
--#                            , u_IBUFG_LVDCI_DV2_15
--#                            , u_IBUFG_LVDCI_DV2_18
--#                            , u_IBUFG_LVDS
--#                            , u_IBUFG_LVPECL
--#                            , u_IBUFG_LVTTL
--#                            , u_IBUFG_PCI33_3
--#                            , u_IBUFG_PCI66_3
--#                            , u_IBUFG_PCIX66_3
--#                            , u_IBUFG_SSTL18_I
--#                            , u_IBUFG_SSTL18_I_DCI
--#                            , u_IBUFG_SSTL18_II
--#                            , u_IBUFG_SSTL18_II_DCI
--#                            , u_IBUF_HSTL_I
--#                            , u_IBUF_HSTL_I_18
--#                            , u_IBUF_HSTL_I_DCI
--#                            , u_IBUF_HSTL_I_DCI_18
--#                            , u_IBUF_HSTL_II
--#                            , u_IBUF_HSTL_II_18
--#                            , u_IBUF_HSTL_II_DCI
--#                            , u_IBUF_HSTL_II_DCI_18
--#                            , u_IBUF_HSTL_III
--#                            , u_IBUF_HSTL_III_18
--#                            , u_IBUF_HSTL_III_DCI
--#                            , u_IBUF_HSTL_III_DCI_18
--#                            , u_IBUF_LVCMOS12
--#                            , u_IBUF_LVCMOS15
--#                            , u_IBUF_LVCMOS18
--#                            , u_IBUF_LVCMOS25
--#                            , u_IBUF_LVCMOS33
--#                            , u_IBUF_LVDCI_15
--#                            , u_IBUF_LVDCI_18
--#                            , u_IBUF_LVDCI_DV2_15
--#                            , u_IBUF_LVDCI_DV2_18
--#                            , u_IBUF_LVDS
--#                            , u_IBUF_LVPECL
--#                            , u_IBUF_LVTTL
--#                            , u_IBUF_PCI33_3
--#                            , u_IBUF_PCI66_3
--#                            , u_IBUF_PCIX66_3
--#                            , u_IBUF_SSTL18_I
--#                            , u_IBUF_SSTL18_I_DCI
--#                            , u_IBUF_SSTL18_II
--#                            , u_IBUF_SSTL18_II_DCI
--#                            , u_ICAPE2
--#                            , u_IDDR
--#                            , u_IDDR_2CLK
--#                            , u_IDELAY
--#                            , u_IDELAYCTRL
--#                            , u_IDELAYE2
--#                            , u_IN_FIFO
--#                            , u_INV
--#                            , u_IOBUF
--#                            , u_IOBUFDS
--#                            , u_IOBUFDS_BLVDS_25
--#                            , u_IOBUFDS_DIFF_OUT
--#                            , u_IOBUFDS_DIFF_OUT_DCIEN
--#                            , u_IOBUF_F_12
--#                            , u_IOBUF_F_16
--#                            , u_IOBUF_F_2
--#                            , u_IOBUF_F_24
--#                            , u_IOBUF_F_4
--#                            , u_IOBUF_F_6
--#                            , u_IOBUF_F_8
--#                            , u_IOBUF_HSTL_I
--#                            , u_IOBUF_HSTL_I_18
--#                            , u_IOBUF_HSTL_II
--#                            , u_IOBUF_HSTL_II_18
--#                            , u_IOBUF_HSTL_II_DCI
--#                            , u_IOBUF_HSTL_II_DCI_18
--#                            , u_IOBUF_HSTL_III
--#                            , u_IOBUF_HSTL_III_18
--#                            , u_IOBUF_LVCMOS12
--#                            , u_IOBUF_LVCMOS15
--#                            , u_IOBUF_LVCMOS18
--#                            , u_IOBUF_LVCMOS25
--#                            , u_IOBUF_LVCMOS33
--#                            , u_IOBUF_LVDCI_15
--#                            , u_IOBUF_LVDCI_18
--#                            , u_IOBUF_LVDCI_DV2_15
--#                            , u_IOBUF_LVDCI_DV2_18
--#                            , u_IOBUF_LVDS
--#                            , u_IOBUF_LVPECL
--#                            , u_IOBUF_LVTTL
--#                            , u_IOBUF_PCI33_3
--#                            , u_IOBUF_PCI66_3
--#                            , u_IOBUF_PCIX66_3
--#                            , u_IOBUF_S_12
--#                            , u_IOBUF_S_16
--#                            , u_IOBUF_S_2
--#                            , u_IOBUF_S_24
--#                            , u_IOBUF_S_4
--#                            , u_IOBUF_S_6
--#                            , u_IOBUF_S_8
--#                            , u_IOBUF_SSTL18_I
--#                            , u_IOBUF_SSTL18_II
--#                            , u_IOBUF_SSTL18_II_DCI
--#                            , u_IODELAY
--#                            , u_IODELAYE1
--#                            , u_ISERDESE2
--#                            , u_JTAG_SIME2
--#                            , u_KEEPER
--#                            , u_LD
--#                            , u_LD_1
--#                            , u_LDC
--#                            , u_LDC_1
--#                            , u_LDCE
--#                            , u_LDCE_1
--#                            , u_LDCP
--#                            , u_LDCP_1
--#                            , u_LDCPE
--#                            , u_LDCPE_1
--#                            , u_LDE
--#                            , u_LDE_1
--#                            , u_LDP
--#                            , u_LDP_1
--#                            , u_LDPE
--#                            , u_LDPE_1
--#                            , u_LUT1
--#                            , u_LUT1_D
--#                            , u_LUT1_L
--#                            , u_LUT2
--#                            , u_LUT2_D
--#                            , u_LUT2_L
--#                            , u_LUT3
--#                            , u_LUT3_D
--#                            , u_LUT3_L
--#                            , u_LUT4
--#                            , u_LUT4_D
--#                            , u_LUT4_L
--#                            , u_LUT5
--#                            , u_LUT5_D
--#                            , u_LUT5_L
--#                            , u_LUT6
--#                            , u_LUT6_2
--#                            , u_LUT6_D
--#                            , u_LUT6_L
--#                            , u_MMCME2_ADV
--#                            , u_MMCME2_BASE
--#                            , u_MULT_AND
--#                            , u_MUXCY
--#                            , u_MUXCY_D
--#                            , u_MUXCY_L
--#                            , u_MUXF5
--#                            , u_MUXF5_D
--#                            , u_MUXF5_L
--#                            , u_MUXF6
--#                            , u_MUXF6_D
--#                            , u_MUXF6_L
--#                            , u_MUXF7
--#                            , u_MUXF7_D
--#                            , u_MUXF7_L
--#                            , u_MUXF8
--#                            , u_MUXF8_D
--#                            , u_MUXF8_L
--#                            , u_NAND2
--#                            , u_NAND2B1
--#                            , u_NAND2B2
--#                            , u_NAND3
--#                            , u_NAND3B1
--#                            , u_NAND3B2
--#                            , u_NAND3B3
--#                            , u_NAND4
--#                            , u_NAND4B1
--#                            , u_NAND4B2
--#                            , u_NAND4B3
--#                            , u_NAND4B4
--#                            , u_NAND5
--#                            , u_NAND5B1
--#                            , u_NAND5B2
--#                            , u_NAND5B3
--#                            , u_NAND5B4
--#                            , u_NAND5B5
--#                            , u_NOR2
--#                            , u_NOR2B1
--#                            , u_NOR2B2
--#                            , u_NOR3
--#                            , u_NOR3B1
--#                            , u_NOR3B2
--#                            , u_NOR3B3
--#                            , u_NOR4
--#                            , u_NOR4B1
--#                            , u_NOR4B2
--#                            , u_NOR4B3
--#                            , u_NOR4B4
--#                            , u_NOR5
--#                            , u_NOR5B1
--#                            , u_NOR5B2
--#                            , u_NOR5B3
--#                            , u_NOR5B4
--#                            , u_NOR5B5
--#                            , u_OBUF
--#                            , u_OBUFDS
--#                            , u_OBUFDS_BLVDS_25
--#                            , u_OBUFDS_DUAL_BUF
--#                            , u_OBUFDS_LVDS_25
--#                            , u_OBUF_F_12
--#                            , u_OBUF_F_16
--#                            , u_OBUF_F_2
--#                            , u_OBUF_F_24
--#                            , u_OBUF_F_4
--#                            , u_OBUF_F_6
--#                            , u_OBUF_F_8
--#                            , u_OBUF_HSTL_I
--#                            , u_OBUF_HSTL_I_18
--#                            , u_OBUF_HSTL_I_DCI
--#                            , u_OBUF_HSTL_I_DCI_18
--#                            , u_OBUF_HSTL_II
--#                            , u_OBUF_HSTL_II_18
--#                            , u_OBUF_HSTL_II_DCI
--#                            , u_OBUF_HSTL_II_DCI_18
--#                            , u_OBUF_HSTL_III
--#                            , u_OBUF_HSTL_III_18
--#                            , u_OBUF_HSTL_III_DCI
--#                            , u_OBUF_HSTL_III_DCI_18
--#                            , u_OBUF_LVCMOS12
--#                            , u_OBUF_LVCMOS15
--#                            , u_OBUF_LVCMOS18
--#                            , u_OBUF_LVCMOS25
--#                            , u_OBUF_LVCMOS33
--#                            , u_OBUF_LVDCI_15
--#                            , u_OBUF_LVDCI_18
--#                            , u_OBUF_LVDCI_DV2_15
--#                            , u_OBUF_LVDCI_DV2_18
--#                            , u_OBUF_LVDS
--#                            , u_OBUF_LVPECL
--#                            , u_OBUF_LVTTL
--#                            , u_OBUF_PCI33_3
--#                            , u_OBUF_PCI66_3
--#                            , u_OBUF_PCIX66_3
--#                            , u_OBUF_S_12
--#                            , u_OBUF_S_16
--#                            , u_OBUF_S_2
--#                            , u_OBUF_S_24
--#                            , u_OBUF_S_4
--#                            , u_OBUF_S_6
--#                            , u_OBUF_S_8
--#                            , u_OBUF_SSTL18_I
--#                            , u_OBUF_SSTL18_I_DCI
--#                            , u_OBUF_SSTL18_II
--#                            , u_OBUF_SSTL18_II_DCI
--#                            , u_OBUFT
--#                            , u_OBUFT_DCIEN
--#                            , u_OBUFTDS
--#                            , u_OBUFTDS_BLVDS_25
--#                            , u_OBUFTDS_DCIEN
--#                            , u_OBUFTDS_DCIEN_DUAL_BUF
--#                            , u_OBUFTDS_DUAL_BUF
--#                            , u_OBUFTDS_LVDS_25
--#                            , u_OBUFT_F_12
--#                            , u_OBUFT_F_16
--#                            , u_OBUFT_F_2
--#                            , u_OBUFT_F_24
--#                            , u_OBUFT_F_4
--#                            , u_OBUFT_F_6
--#                            , u_OBUFT_F_8
--#                            , u_OBUFT_HSTL_I
--#                            , u_OBUFT_HSTL_I_18
--#                            , u_OBUFT_HSTL_I_DCI
--#                            , u_OBUFT_HSTL_I_DCI_18
--#                            , u_OBUFT_HSTL_II
--#                            , u_OBUFT_HSTL_II_18
--#                            , u_OBUFT_HSTL_II_DCI
--#                            , u_OBUFT_HSTL_II_DCI_18
--#                            , u_OBUFT_HSTL_III
--#                            , u_OBUFT_HSTL_III_18
--#                            , u_OBUFT_HSTL_III_DCI
--#                            , u_OBUFT_HSTL_III_DCI_18
--#                            , u_OBUFT_LVCMOS12
--#                            , u_OBUFT_LVCMOS15
--#                            , u_OBUFT_LVCMOS18
--#                            , u_OBUFT_LVCMOS25
--#                            , u_OBUFT_LVCMOS33
--#                            , u_OBUFT_LVDCI_15
--#                            , u_OBUFT_LVDCI_18
--#                            , u_OBUFT_LVDCI_DV2_15
--#                            , u_OBUFT_LVDCI_DV2_18
--#                            , u_OBUFT_LVDS
--#                            , u_OBUFT_LVPECL
--#                            , u_OBUFT_LVTTL
--#                            , u_OBUFT_PCI33_3
--#                            , u_OBUFT_PCI66_3
--#                            , u_OBUFT_PCIX66_3
--#                            , u_OBUFT_S_12
--#                            , u_OBUFT_S_16
--#                            , u_OBUFT_S_2
--#                            , u_OBUFT_S_24
--#                            , u_OBUFT_S_4
--#                            , u_OBUFT_S_6
--#                            , u_OBUFT_S_8
--#                            , u_OBUFT_SSTL18_I
--#                            , u_OBUFT_SSTL18_I_DCI
--#                            , u_OBUFT_SSTL18_II
--#                            , u_OBUFT_SSTL18_II_DCI
--#                            , u_ODDR
--#                            , u_ODELAYE2
--#                            , u_OR2
--#                            , u_OR2B1
--#                            , u_OR2B2
--#                            , u_OR2L
--#                            , u_OR3
--#                            , u_OR3B1
--#                            , u_OR3B2
--#                            , u_OR3B3
--#                            , u_OR4
--#                            , u_OR4B1
--#                            , u_OR4B2
--#                            , u_OR4B3
--#                            , u_OR4B4
--#                            , u_OR5
--#                            , u_OR5B1
--#                            , u_OR5B2
--#                            , u_OR5B3
--#                            , u_OR5B4
--#                            , u_OR5B5
--#                            , u_OSERDESE2
--#                            , u_OUT_FIFO
--#                            , u_PCIE_2_1
--#                            , u_PHASER_IN
--#                            , u_PHASER_IN_PHY
--#                            , u_PHASER_OUT
--#                            , u_PHASER_OUT_PHY
--#                            , u_PHASER_REF
--#                            , u_PHY_CONTROL
--#                            , u_PLLE2_ADV
--#                            , u_PLLE2_BASE
--#                            , u_PSS
--#                            , u_PULLDOWN
--#                            , u_PULLUP
--#                            , u_RAM128X1D
--#                            , u_RAM128X1S
--#                            , u_RAM128X1S_1
--#                            , u_RAM16X1D
--#                            , u_RAM16X1D_1
--#                            , u_RAM16X1S
--#                            , u_RAM16X1S_1
--#                            , u_RAM16X2S
--#                            , u_RAM16X4S
--#                            , u_RAM16X8S
--#                            , u_RAM256X1S
--#                            , u_RAM32M
--#                            , u_RAM32X1D
--#                            , u_RAM32X1D_1
--#                            , u_RAM32X1S
--#                            , u_RAM32X1S_1
--#                            , u_RAM32X2S
--#                            , u_RAM32X4S
--#                            , u_RAM32X8S
--#                            , u_RAM64M
--#                            , u_RAM64X1D
--#                            , u_RAM64X1D_1
--#                            , u_RAM64X1S
--#                            , u_RAM64X1S_1
--#                            , u_RAM64X2S
--#                            , u_RAMB16_S4_S36
--#                            , u_RAMB18E1
--#                            , u_RAMB36E1
--#                            , u_RAMD32
--#                            , u_RAMD64E
--#                            , u_RAMS32
--#                            , u_RAMS64E
--#                            , u_ROM128X1
--#                            , u_ROM16X1
--#                            , u_ROM256X1
--#                            , u_ROM32X1
--#                            , u_ROM64X1
--#                            , u_SIM_CONFIGE2
--#                            , u_SRL16
--#                            , u_SRL16_1
--#                            , u_SRL16E
--#                            , u_SRL16E_1
--#                            , u_SRLC16
--#                            , u_SRLC16_1
--#                            , u_SRLC16E
--#                            , u_SRLC16E_1
--#                            , u_SRLC32E
--#                            , u_STARTUPE2
--#                            , u_USR_ACCESSE2
--#                            , u_VCC
--#                            , u_XADC
--#                            , u_XNOR2
--#                            , u_XNOR3
--#                            , u_XNOR4
--#                            , u_XNOR5
--#                            , u_XOR2
--#                            , u_XOR3
--#                            , u_XOR4
--#                            , u_XOR5
--#                            , u_XORCY
--#                            , u_XORCY_D
--#                            , u_XORCY_L
--#                            , u_ZHOLD_DELAY
--#             )              ); 
--#       -- 
--#       set_to(y, virtex7,   ( 
--#                              u_AND2
--#                            , u_AND2B1
--#                            , u_AND2B1L
--#                            , u_AND2B2
--#                            , u_AND3
--#                            , u_AND3B1
--#                            , u_AND3B2
--#                            , u_AND3B3
--#                            , u_AND4
--#                            , u_AND4B1
--#                            , u_AND4B2
--#                            , u_AND4B3
--#                            , u_AND4B4
--#                            , u_AND5
--#                            , u_AND5B1
--#                            , u_AND5B2
--#                            , u_AND5B3
--#                            , u_AND5B4
--#                            , u_AND5B5
--#                            , u_AUTOBUF
--#                            , u_BSCANE2
--#                            , u_BUF
--#                            , u_BUFCF
--#                            , u_BUFG
--#                            , u_BUFGCE
--#                            , u_BUFGCE_1
--#                            , u_BUFGCTRL
--#                            , u_BUFGMUX
--#                            , u_BUFGMUX_1
--#                            , u_BUFGP
--#                            , u_BUFH
--#                            , u_BUFHCE
--#                            , u_BUFIO
--#                            , u_BUFMR
--#                            , u_BUFMRCE
--#                            , u_BUFR
--#                            , u_BUFT
--#                            , u_CAPTUREE2
--#                            , u_CARRY4
--#                            , u_CFG_IO_ACCESS
--#                            , u_CFGLUT5
--#                            , u_DCIRESET
--#                            , u_DNA_PORT
--#                            , u_DSP48E1
--#                            , u_EFUSE_USR
--#                            , u_FD
--#                            , u_FD_1
--#                            , u_FDC
--#                            , u_FDC_1
--#                            , u_FDCE
--#                            , u_FDCE_1
--#                            , u_FDCP
--#                            , u_FDCP_1
--#                            , u_FDCPE
--#                            , u_FDCPE_1
--#                            , u_FDE
--#                            , u_FDE_1
--#                            , u_FDP
--#                            , u_FDP_1
--#                            , u_FDPE
--#                            , u_FDPE_1
--#                            , u_FDR
--#                            , u_FDR_1
--#                            , u_FDRE
--#                            , u_FDRE_1
--#                            , u_FDRS
--#                            , u_FDRS_1
--#                            , u_FDRSE
--#                            , u_FDRSE_1
--#                            , u_FDS
--#                            , u_FDS_1
--#                            , u_FDSE
--#                            , u_FDSE_1
--#                            , u_FIFO18E1
--#                            , u_FIFO36E1
--#                            , u_FMAP
--#                            , u_FRAME_ECCE2
--#                            , u_GND
--#                            , u_GTXE2_CHANNEL
--#                            , u_GTXE2_COMMON
--#                            , u_IBUF
--#                            , u_IBUF_DCIEN
--#                            , u_IBUFDS
--#                            , u_IBUFDS_BLVDS_25
--#                            , u_IBUFDS_DCIEN
--#                            , u_IBUFDS_DIFF_OUT
--#                            , u_IBUFDS_DIFF_OUT_DCIEN
--#                            , u_IBUFDS_GTE2
--#                            , u_IBUFDS_LVDS_25
--#                            , u_IBUFG
--#                            , u_IBUFGDS
--#                            , u_IBUFGDS_BLVDS_25
--#                            , u_IBUFGDS_DIFF_OUT
--#                            , u_IBUFGDS_LVDS_25
--#                            , u_IBUFG_HSTL_I
--#                            , u_IBUFG_HSTL_I_18
--#                            , u_IBUFG_HSTL_I_DCI
--#                            , u_IBUFG_HSTL_I_DCI_18
--#                            , u_IBUFG_HSTL_II
--#                            , u_IBUFG_HSTL_II_18
--#                            , u_IBUFG_HSTL_II_DCI
--#                            , u_IBUFG_HSTL_II_DCI_18
--#                            , u_IBUFG_HSTL_III
--#                            , u_IBUFG_HSTL_III_18
--#                            , u_IBUFG_HSTL_III_DCI
--#                            , u_IBUFG_HSTL_III_DCI_18
--#                            , u_IBUFG_LVCMOS12
--#                            , u_IBUFG_LVCMOS15
--#                            , u_IBUFG_LVCMOS18
--#                            , u_IBUFG_LVCMOS25
--#                            , u_IBUFG_LVCMOS33
--#                            , u_IBUFG_LVDCI_15
--#                            , u_IBUFG_LVDCI_18
--#                            , u_IBUFG_LVDCI_DV2_15
--#                            , u_IBUFG_LVDCI_DV2_18
--#                            , u_IBUFG_LVDS
--#                            , u_IBUFG_LVPECL
--#                            , u_IBUFG_LVTTL
--#                            , u_IBUFG_PCI33_3
--#                            , u_IBUFG_PCI66_3
--#                            , u_IBUFG_PCIX66_3
--#                            , u_IBUFG_SSTL18_I
--#                            , u_IBUFG_SSTL18_I_DCI
--#                            , u_IBUFG_SSTL18_II
--#                            , u_IBUFG_SSTL18_II_DCI
--#                            , u_IBUF_HSTL_I
--#                            , u_IBUF_HSTL_I_18
--#                            , u_IBUF_HSTL_I_DCI
--#                            , u_IBUF_HSTL_I_DCI_18
--#                            , u_IBUF_HSTL_II
--#                            , u_IBUF_HSTL_II_18
--#                            , u_IBUF_HSTL_II_DCI
--#                            , u_IBUF_HSTL_II_DCI_18
--#                            , u_IBUF_HSTL_III
--#                            , u_IBUF_HSTL_III_18
--#                            , u_IBUF_HSTL_III_DCI
--#                            , u_IBUF_HSTL_III_DCI_18
--#                            , u_IBUF_LVCMOS12
--#                            , u_IBUF_LVCMOS15
--#                            , u_IBUF_LVCMOS18
--#                            , u_IBUF_LVCMOS25
--#                            , u_IBUF_LVCMOS33
--#                            , u_IBUF_LVDCI_15
--#                            , u_IBUF_LVDCI_18
--#                            , u_IBUF_LVDCI_DV2_15
--#                            , u_IBUF_LVDCI_DV2_18
--#                            , u_IBUF_LVDS
--#                            , u_IBUF_LVPECL
--#                            , u_IBUF_LVTTL
--#                            , u_IBUF_PCI33_3
--#                            , u_IBUF_PCI66_3
--#                            , u_IBUF_PCIX66_3
--#                            , u_IBUF_SSTL18_I
--#                            , u_IBUF_SSTL18_I_DCI
--#                            , u_IBUF_SSTL18_II
--#                            , u_IBUF_SSTL18_II_DCI
--#                            , u_ICAPE2
--#                            , u_IDDR
--#                            , u_IDDR_2CLK
--#                            , u_IDELAY
--#                            , u_IDELAYCTRL
--#                            , u_IDELAYE2
--#                            , u_IN_FIFO
--#                            , u_INV
--#                            , u_IOBUF
--#                            , u_IOBUFDS
--#                            , u_IOBUFDS_BLVDS_25
--#                            , u_IOBUFDS_DIFF_OUT
--#                            , u_IOBUFDS_DIFF_OUT_DCIEN
--#                            , u_IOBUF_F_12
--#                            , u_IOBUF_F_16
--#                            , u_IOBUF_F_2
--#                            , u_IOBUF_F_24
--#                            , u_IOBUF_F_4
--#                            , u_IOBUF_F_6
--#                            , u_IOBUF_F_8
--#                            , u_IOBUF_HSTL_I
--#                            , u_IOBUF_HSTL_I_18
--#                            , u_IOBUF_HSTL_II
--#                            , u_IOBUF_HSTL_II_18
--#                            , u_IOBUF_HSTL_II_DCI
--#                            , u_IOBUF_HSTL_II_DCI_18
--#                            , u_IOBUF_HSTL_III
--#                            , u_IOBUF_HSTL_III_18
--#                            , u_IOBUF_LVCMOS12
--#                            , u_IOBUF_LVCMOS15
--#                            , u_IOBUF_LVCMOS18
--#                            , u_IOBUF_LVCMOS25
--#                            , u_IOBUF_LVCMOS33
--#                            , u_IOBUF_LVDCI_15
--#                            , u_IOBUF_LVDCI_18
--#                            , u_IOBUF_LVDCI_DV2_15
--#                            , u_IOBUF_LVDCI_DV2_18
--#                            , u_IOBUF_LVDS
--#                            , u_IOBUF_LVPECL
--#                            , u_IOBUF_LVTTL
--#                            , u_IOBUF_PCI33_3
--#                            , u_IOBUF_PCI66_3
--#                            , u_IOBUF_PCIX66_3
--#                            , u_IOBUF_S_12
--#                            , u_IOBUF_S_16
--#                            , u_IOBUF_S_2
--#                            , u_IOBUF_S_24
--#                            , u_IOBUF_S_4
--#                            , u_IOBUF_S_6
--#                            , u_IOBUF_S_8
--#                            , u_IOBUF_SSTL18_I
--#                            , u_IOBUF_SSTL18_II
--#                            , u_IOBUF_SSTL18_II_DCI
--#                            , u_IODELAY
--#                            , u_IODELAYE1
--#                            , u_ISERDESE2
--#                            , u_JTAG_SIME2
--#                            , u_KEEPER
--#                            , u_LD
--#                            , u_LD_1
--#                            , u_LDC
--#                            , u_LDC_1
--#                            , u_LDCE
--#                            , u_LDCE_1
--#                            , u_LDCP
--#                            , u_LDCP_1
--#                            , u_LDCPE
--#                            , u_LDCPE_1
--#                            , u_LDE
--#                            , u_LDE_1
--#                            , u_LDP
--#                            , u_LDP_1
--#                            , u_LDPE
--#                            , u_LDPE_1
--#                            , u_LUT1
--#                            , u_LUT1_D
--#                            , u_LUT1_L
--#                            , u_LUT2
--#                            , u_LUT2_D
--#                            , u_LUT2_L
--#                            , u_LUT3
--#                            , u_LUT3_D
--#                            , u_LUT3_L
--#                            , u_LUT4
--#                            , u_LUT4_D
--#                            , u_LUT4_L
--#                            , u_LUT5
--#                            , u_LUT5_D
--#                            , u_LUT5_L
--#                            , u_LUT6
--#                            , u_LUT6_2
--#                            , u_LUT6_D
--#                            , u_LUT6_L
--#                            , u_MMCME2_ADV
--#                            , u_MMCME2_BASE
--#                            , u_MULT_AND
--#                            , u_MUXCY
--#                            , u_MUXCY_D
--#                            , u_MUXCY_L
--#                            , u_MUXF5
--#                            , u_MUXF5_D
--#                            , u_MUXF5_L
--#                            , u_MUXF6
--#                            , u_MUXF6_D
--#                            , u_MUXF6_L
--#                            , u_MUXF7
--#                            , u_MUXF7_D
--#                            , u_MUXF7_L
--#                            , u_MUXF8
--#                            , u_MUXF8_D
--#                            , u_MUXF8_L
--#                            , u_NAND2
--#                            , u_NAND2B1
--#                            , u_NAND2B2
--#                            , u_NAND3
--#                            , u_NAND3B1
--#                            , u_NAND3B2
--#                            , u_NAND3B3
--#                            , u_NAND4
--#                            , u_NAND4B1
--#                            , u_NAND4B2
--#                            , u_NAND4B3
--#                            , u_NAND4B4
--#                            , u_NAND5
--#                            , u_NAND5B1
--#                            , u_NAND5B2
--#                            , u_NAND5B3
--#                            , u_NAND5B4
--#                            , u_NAND5B5
--#                            , u_NOR2
--#                            , u_NOR2B1
--#                            , u_NOR2B2
--#                            , u_NOR3
--#                            , u_NOR3B1
--#                            , u_NOR3B2
--#                            , u_NOR3B3
--#                            , u_NOR4
--#                            , u_NOR4B1
--#                            , u_NOR4B2
--#                            , u_NOR4B3
--#                            , u_NOR4B4
--#                            , u_NOR5
--#                            , u_NOR5B1
--#                            , u_NOR5B2
--#                            , u_NOR5B3
--#                            , u_NOR5B4
--#                            , u_NOR5B5
--#                            , u_OBUF
--#                            , u_OBUFDS
--#                            , u_OBUFDS_BLVDS_25
--#                            , u_OBUFDS_DUAL_BUF
--#                            , u_OBUFDS_LVDS_25
--#                            , u_OBUF_F_12
--#                            , u_OBUF_F_16
--#                            , u_OBUF_F_2
--#                            , u_OBUF_F_24
--#                            , u_OBUF_F_4
--#                            , u_OBUF_F_6
--#                            , u_OBUF_F_8
--#                            , u_OBUF_HSTL_I
--#                            , u_OBUF_HSTL_I_18
--#                            , u_OBUF_HSTL_I_DCI
--#                            , u_OBUF_HSTL_I_DCI_18
--#                            , u_OBUF_HSTL_II
--#                            , u_OBUF_HSTL_II_18
--#                            , u_OBUF_HSTL_II_DCI
--#                            , u_OBUF_HSTL_II_DCI_18
--#                            , u_OBUF_HSTL_III
--#                            , u_OBUF_HSTL_III_18
--#                            , u_OBUF_HSTL_III_DCI
--#                            , u_OBUF_HSTL_III_DCI_18
--#                            , u_OBUF_LVCMOS12
--#                            , u_OBUF_LVCMOS15
--#                            , u_OBUF_LVCMOS18
--#                            , u_OBUF_LVCMOS25
--#                            , u_OBUF_LVCMOS33
--#                            , u_OBUF_LVDCI_15
--#                            , u_OBUF_LVDCI_18
--#                            , u_OBUF_LVDCI_DV2_15
--#                            , u_OBUF_LVDCI_DV2_18
--#                            , u_OBUF_LVDS
--#                            , u_OBUF_LVPECL
--#                            , u_OBUF_LVTTL
--#                            , u_OBUF_PCI33_3
--#                            , u_OBUF_PCI66_3
--#                            , u_OBUF_PCIX66_3
--#                            , u_OBUF_S_12
--#                            , u_OBUF_S_16
--#                            , u_OBUF_S_2
--#                            , u_OBUF_S_24
--#                            , u_OBUF_S_4
--#                            , u_OBUF_S_6
--#                            , u_OBUF_S_8
--#                            , u_OBUF_SSTL18_I
--#                            , u_OBUF_SSTL18_I_DCI
--#                            , u_OBUF_SSTL18_II
--#                            , u_OBUF_SSTL18_II_DCI
--#                            , u_OBUFT
--#                            , u_OBUFT_DCIEN
--#                            , u_OBUFTDS
--#                            , u_OBUFTDS_BLVDS_25
--#                            , u_OBUFTDS_DCIEN
--#                            , u_OBUFTDS_DCIEN_DUAL_BUF
--#                            , u_OBUFTDS_DUAL_BUF
--#                            , u_OBUFTDS_LVDS_25
--#                            , u_OBUFT_F_12
--#                            , u_OBUFT_F_16
--#                            , u_OBUFT_F_2
--#                            , u_OBUFT_F_24
--#                            , u_OBUFT_F_4
--#                            , u_OBUFT_F_6
--#                            , u_OBUFT_F_8
--#                            , u_OBUFT_HSTL_I
--#                            , u_OBUFT_HSTL_I_18
--#                            , u_OBUFT_HSTL_I_DCI
--#                            , u_OBUFT_HSTL_I_DCI_18
--#                            , u_OBUFT_HSTL_II
--#                            , u_OBUFT_HSTL_II_18
--#                            , u_OBUFT_HSTL_II_DCI
--#                            , u_OBUFT_HSTL_II_DCI_18
--#                            , u_OBUFT_HSTL_III
--#                            , u_OBUFT_HSTL_III_18
--#                            , u_OBUFT_HSTL_III_DCI
--#                            , u_OBUFT_HSTL_III_DCI_18
--#                            , u_OBUFT_LVCMOS12
--#                            , u_OBUFT_LVCMOS15
--#                            , u_OBUFT_LVCMOS18
--#                            , u_OBUFT_LVCMOS25
--#                            , u_OBUFT_LVCMOS33
--#                            , u_OBUFT_LVDCI_15
--#                            , u_OBUFT_LVDCI_18
--#                            , u_OBUFT_LVDCI_DV2_15
--#                            , u_OBUFT_LVDCI_DV2_18
--#                            , u_OBUFT_LVDS
--#                            , u_OBUFT_LVPECL
--#                            , u_OBUFT_LVTTL
--#                            , u_OBUFT_PCI33_3
--#                            , u_OBUFT_PCI66_3
--#                            , u_OBUFT_PCIX66_3
--#                            , u_OBUFT_S_12
--#                            , u_OBUFT_S_16
--#                            , u_OBUFT_S_2
--#                            , u_OBUFT_S_24
--#                            , u_OBUFT_S_4
--#                            , u_OBUFT_S_6
--#                            , u_OBUFT_S_8
--#                            , u_OBUFT_SSTL18_I
--#                            , u_OBUFT_SSTL18_I_DCI
--#                            , u_OBUFT_SSTL18_II
--#                            , u_OBUFT_SSTL18_II_DCI
--#                            , u_ODDR
--#                            , u_ODELAYE2
--#                            , u_OR2
--#                            , u_OR2B1
--#                            , u_OR2B2
--#                            , u_OR2L
--#                            , u_OR3
--#                            , u_OR3B1
--#                            , u_OR3B2
--#                            , u_OR3B3
--#                            , u_OR4
--#                            , u_OR4B1
--#                            , u_OR4B2
--#                            , u_OR4B3
--#                            , u_OR4B4
--#                            , u_OR5
--#                            , u_OR5B1
--#                            , u_OR5B2
--#                            , u_OR5B3
--#                            , u_OR5B4
--#                            , u_OR5B5
--#                            , u_OSERDESE2
--#                            , u_OUT_FIFO
--#                            , u_PCIE_2_1
--#                            , u_PHASER_IN
--#                            , u_PHASER_IN_PHY
--#                            , u_PHASER_OUT
--#                            , u_PHASER_OUT_PHY
--#                            , u_PHASER_REF
--#                            , u_PHY_CONTROL
--#                            , u_PLLE2_ADV
--#                            , u_PLLE2_BASE
--#                            , u_PSS
--#                            , u_PULLDOWN
--#                            , u_PULLUP
--#                            , u_RAM128X1D
--#                            , u_RAM128X1S
--#                            , u_RAM128X1S_1
--#                            , u_RAM16X1D
--#                            , u_RAM16X1D_1
--#                            , u_RAM16X1S
--#                            , u_RAM16X1S_1
--#                            , u_RAM16X2S
--#                            , u_RAM16X4S
--#                            , u_RAM16X8S
--#                            , u_RAM256X1S
--#                            , u_RAM32M
--#                            , u_RAM32X1D
--#                            , u_RAM32X1D_1
--#                            , u_RAM32X1S
--#                            , u_RAM32X1S_1
--#                            , u_RAM32X2S
--#                            , u_RAM32X4S
--#                            , u_RAM32X8S
--#                            , u_RAM64M
--#                            , u_RAM64X1D
--#                            , u_RAM64X1D_1
--#                            , u_RAM64X1S
--#                            , u_RAM64X1S_1
--#                            , u_RAM64X2S
--#                            , u_RAMB16_S4_S36
--#                            , u_RAMB36E1
--#                            , u_RAMB36E1
--#                            , u_RAMD32
--#                            , u_RAMD64E
--#                            , u_RAMS32
--#                            , u_RAMS64E
--#                            , u_ROM128X1
--#                            , u_ROM16X1
--#                            , u_ROM256X1
--#                            , u_ROM32X1
--#                            , u_ROM64X1
--#                            , u_SIM_CONFIGE2
--#                            , u_SRL16
--#                            , u_SRL16_1
--#                            , u_SRL16E
--#                            , u_SRL16E_1
--#                            , u_SRLC16
--#                            , u_SRLC16_1
--#                            , u_SRLC16E
--#                            , u_SRLC16E_1
--#                            , u_SRLC32E
--#                            , u_STARTUPE2
--#                            , u_USR_ACCESSE2
--#                            , u_VCC
--#                            , u_XADC
--#                            , u_XNOR2
--#                            , u_XNOR3
--#                            , u_XNOR4
--#                            , u_XNOR5
--#                            , u_XOR2
--#                            , u_XOR3
--#                            , u_XOR4
--#                            , u_XOR5
--#                            , u_XORCY
--#                            , u_XORCY_D
--#                            , u_XORCY_L
--#                            , u_ZHOLD_DELAY
--#             )              ); 
--#       -- 
--#       set_to(y, artix7,   ( 
--#                             u_AND2
--#                           , u_AND2B1
--#                           , u_AND2B1L
--#                           , u_AND2B2
--#                           , u_AND3
--#                           , u_AND3B1
--#                           , u_AND3B2
--#                           , u_AND3B3
--#                           , u_AND4
--#                           , u_AND4B1
--#                           , u_AND4B2
--#                           , u_AND4B3
--#                           , u_AND4B4
--#                           , u_AND5
--#                           , u_AND5B1
--#                           , u_AND5B2
--#                           , u_AND5B3
--#                           , u_AND5B4
--#                           , u_AND5B5
--#                           , u_AUTOBUF
--#                           , u_BSCANE2
--#                           , u_BUF
--#                           , u_BUFCF
--#                           , u_BUFG
--#                           , u_BUFGCE
--#                           , u_BUFGCE_1
--#                           , u_BUFGCTRL
--#                           , u_BUFGMUX
--#                           , u_BUFGMUX_1
--#                           , u_BUFGP
--#                           , u_BUFH
--#                           , u_BUFHCE
--#                           , u_BUFIO
--#                           , u_BUFMR
--#                           , u_BUFMRCE
--#                           , u_BUFR
--#                           , u_BUFT
--#                           , u_CAPTUREE2
--#                           , u_CARRY4
--#                           , u_CFGLUT5
--#                           , u_DCIRESET
--#                           , u_DNA_PORT
--#                           , u_DSP48E1
--#                           , u_EFUSE_USR
--#                           , u_FD
--#                           , u_FD_1
--#                           , u_FDC
--#                           , u_FDC_1
--#                           , u_FDCE
--#                           , u_FDCE_1
--#                           , u_FDCP
--#                           , u_FDCP_1
--#                           , u_FDCPE
--#                           , u_FDCPE_1
--#                           , u_FDE
--#                           , u_FDE_1
--#                           , u_FDP
--#                           , u_FDP_1
--#                           , u_FDPE
--#                           , u_FDPE_1
--#                           , u_FDR
--#                           , u_FDR_1
--#                           , u_FDRE
--#                           , u_FDRE_1
--#                           , u_FDRS
--#                           , u_FDRS_1
--#                           , u_FDRSE
--#                           , u_FDRSE_1
--#                           , u_FDS
--#                           , u_FDS_1
--#                           , u_FDSE
--#                           , u_FDSE_1
--#                           , u_FIFO18E1
--#                           , u_FIFO36E1
--#                           , u_FMAP
--#                           , u_FRAME_ECCE2
--#                           , u_GND
--#                           , u_IBUF
--#                           , u_IBUF_DCIEN
--#                           , u_IBUFDS
--#                           , u_IBUFDS_DCIEN
--#                           , u_IBUFDS_DIFF_OUT
--#                           , u_IBUFDS_DIFF_OUT_DCIEN
--#                           , u_IBUFDS_GTE2
--#                           , u_IBUFG
--#                           , u_IBUFGDS
--#                           , u_IBUFGDS_DIFF_OUT
--#                           , u_IBUFG_LVDS
--#                           , u_IBUFG_LVPECL
--#                           , u_IBUFG_PCIX66_3
--#                           , u_IBUF_LVDS
--#                           , u_IBUF_LVPECL
--#                           , u_IBUF_PCIX66_3
--#                           , u_ICAPE2
--#                           , u_IDDR
--#                           , u_IDDR_2CLK
--#                           , u_IDELAY
--#                           , u_IDELAYCTRL
--#                           , u_IDELAYE2
--#                           , u_IN_FIFO
--#                           , u_INV
--#                           , u_IOBUF
--#                           , u_IOBUFDS
--#                           , u_IOBUFDS_DIFF_OUT
--#                           , u_IOBUFDS_DIFF_OUT_DCIEN
--#                           , u_IOBUF_F_12
--#                           , u_IOBUF_F_16
--#                           , u_IOBUF_F_2
--#                           , u_IOBUF_F_24
--#                           , u_IOBUF_F_4
--#                           , u_IOBUF_F_6
--#                           , u_IOBUF_F_8
--#                           , u_IOBUF_LVDS
--#                           , u_IOBUF_LVPECL
--#                           , u_IOBUF_PCIX66_3
--#                           , u_IOBUF_S_12
--#                           , u_IOBUF_S_16
--#                           , u_IOBUF_S_2
--#                           , u_IOBUF_S_24
--#                           , u_IOBUF_S_4
--#                           , u_IOBUF_S_6
--#                           , u_IOBUF_S_8
--#                           , u_IODELAY
--#                           , u_IODELAYE1
--#                           , u_ISERDESE2
--#                           , u_JTAG_SIME2
--#                           , u_KEEPER
--#                           , u_LD
--#                           , u_LD_1
--#                           , u_LDC
--#                           , u_LDC_1
--#                           , u_LDCE
--#                           , u_LDCE_1
--#                           , u_LDCP
--#                           , u_LDCP_1
--#                           , u_LDCPE
--#                           , u_LDCPE_1
--#                           , u_LDE
--#                           , u_LDE_1
--#                           , u_LDP
--#                           , u_LDP_1
--#                           , u_LDPE
--#                           , u_LDPE_1
--#                           , u_LUT1
--#                           , u_LUT1_D
--#                           , u_LUT1_L
--#                           , u_LUT2
--#                           , u_LUT2_D
--#                           , u_LUT2_L
--#                           , u_LUT3
--#                           , u_LUT3_D
--#                           , u_LUT3_L
--#                           , u_LUT4
--#                           , u_LUT4_D
--#                           , u_LUT4_L
--#                           , u_LUT5
--#                           , u_LUT5_D
--#                           , u_LUT5_L
--#                           , u_LUT6
--#                           , u_LUT6_2
--#                           , u_LUT6_D
--#                           , u_LUT6_L
--#                           , u_MMCME2_ADV
--#                           , u_MMCME2_BASE
--#                           , u_MULT_AND
--#                           , u_MUXCY
--#                           , u_MUXCY_D
--#                           , u_MUXCY_L
--#                           , u_MUXF5
--#                           , u_MUXF5_D
--#                           , u_MUXF5_L
--#                           , u_MUXF6
--#                           , u_MUXF6_D
--#                           , u_MUXF6_L
--#                           , u_MUXF7
--#                           , u_MUXF7_D
--#                           , u_MUXF7_L
--#                           , u_MUXF8
--#                           , u_MUXF8_D
--#                           , u_MUXF8_L
--#                           , u_NAND2
--#                           , u_NAND2B1
--#                           , u_NAND2B2
--#                           , u_NAND3
--#                           , u_NAND3B1
--#                           , u_NAND3B2
--#                           , u_NAND3B3
--#                           , u_NAND4
--#                           , u_NAND4B1
--#                           , u_NAND4B2
--#                           , u_NAND4B3
--#                           , u_NAND4B4
--#                           , u_NAND5
--#                           , u_NAND5B1
--#                           , u_NAND5B2
--#                           , u_NAND5B3
--#                           , u_NAND5B4
--#                           , u_NAND5B5
--#                           , u_NOR2
--#                           , u_NOR2B1
--#                           , u_NOR2B2
--#                           , u_NOR3
--#                           , u_NOR3B1
--#                           , u_NOR3B2
--#                           , u_NOR3B3
--#                           , u_NOR4
--#                           , u_NOR4B1
--#                           , u_NOR4B2
--#                           , u_NOR4B3
--#                           , u_NOR4B4
--#                           , u_NOR5
--#                           , u_NOR5B1
--#                           , u_NOR5B2
--#                           , u_NOR5B3
--#                           , u_NOR5B4
--#                           , u_NOR5B5
--#                           , u_OBUF
--#                           , u_OBUFDS
--#                           , u_OBUFDS_DUAL_BUF
--#                           , u_OBUF_F_12
--#                           , u_OBUF_F_16
--#                           , u_OBUF_F_2
--#                           , u_OBUF_F_24
--#                           , u_OBUF_F_4
--#                           , u_OBUF_F_6
--#                           , u_OBUF_F_8
--#                           , u_OBUF_LVDS
--#                           , u_OBUF_LVPECL
--#                           , u_OBUF_PCIX66_3
--#                           , u_OBUF_S_12
--#                           , u_OBUF_S_16
--#                           , u_OBUF_S_2
--#                           , u_OBUF_S_24
--#                           , u_OBUF_S_4
--#                           , u_OBUF_S_6
--#                           , u_OBUF_S_8
--#                           , u_OBUFT
--#                           , u_OBUFT_DCIEN
--#                           , u_OBUFTDS
--#                           , u_OBUFTDS_DCIEN
--#                           , u_OBUFTDS_DCIEN_DUAL_BUF
--#                           , u_OBUFTDS_DUAL_BUF
--#                           , u_OBUFT_F_12
--#                           , u_OBUFT_F_16
--#                           , u_OBUFT_F_2
--#                           , u_OBUFT_F_24
--#                           , u_OBUFT_F_4
--#                           , u_OBUFT_F_6
--#                           , u_OBUFT_F_8
--#                           , u_OBUFT_LVDS
--#                           , u_OBUFT_LVPECL
--#                           , u_OBUFT_PCIX66_3
--#                           , u_OBUFT_S_12
--#                           , u_OBUFT_S_16
--#                           , u_OBUFT_S_2
--#                           , u_OBUFT_S_24
--#                           , u_OBUFT_S_4
--#                           , u_OBUFT_S_6
--#                           , u_OBUFT_S_8
--#                           , u_ODDR
--#                           , u_ODELAYE2
--#                           , u_OR2
--#                           , u_OR2B1
--#                           , u_OR2B2
--#                           , u_OR2L
--#                           , u_OR3
--#                           , u_OR3B1
--#                           , u_OR3B2
--#                           , u_OR3B3
--#                           , u_OR4
--#                           , u_OR4B1
--#                           , u_OR4B2
--#                           , u_OR4B3
--#                           , u_OR4B4
--#                           , u_OR5
--#                           , u_OR5B1
--#                           , u_OR5B2
--#                           , u_OR5B3
--#                           , u_OR5B4
--#                           , u_OR5B5
--#                           , u_OSERDESE2
--#                           , u_OUT_FIFO
--#                           , u_PCIE_2_1
--#                           , u_PHASER_IN
--#                           , u_PHASER_IN_PHY
--#                           , u_PHASER_OUT
--#                           , u_PHASER_OUT_PHY
--#                           , u_PHASER_REF
--#                           , u_PHY_CONTROL
--#                           , u_PLLE2_ADV
--#                           , u_PLLE2_BASE
--#                           , u_PSS
--#                           , u_PULLDOWN
--#                           , u_PULLUP
--#                           , u_RAM128X1D
--#                           , u_RAM128X1S
--#                           , u_RAM128X1S_1
--#                           , u_RAM16X1D
--#                           , u_RAM16X1D_1
--#                           , u_RAM16X1S
--#                           , u_RAM16X1S_1
--#                           , u_RAM16X2S
--#                           , u_RAM16X4S
--#                           , u_RAM16X8S
--#                           , u_RAM256X1S
--#                           , u_RAM32M
--#                           , u_RAM32X1D
--#                           , u_RAM32X1D_1
--#                           , u_RAM32X1S
--#                           , u_RAM32X1S_1
--#                           , u_RAM32X2S
--#                           , u_RAM32X4S
--#                           , u_RAM32X8S
--#                           , u_RAM64M
--#                           , u_RAM64X1D
--#                           , u_RAM64X1D_1
--#                           , u_RAM64X1S
--#                           , u_RAM64X1S_1
--#                           , u_RAM64X2S
--#                            , u_RAMB16_S4_S36
--#                           , u_RAMB18E1
--#                           , u_RAMB36E1
--#                           , u_RAMD32
--#                           , u_RAMD64E
--#                           , u_RAMS32
--#                           , u_RAMS64E
--#                           , u_ROM128X1
--#                           , u_ROM16X1
--#                           , u_ROM256X1
--#                           , u_ROM32X1
--#                           , u_ROM64X1
--#                           , u_SIM_CONFIGE2
--#                           , u_SRL16
--#                           , u_SRL16_1
--#                           , u_SRL16E
--#                           , u_SRL16E_1
--#                           , u_SRLC16
--#                           , u_SRLC16_1
--#                           , u_SRLC16E
--#                           , u_SRLC16E_1
--#                           , u_SRLC32E
--#                           , u_STARTUPE2
--#                           , u_USR_ACCESSE2
--#                           , u_VCC
--#                           , u_XADC
--#                           , u_XNOR2
--#                           , u_XNOR3
--#                           , u_XNOR4
--#                           , u_XNOR5
--#                           , u_XOR2
--#                           , u_XOR3
--#                           , u_XOR4
--#                           , u_XOR5
--#                           , u_XORCY
--#                           , u_XORCY_D
--#                           , u_XORCY_L
--#                           , u_ZHOLD_DELAY
--#             )              ); 
--#       -- 
--#       return pp; 
--#   end prim_population; 
--#   ---) 
--#
--#constant fam_has_prim :  fam_has_prim_type := prim_population; 
constant fam_has_prim :  fam_has_prim_type := 
(
     nofamily => (
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex => (
y, n, y, y, n, n, n, n, n, n, y, n, n, n, n, y, y, y, y, n, n, n, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan2 => (
y, n, y, y, n, y, n, n, n, n, n, n, n, n, n, y, y, y, y, n, n, n, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, y, n, n, n, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan2e => (
y, n, y, y, n, y, n, n, n, n, n, n, n, n, n, y, y, y, y, n, n, n, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, y, n, n, n, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtexe => (
y, n, y, y, n, n, n, n, n, n, y, n, n, n, n, y, y, y, y, n, n, n, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex2 => (
y, n, y, y, n, n, n, n, n, n, n, y, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qvirtex2 => (
y, n, y, y, n, n, n, n, n, n, n, y, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qrvirtex2 => (
y, n, y, y, n, n, n, n, n, n, n, y, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex2p => (
y, n, y, y, n, n, n, n, n, n, n, y, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, y, n, n, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan3 => (
y, n, y, y, n, n, y, n, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     aspartan3 => (
y, n, y, y, n, n, y, n, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex4 => (
y, n, y, y, n, n, n, n, n, n, n, n, y, n, n, y, y, n, y, y, y, y, n, y, y, n, y, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, y, y, y, y, n, y, n, y, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, y, y, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, y, y, n, y, n, n, n, n, n, n, y, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, n, n, n, n, y, y, y, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex4lx => (
y, n, y, y, n, n, n, n, n, n, n, n, y, n, n, y, y, n, y, y, y, y, n, y, y, n, y, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, y, y, y, y, n, y, n, y, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, y, y, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, y, y, n, y, n, n, n, n, n, n, y, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, n, n, n, n, y, y, y, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex4fx => (
y, n, y, y, n, n, n, n, n, n, n, n, y, n, n, y, y, n, y, y, y, y, n, y, y, n, y, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, y, y, y, y, n, y, n, y, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, y, y, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, y, y, n, y, n, n, n, n, n, n, y, n, y, y, n, y, y, n, n, n, y, y, y, y, y, y, y, n, n, n, n, y, y, y, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex4sx => (
y, n, y, y, n, n, n, n, n, n, n, n, y, n, n, y, y, n, y, y, y, y, n, y, y, n, y, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, y, y, y, y, n, y, n, y, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, y, y, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, y, y, n, y, n, n, n, n, n, n, y, n, y, y, n, y, y, n, n, n, y, y, y, y, y, y, y, n, n, n, n, y, y, y, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan3e => (
y, n, y, y, n, n, y, n, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, y, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex5 => (
y, n, y, y, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, y, y, y, n, y, y, y, n, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, n, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, n, y, n, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, n, y, y, n, y, n, n, n, n, y, y, y, n, n, n, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, y, y, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan3a => (
y, n, y, y, n, n, n, y, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan3an => (
y, n, y, y, n, n, n, y, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan3adsp => (
y, n, y, y, n, n, n, y, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, y, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     aspartan3e => (
y, n, y, y, n, n, y, n, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, y, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     aspartan3a => (
y, n, y, y, n, n, n, y, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     aspartan3adsp => (
y, n, y, y, n, n, n, y, n, n, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, y, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qvirtex4 => (
y, n, y, y, n, n, n, n, n, n, n, n, y, n, n, y, y, n, y, y, y, y, n, y, y, n, y, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, y, y, y, y, n, y, n, y, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, y, y, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, y, y, n, y, n, n, n, n, n, n, y, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, n, n, n, n, y, y, y, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qrvirtex4 => (
y, n, y, y, n, n, n, n, n, n, n, n, y, n, n, y, y, n, y, y, y, y, n, y, y, n, y, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, n, y, y, y, y, n, y, n, y, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, y, y, n, n, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, y, n, y, y, n, y, n, n, n, n, n, n, y, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, n, n, n, n, y, y, y, y, y, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan6 => (
y, y, y, y, y, n, n, n, n, y, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, n, y, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, n, n, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, n, n, n, y, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, n, n, y, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, y, n, y, n, n, n, n, n, y, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex6 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, n, y, y, y, y, n, y, y, y, n, y, y, y, y, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, y, y, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, n, y, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, y, y, y, y, y, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, n, y, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, n, y, n, y, y, n, y, y, y, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     spartan6l => (
y, y, y, y, y, n, n, n, n, y, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, n, y, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, n, n, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, n, n, n, y, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, n, n, y, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, y, n, y, n, n, n, n, n, y, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qspartan6 => (
y, y, y, y, y, n, n, n, n, y, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, n, y, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, n, n, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, n, n, n, y, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, n, n, y, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, y, n, y, n, n, n, n, n, y, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     aspartan6 => (
y, y, y, y, y, n, n, n, n, y, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, n, y, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, n, n, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, n, n, n, y, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, n, n, y, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, y, n, y, n, n, n, n, n, y, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex6l => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, n, y, y, y, y, n, y, y, y, n, y, y, y, y, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, y, y, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, n, y, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, y, y, y, y, y, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, n, y, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, n, y, n, y, y, n, y, y, y, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qspartan6l => (
y, y, y, y, y, n, n, n, n, y, n, n, n, n, n, y, y, n, y, y, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, n, y, y, n, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, y, y, n, n, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, y, y, y, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, n, n, n, y, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, y, n, n, y, n, n, n, y, y, n, n, n, y, y, y, y, y, y, n, n, n, n, n, y, y, y, n, n, n, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, y, n, y, n, n, n, n, n, y, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qvirtex5 => (
y, n, y, y, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, y, y, y, n, y, y, y, n, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, n, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, n, y, n, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, n, y, y, n, y, n, n, n, n, y, y, y, n, n, n, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, y, y, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qvirtex6 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, n, y, y, y, y, n, y, y, y, n, y, y, y, y, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, y, y, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, n, y, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, y, y, y, y, y, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, n, y, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, n, y, n, y, y, n, y, y, y, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     qrvirtex5 => (
y, n, y, y, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, y, y, y, n, y, y, y, n, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, n, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, n, y, n, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, n, y, y, n, y, n, n, n, n, y, y, y, n, n, n, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, y, y, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex5tx => (
y, n, y, y, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, y, y, y, n, y, y, y, n, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, n, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, n, y, n, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, n, y, y, n, y, n, n, n, n, y, y, y, n, n, n, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, y, y, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex5fx => (
y, n, y, y, n, n, n, n, n, n, n, n, n, y, n, y, y, n, y, y, y, y, n, y, y, y, n, y, n, n, y, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, n, y, n, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, n, y, n, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, n, y, y, n, y, n, n, n, n, y, y, y, n, n, n, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, y, y, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     virtex6cx => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, n, y, y, y, y, n, y, y, y, n, y, y, y, y, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, y, y, y, y, n, n, n, y, y, y, y, y, y, n, y, n, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, y, n, y, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, y, y, y, y, y, y, n, n, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, n, n, y, n, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, n, y, n, y, y, n, y, y, y, n, n, n, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, n, y, y, y, y, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n), 
     kintex7 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     kintex7l => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     qkintex7 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     qkintex7l => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     virtex7 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     virtex7l => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     qvirtex7 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     qvirtex7l => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     artix7 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     aartix7 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     artix7l => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     qartix7 => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     qartix7l => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, 
n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     zynq => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     azynq => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y), 
     qzynq => (
y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, y, y, n, y, y, y, y, n, y, y, n, n, y, y, y, y, n, n, n, n, n, n, n, y, y, n, n, n, n, n, n, n, n, n, y, y, n, n, n, n, n, y, n, n, n, n, n, y, n, n, n, n, y, n, n, y, n, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, y, n, n, y, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, y, y, n, n, y, n, n, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, y, y, n, y, n, y, y, y, n, y, y, n, n, n, n, n, n, n, n, n, n, y, n, y, y, y, n, n, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, y, n, n, n, n, n, n, n, n, n, y, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, y, n, n, y, y, y, y, y, y, y, y, n, n, y, y, n, y, n, y, y, y, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, y, n, n, n, n, n, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, n, n, n, n, n, n, n, y, n, n, n, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, n, n, y, y, y, y, y, y, y, y, y, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, 
y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y, y) 
);

    function supported( family         : families_type;
                        primitive      : primitives_type
                      ) return boolean is
    begin
        return  fam_has_prim(family)(primitive) = y;
    end supported;


    function supported( family         : families_type;
                        primitives     : primitive_array_type
                      ) return boolean is
    begin
        for i in primitives'range loop
            if fam_has_prim(family)(primitives(i)) /= y then
                return false;
            end if;
        end loop;
        return true;
    end supported;

    ----------------------------------------------------------------------------
    -- This function is used as alternative to the 'IMAGE attribute, which
    -- is not correctly interpretted by some vhdl tools.
    ----------------------------------------------------------------------------
    function myimage (fam_type :  families_type) return string is 
      variable temp : families_type :=fam_type;
    begin 
    case temp is 
      when nofamily      => return "nofamily"     ;
      when virtex        => return "virtex"       ;
      when spartan2      => return "spartan2"     ;
      when spartan2e     => return "spartan2e"    ;
      when virtexe       => return "virtexe"      ;
      when virtex2       => return "virtex2"      ;
      when qvirtex2      => return "qvirtex2"     ;
      when qrvirtex2     => return "qrvirtex2"    ;
      when virtex2p      => return "virtex2p"     ;
      when spartan3      => return "spartan3"     ;
      when aspartan3     => return "aspartan3"    ;
      when spartan3e     => return "spartan3e"    ;
      when virtex4       => return "virtex4"      ;
      when virtex4lx     => return "virtex4lx"    ;
      when virtex4fx     => return "virtex4fx"    ;
      when virtex4sx     => return "virtex4sx"    ;
      when virtex5       => return "virtex5"      ;
      when spartan3a     => return "spartan3a"    ;
      when spartan3an    => return "spartan3an"   ;
      when spartan3adsp  => return "spartan3adsp" ;
      when aspartan3e    => return "aspartan3e"   ;
      when aspartan3a    => return "aspartan3a"   ;
      when aspartan3adsp => return "aspartan3adsp";
      when qvirtex4      => return "qvirtex4"     ;
      when qrvirtex4     => return "qrvirtex4"    ;
      when spartan6      => return "spartan6"     ;
      when virtex6       => return "virtex6"      ;
      when spartan6l     => return "spartan6l"    ;
      when qspartan6     => return "qspartan6"    ;
      when aspartan6     => return "aspartan6"    ;
      when virtex6l      => return "virtex6l"     ;
      when qspartan6l    => return "qspartan6l"   ;
      when qvirtex5      => return "qvirtex5"     ;
      when qvirtex6      => return "qvirtex6"     ;
      when qrvirtex5     => return "qrvirtex5"    ;
      when virtex5tx     => return "virtex5tx"    ;
      when virtex5fx     => return "virtex5fx"    ;
      when virtex6cx     => return "virtex6cx"    ;
      when virtex7       => return "virtex7"      ;
      when virtex7l      => return "virtex7l"     ;
      when qvirtex7      => return "qvirtex7"     ;
      when qvirtex7l     => return "qvirtex7l"    ;
      when kintex7       => return "kintex7"      ;
      when kintex7l      => return "kintex7l"     ;
      when qkintex7      => return "qkintex7"     ;
      when qkintex7l     => return "qkintex7l"    ;
      when artix7        => return "artix7"       ;
      when aartix7       => return "aartix7"      ;
      when artix7l       => return "artix7l"      ;
      when qartix7       => return "qartix7"      ;
      when qartix7l      => return "qartix7l"     ;
      when zynq          => return "zynq"         ;
      when azynq         => return "azynq"        ;
      when qzynq         => return "qzynq"        ;
    end case;
    end myimage;


    
    ---------------------------------------------------------------------------- 
    -- Function: get_root_family
    --
    -- This function takes in the string for the desired FPGA family type and
    -- returns the root FPGA family type string. This is used for derivative part 
    -- aliasing to the root family. This is primarily for fifo_generator and 
    -- blk_mem_gen calls that need the root family passed to the call.
    ---------------------------------------------------------------------------- 
    function get_root_family(family_in : string) return string is
    
    begin 
      
      -- spartan3 Root family
      if    (equalIgnoringCase(family_in, "spartan3"      )) Then return "spartan3" ;
      Elsif (equalIgnoringCase(family_in, "spartan3a"     )) Then return "spartan3" ;
      Elsif (equalIgnoringCase(family_in, "spartan3an"    )) Then return "spartan3" ;
      Elsif (equalIgnoringCase(family_in, "spartan3adsp"  )) Then return "spartan3" ;
      Elsif (equalIgnoringCase(family_in, "aspartan3"     )) Then return "spartan3" ;
      Elsif (equalIgnoringCase(family_in, "aspartan3a"    )) Then return "spartan3" ;
      Elsif (equalIgnoringCase(family_in, "aspartan3adsp" )) Then return "spartan3" ;
      Elsif (equalIgnoringCase(family_in, "spartan3e"     )) Then return "spartan3" ;
      Elsif (equalIgnoringCase(family_in, "aspartan3e"    )) Then return "spartan3" ;
                                                           
      -- virtex4 Root family                               
      Elsif (equalIgnoringCase(family_in, "virtex4"       )) Then return "virtex4"  ;
      Elsif (equalIgnoringCase(family_in, "virtex4lx"     )) Then return "virtex4"  ;
      Elsif (equalIgnoringCase(family_in, "virtex4fx"     )) Then return "virtex4"  ;
      Elsif (equalIgnoringCase(family_in, "virtex4sx"     )) Then return "virtex4"  ;
      Elsif (equalIgnoringCase(family_in, "qvirtex4"      )) Then return "virtex4"  ;
      Elsif (equalIgnoringCase(family_in, "qrvirtex4"     )) Then return "virtex4"  ;
                                                           
      -- virtex5 Root family                               
      Elsif (equalIgnoringCase(family_in, "virtex5"       )) Then return "virtex5"  ;
      Elsif (equalIgnoringCase(family_in, "qvirtex5"      )) Then return "virtex5"  ;
      Elsif (equalIgnoringCase(family_in, "qrvirtex5"     )) Then return "virtex5"  ;
      Elsif (equalIgnoringCase(family_in, "virtex5tx"     )) Then return "virtex5"  ;
      Elsif (equalIgnoringCase(family_in, "virtex5fx"     )) Then return "virtex5"  ;
                                                           
      -- virtex6 Root family                               
      Elsif (equalIgnoringCase(family_in, "virtex6"       )) Then return "virtex6"  ;
      Elsif (equalIgnoringCase(family_in, "virtex6l"      )) Then return "virtex6"  ;
      Elsif (equalIgnoringCase(family_in, "qvirtex6"      )) Then return "virtex6"  ;
      Elsif (equalIgnoringCase(family_in, "virtex6cx"     )) Then return "virtex6"  ;
                                                           
      -- spartan6 Root family                              
      Elsif (equalIgnoringCase(family_in, "spartan6"      )) Then return "spartan6" ;
      Elsif (equalIgnoringCase(family_in, "spartan6l"     )) Then return "spartan6" ;
      Elsif (equalIgnoringCase(family_in, "qspartan6"     )) Then return "spartan6" ;
      Elsif (equalIgnoringCase(family_in, "aspartan6"     )) Then return "spartan6" ;
      Elsif (equalIgnoringCase(family_in, "qspartan6l"    )) Then return "spartan6" ;
      
      -- Virtex7 Root family                              
      Elsif (equalIgnoringCase(family_in, "virtex7"      )) Then return "virtex7" ;
      Elsif (equalIgnoringCase(family_in, "virtex7l"     )) Then return "virtex7" ;
      Elsif (equalIgnoringCase(family_in, "qvirtex7"     )) Then return "virtex7" ;
      Elsif (equalIgnoringCase(family_in, "qvirtex7l"    )) Then return "virtex7" ;
      
      -- Kintex7 Root family                              
      Elsif (equalIgnoringCase(family_in, "kintex7"     )) Then return "kintex7" ;
      Elsif (equalIgnoringCase(family_in, "kintex7l"    )) Then return "kintex7" ;
      Elsif (equalIgnoringCase(family_in, "qkintex7"    )) Then return "kintex7" ;
      Elsif (equalIgnoringCase(family_in, "qkintex7l"   )) Then return "kintex7" ;
      
      -- artix7 Root family                              
      Elsif (equalIgnoringCase(family_in, "artix7"     )) Then return "artix7" ;
      Elsif (equalIgnoringCase(family_in, "aartix7"    )) Then return "artix7" ;
      Elsif (equalIgnoringCase(family_in, "artix7l"    )) Then return "artix7" ;
      Elsif (equalIgnoringCase(family_in, "qartix7"    )) Then return "artix7" ;
      Elsif (equalIgnoringCase(family_in, "qartix7l"   )) Then return "artix7" ;
      
      -- zynq Root family                              
      Elsif (equalIgnoringCase(family_in, "zynq"     )) Then return "zynq" ;
      Elsif (equalIgnoringCase(family_in, "azynq"    )) Then return "zynq" ;
      Elsif (equalIgnoringCase(family_in, "qzynq"    )) Then return "zynq" ;
      
      -- No Match to supported families and derivatives
      Else  return "nofamily";
      
      End if;
    
    end get_root_family;


    
    
    function toLowerCaseChar( char : character ) return character is
    begin
       -- If char is not an upper case letter then return char
       if char < 'A' OR char > 'Z' then
         return char;
       end if;
       -- Otherwise map char to its corresponding lower case character and
       -- return that
       case char is
         when 'A' => return 'a';
         when 'B' => return 'b';
         when 'C' => return 'c';
         when 'D' => return 'd';
         when 'E' => return 'e';
         when 'F' => return 'f';
         when 'G' => return 'g';
         when 'H' => return 'h';
         when 'I' => return 'i';
         when 'J' => return 'j';
         when 'K' => return 'k';
         when 'L' => return 'l';
         when 'M' => return 'm';
         when 'N' => return 'n';
         when 'O' => return 'o';
         when 'P' => return 'p';
         when 'Q' => return 'q';
         when 'R' => return 'r';
         when 'S' => return 's';
         when 'T' => return 't';
         when 'U' => return 'u';
         when 'V' => return 'v';
         when 'W' => return 'w';
         when 'X' => return 'x';
         when 'Y' => return 'y';
         when 'Z' => return 'z';
         when others => return char;
       end case;
    end toLowerCaseChar;


    ---------------------------------------------------------------------------- 
    -- Function: equalIgnoringCase
    --
    -- Compare one string against another for equality with case insensitivity.
    -- Can be used to test see if a family, C_FAMILY, is equal to some
    -- family. However such usage is discouraged. Use instead availability
    -- primitive guards based on the function, 'supported', wherever possible.
    ---------------------------------------------------------------------------- 
    function equalIgnoringCase( str1, str2 : string ) return boolean is
      constant LEN1 : integer := str1'length;
      constant LEN2 : integer := str2'length;
      variable equal : boolean := TRUE;
    begin
       if not (LEN1 = LEN2) then
         equal := FALSE;
       else
         for i in str1'range loop
           if not (toLowerCaseChar(str1(i)) = toLowerCaseChar(str2(i))) then
             equal := FALSE;
           end if;
         end loop;
       end if;
       return equal;
    end equalIgnoringCase;


    ---------------------------------------------------------------------------- 
    -- Conversions from/to STRING to/from families_type.
    -- These are convenience functions that are not normally needed when
    -- using the 'supported' functions.
    ---------------------------------------------------------------------------- 
    function str2fam( fam_as_string  : string ) return families_type is
        --
        variable fas : string(1 to fam_as_string'length) := fam_as_string;
        variable fam  : families_type;
        --
    begin
        -- Search for and return the corresponding family.
        for fam in families_type'low to families_type'high loop
            if equalIgnoringCase(fas, myimage(fam)) then return fam; end if;
        end loop;
        -- If there is no matching family, report a warning and return nofamily.
        assert false
          report "Package family_support: Function str2fam called" &
                 " with string parameter, " & fam_as_string &
                 ", that does not correspond" &
                 " to a supported family. Returning nofamily."
          severity warning;
        return nofamily;
    end str2fam;


    function fam2str( fam :  families_type) return string is
    begin
      --return families_type'IMAGE(fam);
        return myimage(fam);
    end fam2str;

    function supported( fam_as_str     : string;
                        primitive      : primitives_type
                      ) return boolean is
    begin
        return supported(str2fam(fam_as_str), primitive);
    end supported;


    function supported( fam_as_str     : string;
                        primitives     : primitive_array_type
                      ) return boolean is
    begin
        return supported(str2fam(fam_as_str), primitives);
    end supported;


    ---------------------------------------------------------------------------- 
    -- Function: native_lut_size, two overloads.
    ---------------------------------------------------------------------------- 
    function native_lut_size( fam : families_type;
                              no_lut_return_val : natural := 0
                            ) return natural is
    begin
        if    supported(fam, u_LUT6) then return  6;
        elsif supported(fam, u_LUT5) then return  5;
        elsif supported(fam, u_LUT4) then return  4;
        elsif supported(fam, u_LUT3) then return  3;
        elsif supported(fam, u_LUT2) then return  2;
        elsif supported(fam, u_LUT1) then return  1;
        else                              return no_lut_return_val;
        end if;
    end;


    function native_lut_size( fam_as_string : string;
                              no_lut_return_val : natural := 0
                            ) return natural is
    begin
        return native_lut_size( fam => str2fam(fam_as_string),
                                no_lut_return_val => no_lut_return_val
                              );
    end;


end package body family_support;
