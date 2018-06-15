----------------------------------------------------------------------------------
-- fault_param_regs.vhd
-- Author: Froylan Aguirre
-- Fault Parameter module for MISST system core.
-- addr has specific addressing scheme. The two least significant value select
--  between dut_addr (0b00), inj_time (0b01), and flt_oprnd (0b10).
-- The remaining three bits select the associated element to write to.
--  name (0b000)
--  oprnd (0b001)
--  op (0b010)
--  min (0b011)
--  max (0b100)
-- When component is chip enabled, it outputs element values.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Module is complete.

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fault_param_regs is
    Port (
        data_in : in std_logic_vector(31 downto 0);
        addr : in std_logic_vector(4 downto 0);
        wr_en : in std_logic;  -- chipe enable, needs to be asserted to write and output data
        wr : in std_logic;     -- write enable on rising edge
        
        -- element outputs
        var_out : out std_logic_vector(31 downto 0);
        oprnd_out : out std_logic_vector(31 downto 0);
        alu_op_out : out std_logic_vector(3 downto 0);
        min_val_out : out std_logic_vector(31 downto 0);
        max_val_out : out std_logic_vector(31 downto 0) 
    );
end fault_param_regs;

architecture Behavioral of fault_param_regs is

    constant NO_ELEM_SEL : std_logic_vector(2 downto 0) := "101";
    constant NO_GROUP_SEL : std_logic_vector(1 downto 0) := "11";
    constant DUT_ADDR_G_SEL : std_logic_vector(1 downto 0) := "00";
    constant INJ_TIME_G_SEL : std_logic_vector(1 downto 0) := "01";
    constant FLT_OPRND_G_SEL : std_logic_vector(1 downto 0) := "10";

    component grouping_unit is
        Port ( 
            data_in : in std_logic_vector (31 downto 0);
            element_sel : in std_logic_vector (2 downto 0);
            enable : in std_logic;
            write : in std_logic;
            var_name : out std_logic_vector (31 downto 0);
            var_oprnd : out std_logic_vector (31 downto 0);
            var_op : out std_logic_vector (3 downto 0);
            var_min : out std_logic_vector (31 downto 0);
            var_max : out std_logic_vector (31 downto 0)
        );
    end component grouping_unit;

    signal t_group_sel : std_logic_vector(1 downto 0);
    signal t_elem_sel : std_logic_vector(2 downto 0);
    signal t_dut_addr_en, t_inj_time_en, t_flt_oprnd_en : std_logic;
    
    signal t_da_name, t_it_name, t_fo_name : std_logic_vector(31 downto 0);
    signal t_da_oprnd, t_it_oprnd, t_fo_oprnd : std_logic_vector(31 downto 0);
    signal t_da_min, t_it_min, t_fo_min : std_logic_vector(31 downto 0);
    signal t_da_max, t_it_max, t_fo_max : std_logic_vector(31 downto 0);
    signal t_da_op, t_it_op, t_fo_op : std_logic_vector(3 downto 0);
    
begin

    t_elem_sel <= addr(4 downto 2);
        
    t_group_sel <= addr(1 downto 0);
        
    t_dut_addr_en <= '1' when (t_group_sel = DUT_ADDR_G_SEL and wr_en = '1') else '0';
    t_inj_time_en <= '1' when (t_group_sel = INJ_TIME_G_SEL and wr_en = '1') else '0';
    t_flt_oprnd_en <= '1' when (t_group_sel = FLT_OPRND_G_SEL and wr_en = '1') else '0';

    var_out <= t_da_name when (t_group_sel = DUT_ADDR_G_SEL and wr_en = '1') else
               t_it_name when (t_group_sel = INJ_TIME_G_SEL and wr_en = '1') else
               t_fo_name when (t_group_sel = FLT_OPRND_G_SEL and wr_en = '1') else
               (others => '0');
     
   oprnd_out <= t_da_oprnd when (t_group_sel = DUT_ADDR_G_SEL and wr_en = '1') else
                t_it_oprnd when (t_group_sel = INJ_TIME_G_SEL and wr_en = '1') else
                t_fo_oprnd when (t_group_sel = FLT_OPRND_G_SEL and wr_en = '1') else
                (others => '0');               
            
    
  min_val_out <= t_da_min when (t_group_sel = DUT_ADDR_G_SEL and wr_en = '1') else
                 t_it_min when (t_group_sel = INJ_TIME_G_SEL and wr_en = '1') else
                 t_fo_min when (t_group_sel = FLT_OPRND_G_SEL and wr_en = '1') else
                 (others => '0');
                 
    
    max_val_out <= t_da_max when (t_group_sel = DUT_ADDR_G_SEL and wr_en = '1') else
                   t_it_max when (t_group_sel = INJ_TIME_G_SEL and wr_en = '1') else
                   t_fo_max when (t_group_sel = FLT_OPRND_G_SEL and wr_en = '1') else
                   (others => '0');
                   
    
   alu_op_out <= t_da_op when (t_group_sel = DUT_ADDR_G_SEL and wr_en = '1') else
                 t_it_op when (t_group_sel = INJ_TIME_G_SEL and wr_en = '1') else
                 t_fo_op when (t_group_sel = FLT_OPRND_G_SEL and wr_en = '1') else
                 (others => '0');
                   
    dut_addr_g : grouping_unit
        port map(
            data_in => data_in,
            element_sel => t_elem_sel,
            enable => t_dut_addr_en,
            write => wr,
            var_name => t_da_name, 
            var_oprnd => t_da_oprnd,
            var_op => t_da_op,
            var_min => t_da_min,
            var_max => t_da_max
        );
        
    inj_time_g : grouping_unit
        port map(
            data_in => data_in,
            element_sel => t_elem_sel,
            enable => t_inj_time_en,
            write => wr,
            var_name => t_it_name, 
            var_oprnd => t_it_oprnd,
            var_op => t_it_op,
            var_min => t_it_min,
            var_max => t_it_max
        );
        
    flt_oprnd_g : grouping_unit
        port map(
            data_in => data_in,
            element_sel => t_elem_sel,
            enable => t_flt_oprnd_en,
            write => wr,
            var_name => t_fo_name, 
            var_oprnd => t_fo_oprnd,
            var_op => t_fo_op,
            var_min => t_fo_min,
            var_max => t_fo_max
        );

end Behavioral;
