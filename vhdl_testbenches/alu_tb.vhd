----------------------------------------------------------------------------------
-- Module: alu_tb (Behavioral)
-- Author: Froylan Aguirre
-- Testbench for sys_alu.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity alu_tb is
--  Port ( );
end alu_tb;

architecture Behavioral of alu_tb is
    type TEST_NAME is (SIMPLE_TEST, SEU_TEST, RAND_TEST);
    
    component sys_alu is
        Port (
            oprnd_a_in : in std_logic_vector(31 downto 0);
            oprnd_b_in : in std_logic_vector(31 downto 0);
            oprnd_c_in : in std_logic_vector(31 downto 0);
            min_res_in : in std_logic_vector(31 downto 0);
            max_res_in : in std_logic_vector(31 downto 0);
            func_sel_in : in std_logic_vector(3 downto 0);
            oprnd_sel_in : in std_logic;
            clk_in : in std_logic;
            range_vio_out : out std_logic;
            rand_range_vio_out: out std_logic;
            op_res_out : out std_logic_vector(31 downto 0)
        );
    end component;
    
    signal test: TEST_NAME := SIMPLE_TEST;
    signal oprnd_a, oprnd_b, oprnd_c, min_res, max_res, op_res: std_logic_vector(31 downto 0);
    signal func_sel: std_logic_vector(3 downto 0);
    signal oprnd_sel, clk, range_vio, rand_range_vio: std_logic;
    
begin

    process
    begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    alu: sys_alu
        port map(
            oprnd_a_in => oprnd_a,
            oprnd_b_in => oprnd_b,
            oprnd_c_in => oprnd_c,
            min_res_in => min_res,
            max_res_in => max_res,
            func_sel_in => func_sel,
            oprnd_sel_in => oprnd_sel,
            clk_in => clk,
            range_vio_out => range_vio,
            rand_range_vio_out => rand_range_vio,
            op_res_out => op_res
        );

    stim_proc: process
    begin
        oprnd_a <= x"00000000";
        oprnd_b <= x"00000000";
        oprnd_c <= x"00000000";
        min_res <= x"00000000"; 
        max_res <= x"00000000";
        func_sel <= x"0";
        oprnd_sel <= '0';
        wait for 10 ns;
        oprnd_a <= x"00000001";
        oprnd_b <= x"00000001";
        func_sel <= x"1";
        wait for 10 ns;
        max_res <= x"0000000F";
        wait for 10 ns;
        max_res <= x"00000001";
        
        wait for 10ns;
        test <= SEU_TEST;
        oprnd_a <= x"00000000";
        min_res <= x"00000000";
        max_res <= x"FFFFFFFF";
        func_sel <= x"D"; -- unimodal gaussian
        wait for 100ns;
        
        test <= RAND_TEST; -- testing all radom operations except for SEU
        for f in 9 to 12 loop
            func_sel <= std_logic_vector(to_unsigned(f, func_sel'length));
            wait for 100ns;
        end loop;
        
        wait;
    end process;

end Behavioral;
