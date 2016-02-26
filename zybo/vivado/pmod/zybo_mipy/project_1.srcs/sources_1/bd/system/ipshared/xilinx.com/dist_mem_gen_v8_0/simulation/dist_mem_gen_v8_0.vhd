-------------------------------------------------------------------------------
--
-- Distributed Memory Generator - VHDL Behavioral Model
--
-------------------------------------------------------------------------------
-- (c) Copyright 1995 - 2009 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Filename    : dist_mem_gen_v8_0_9.vhd
--
-- Author      : Xilinx
--
-- Description : Distributed Memory Simulation Model
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity dist_mem_gen_v8_0_9 is
   generic (
      C_FAMILY         : STRING  := "VIRTEX5";
      C_ADDR_WIDTH     : INTEGER := 6;
      C_DEFAULT_DATA   : STRING  := "0";
      C_ELABORATION_DIR : STRING  := "0";
      C_DEPTH          : INTEGER := 64;
      C_HAS_CLK        : INTEGER := 1;
      C_HAS_D          : INTEGER := 1;
      C_HAS_DPO        : INTEGER := 0;
      C_HAS_DPRA       : INTEGER := 0;
      C_HAS_I_CE       : INTEGER := 0;
      C_HAS_QDPO       : INTEGER := 0;
      C_HAS_QDPO_CE    : INTEGER := 0;
      C_HAS_QDPO_CLK   : INTEGER := 0;
      C_HAS_QDPO_RST   : INTEGER := 0;
      C_HAS_QDPO_SRST  : INTEGER := 0;
      C_HAS_QSPO       : INTEGER := 0;
      C_HAS_QSPO_CE    : INTEGER := 0;
      C_HAS_QSPO_RST   : INTEGER := 0;
      C_HAS_QSPO_SRST  : INTEGER := 0;
      C_HAS_SPO        : INTEGER := 1;
      C_HAS_WE         : INTEGER := 1;
      C_MEM_INIT_FILE  : STRING  := "NULL.MIF";
      C_MEM_TYPE       : INTEGER := 1;
      C_PIPELINE_STAGES : INTEGER := 0;
      C_QCE_JOINED     : INTEGER := 0;
      C_QUALIFY_WE     : INTEGER := 0;
      C_READ_MIF       : INTEGER := 0;
      C_REG_A_D_INPUTS : INTEGER := 0;
      C_REG_DPRA_INPUT : INTEGER := 0;
      C_SYNC_ENABLE    : INTEGER := 0;
      C_WIDTH          : INTEGER := 16;
      C_PARSER_TYPE    : INTEGER := 1);
   port (
      a    : in  std_logic_vector(c_addr_width-1 downto 0) := (others => '0');

      d    : in std_logic_vector(c_width-1 downto 0)      := (others => '0');
      dpra : in std_logic_vector(c_addr_width-1 downto 0) := (others => '0');

      clk       : in  std_logic := '0';
      we        : in  std_logic := '0';
      i_ce      : in  std_logic := '1';
      qspo_ce   : in  std_logic := '1';
      qdpo_ce   : in  std_logic := '1';
      qdpo_clk  : in  std_logic := '0';
      qspo_rst  : in  std_logic := '0';
      qdpo_rst  : in  std_logic := '0';
      qspo_srst : in  std_logic := '0';
      qdpo_srst : in  std_logic := '0';
      spo       : out std_logic_vector(c_width-1 downto 0);
      dpo       : out std_logic_vector(c_width-1 downto 0);
      qspo      : out std_logic_vector(c_width-1 downto 0);
      qdpo      : out std_logic_vector(c_width-1 downto 0)); 

end dist_mem_gen_v8_0_9;

