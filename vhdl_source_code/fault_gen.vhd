---------------------------------------------------------------------
-- fault_gen.vhd
-- Author: Froylan Aguirre
-- Module: fault_gen
-- Outputs the appropriate sequential signals to update a fault
--  parameter when requested. When complete, asserts done_out for 
--  half a clock cycle.
-- This module is used in injection_campaign_FSM which is in the
--  Control_Unit.
-- Note that "initialization" here means setting a fault parameter to
--  a pre-configured value. 
-- Note that "updating" here means changing a fault parameter's 
--  value to the result of an ALU operation.
-- Refer to the Design or User's Guide for a description on "levels".
-- For an updating fault parameter, a cycle consists of an 
--  initialization (i) and one or more updates (u). The length of 
--  this repeating pattern is its cycle length.
-- When updating and the ALU experiences a random operation range
--  violation, the operation will be repeated until the result is 
--  within range.
---------------------------------------------------------------------

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

entity fault_gen is
    Port (
        gen_request_in : in std_logic; -- updates fault parameters on clk_in rising edge, must keep high until process is done
        reset_in       : in std_logic; -- resets module on rising edge
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
        init_on_out : out std_logic; -- if asserted, a FP initialization operation is happening
        mux_sel_out : out std_logic_vector(1 downto 0)  -- selects initial value, connected to mux1_sel_out on CU
    );
end fault_gen;

architecture Behavioral of fault_gen is
    
    TYPE MASTER_STATE IS (UPDATE_LVL0, UPDATE_LVL1, UPDATE_LVL2);
    
    constant MAX_UPDATE_EDGE_CNT: integer := 5;
    constant MAX_INIT_EDGE_CNT: integer := 4; 

    component cycle_counter is
        Port (
            clk_in : in std_logic;
            start_count_in : in std_logic;
            trigger_pos_in : in std_logic_vector(1 downto 0);
            max_count_in : in std_logic_vector(31 downto 0);
            trigger_out : out std_logic 
        );
    end component;

    signal curr_lvl_s : MASTER_STATE := UPDATE_LVL0;
    
    signal generate_fault_s, done_s : std_logic := '0';
    signal lvl2_reset_s, lvl1_reset_s, lvl0_reset_s : std_logic := '0';
    
    -- signal names below describe which levels (lvl) are initialized (i) or
    --      simply updated (u) when asserted 
    signal i2u1_s, i1u0_s, i0_s : std_logic := '0';
    
    signal update1_s, update0_s : std_logic := '0';
    signal start_update_s, start_init_s : std_logic := '0';
    signal stop_update_s, stop_init_s : std_logic := '0';
    signal curr_addr_s : std_logic_vector(7 downto 0) := x"00";
    signal u_w_s, u_wen_s : std_logic := '0';
    signal i_w_s, i_wen_s : std_logic := '0';
    signal t_i2u1_s, t_i1u0_s, t_i0_s : std_logic := '0'; -- cycle trigger output from cycle_counters
    signal ir0_s, ir1_s, ir2_s : std_logic := '0'; -- reset after FP initialization
