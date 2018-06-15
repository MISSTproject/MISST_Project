---------------------------------------------------------------------
-- tb_fault_gen.vhd
-- Author: Froylan Aguirre
-- Testbench for fault_gen.vhd module.
---------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_fault_gen is
--  Port ( );
end tb_fault_gen;

architecture Behavioral of tb_fault_gen is
    
    constant CLOCK: time := 10ns;
   
    TYPE TEST_NAME is (SETUP, NOTHING_HAPPENS, LVL2_ONLY, RAND_VIO, ALL_LVL, L2_3_L01_0, PARALLEL);
    
    component fault_gen is
        Port (
            gen_request_in : in std_logic; -- updates fault parameters on clk_in rising edge, must keep high until process is done
            reset_in       : in std_logic; -- resets module
            clk_in : in std_logic;
            rand_range_vio_in : in std_logic;            
            lvl2_cyc_len_in : in std_logic_vector(31 downto 0); -- lvl2 cycle length
            lvl1_cyc_len_in : in std_logic_vector(31 downto 0); -- lvl1 cycle length
            lvl0_cyc_len_in : in std_logic_vector(31 downto 0); -- lvl0 cycle length            
            lvl2_addr_in : in std_logic_vector(7 downto 0); -- lvl2 fault parameter address
            lvl1_addr_in : in std_logic_vector(7 downto 0); -- lvl1 fault parameter address
            lvl0_addr_in : in std_logic_vector(7 downto 0); -- lvl0 fault parameter address        
            done_out : out std_logic; -- rising edge indicates fault generation is complete
            addr_out : out std_logic_vector(7 downto 0); -- address of updating fault parameter
            w_fp_out : out std_logic;
            wen_fp_out : out std_logic;
            init_on_out : out std_logic; -- if asserted, an init operation is happening
            mux_sel_out : out std_logic_vector(1 downto 0)  -- selects initial value
        );
    end component;
    
    signal test : TEST_NAME := SETUP;
    signal gen_request_in : std_logic; -- updates fault parameters on clk_in rising edge, must keep high until process is done
    signal reset_in       : std_logic; -- resets module
    signal clk_in         : std_logic;
    signal rand_range_vio_in : std_logic;            
    signal lvl2_cyc_len_in   : std_logic_vector(31 downto 0); -- lvl2 cycle length
    signal lvl1_cyc_len_in   : std_logic_vector(31 downto 0); -- lvl1 cycle length
    signal lvl0_cyc_len_in   : std_logic_vector(31 downto 0); -- lvl0 cycle length            
    signal lvl2_addr_in : std_logic_vector(7 downto 0); -- lvl2 fault parameter address
    signal lvl1_addr_in : std_logic_vector(7 downto 0); -- lvl1 fault parameter address
    signal lvl0_addr_in : std_logic_vector(7 downto 0); -- lvl0 fault parameter address        
    signal done_out : std_logic; -- rising edge indicates fault generation is complete
    signal addr_out : std_logic_vector(7 downto 0); -- address of updating fault parameter
    signal w_fp_out : std_logic;
    signal wen_fp_out  : std_logic;
    signal init_on_out : std_logic; -- if asserted, an init operation is happening
    signal mux_sel_out : std_logic_vector(1 downto 0);  -- selects initial value
    
begin

    clock_gen : process
    begin
        clk_in <= '1';
        wait for CLOCK/2;
        clk_in <= '0';
        wait for CLOCK/2;
    end process;
    
    dut: fault_gen
    port map(
        gen_request_in    => gen_request_in   ,
        reset_in          => reset_in         ,
        clk_in            => clk_in           ,
        rand_range_vio_in => rand_range_vio_in,           
        lvl2_cyc_len_in   => lvl2_cyc_len_in  ,
        lvl1_cyc_len_in   => lvl1_cyc_len_in  ,
        lvl0_cyc_len_in   => lvl0_cyc_len_in  ,           
        lvl2_addr_in      => lvl2_addr_in     ,
        lvl1_addr_in      => lvl1_addr_in     ,
        lvl0_addr_in      => lvl0_addr_in     , 
        done_out          => done_out         ,
        addr_out          => addr_out         ,
        w_fp_out          => w_fp_out         ,
        wen_fp_out        => wen_fp_out       ,
        init_on_out       => init_on_out      ,
        mux_sel_out       => mux_sel_out      
    );

    stim_proc : process
    begin
        report "====";
        report "Testing";
        test <= SETUP;
        gen_request_in    <= '0';   
        reset_in          <= '0';
        rand_range_vio_in <= '0';
        lvl2_cyc_len_in   <= x"00000000";
        lvl1_cyc_len_in   <= x"00000000";
        lvl0_cyc_len_in   <= x"00000000";
        lvl2_addr_in      <= x"00";
        lvl1_addr_in      <= x"00";
        lvl0_addr_in      <= x"00";
        wait for CLOCK;
        reset_in <= '1';
        wait for CLOCK;
        reset_in <= '0';
        wait for CLOCK;
        
        test <= NOTHING_HAPPENS;
        wait for CLOCK*10;
        
        -- test passed
        test <= ALL_LVL;
        reset_in <= '1';
        wait for CLOCK;
        reset_in <= '0';
        wait for CLOCK;
        lvl2_cyc_len_in   <= x"00000003";
        lvl1_cyc_len_in   <= x"00000002";
        lvl0_cyc_len_in   <= x"00000002";
        lvl2_addr_in      <= x"02";
        lvl1_addr_in      <= x"01";
        lvl0_addr_in      <= x"00";
        for count in 1 to 30 loop
            gen_request_in <= '1';
            wait for CLOCK;
            gen_request_in <= '0';
            wait for CLOCK*9;
        end loop;
        wait for CLOCK;
        
        -- test commented to decrease simulation time, uncomment to include them in tests
        -- test passed
