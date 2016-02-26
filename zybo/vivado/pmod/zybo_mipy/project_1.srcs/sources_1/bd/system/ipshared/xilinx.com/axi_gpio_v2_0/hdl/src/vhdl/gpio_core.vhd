-------------------------------------------------------------------------------
-- gpio_core - entity/architecture pair 
-------------------------------------------------------------------------------
-- ***************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2009 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
-- ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        gpio_core.vhd
-- Version:         v1.01a
-- Description:     General Purpose I/O for AXI Interface
--
-------------------------------------------------------------------------------
-- Structure:   
--                  axi_gpio.vhd
--                        -- axi_lite_ipif.vhd
--                        -- interrupt_control.vhd
--                        -- gpio_core.vhd
--
-------------------------------------------------------------------------------
--
-- Author:          KSB
-- History:
-- ~~~~~~~~~~~~~~
--   KSB               09/15/09
-- ^^^^^^^^^^^^^^

-- ~~~~~~~~~~~~~~
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_cmb" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

library lib_cdc_v1_0_2;

-------------------------------------------------------------------------------
--                     Definition of Generics :                              --
-------------------------------------------------------------------------------
-- C_DW                --  Data width of PLB BUS.
-- C_AW                --  Address width of PLB BUS.
-- C_GPIO_WIDTH        --  GPIO Data Bus width.
-- C_GPIO2_WIDTH       --  GPIO2 Data Bus width.
-- C_INTERRUPT_PRESENT --  GPIO Interrupt.
-- C_DOUT_DEFAULT      --  GPIO_DATA Register reset value.
-- C_TRI_DEFAULT       --  GPIO_TRI Register reset value.
-- C_IS_DUAL           --  Dual Channel GPIO.
-- C_DOUT_DEFAULT_2    --  GPIO2_DATA Register reset value.
-- C_TRI_DEFAULT_2     --  GPIO2_TRI Register reset value.
-- C_FAMILY            --  XILINX FPGA family
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--                  Definition of Ports                                      --
-------------------------------------------------------------------------------
-- Clk                 -- Input clock
-- Rst                 -- Reset
-- ABus_Reg            -- Bus to IP address
-- BE_Reg              -- Bus to IP byte enables
-- DBus_Reg            -- Bus to IP data bus
-- RNW_Reg             -- Bus to IP read write control
-- GPIO_DBus           -- IP to Bus data bus
-- GPIO_xferAck        -- GPIO transfer acknowledge 
-- GPIO_intr           -- GPIO channel 1 interrupt to IPIC
-- GPIO2_intr          -- GPIO channel 2 interrupt to IPIC
-- GPIO_Select         -- GPIO select
--               
-- GPIO_IO_I           -- Channel 1 General purpose I/O in port
-- GPIO_IO_O           -- Channel 1 General purpose I/O out port
-- GPIO_IO_T           -- Channel 1 General purpose I/O TRI-STATE control port
-- GPIO2_IO_I          -- Channel 2 General purpose I/O in port
-- GPIO2_IO_O          -- Channel 2 General purpose I/O out port
-- GPIO2_IO_T          -- Channel 2 General purpose I/O TRI-STATE control port
-------------------------------------------------------------------------------