begin
    addr_out <= curr_addr_s;
    w_fp_out <= u_w_s or i_w_s;
    wen_fp_out <= u_wen_s or i_wen_s;
    done_out <= done_s;
    
    update1_s <= '1' when (lvl1_cyc_len_in = x"00000000") else -- always updated
        '0' when (lvl1_cyc_len_in = x"00000001") else    -- never updated, stays contant
        ((not i1u0_s) and i2u1_s);
    update0_s <= '1' when (lvl0_cyc_len_in = x"00000000") else -- always updated
        '0' when (lvl0_cyc_len_in = x"00000001") else -- never updated, stays constant
        ((not i0_s) and i1u0_s);
    
    lvl2_reset_s <= reset_in or ir2_s;
    lvl1_reset_s <= reset_in or ir1_s;
    lvl0_reset_s <= reset_in or ir0_s;

    lvl2_cnt: cycle_counter
    port map(
        clk_in => generate_fault_s,
        start_count_in => lvl2_reset_s,
        trigger_pos_in => "00",
        max_count_in => lvl2_cyc_len_in,
        trigger_out => t_i2u1_s
    );
    
    i2u1_s <= '0' when ((lvl2_cyc_len_in = x"00000000") or (lvl2_cyc_len_in = x"00000001")) else t_i2u1_s;
    
    lvl1_cnt: cycle_counter
    port map(
        clk_in => i2u1_s,
        start_count_in => lvl1_reset_s,
        trigger_pos_in => "00",
        max_count_in => lvl1_cyc_len_in,
        trigger_out => t_i1u0_s
    );
    
    i1u0_s <= '0' when ((lvl1_cyc_len_in = x"00000000") or (lvl1_cyc_len_in = x"00000001")) else t_i1u0_s;
    
    lvl0_cnt: cycle_counter
    port map(
        clk_in => i1u0_s,
        start_count_in => lvl0_reset_s,
        trigger_pos_in => "00",
        max_count_in => lvl0_cyc_len_in,
        trigger_out => t_i0_s
    );
    
    i0_s <= '0' when ((lvl0_cyc_len_in = x"00000000") or (lvl0_cyc_len_in = x"00000001")) else t_i0_s;
    
    module_enable_disable: process(gen_request_in, done_s)
    begin
        if (rising_edge(gen_request_in)) then
            generate_fault_s <= '1';
        end if;
        
        if (rising_edge(done_s)) then
            generate_fault_s <= '0';
        end if;
        
    end process;
    
    -- resets a lvl's counter when it time-outs 
    counter_reseter: process(clk_in, stop_init_s)
    begin
        ir0_s <= '0';
        ir1_s <= '0';
        ir2_s <= '0';
    
        if (rising_edge(stop_init_s)) then
            case curr_lvl_s is
                when UPDATE_LVL0 =>
                    ir0_s <= '1';
                when UPDATE_LVL1 =>
                    ir1_s <= '1';
                when UPDATE_LVL2 =>
                    ir2_s <= '1';
                when others =>
                    null;
            end case;
        end if;
    end process;

    -- controls the entire fault parameter generation process
    -- begins with changing lvl0 first, then lvl1 and then lvl2
    -- lvl2 is ALWAYS changed, either updated or initialized
    master_fsm : process(clk_in, reset_in)
    begin
        if (rising_edge(reset_in)) then
            curr_addr_s <= x"00";
            start_init_s <= '0';
            start_update_s <= '0';
            curr_lvl_s <= UPDATE_LVL0;
        end if;
        
        done_s <= '0';
        
        if (generate_fault_s = '1') then    
            case curr_lvl_s is
                when UPDATE_LVL0 =>
                    curr_addr_s <= lvl0_addr_in;
                    
                    if ((stop_update_s = '1') or (stop_init_s = '1')) then
                        if ((i1u0_s = '1') or (update1_s = '1')) then
                            curr_lvl_s <= UPDATE_LVL1;
                            curr_addr_s <= lvl1_addr_in;
                        else
                            curr_lvl_s <= UPDATE_LVL2;
                            curr_addr_s <= lvl2_addr_in;
                        end if;
                        start_init_s <= '0';
                        start_update_s <= '0';
                    elsif (i0_s = '1') then
                        start_init_s <= '1';
                    elsif (update0_s = '1') then
                        start_update_s <= '1';
                    else
                        if ((i1u0_s = '1') or (update1_s = '1')) then
                            curr_lvl_s <= UPDATE_LVL1;
                            curr_addr_s <= lvl1_addr_in;
                        else
                            curr_lvl_s <= UPDATE_LVL2;
                            curr_addr_s <= lvl2_addr_in;
                        end if;
                    end if;
                when UPDATE_LVL1 => 
                    curr_addr_s <= lvl1_addr_in;
                                    
                    if ((stop_update_s = '1') or (stop_init_s = '1')) then
                        curr_lvl_s <= UPDATE_LVL2;
                        curr_addr_s <= lvl2_addr_in; -- for faster through-put
                        start_init_s <= '0';
                        start_update_s <= '0';
                    elsif (i1u0_s = '1') then
                        start_init_s <= '1';
                    elsif (update1_s = '1') then
                        start_update_s <= '1';
                    else
                        curr_lvl_s <= UPDATE_LVL2;
                        curr_addr_s <= lvl2_addr_in; -- for faster through-put
                    end if;
                when UPDATE_LVL2 =>
                                        
                    if ((stop_update_s = '1') or (stop_init_s = '1')) then
                        curr_lvl_s <= UPDATE_LVL0;
                        start_init_s <= '0';
                        start_update_s <= '0';
                        done_s <= '1';
                        curr_addr_s <= lvl0_addr_in;
                    elsif (i2u1_s = '1') then
                        start_init_s <= '1';
                    elsif (generate_fault_s = '1') then
                        start_update_s <= '1';
                    end if;
                when others =>
                    null;
            end case;
        
        end if;
    end process;

    -- regulates the steps needed to change the value of a fault paramter using ALU operation
    update_fsm : process(clk_in, reset_in)
        variable edge_cnt : integer := 0;
    begin
        if ((start_update_s = '0') or rising_edge(reset_in)) then
            u_wen_s <= '0';
            u_w_s <= '0';
            edge_cnt := 0;
            stop_update_s <= '0';
        end if;
        
        if ((start_update_s = '1') and (edge_cnt < MAX_UPDATE_EDGE_CNT))then
            case edge_cnt is
                when 0 =>
                    u_wen_s <= '1';
                when 2 =>
                    u_w_s <= '1';
                when 3 =>
                    u_wen_s <= '0';
                    u_w_s <= '0';
                    stop_update_s <= '1';
                when 4 =>
                    stop_update_s <= '0';
                when others =>
                    null;
            end case;
            
            if ((edge_cnt < MAX_UPDATE_EDGE_CNT) and (rand_range_vio_in = '0')) then
                edge_cnt := edge_cnt + 1;
            end if;
        end if;
        
    end process;

    -- controls the process of setting a FP (fault parameter) to an initial value
    initialization_fsm : process(clk_in, reset_in)
        variable edge_cnt : integer := 0;
    begin
        if ((start_init_s = '0') or rising_edge(reset_in)) then
            edge_cnt := 0;
            stop_init_s <= '0';
            mux_sel_out <= "11";
            init_on_out <= '0';
            i_wen_s <= '0';
            i_w_s <= '0';
        end if;
        
        if ((start_init_s = '1') and (edge_cnt < MAX_INIT_EDGE_CNT))then
            case edge_cnt is
                when 0 =>
                    case curr_lvl_s is
                        when UPDATE_LVL0 =>
                            mux_sel_out <= "00";
                        when UPDATE_LVL1 =>
                            mux_sel_out <= "01";
                        when UPDATE_LVL2 =>
                            mux_sel_out <= "10";
                        when others =>
                            mux_sel_out <= "11"; -- nothing selected
                    end case;
                    init_on_out <= '1';
                when 1 =>
                    i_wen_s <= '1';
                    i_w_s <= '1';
                when 2 =>
                    i_wen_s <= '0';
                    i_w_s <= '0';
                    init_on_out <= '0';
                    mux_sel_out <= "11";
                    stop_init_s <= '1';
                when 3 =>
                    stop_init_s <= '0';
                when others =>
                    null;
            end case;
            
            if (edge_cnt < MAX_INIT_EDGE_CNT) then
                edge_cnt := edge_cnt + 1;
            end if;
        end if;
        
    end process;

end Behavioral;
