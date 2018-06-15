----------------------------------------------------------------------------------
-- cu_counter_tb.vhd
-- Author: Froylan Aguirre
-- Testbench for cycle_counter module.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cu_counter_tb is
--  Port ( );
end cu_counter_tb;

architecture Behavioral of cu_counter_tb is
    
    component cycle_counter is
        Port (
            clk_in : in std_logic;
            start_count_in : in std_logic;
            trigger_pos_in : in std_logic_vector(1 downto 0);         
            max_count_in : in std_logic_vector(31 downto 0);
            trigger_out : out std_logic 
        );
    end component cycle_counter;
    
    signal clk_i, start_cnt_i, trigger_o : std_logic;
    signal trigger_pos_i : std_logic_vector(1 downto 0); 
    signal max_count_i : std_logic_vector(31 downto 0);

begin

    clock: process
    begin
        clk_i <= '1';
        wait for 5 ns;
        clk_i <= '0';
        wait for 5 ns;
    end process;

    dut: cycle_counter 
        Port Map (
            clk_in => clk_i,
            start_count_in => start_cnt_i,
            trigger_pos_in => trigger_pos_i,        
            max_count_in => max_count_i,
            trigger_out => trigger_o
        );
  
    stim_proc: process
    begin
        start_cnt_i <= '0';
        trigger_pos_i <= "00"; -- change to test position trigger
        max_count_i <= x"00000000";
        wait for 30 ns;
        
        start_cnt_i <= '1';
        wait for 10 ns;
        
        start_cnt_i <= '0';
        wait for 30 ns;
        
        max_count_i <= x"00000003";
        wait for 50 ns;
        
        start_cnt_i <= '1';
        wait for 50 ns;
        
        start_cnt_i <= '0';
        wait for 50 ns;
        
        start_cnt_i <= '1';
        wait for 10 ns;
        
        start_cnt_i <= '0';
        wait for 34 ns;
        
        start_cnt_i <= '1';
        wait for 10 ns;
        
        start_cnt_i <= '0';
        wait for 10 ns;
        start_cnt_i <= '1';
        
        
        wait;
    end process;


end Behavioral;