entity GPIO_Core is
  generic 
  (
    C_DW                : integer     := 32;
    C_AW                : integer     := 32;
    C_GPIO_WIDTH        : integer     := 32;
    C_GPIO2_WIDTH       : integer     := 32;
    C_MAX_GPIO_WIDTH    : integer     := 32;
    C_INTERRUPT_PRESENT : integer     := 0;
    C_DOUT_DEFAULT      : std_logic_vector (0 to 31)    := X"0000_0000";
    C_TRI_DEFAULT       : std_logic_vector (0 to 31)    := X"FFFF_FFFF";
    C_IS_DUAL           : integer          := 0;
    C_DOUT_DEFAULT_2    : std_logic_vector (0 to 31)    := X"0000_0000";
    C_TRI_DEFAULT_2     : std_logic_vector (0 to 31)    := X"FFFF_FFFF";
    C_FAMILY            : string                        := "virtex7"
  );   
  port 
  (
    Clk             : in  std_logic;
    Rst             : in  std_logic;
    ABus_Reg        : in  std_logic_vector(0 to C_AW-1);
    BE_Reg          : in  std_logic_vector(0 to C_DW/8-1);
    DBus_Reg        : in  std_logic_vector(0 to C_MAX_GPIO_WIDTH-1);
    RNW_Reg         : in  std_logic;
    GPIO_DBus       : out std_logic_vector(0 to C_DW-1);
    GPIO_xferAck    : out std_logic;
    GPIO_intr       : out std_logic;
    GPIO2_intr      : out std_logic;
    GPIO_Select     : in  std_logic;

    GPIO_IO_I       : in  std_logic_vector(0 to C_GPIO_WIDTH-1);
    GPIO_IO_O       : out std_logic_vector(0 to C_GPIO_WIDTH-1);
    GPIO_IO_T       : out std_logic_vector(0 to C_GPIO_WIDTH-1);
    GPIO2_IO_I      : in  std_logic_vector(0 to C_GPIO2_WIDTH-1);
    GPIO2_IO_O      : out std_logic_vector(0 to C_GPIO2_WIDTH-1);
    GPIO2_IO_T      : out std_logic_vector(0 to C_GPIO2_WIDTH-1)
  );
end entity GPIO_Core;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture IMP of GPIO_Core is

-- Pragma Added to supress synth warnings
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of IMP : architecture is "yes";
 
----------------------------------------------------------------------
-- Function for Reduction OR
----------------------------------------------------------------------
  function or_reduce(l : std_logic_vector) return std_logic is
    variable v : std_logic := '0';
    begin
     for i in l'range loop 
         v := v or l(i); 
     end loop;
     return v;
    end;
---------------------------------------------------------------------
-- End of Function
-------------------------------------------------------------------

  signal gpio_Data_Select        : std_logic_vector(0 to C_IS_DUAL);
  signal gpio_OE_Select          : std_logic_vector(0 to C_IS_DUAL);
  signal Read_Reg_Rst            : STD_LOGIC;
  signal Read_Reg_In             : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal Read_Reg_CE             : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal gpio_Data_Out           : std_logic_vector(0 to C_GPIO_WIDTH-1) := C_DOUT_DEFAULT(C_DW-C_GPIO_WIDTH to C_DW-1);
  signal gpio_Data_In            : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal gpio_in_d1              : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal gpio_in_d2              : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal gpio_io_i_d1            : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal gpio_io_i_d2            : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal gpio_OE                 : std_logic_vector(0 to C_GPIO_WIDTH-1) := C_TRI_DEFAULT(C_DW-C_GPIO_WIDTH to C_DW-1);
  signal GPIO_DBus_i             : std_logic_vector(0 to C_DW-1);
  signal gpio_data_in_xor        : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal gpio_data_in_xor_reg    : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal or_ints                 : std_logic_vector(0 to 0);
  signal or_ints2                : std_logic_vector(0 to 0);
  signal iGPIO_xferAck           : STD_LOGIC;
  signal gpio_xferAck_Reg        : STD_LOGIC;
  signal dout_default_i          : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal tri_default_i           : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal reset_zeros             : std_logic_vector(0 to C_GPIO_WIDTH-1);
  signal dout2_default_i         : std_logic_vector(0 to C_GPIO2_WIDTH-1);
  signal tri2_default_i          : std_logic_vector(0 to C_GPIO2_WIDTH-1);
  signal reset2_zeros            : std_logic_vector(0 to C_GPIO2_WIDTH-1);
  signal gpio_reg_en             : std_logic;