architecture behavioral of dist_mem_gen_v8_0_9 is

   -- Register delay
   CONSTANT C_TCQ : time := 100 ps;

   constant max_address : std_logic_vector(c_addr_width-1 downto 0) :=
      std_logic_vector(to_unsigned(c_depth-1, c_addr_width));

   constant c_rom      : integer := 0;
   constant c_sp_ram   : integer := 1;
   constant c_dp_ram   : integer := 2;
   constant c_sdp_ram  : integer := 4;

   type mem_type is array ((2**c_addr_width)-1 downto 0) of std_logic_vector(c_width-1 downto 0);

   ---------------------------------------------------------------------
   -- Convert character to type std_logic.
   ---------------------------------------------------------------------
   impure function char_to_std_logic (
      char : in character)
      return std_logic is

      variable data : std_logic;
      
   begin
      if char = '0' then
         data := '0';
         
      elsif char = '1' then
         data := '1';

      elsif char = 'X' then
         data := 'X';
         
      else
         assert false
            report "character which is not '0', '1' or 'X'."
            severity warning;
         
         data := 'U';
      end if;

      return data;
      
   end char_to_std_logic;
   ---------------------------------------------------------------------

   impure function read_mif (
      filename : in string;
      def_data : in std_logic_vector;
      depth    : in integer;
      width    : in integer)
      return mem_type is

      file meminitfile     : text;
      variable mif_status  : file_open_status;
      variable bitline     : line;
      variable bitsgood    : boolean := true;
      variable bitchar     : character;
      variable lines       : integer := 0;

      variable memory_content : mem_type;
      
   begin

      for i in 0 to depth-1 loop
         memory_content(i) := def_data;
      end loop;  -- i

      file_open(mif_status, meminitfile, filename, read_mode);

      if mif_status /= open_ok then
         assert false
            report "Error: read_mem_init_file: could not open MIF."
            severity failure;
      end if;

      lines := 0;

      for i in 0 to depth-1 loop
         
         if not(endfile(meminitfile)) and i < depth then
            
            memory_content(i) := (others => '0');
            readline(meminitfile, bitline);

            for j in 0 to width-1 loop
               read(bitline, bitchar, bitsgood);
               
               if ((bitsgood = false) or
                   ((bitchar /= ' ') and (bitchar /= cr) and
                    (bitchar /= ht) and (bitchar /= lf) and
                    (bitchar /= '0') and (bitchar /= '1') and
                    (bitchar /= 'x') and (bitchar /= 'z'))) then
                  assert false
                     report
                     "Warning: dist_mem_utils: unknown or illegal " &
                     "character encountered while reading mif - " &
                     "finishing file read." & cr &
                     "This could be due to an undersized mif file"
                     severity warning;
                  exit;                 -- abort the file read
               end if;

               memory_content(i)(width-1-j) := char_to_std_logic(bitchar);
            end loop;  -- j
            
         else
            exit;
         end if;

         lines := i + 1;
         
      end loop;

      file_close(meminitfile);      

      assert not(lines > depth)
         report "MIF file contains more addresses than the memory."
         severity failure;

      assert lines = depth
         report
         "MIF file size does not match memory size." & cr &
         "Remaining addresses in memory are padded with default data."
         severity warning;
      
      return memory_content;
      
   end read_mif;

   ---------------------------------------------------------------------

   impure function string_to_std_logic_vector (
      the_string : string;
      size       : integer)
      return std_logic_vector is
      variable slv_tmp : std_logic_vector(1 to size) := (others => '0');
      variable slv : std_logic_vector(size-1 downto 0) := (others => '0');
      
      variable index : integer := 0;
   begin

      slv_tmp := (others => '0');
      index := size;      

      if the_string'length > size then
         for i in the_string'length downto the_string'length-size+1 loop            
            slv_tmp(index) := char_to_std_logic(the_string(i));
            index := index - 1;
         end loop;  -- i
      else
         for i in the_string'length downto 1 loop
            slv_tmp(index) := char_to_std_logic(the_string(i));
            index := index - 1;
         end loop;  -- i
      end if;

      for i in 1 to size loop
         slv(size-i) := slv_tmp(i);
      end loop;  -- i

      return slv;
      
   end string_to_std_logic_vector;

   ---------------------------------------------------------------------
   -- Convert the content of a file and return an array of
   -- std_logic_vectors.
   ---------------------------------------------------------------------
   
   ---------------------------------------------------------------------

   ---------------------------------------------------------------------
   -- Function which initialises the memory from the c_default_data
   -- string or the c_mem_init_file MIF file.
   ---------------------------------------------------------------------   
   impure function init_mem (
      memory_type   : in integer;
      read_mif_file : in integer;
      filename      : in string;
      default_data  : in string;
      depth         : in integer;
      width         : in integer)
      return mem_type is

      variable memory_content : mem_type := (others => (others => '0'));
      
      variable def_data  : std_logic_vector(width-1 downto 0) := (others => '0');
      constant all_zeros : std_logic_vector(width-1 downto 0) := (others => '0');
      
   begin

      def_data := string_to_std_logic_vector(default_data, width);

      if read_mif_file = 0 then
         -- If the memory is not initialised from a MIF file then fill the memory array with
         -- default data.
         for i in 0 to depth-1 loop
            memory_content(i) := def_data;
         end loop;  -- i                 
      else
         --Initialise the memory from the MIF file.
         memory_content := read_mif(filename, def_data, depth, width);
      end if;

      return memory_content;
      
   end init_mem;
   ------------------------------------------------------------------

   signal memory : mem_type :=
      init_mem(
         c_mem_type,
         c_read_mif,
         c_mem_init_file,
         c_default_data,
         c_depth,
         c_width);

   -- address signal connected to memory
   signal a_int     : std_logic_vector(c_addr_width-1 downto 0) := (others => '0');
   -- address signal connected to memory, which has been registered.
   signal a_reg     : std_logic_vector(c_addr_width-1 downto 0) := (others => '0');

   signal a_over    : std_logic_vector(c_addr_width-1 downto 0) := (others => '0');

   -- dual port read address signal connected to dual port memory
   signal dpra_int  : std_logic_vector(c_addr_width-1 downto 0) := (others => '0');
   -- dual port read address signal connected to dual port memory, which
   -- has been registered.
   signal dpra_reg  : std_logic_vector(c_addr_width-1 downto 0) := (others => '0');

   signal dpra_over : std_logic_vector(c_addr_width-1 downto 0) := (others => '0');

   -- input data signal connected to RAM
   signal d_int : std_logic_vector(c_width-1 downto 0) := (others => '0');
   -- input data signal connected to RAM, which has been registered.   
   signal d_reg : std_logic_vector(c_width-1 downto 0) := (others => '0');

   -- Write Enable signal connected to memory
   signal we_int : std_logic := '0';
   -- Write Enable signal connected to memory, which has been registered.   
   signal we_reg : std_logic := '0';

   -- Internal Clock Enable for optional qspo output
   signal qspo_ce_int : std_logic := '0';
   -- Internal Clock Enable for optional qspo output, which has been
   -- registered
   signal qspo_ce_reg : std_logic := '0';

   -- Internal Clock Enable for optional qdpo output
   signal qdpo_ce_int : std_logic := '0';
   -- Internal Clock Enable for optional qspo output, which has been
   -- registered
   signal qdpo_ce_reg : std_logic := '0';

   -- Internal version of the spo output
   signal spo_int : std_logic_vector(c_width-1 downto 0) := (others => '0');
   
   -- Pipeline for the qspo output
   signal qspo_pipe : std_logic_vector(c_width-1 downto 0) := (others => '0');

   -- Internal version of the qspo output
   signal qspo_int : std_logic_vector(c_width-1 downto 0) :=
      string_to_std_logic_vector(c_default_data, c_width);

   -- Internal version of the dpo output
   signal dpo_int : std_logic_vector(c_width-1 downto 0) := (others => '0');

   -- Pipeline for the qdpo output
   signal qdpo_pipe : std_logic_vector(c_width-1 downto 0) := (others => '0');
   
   -- Internal version of the qdpo output
   signal qdpo_int : std_logic_vector(c_width-1 downto 0) :=
      string_to_std_logic_vector(c_default_data, c_width);

   -- Content of spo_int from address a
   signal data_sp       : std_logic_vector(c_width-1 downto 0);

   -- Content of Dual Port Output at address dpra
   signal data_dp       : std_logic_vector(c_width-1 downto 0);

   -- Content of spo_int from address a
   signal data_sp_over  : std_logic_vector(c_width-1 downto 0);

   -- Content of Dual Port Output at address dpra
   signal data_dp_over  : std_logic_vector(c_width-1 downto 0);

   signal a_is_over    : std_logic;
   signal dpra_is_over : std_logic;