--        test <= LVL2_ONLY;
--        reset_in <= '1';
--        wait for CLOCK;
--        reset_in <= '0';
--        wait for CLOCK;
--        lvl2_cyc_len_in   <= x"00000003";
--        lvl1_cyc_len_in   <= x"00000001"; -- never update
--        lvl0_cyc_len_in   <= x"00000001"; -- never update
--        lvl2_addr_in      <= x"0C";
--        lvl1_addr_in      <= x"0B";
--        lvl0_addr_in      <= x"0A";
--        for count in 1 to 8 loop
--            gen_request_in <= '1';
--            wait for CLOCK;
--            gen_request_in <= '0';
--            wait for CLOCK*9;
--        end loop;
--        wait for CLOCK;
        
        -- test passed
--        test <= L2_3_L01_0; -- have lvl2 have cycle of length 3, but lvl0 and 1 have cycles of length 1
--        reset_in <= '1';
--        wait for CLOCK;
--        reset_in <= '0';
--        wait for CLOCK;
--        lvl2_cyc_len_in   <= x"00000003";
--        lvl1_cyc_len_in   <= x"00000000"; -- always update
--        lvl0_cyc_len_in   <= x"00000000"; -- always update
--        lvl2_addr_in      <= x"0C";
--        lvl1_addr_in      <= x"0B";
--        lvl0_addr_in      <= x"0A";
--        for count in 1 to 8 loop
--            gen_request_in <= '1';
--            wait for CLOCK;
--            gen_request_in <= '0';
--            wait for CLOCK*9;
--        end loop;
--        wait for CLOCK;
        
        -- test passed
--        test <= RAND_VIO; -- testing that when rand_range_vio_in is high, updating retries updating
--        reset_in <= '1';
--        wait for CLOCK;
--        reset_in <= '0';
--        wait for CLOCK;
--        lvl2_cyc_len_in   <= x"00000002";
--        lvl1_cyc_len_in   <= x"00000002";
--        lvl0_cyc_len_in   <= x"00000002";
--        lvl2_addr_in      <= x"0C";
--        lvl1_addr_in      <= x"0B";
--        lvl0_addr_in      <= x"0A";
--        for count in 1 to 8 loop
--            gen_request_in <= '1';
--            wait for CLOCK;
            
--            if ((count = 2) or (count = 5)) then
--                rand_range_vio_in <= '1';
--            end if;
            
--            gen_request_in <= '0';
--            wait for CLOCK*9;
--            rand_range_vio_in <= '0';
--        end loop;
--        rand_range_vio_in <= '0';
--        wait for CLOCK;

        -- test passed
--        test <= PARALLEL; -- all FP update every time a fault is generated
--        reset_in <= '1';
--        wait for CLOCK;
--        reset_in <= '0';
--        wait for CLOCK;
--        lvl2_cyc_len_in   <= x"00000000";
--        lvl1_cyc_len_in   <= x"00000000"; -- never update
--        lvl0_cyc_len_in   <= x"00000000"; -- never update
--        lvl2_addr_in      <= x"0C";
--        lvl1_addr_in      <= x"0B";
--        lvl0_addr_in      <= x"0A";
--        for count in 1 to 5 loop
--            gen_request_in <= '1';
--            wait for CLOCK;
--            gen_request_in <= '0';
--            wait for CLOCK*9;
--        end loop;
--        wait for CLOCK;

        
        
        wait;
    end process;

end Behavioral;