begin  -- architecture IMP


  reset_zeros <=  (others => '0');
  reset2_zeros <= (others => '0');

  TIE_DEFAULTS_GENERATE : if C_DW >= C_GPIO_WIDTH generate
    SELECT_BITS_GENERATE : for i in 0 to C_GPIO_WIDTH-1 generate
        dout_default_i(i)  <= C_DOUT_DEFAULT(i-C_GPIO_WIDTH+C_DW);
        tri_default_i(i)   <= C_TRI_DEFAULT(i-C_GPIO_WIDTH+C_DW);
    end generate SELECT_BITS_GENERATE;
  end generate TIE_DEFAULTS_GENERATE;

  TIE_DEFAULTS_2_GENERATE : if C_DW >= C_GPIO2_WIDTH generate
    SELECT_BITS_2_GENERATE : for i in 0 to C_GPIO2_WIDTH-1 generate
        dout2_default_i(i) <= C_DOUT_DEFAULT_2(i-C_GPIO2_WIDTH+C_DW);
        tri2_default_i(i)  <= C_TRI_DEFAULT_2(i-C_GPIO2_WIDTH+C_DW);
    end generate SELECT_BITS_2_GENERATE;
  end generate TIE_DEFAULTS_2_GENERATE;


  Read_Reg_Rst <= iGPIO_xferAck or gpio_xferAck_Reg or (not GPIO_Select) or
                                                (GPIO_Select and not RNW_Reg);
  gpio_reg_en <= GPIO_Select when (ABus_Reg(0) = '0') else '0';                    

  -----------------------------------------------------------------------------
  -- XFER_ACK_PROCESS
  -----------------------------------------------------------------------------
  -- Generation of Transfer Ack signal for one clock pulse              
  -----------------------------------------------------------------------------
  XFER_ACK_PROCESS : process (Clk) is
  begin
    if (Clk'EVENT and Clk = '1') then
      if (Rst = '1') then
        iGPIO_xferAck <= '0';    
      else  
        iGPIO_xferAck <= GPIO_Select and not gpio_xferAck_Reg;
        if iGPIO_xferAck = '1' then
          iGPIO_xferAck <= '0';
        end if;
      end if;  
    end if;
  end process XFER_ACK_PROCESS;
  
  -----------------------------------------------------------------------------
  -- DELAYED_XFER_ACK_PROCESS
  -----------------------------------------------------------------------------
  -- Single Reg stage to make Transfer Ack period one clock pulse wide  
  -----------------------------------------------------------------------------
  DELAYED_XFER_ACK_PROCESS : process (Clk) is
  begin
    if (Clk'EVENT and Clk = '1') then
      if (Rst = '1') then
        gpio_xferAck_Reg <= '0';
      else    
        gpio_xferAck_Reg <= iGPIO_xferAck;
      end if;  
    end if;
  end process DELAYED_XFER_ACK_PROCESS;

  GPIO_xferAck <= iGPIO_xferAck;
 
  -----------------------------------------------------------------------------
  -- Drive GPIO interrupts to '0' when interrupt not present         
  -----------------------------------------------------------------------------
  
  DONT_GEN_INTERRUPT : if (C_INTERRUPT_PRESENT = 0) generate
     gpio_intr  <= '0';
     gpio2_intr <= '0';
  end generate DONT_GEN_INTERRUPT;
  
  ----------------------------------------------------------------------------
  -- When only one channel is used, the additional logic for the second
  -- channel ports is not present
  -----------------------------------------------------------------------------
  Not_Dual : if (C_IS_DUAL = 0) generate

      GPIO2_IO_O <= C_DOUT_DEFAULT(0 to C_GPIO2_WIDTH-1);
      GPIO2_IO_T <= C_TRI_DEFAULT_2(0 to C_GPIO2_WIDTH-1);


  READ_REG_GEN : for i in 0 to C_GPIO_WIDTH-1 generate
   ----------------------------------------------------------------------------
   -- XFER_ACK_PROCESS
   ----------------------------------------------------------------------------
   -- Generation of Transfer Ack signal for one clock pulse              
   ----------------------------------------------------------------------------
   GPIO_DBUS_I_PROC : process(Clk)
     begin
        if Clk'event and Clk = '1' then
            if Read_Reg_Rst = '1' then
                GPIO_DBus_i(i-C_GPIO_WIDTH+C_DW) <= '0';
            else
                GPIO_DBus_i(i-C_GPIO_WIDTH+C_DW) <= Read_Reg_In(i);
            end if;
        end if;
   end process;
  end generate READ_REG_GEN;

  TIE_DBUS_GENERATE : if C_DW > C_GPIO_WIDTH generate
      GPIO_DBus_i(0 to C_DW-C_GPIO_WIDTH-1) <= (others => '0');
  end generate TIE_DBUS_GENERATE;

  -----------------------------------------------------------------------------
  -- GPIO_DBUS_PROCESS
  -----------------------------------------------------------------------------
  -- This process generates the GPIO DATA BUS from the GPIO_DBUS_I based on 
  -- the channel select signals               
  -----------------------------------------------------------------------------
        GPIO_DBus <= GPIO_DBus_i;

  -----------------------------------------------------------------------------
  -- REG_SELECT_PROCESS
  -----------------------------------------------------------------------------
  --      GPIO REGISTER selection decoder for single channel configuration   
  -----------------------------------------------------------------------------
    --REG_SELECT_PROCESS : process (GPIO_Select, ABus_Reg) is
    REG_SELECT_PROCESS : process (gpio_reg_en, ABus_Reg) is
    begin
      gpio_Data_Select(0) <= '0';
      gpio_OE_Select(0)   <= '0';
      
      --if GPIO_Select = '1' then
      if gpio_reg_en = '1' then
        if (ABus_Reg(5) = '0') then
          case ABus_Reg(6) is        -- bit A29
            when '0'    => gpio_Data_Select(0) <= '1';
            when '1'    => gpio_OE_Select(0)   <= '1';
            -- coverage off
            when others => null;
            -- coverage on
          end case;
        end if;
      end if;
    end process REG_SELECT_PROCESS;

   INPUT_DOUBLE_REGS3 : entity  lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                 => 1,
        C_RESET_STATE              => 0,
        C_SINGLE_BIT               => 0,
        C_VECTOR_WIDTH             => C_GPIO_WIDTH,
        C_MTBF_STAGES              => 4
    )
    port map (
        prmry_aclk                 => '0',
        prmry_resetn               => '0',
        prmry_in                   => '0',
        prmry_vect_in              => GPIO_IO_I,

        scndry_aclk                => Clk,
        scndry_resetn              => '0',
        scndry_out                 => open,
        scndry_vect_out            => gpio_io_i_d2
    );

 
    ---------------------------------------------------------------------------
    -- GPIO_INDATA_BIRDIR_PROCESS
    ---------------------------------------------------------------------------
    -- Reading of channel 1 data from Bidirectional GPIO port            
    -- to GPIO_DATA REGISTER                                             
    ---------------------------------------------------------------------------
      GPIO_INDATA_BIRDIR_PROCESS : process(Clk) is
      begin
        if Clk = '1' and Clk'EVENT then
     --     gpio_io_i_d1 <= GPIO_IO_I;
     --     gpio_io_i_d2 <= gpio_io_i_d1;
          gpio_Data_In <= gpio_io_i_d2;
        end if;
      end process GPIO_INDATA_BIRDIR_PROCESS;
    

    ---------------------------------------------------------------------------
    -- READ_MUX_PROCESS
    ---------------------------------------------------------------------------
    -- Selects GPIO_TRI control or GPIO_DATA Register to be read             
    ---------------------------------------------------------------------------
      READ_MUX_PROCESS : process (gpio_Data_In, gpio_Data_Select, gpio_OE,
                                  gpio_OE_Select) is
      begin
        Read_Reg_In <= (others => '0');
        if gpio_Data_Select(0) = '1' then
          Read_Reg_In <= gpio_Data_In;
        elsif gpio_OE_Select(0) = '1' then
          Read_Reg_In <= gpio_OE;
        end if;
      end process READ_MUX_PROCESS;
      
    ---------------------------------------------------------------------------
    -- GPIO_OUTDATA_PROCESS
    ---------------------------------------------------------------------------
    -- Writing to Channel 1 GPIO_DATA REGISTER                           
    ---------------------------------------------------------------------------
      GPIO_OUTDATA_PROCESS : process(Clk) is
      begin
        if Clk = '1' and Clk'EVENT then
          if (Rst = '1') then
             gpio_Data_Out <= dout_default_i;
          elsif gpio_Data_Select(0) = '1' and RNW_Reg = '0' then
            for i in 0 to C_GPIO_WIDTH-1 loop
                gpio_Data_Out(i) <= DBus_Reg(i);
            end loop;
          end if;
        end if;
      end process GPIO_OUTDATA_PROCESS;
      
    ---------------------------------------------------------------------------
    -- GPIO_OE_PROCESS
    ---------------------------------------------------------------------------
    -- Writing to Channel 1 GPIO_TRI Control REGISTER                    
    ---------------------------------------------------------------------------
      GPIO_OE_PROCESS : process(Clk) is
      begin
        
        if Clk = '1' and Clk'EVENT then
	  if (Rst = '1') then
            gpio_OE <= tri_default_i;        
          elsif gpio_OE_Select(0) = '1' and RNW_Reg = '0' then
            for i in 0 to C_GPIO_WIDTH-1 loop
                gpio_OE(i) <= DBus_Reg(i);
            end loop;
          end if;
        end if;          
      end process GPIO_OE_PROCESS;

      GPIO_IO_O  <= gpio_Data_Out;
      GPIO_IO_T  <= gpio_OE;

    
   ----------------------------------------------------------------------------
   -- INTERRUPT IS PRESENT
   ----------------------------------------------------------------------------
   -- When the C_INTERRUPT_PRESENT=1, the interrupt is driven based on whether
   -- there is a change in the data coming in at the GPIO_IO_I port or GPIO_In
   -- port
   ----------------------------------------------------------------------------

   GEN_INTERRUPT : if (C_INTERRUPT_PRESENT = 1) generate
     gpio_data_in_xor <= gpio_Data_In xor gpio_io_i_d2;
     
     -------------------------------------------------------------------------
     -- An interrupt conditon exists if there is a change on any bit.
     -------------------------------------------------------------------------
     or_ints(0) <= or_reduce(gpio_data_in_xor_reg);
  
      -------------------------------------------------------------------------
      -- Registering Interrupt condition
      -------------------------------------------------------------------------
     REGISTER_XOR_INTR : process (Clk) is
       begin
         if (Clk'EVENT and Clk = '1') then
           if (Rst = '1') then
             gpio_data_in_xor_reg <= reset_zeros;
             GPIO_intr            <= '0';
           else
             gpio_data_in_xor_reg <= gpio_data_in_xor;
             GPIO_intr            <= or_ints(0);
           end if;         
         end if;
     end process REGISTER_XOR_INTR;
      
     gpio2_intr          <= '0';  -- Channel 2 interrupt is driven low

   end generate GEN_INTERRUPT;

  end generate Not_Dual;

  ---)(------------------------------------------------------------------------
  -- When both the channels are used, the additional logic for the second
  -- channel ports
  -----------------------------------------------------------------------------
  Dual : if (C_IS_DUAL = 1) generate
    signal gpio2_Data_In           : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal gpio2_in_d1             : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal gpio2_in_d2             : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal gpio2_io_i_d1           : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal gpio2_io_i_d2           : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal gpio2_data_in_xor       : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal gpio2_data_in_xor_reg   : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal gpio2_Data_Out          : std_logic_vector(0 to C_GPIO2_WIDTH-1) := C_DOUT_DEFAULT_2(C_DW-C_GPIO2_WIDTH to C_DW-1);
    signal gpio2_OE                : std_logic_vector(0 to C_GPIO2_WIDTH-1) := C_TRI_DEFAULT_2(C_DW-C_GPIO2_WIDTH to C_DW-1);
    signal Read_Reg2_In            : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal Read_Reg2_CE            : std_logic_vector(0 to C_GPIO2_WIDTH-1);
    signal GPIO2_DBus_i            : std_logic_vector(0 to C_DW-1);
    begin


    READ_REG_GEN : for i in 0 to C_GPIO_WIDTH-1 generate
    begin
     --------------------------------------------------------------------------
     -- GPIO_DBUS_I_PROCESS
     --------------------------------------------------------------------------
     -- This process generates the GPIO CHANNEL1 DATA BUS               
     --------------------------------------------------------------------------
     GPIO_DBUS_I_PROC : process(Clk)
       begin
          if Clk'event and Clk = '1' then
              if Read_Reg_Rst = '1' then
                  GPIO_DBus_i(i-C_GPIO_WIDTH+C_DW) <= '0';
              else
                  GPIO_DBus_i(i-C_GPIO_WIDTH+C_DW) <= Read_Reg_In(i);
              end if;
          end if;
     end process;
    end generate READ_REG_GEN;
  
    TIE_DBUS_GENERATE : if C_DW > C_GPIO_WIDTH generate
        GPIO_DBus_i(0 to C_DW-C_GPIO_WIDTH-1) <= (others => '0');
    end generate TIE_DBUS_GENERATE;
  
    READ_REG2_GEN : for i in 0 to C_GPIO2_WIDTH-1 generate
     --------------------------------------------------------------------------
     -- GPIO2_DBUS_I_PROCESS
     --------------------------------------------------------------------------
     -- This process generates the GPIO CHANNEL2 DATA BUS               
     --------------------------------------------------------------------------
     GPIO2_DBUS_I_PROC : process(Clk)
       begin
          if Clk'event and Clk = '1' then
              if Read_Reg_Rst = '1' then
                  GPIO2_DBus_i(i-C_GPIO2_WIDTH+C_DW) <= '0';
              else
                  GPIO2_DBus_i(i-C_GPIO2_WIDTH+C_DW) <= Read_Reg2_In(i);
              end if;
          end if;
     end process;
    end generate READ_REG2_GEN;
  
    TIE_DBUS2_GENERATE : if C_DW > C_GPIO2_WIDTH generate
        GPIO2_DBus_i(0 to C_DW-C_GPIO2_WIDTH-1) <= (others => '0');
    end generate TIE_DBUS2_GENERATE;

    ---------------------------------------------------------------------------
    -- GPIO_DBUS_PROCESS
    ---------------------------------------------------------------------------
    -- This process generates the GPIO DATA BUS from the GPIO_DBUS_I and 
    -- GPIO2_DBUS_I based on which channel is selected               
    ---------------------------------------------------------------------------
    GPIO_DBus <= GPIO_DBus_i when (((gpio_Data_Select(0) = '1') or 
    				(gpio_OE_Select(0) = '1')) and (RNW_Reg = '1'))
    		else GPIO2_DBus_i; 
    
  -----------------------------------------------------------------------------
  -- DUAL_REG_SELECT_PROCESS
  -----------------------------------------------------------------------------
  -- GPIO REGISTER selection decoder for Dual channel configuration     
  -----------------------------------------------------------------------------
    --DUAL_REG_SELECT_PROCESS : process (GPIO_Select, ABus_Reg) is
    DUAL_REG_SELECT_PROCESS : process (gpio_reg_en, ABus_Reg) is
      variable ABus_reg_select : std_logic_vector(0 to 1);
      begin
        ABus_reg_select := ABus_Reg(5 to 6);  
        gpio_Data_Select <= (others => '0');
        gpio_OE_Select   <= (others => '0');
        --if GPIO_Select = '1' then
        if gpio_reg_en = '1' then
          -- case ABus_Reg(28 to 29) is  -- bit A28,A29 for dual
          case ABus_reg_select is  -- bit A28,A29 for dual
            when "00"   => gpio_Data_Select(0) <= '1';
            when "01"   => gpio_OE_Select(0)   <= '1';
            when "10"   => gpio_Data_Select(1) <= '1';
            when "11"   => gpio_OE_Select(1)   <= '1';
            -- coverage off
            when others => null;
            -- coverage on
          end case;
        end if;
    end process DUAL_REG_SELECT_PROCESS;
    ---------------------------------------------------------------------------
    -- GPIO_INDATA_BIRDIR_PROCESS
    ---------------------------------------------------------------------------
    -- Reading of channel 1 data from Bidirectional GPIO port            
    -- to GPIO_DATA REGISTER                                             
    ---------------------------------------------------------------------------

   INPUT_DOUBLE_REGS4 : entity  lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                 => 1,
        C_RESET_STATE              => 0,
        C_SINGLE_BIT               => 0,
        C_VECTOR_WIDTH             => C_GPIO_WIDTH,
        C_MTBF_STAGES              => 4
    )
    port map (
        prmry_aclk                 => '0',
        prmry_resetn               => '0',
        prmry_in                   => '0',
        prmry_vect_in              => GPIO_IO_I,

        scndry_aclk                => Clk,
        scndry_resetn              => '0',
        scndry_out                 => open,
        scndry_vect_out            => gpio_io_i_d2
    );


    GPIO_INDATA_BIRDIR_PROCESS : process(Clk) is
      begin
        if Clk = '1' and Clk'EVENT then
     --     gpio_io_i_d1 <= GPIO_IO_I;
     --     gpio_io_i_d2 <= gpio_io_i_d1;
          gpio_Data_In <= gpio_io_i_d2;
        end if;
      end process GPIO_INDATA_BIRDIR_PROCESS;
    
   INPUT_DOUBLE_REGS5 : entity  lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                 => 1,
        C_RESET_STATE              => 0,
        C_SINGLE_BIT               => 0,
        C_VECTOR_WIDTH             => C_GPIO2_WIDTH,
        C_MTBF_STAGES              => 4
    )
    port map (
        prmry_aclk                 => '0',
        prmry_resetn               => '0',
        prmry_in                   => '0',
        prmry_vect_in              => GPIO2_IO_I,

        scndry_aclk                => Clk,
        scndry_resetn              => '0',
        scndry_out                 => open,
        scndry_vect_out            => gpio2_io_i_d2
    );
    ---------------------------------------------------------------------------
    -- GPIO2_INDATA_BIRDIR_PROCESS
    ---------------------------------------------------------------------------
    -- Reading of channel 2 data from Bidirectional GPIO2 port           
    -- to GPIO2_DATA REGISTER                                            
    ---------------------------------------------------------------------------
    GPIO2_INDATA_BIRDIR_PROCESS : process(Clk) is
      begin
        if Clk = '1' and Clk'EVENT then
       --   gpio2_io_i_d1 <= GPIO2_IO_I;
       --   gpio2_io_i_d2 <= gpio2_io_i_d1;
          gpio2_Data_In <= gpio2_io_i_d2;
        end if;
      end process GPIO2_INDATA_BIRDIR_PROCESS;
    
    ---------------------------------------------------------------------------
    -- READ_MUX_PROCESS_0_0
    ---------------------------------------------------------------------------
    -- Selects among Channel 1 GPIO_DATA ,GPIO_TRI and Channel 2 GPIO2_DATA  
    -- GPIO2_TRI REGISTERS for reading                                       
    ---------------------------------------------------------------------------
    READ_MUX_PROCESS_0_0 : process (gpio2_Data_In, gpio2_OE, gpio_Data_In,
                                      gpio_Data_Select, gpio_OE,
                                      gpio_OE_Select) is
      begin
        Read_Reg_In <= (others => '0');
        Read_Reg2_In <= (others => '0');
        if gpio_Data_Select(0) = '1' then
          Read_Reg_In <= gpio_Data_In;
        elsif gpio_OE_Select(0) = '1' then
          Read_Reg_In <= gpio_OE;
        elsif gpio_Data_Select(1) = '1' then
          Read_Reg2_In <= gpio2_Data_In;
        elsif gpio_OE_Select(1) = '1' then
          Read_Reg2_In <= gpio2_OE;
        end if;
      end process READ_MUX_PROCESS_0_0;

    ---------------------------------------------------------------------------
    -- GPIO_OUTDATA_PROCESS_0_0
    ---------------------------------------------------------------------------
    -- Writing to Channel 1 GPIO_DATA REGISTER                           
    ---------------------------------------------------------------------------
      GPIO_OUTDATA_PROCESS_0_0 : process(Clk) is
      begin
        if Clk = '1' and Clk'EVENT then
          if (Rst = '1') then
            gpio_Data_Out <= dout_default_i;        
          elsif gpio_Data_Select(0) = '1' and RNW_Reg = '0' then
            for i in 0 to C_GPIO_WIDTH-1 loop
                gpio_Data_Out(i) <= DBus_Reg(i);
            end loop;
          end if;
        end if;
      end process GPIO_OUTDATA_PROCESS_0_0;

    ---------------------------------------------------------------------------
    -- GPIO_OE_PROCESS_0_0
    ---------------------------------------------------------------------------
    -- Writing to Channel 1 GPIO_TRI Control REGISTER                    
    ---------------------------------------------------------------------------
      GPIO_OE_PROCESS : process(Clk) is
      begin
        
        if Clk = '1' and Clk'EVENT then
	  if (Rst = '1') then
            gpio_OE <= tri_default_i;        
          elsif gpio_OE_Select(0) = '1' and RNW_Reg = '0' then
            for i in 0 to C_GPIO_WIDTH-1 loop
                gpio_OE(i) <= DBus_Reg(i);