begin
  p_warn_behavioural : process
  begin
    assert false report "This core is supplied with a behavioral model. To model cycle-accurate behavior you must run timing simulation." severity warning;
    wait;
  end process p_warn_behavioural;

   ---------------------------------------------------------------------
   -- Infer any optional input registers, in the clk clock domain.
   ---------------------------------------------------------------------
   p_optional_input_registers : process
   begin
      wait until c_reg_a_d_inputs = 1 and clk'event and clk = '1';

      if c_mem_type = c_rom then
         if (c_has_qspo_ce = 1) then
            if (qspo_ce = '1') then
               a_reg    <= a after C_TCQ;
            end if;
         else
            a_reg    <= a after C_TCQ;
         end if;
      elsif c_has_i_ce = 0 then
         we_reg   <= we after C_TCQ;
         a_reg    <= a after C_TCQ;
         d_reg    <= d after C_TCQ;
      elsif c_qualify_we = 0 then
         we_reg <= we after C_TCQ;
         if i_ce = '1' then
            a_reg    <= a after C_TCQ;
            d_reg    <= d after C_TCQ;
         end if;
      elsif c_qualify_we = 1 and i_ce = '1' then
         we_reg   <= we after C_TCQ;
         a_reg    <= a after C_TCQ;
         d_reg    <= d after C_TCQ;
      end if;

      qspo_ce_reg <= qspo_ce after C_TCQ;

   end process p_optional_input_registers;

   ---------------------------------------------------------------------
   -- If the inputs are registered, propogate those signals to the
   -- internal versions that will be used by the memory construct.
   ---------------------------------------------------------------------
   g_optional_input_regs : if c_reg_a_d_inputs = 1 generate
      we_int      <= we_reg;
      d_int       <= d_reg;
      a_int       <= a_reg;
      qspo_ce_int <= qspo_ce_reg;
   end generate g_optional_input_regs;

   ---------------------------------------------------------------------
   -- Otherwise, just pass the ports directly to the internal signals
   -- used by the memory construct.
   ---------------------------------------------------------------------
   g_no_optional_input_regs : if c_reg_a_d_inputs = 0 generate
      we_int      <= we;
      d_int       <= d;
      a_int       <= a;
      qspo_ce_int <= qspo_ce;
   end generate g_no_optional_input_regs;
   ---------------------------------------------------------------------

   ---------------------------------------------------------------------
   -- In addition, there are inputs that can be registered, that can
   -- have their own clock domain.  This is best handled in a seperate
   -- process for readability.
   ---------------------------------------------------------------------
   p_optional_dual_port_regs : process
   begin

      if c_reg_dpra_input = 0 then
         wait;
      elsif c_has_qdpo_clk = 0 then
         wait until clk'event and clk = '1';
      else
         wait until qdpo_clk'event and qdpo_clk = '1';
      end if;

      if c_qce_joined = 1 then
         if c_has_qspo_ce = 0 or (c_has_qspo_ce = 1 and qspo_ce = '1') then
            dpra_reg <= dpra after C_TCQ;
         end if;
      elsif c_has_qdpo_ce = 0 or (c_has_qdpo_ce = 1 and qdpo_ce = '1') then
         dpra_reg <= dpra after C_TCQ;
      end if;

      qdpo_ce_reg <= qdpo_ce after C_TCQ;
      
   end process p_optional_dual_port_regs;

   ---------------------------------------------------------------------
   -- If the inputs are registered, propogate those signals to the
   -- internal versions that will be used by the memory construct.
   ---------------------------------------------------------------------
   g_optional_dual_port_regs : if c_reg_dpra_input = 1 generate
      dpra_int    <= dpra_reg;
      qdpo_ce_int <= qdpo_ce_reg;
   end generate g_optional_dual_port_regs;

   ---------------------------------------------------------------------
   -- Otherwise, just pass the ports directly to the internal signals
   -- used by the memory construct.
   ---------------------------------------------------------------------
   g_no_optional_dual_port_regs : if c_reg_dpra_input = 0 generate
      dpra_int    <= dpra;
      qdpo_ce_int <= qdpo_ce;
   end generate g_no_optional_dual_port_regs;
   ---------------------------------------------------------------------

   ---------------------------------------------------------------------
   -- For the Single Port RAM and Dual Port RAM memory types, define how
   -- the RAM is written to.
   ---------------------------------------------------------------------
   p_write_to_spram_dpram : process
   begin  -- process p_write_to_spram_dpram      

      wait until clk'event and clk = '1' and we_int = '1'
        and c_mem_type /= c_rom;

      if a_is_over = '1' then
         assert false
            report "Writing to out of range address." & cr &
            "Max address is " & integer'image(c_depth-1) & "." &
            cr & "Write ignored."
            severity warning;         
      else
         memory(to_integer(unsigned(a_int))) <= d_int after C_TCQ;
      end if;
      
   end process p_write_to_spram_dpram;
   
   ---------------------------------------------------------------------   
   -- Form the spo_int signal and the optional spo output. spo_int will
   -- be used in assigning the optional qspo output.
   ---------------------------------------------------------------------

   spo_int <= data_sp_over when a_is_over = '1' else data_sp;

   a_is_over    <= '1' when a_int > max_address else '0';
   dpra_is_over <= '1' when dpra_int > max_address else '0';

   g_dpra_over: for i in 0 to c_addr_width-1 generate
      dpra_over(i) <= dpra_int(i) and max_address(i);
   end generate g_dpra_over;

   data_sp       <= memory(to_integer(unsigned(a_int)));
   data_sp_over  <= (others => 'X');
   data_dp       <= memory(to_integer(unsigned(dpra_int)));
   data_dp_over  <= (others => 'X');
   
   g_has_spo : if c_has_spo = 1 generate
      spo <= spo_int;
   end generate g_has_spo;

   g_has_no_spo : if c_has_spo = 0 generate
      spo <= (others => 'X');
   end generate g_has_no_spo;
   ---------------------------------------------------------------------

   ---------------------------------------------------------------------
   -- Form the dpo_int signal and the optional dpo output. dpo_int will
   -- be used in assigning the optional qdpo output.
   ---------------------------------------------------------------------   
   g_dpram: if (c_mem_type = c_dp_ram or c_mem_type = c_sdp_ram) generate
      dpo_int <= data_dp_over when dpra_is_over = '1' else data_dp;
   end generate g_dpram;
   g_not_dpram: if (c_mem_type /= c_dp_ram and c_mem_type /= c_sdp_ram) generate
      dpo_int <= (others => 'X');
   end generate g_not_dpram;

   assert not((c_mem_type = c_dp_ram or c_mem_type = c_sdp_ram) and dpra_is_over = '1')
      report "DPRA trying to read from out of range address." & cr &
      "Max address is " & integer'image(c_depth-1)
       severity warning;

   g_has_dpo : if c_has_dpo = 1 generate
      dpo <= dpo_int;
   end generate g_has_dpo;

   g_has_no_dpo : if c_has_dpo = 0 generate
      dpo <= (others => 'X');
   end generate g_has_no_dpo;
   ---------------------------------------------------------------------

   ---------------------------------------------------------------------
   -- Form the QSPO output depending on the following:
   ---------------------------------------------------------------------
   -- Generics
   -- c_has_qspo
   -- c_has_qspo_rst
   -- c_sync_enable
   -- c_has_qspo_ce
   ---------------------------------------------------------------------
   -- Signals
   -- clk
   -- qspo_rst
   -- qspo_srst
   -- qspo_ce
   -- spo_int
   ---------------------------------------------------------------------
   p_has_qspo : process
   begin
      if c_has_qspo /= 1 then
         qspo_int <= (others => 'X');
         qspo_pipe <= (others => 'X');
         wait;
      end if;

      wait until (clk'event and clk = '1') or (qspo_rst = '1' and c_has_qspo_rst = 1);
   ---------------------------------------------------------------------
      if c_has_qspo_rst = 1 and qspo_rst = '1' then
         qspo_pipe <= (others => '0');
         qspo_int <= (others => '0');
         
      elsif c_has_qspo_srst = 1 and qspo_srst = '1' then
         
         if c_sync_enable = 0 then
            qspo_pipe <= (others => '0') after C_TCQ;
            qspo_int <= (others => '0') after C_TCQ;
            
         elsif c_has_qspo_ce = 0 or (c_has_qspo_ce = 1 and qspo_ce_int = '1') then
            qspo_pipe <= (others => '0') after C_TCQ;
            qspo_int <= (others => '0') after C_TCQ;
         end if;
         
      elsif c_has_qspo_ce = 0 or qspo_ce_int = '1' then
         qspo_pipe <= spo_int after C_TCQ;
         if c_pipeline_stages = 1 then
           qspo_int <= qspo_pipe after C_TCQ;
         else
           qspo_int <= spo_int after C_TCQ;
         end if;
      end if;
   end process p_has_qspo;
   ---------------------------------------------------------------------
   qspo <= qspo_int;

   ---------------------------------------------------------------------
   -- Form the QDPO output depending on the following:
   ---------------------------------------------------------------------
   -- Generics
   -- c_has_qdpo
   -- c_qce_joined
   -- c_has_qdpo_clk
   -- c_has_qdpo_rst
   -- c_has_qdpo_srst
   -- c_has_qdpo_ce
   -- c_has_qspo_ce
   -- c_sync_enable
   ---------------------------------------------------------------------
   -- Signals
   -- clk
   -- qdpo_clk
   -- qdpo_rst
   -- qdpo_srst
   -- qdpo_ce
   -- qspo_ce
   -- dpo_int
   ---------------------------------------------------------------------
   p_has_qdpo : process
   begin
      if c_has_qdpo /= 1 then
         qdpo_pipe <= (others => 'X');
         qdpo_int <= (others => 'X');
         wait;
      end if;

      if c_has_qdpo_clk = 0 then
         --Common clock enables used for qspo and qdpo outputs.
         --Therefore we have one clock domain to worry about.
         wait until (clk'event and clk = '1')
           or (c_has_qdpo_rst = 1 and qdpo_rst = '1');
      else
         --The qdpo output is in a seperate clock domain from the rest
         --of the dual port RAM.
         wait until
            (qdpo_clk'event and qdpo_clk = '1') or
            (c_has_qdpo_rst = 1 and qdpo_rst = '1');
      end if;

      if c_has_qdpo_rst = 1 and qdpo_rst = '1' then
         -- Async reset asserted.
         qdpo_pipe <= (others => '0');
         qdpo_int <= (others => '0');
         
      elsif c_has_qdpo_srst = 1 and qdpo_srst = '1' then
         
         if c_sync_enable = 0 then
            --Synchronous reset asserted.  Sync reset overrides the
            --clock enable
            qdpo_pipe <= (others => '0') after C_TCQ;
            qdpo_int <= (others => '0') after C_TCQ;
            
         elsif c_qce_joined = 0 then
            -- Seperate qdpo_clk domain
            if c_has_qdpo_ce = 0 or (c_has_qdpo_ce = 1 and qdpo_ce_int = '1') then
               -- Either the qdpo does not have a clock enable, or it
               -- does, and it has been asserted permitting the sync
               -- reset to act.
               qdpo_pipe <= (others => '0') after C_TCQ;
               qdpo_int <= (others => '0') after C_TCQ;
            end if;
            
         elsif c_has_qspo_ce = 0 or (c_has_qspo_ce = 1 and qspo_ce_int = '1') then
            -- Common clock domain so we monitor the common clock
            -- enable to see if the a sync reset is permitted, or there
            -- are no clock enables to block the sync reset.
            qdpo_pipe <= (others => '0') after C_TCQ;
            qdpo_int <= (others => '0') after C_TCQ;
         end if;
         
      elsif c_qce_joined = 0 then
         -- qdpo is a seperate clock domain, so check to see if there
         -- is a qdpo_ce clock enable, if it is there, assign qdpo when
         -- qdpo_ce is active - if there is no clock enable just assign
         -- it.
         if c_has_qdpo_ce = 0 or (c_has_qdpo_ce = 1 and qdpo_ce_int = '1') then
            qdpo_pipe <= dpo_int after C_TCQ;
            if c_pipeline_stages = 1 then
              qdpo_int <= qdpo_pipe after C_TCQ;
            else
              qdpo_int <= dpo_int after C_TCQ;
            end if;
         end if;
         
      elsif c_has_qspo_ce = 0 or (c_has_qspo_ce = 1 and qspo_ce_int = '1') then
         -- Common clock domain, check to see if there is a qspo_ce to
         -- concern us.
         qdpo_pipe <= dpo_int after C_TCQ;
         if c_pipeline_stages = 1 then
           qdpo_int <= qdpo_pipe after C_TCQ;
         else
           qdpo_int <= dpo_int after C_TCQ;
         end if;
      end if;
   end process p_has_qdpo;
   ---------------------------------------------------------------------
   qdpo <= qdpo_int;

end behavioral;
