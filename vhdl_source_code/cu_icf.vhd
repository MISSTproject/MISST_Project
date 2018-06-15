----------------------------------------------------------------------------------
-- cu_icf.vhd
-- Module: injection_campaign_FSM (aka ICF)
-- Sub module in Control_Unit that is the "brain" of the entire system 
--  implementing all high level logic.
-- Outputs explained in design_guide.pdf
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Already implemented:
-- Sampling (that sends data to user).
-- States SETUP, FIRST_SAMPLE, SECOND_SAMPLE, DUT_RESET have been implemented.

-- TODO:
-- Continue implementing DUT_RESET state
-- Injection capability:
--   Add samp_inj_start_out functionality
--   Test sampling ability.
-- Add fault_gen.vhd component and fault generation capability.

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cu_icf is
    Port (
        start_campaign_in      : in std_logic;
        resume_in              : in std_logic;
        alu_data_in            : in std_logic_vector(31 downto 0);
        alu_range_vio_in       : in std_logic;
        alu_rand_range_vio_in  : in std_logic;
        reset_in               : in std_logic;
        fault_trigger_in       : in std_logic;
        sampling_trigger_in    : in std_logic;
        set_cnt_trigger_in     : in std_logic;
        clk_in                 : in std_logic;
        
        samp_inj_start_out     : out std_logic;
        sample_start_out       : out std_logic;
        inj_start_out          : out std_logic;
        data_to_regs_out       : out std_logic_vector(31 downto 0);
        addr_to_regs_out       : out std_logic_vector(31 downto 0);
        write_data_out         : out std_logic;
        fp_wr_out              : out std_logic;
        fp_wr_en_out           : out std_logic;
        mux0_sel_out           : out std_logic;
        alu_oprnd_sel_out      : out std_logic;
        mux1_data_out          : out std_logic_vector(31 downto 0);
        mux1_sel_out           : out std_logic;
        reset_fault_cnt_out    : out std_logic;
        reset_sampling_cnt_out : out std_logic;
        reset_set_cnt_out      : out std_logic;
        dut_clk_disable_out    : out std_logic;
        campaign_done_out      : out std_logic;
        
                              
        -- register inputs (from output of memory interconnect module)  
        dut_addr_init_in       : in std_logic_vector(31 downto 0);   
        inj_time_init_in       : in std_logic_vector(31 downto 0);  
        flt_oprnd_init_in      : in std_logic_vector(31 downto 0);
        sample_dataA_in        : in std_logic_vector(31 downto 0);
        dut_addr_cyc_len_in    : in std_logic_vector(31 downto 0);
        inj_time_cyc_len_in    : in std_logic_vector(31 downto 0);
        flt_oprnd_cyc_len_in   : in std_logic_vector(31 downto 0);
        sampling_addr_a_in     : in std_logic_vector(31 downto 0);
        sampling_addr_b_in     : in std_logic_vector(31 downto 0);
        general_config_in      : in std_logic_vector(31 downto 0);
        sample_shutdown_value_in : in std_logic_vector(31 downto 0)
        
    );
end cu_icf;

architecture Behavioral of cu_icf is

    type HIGH_LEVEL_SYS_STATE is (SETUP, WAIT_INJ_OR_SAMP, FIRST_SAMPLE, SECOND_SAMPLE, 
        DUT_RESET, FAULT_SAMP,FAULT_GEN, FAULT_INJ);
    type SAMPLING_STEP is (WAIT_FOR_TRIGGER, SETUP, CLEAR_SETUP, WAIT_FOR_RESUME); --might remove CLEAR_SETUP

    signal misst_sys_state: HIGH_LEVEL_SYS_STATE := SETUP;
    signal sampling_state_s: SAMPLING_STEP := WAIT_FOR_TRIGGER;
    signal start_sampling_s, start_inj_samp_s, stop_sampling_s : std_logic := '0';
    signal start_inj_s, stop_inj_s : std_logic := '0';
    signal data_to_regs_mux_sel_s : std_logic_vector(1 downto 0) := "00";
    signal curr_sampling_addr_s : std_logic_vector(31 downto 0);
    signal off_from_sample_s, off_from_sample_res_s : std_logic; -- if set, system will shutdown due to sample taken
    
    -- signals for sampling_fsm
    signal samp_addr_s : std_logic_vector(31 downto 0);
    signal samp_send_s : std_logic := '0';