--              end if;
            end loop;
          end if;
        end if;          
      end process GPIO_OE_PROCESS;


    ---------------------------------------------------------------------------
    -- GPIO2_OUTDATA_PROCESS_0_0
    ---------------------------------------------------------------------------
    -- Writing to Channel 2 GPIO2_DATA REGISTER                          
    ---------------------------------------------------------------------------
      GPIO2_OUTDATA_PROCESS_0_0 : process(Clk) is
      begin
        if Clk = '1' and Clk'EVENT then
          if (Rst = '1') then
            gpio2_Data_Out <= dout2_default_i;        
          elsif gpio_Data_Select(1) = '1' and RNW_Reg = '0' then
            for i in 0 to C_GPIO2_WIDTH-1 loop
                gpio2_Data_Out(i) <= DBus_Reg(i);
             -- end if;
            end loop;
          end if;
        end if;
      end process GPIO2_OUTDATA_PROCESS_0_0;

    ---------------------------------------------------------------------------
    -- GPIO2_OE_PROCESS_0_0
    ---------------------------------------------------------------------------
    -- Writing to Channel 2 GPIO2_TRI Control REGISTER                   
    ---------------------------------------------------------------------------
      GPIO2_OE_PROCESS_0_0 : process(Clk) is
      begin
        if Clk = '1' and Clk'EVENT then
          if (Rst = '1') then
            gpio2_OE <= tri2_default_i;        
          elsif gpio_OE_Select(1) = '1' and RNW_Reg = '0' then
            for i in 0 to C_GPIO2_WIDTH-1 loop
                gpio2_OE(i) <= DBus_Reg(i);
            end loop;
          end if;
        end if;  
      end process GPIO2_OE_PROCESS_0_0;

      GPIO_IO_O  <= gpio_Data_Out;
      GPIO_IO_T  <= gpio_OE;

      GPIO2_IO_O  <= gpio2_Data_Out;
      GPIO2_IO_T  <= gpio2_OE;

    ---------------------------------------------------------------------------
    -- INTERRUPT IS PRESENT
    ---------------------------------------------------------------------------
    gen_interrupt_dual : if (C_INTERRUPT_PRESENT = 1) generate

      gpio_data_in_xor  <= gpio_Data_In xor gpio_io_i_d2;
      gpio2_data_in_xor <= gpio2_Data_In xor gpio2_io_i_d2;
      

      -------------------------------------------------------------------------
      -- An interrupt conditon exists if there is a change any bit.
      -------------------------------------------------------------------------
      or_ints(0)  <= or_reduce(gpio_data_in_xor_reg);
      or_ints2(0) <= or_reduce(gpio2_data_in_xor_reg);

      -------------------------------------------------------------------------
      -- Registering Interrupt condition
      -------------------------------------------------------------------------
      REGISTER_XORs_INTRs : process (Clk) is
        begin
          if (Clk'EVENT and Clk = '1') then
            if (Rst = '1') then
              gpio_data_in_xor_reg  <= reset_zeros;
              gpio2_data_in_xor_reg <= reset2_zeros;
              GPIO_intr             <= '0';
              GPIO2_intr            <= '0';
            else
              gpio_data_in_xor_reg  <= gpio_data_in_xor;
              gpio2_data_in_xor_reg <= gpio2_data_in_xor;
              GPIO_intr             <= or_ints(0);
              GPIO2_intr            <= or_ints2(0);
            end if;         
          end if;
      end process REGISTER_XORs_INTRs;


    end generate gen_interrupt_dual;

  end generate Dual;   


end architecture IMP;
