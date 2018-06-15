----------------------------------------------------------------------------------
-- Module: comb_alu (Behavioral)
-- Author: Froylan Aguirre
-- Description: A simple combinatorial ALU unit.
-- oprtn_sel selects the function for two operands:
--    no operation : 0x00   
--    addition : 0x1
--    increment by one : 0x2
--    decrement by one : 0x3
--    single left bitwise shift : 0x4 
--    single right bitwise shift: 0x5 
--    bitwise OR : 0x6
--    bitwise AND : 0x7
--    subtraction : 0x8
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Things to implement/improve:
-- This module is essentially complete. Add any simple arithmetic operations to ALU in this file.

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity comb_alu is
    Port (
        -- operand A
        oprnd_a : in std_logic_vector(31 downto 0);
        
        -- operand B
        oprnd_b : in std_logic_vector(31 downto 0);
        
        -- operation selection
        oprtn_sel : in std_logic_vector(3 downto 0);
        
        --operation result
        oprtn_res : out std_logic_vector(31 downto 0)
    );
end comb_alu;

architecture Behavioral of comb_alu is

    -- Operation Op-codes
    constant NOP : integer := 0; -- no operation will return the value of operand A
    constant ADD : integer := 1;
    constant INCR : integer := 2;
    constant DECR : integer := 3;
    constant SFL : integer := 4;
    constant SFR : integer := 5;
    constant EXOR : integer := 6;
    constant BAND : integer := 7;
    constant SUB : integer := 8; -- returns oprnd_a - oprnd_b
    
    type operation_results is array (15 downto 0) of unsigned (31 downto 0);
    
    signal t_op_res_arr : operation_results;
    signal t_us_input_a : unsigned(31 downto 0);
    signal t_us_input_b : unsigned(31 downto 0);
    signal t_us_op_res : unsigned(31 downto 0);
begin
    t_us_input_a <= unsigned(oprnd_a);
    t_us_input_b <= unsigned(oprnd_b);
    oprtn_res <= std_logic_vector(t_us_op_res);
    
    t_op_res_arr(NOP) <= t_us_input_a;
    t_op_res_arr(ADD) <= t_us_input_a + t_us_input_b;
    t_op_res_arr(INCR) <= t_us_input_a + x"00000001";
    t_op_res_arr(DECR) <= t_us_input_a - x"00000001";
    t_op_res_arr(SFL) <= t_us_input_a(30 downto 0) & '0';
    t_op_res_arr(SFR) <= '0' & t_us_input_a(31 downto 1);
    t_op_res_arr(EXOR) <= t_us_input_a xor t_us_input_b;
    t_op_res_arr(BAND) <= t_us_input_a and t_us_input_b;
    t_op_res_arr(SUB) <= t_us_input_a - t_us_input_b;

    with oprtn_sel select
        t_us_op_res <= t_op_res_arr(NOP) when x"0",
            t_op_res_arr(ADD) when x"1",
            t_op_res_arr(INCR) when x"2",
            t_op_res_arr(DECR) when x"3",
            t_op_res_arr(SFL) when x"4",
            t_op_res_arr(SFR) when x"5",
            t_op_res_arr(EXOR) when x"6",
            t_op_res_arr(BAND) when x"7",
            t_op_res_arr(SUB) when x"8",
            x"00000000" when others;
            
end Behavioral;