begin
        
    -- checks current sample data to see if shutdown condition is met
    -- drives: off_from_sample_s
    sample_check : process(resume_in) --removed sample_dataA_in from sensitivity list
    begin
        case general_config_in(9 downto 8) is
            when "01" =>
                if (sample_dataA_in = sample_shutdown_value_in) then
                    off_from_sample_res_s <= '1';
                else
                    off_from_sample_res_s <= '0';
                end if;
            when "10" =>
                if ((sample_dataA_in and sample_shutdown_value_in) = x"00000000") then
                    off_from_sample_res_s <= '1';
                else
                    off_from_sample_res_s <= '0';  
                end if;
            when "11" =>
                if ((sample_dataA_in xor sample_shutdown_value_in) = x"00000000") then
                    off_from_sample_res_s <= '1';
                else
                    off_from_sample_res_s <= '0';  
                end if;
            when others =>
                off_from_sample_res_s <= '0';
        end case;
    end process;
    
    -- handles sampling requests
    -- Sampling starts when sampling_trigger_in is high during a rising edge of clk_in.
    sampling_fsm : process(clk_in, start_sampling_s, start_inj_samp_s, resume_in)
    begin
        if (rising_edge(start_sampling_s)) then
            sampling_state_s <= SETUP;
        end if;
        
        if (rising_edge(start_inj_samp_s)) then
            sampling_state_s <= SETUP;
        end if;
        
        if (sampling_state_s /= WAIT_FOR_TRIGGER) then
            case sampling_state_s is
                when SETUP =>
                    if (start_sampling_s = '1') then
                        samp_addr_s <= curr_sampling_addr_s;
                        samp_send_s <= '1';
                    end if;
                    
                    --samp_send_s <= '1';
                    sampling_state_s <= WAIT_FOR_RESUME;
--                when CLEAR_SETUP =>
--                    samp_send_s <= '0';
                    
                when WAIT_FOR_RESUME =>
                    samp_send_s <= '0';
                    if (rising_edge(resume_in)) then
                        sampling_state_s <= WAIT_FOR_TRIGGER;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    -- overall system control
    -- drives: dut_clk_disable_out, curr_sampling_addr_s
    overall_sys_fsm : process(start_campaign_in, sampling_trigger_in, resume_in)
    begin
        case misst_sys_state is
            when SETUP =>
                if (rising_edge(start_campaign_in)) then
                    misst_sys_state <= WAIT_INJ_OR_SAMP;
                end if;
            when WAIT_INJ_OR_SAMP =>
                -- injection trigger not implemented
                -- if (rising_edge(fault_trigger_in) and (sampling_trigger_in = '0')) then
                --     misst_sys_state <= FAULT_INJ;
                -- end if;
            
                if (rising_edge(sampling_trigger_in)) then
                    misst_sys_state <= FIRST_SAMPLE;
                    start_sampling_s <= '1';
                    dut_clk_disable_out <= '1';
                    curr_sampling_addr_s <= sampling_addr_a_in;
                end if;
                               
            when FIRST_SAMPLE =>
                -- sampling a second location
                if (rising_edge(resume_in) and (general_config_in(6) = '1')) then
                    misst_sys_state <= SECOND_SAMPLE;
                    -- off_from_sample_s <= off_from_sample_res_s; -- use off_from_sample_res_s directly!
                    start_sampling_s <= '0';
                    curr_sampling_addr_s <= sampling_addr_b_in;
                end if;
                
                -- sampling only one location
                if (rising_edge(resume_in) and (general_config_in(6) = '0')) then
                    misst_sys_state <= DUT_RESET;
                    start_sampling_s <= '0';
                    -- off_from_sample_s <= off_from_sample_res_s; -- use off_from_sample_res_s directly!
                end if;
            when SECOND_SAMPLE =>
                start_sampling_s <= '1'; -- this should be assigned when falling edge of resume in happens
                if (rising_edge(resume_in)) then
                    start_sampling_s <= '0';
                    misst_sys_state <= DUT_RESET;
                end if;
            when DUT_RESET =>
                if (off_from_sample_res_s = '1') then -- changed from off_from_sample_s
                    misst_sys_state <= SETUP;
                    dut_clk_disable_out <= '0';
                    off_from_sample_s <= '0';
                end if;
                
                if (rising_edge(resume_in)) then
                    misst_sys_state <= WAIT_INJ_OR_SAMP;
                    dut_clk_disable_out <= '0';
                end if;
            -- fault injection states not completely implemented yet
            when others =>
                null;
        end case;
    end process;
    
    -- controls communication to memory interconnect (mi) and register control (rc) modules
    -- drives: addr_to_regs_out, sample_start_out, data_to_regs_out, inj_start_out, write_data_out
    coms_to_mi_rc : process(samp_send_s)
    begin
        
        if (rising_edge(samp_send_s) and (start_sampling_s = '1')) then
            sample_start_out <= '1';
            addr_to_regs_out <= samp_addr_s;
        end if;
        
        if (falling_edge(samp_send_s)) then
            sample_start_out <= '0';
            addr_to_regs_out <= x"00000000";
        end if;
        
    end process;

    -- resets sample timer
    -- drives: reset_sampling_cnt_out
    sample_timer_reset : process(resume_in)
    begin
        reset_sampling_cnt_out <= '0';
    
        if (rising_edge(resume_in) and (misst_sys_state = FIRST_SAMPLE)) then
            reset_sampling_cnt_out <= '1';
        end if;
    end process;


end Behavioral;
