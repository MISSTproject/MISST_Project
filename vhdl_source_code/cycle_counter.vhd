----------------------------------------------------------------------------------
-- cycle_counter.vhd
-- Author: Froylan Aguirre
-- Counts clock cycles. Used as a sub-module for Control Unit.
-- Module starts counting as long as trigger_pos_in is not "11". trigger_pos_in 
--      at "11" acts as chip disable.
-- clk_in acts as the signal to be counted on rising edges. In other words, the
--      count is incremented by one for every rising edge of clk_in.
-- A rising edge of start_count_in resets counting.
-- Giving a max_count_in value of zero or one makes trigger_out assert on clk_in
--      cycle immediately after the clock cycle start_count_in was asserted.
-- Once counting has reached the max_count_in value, trigger_out is asserted*.
-- * Assumming counter has reached value of max_count_in, trigger_out asserts
--      on different phase of clk_in depending on trigger_pos_in value.
--      trigger_pos_in value | Description
--                        00 | trigger_out asserts on first rising edge of clk_in
--                        01 | trigger_out asserts on falling edge of clk_in
--                        10 | trigger_out asserts on last rising edge of clk_in
--                        11 | trigger_out never asserts
-- Example: max_count_in == 3, trigger_pos_in == "00"
--         clk_in |111100001111000011110000111100001111000011110000
-- start_count_in |000001111111100000000000000000000000000000000000
--    trigger_out |-----0000000000000000000111111111111111111111111
--    count (hex) |--------1111111122222222333333333333333333333333
-- trigger_out for trigger_out_in == "01" :
--    trigger_out |-----0000000000000000000000011111111111111111111
-- trigger_out for trigger_out_in == "10":
--    trigger_out |-----0000000000000000000000000001111111111111111                                
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Module is complete. Do NOT modify.

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cycle_counter is
    Port (
        clk_in : in std_logic;
        
        -- starts the count on rising edge
        start_count_in : in std_logic;
        
        -- selects which edge asserts trigger
        trigger_pos_in : in std_logic_vector(1 downto 0);
        
        -- maximum number of clock cycles
        max_count_in : in std_logic_vector(31 downto 0);
        
        -- trigger signal asserted when number of clock cycles reached
        trigger_out : out std_logic 
    );
end cycle_counter;

architecture Behavioral of cycle_counter is
    constant FRONT_EDGE: std_logic_vector(1 downto 0) := "00";
    constant MIDDLE_EDGE: std_logic_vector(1 downto 0) := "01";
    constant BACK_EDGE: std_logic_vector(1 downto 0) := "10";
    constant NO_EDGE: std_logic_vector(1 downto 0) := "11";
    
    signal count_reached_s : std_logic := '0';
    signal count_reset_s : std_logic := '0';
    signal start_pulse_s : std_logic := '0';
    signal pulse_begin_s, pulse_end_s : std_logic := '0';
    signal front_edge_s, middle_edge_s, back_edge_s : std_logic := '0';
    
begin
    start_pulse_s <= pulse_begin_s xor pulse_end_s;
    
    with trigger_pos_in select
        trigger_out <= front_edge_s when FRONT_EDGE,
            middle_edge_s when MIDDLE_EDGE,
            back_edge_s when BACK_EDGE,
            '0' when others;

    start_pulse_start: process(start_count_in)
    begin
        if (rising_edge(start_count_in) and start_pulse_s = '0') then
            pulse_begin_s <= not pulse_begin_s;
        end if;
    end process;

    start_pulse_end : process(clk_in)
    begin
        if (falling_edge(clk_in) and start_pulse_s = '1') then
            pulse_end_s <= not pulse_end_s;
        end if;
    end process;

    adder : process(clk_in, start_pulse_s)
        variable clk_count : unsigned(31 downto 0) := x"00000000";
    begin
        if (start_pulse_s = '1') then
            clk_count := x"00000000";
            count_reached_s <= '0';
            front_edge_s <= '0';
        end if;
    
        if (rising_edge(clk_in) and count_reached_s = '0') then
            if (start_pulse_s = '1') then
                clk_count := x"00000000";
            end if;
            
            if (clk_count < unsigned(max_count_in)) then
                clk_count := clk_count + 1;
            end if;
            
            if (clk_count = unsigned(max_count_in)) then
                count_reached_s <= '1';
                front_edge_s <= '1';
            end if; 
        end if;
    
    end process;
    
    middle_edge_detection: process(clk_in, start_pulse_s)
    begin
        if (rising_edge(start_pulse_s)) then
            middle_edge_s <= '0';
        end if;
    
        if (falling_edge(clk_in) and front_edge_s = '1') then
            middle_edge_s <= '1';
        end if;
    
    end process;

    back_edge_detection: process(clk_in, start_pulse_s)
    begin
        if (rising_edge(start_pulse_s)) then
            back_edge_s <= '0';
        end if;
    
        if (rising_edge(clk_in) and middle_edge_s = '1' and count_reached_s = '1') then
            back_edge_s <= '1';
        end if;
    
    end process;

end Behavioral;
