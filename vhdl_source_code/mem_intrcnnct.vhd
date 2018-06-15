----------------------------------------------------------------------------------
-- mem_intrcnnct.vhd
-- Author: Froylan Aguirre
-- memory_interconnect module
-- The memory interconnect submodule of control unit responsible for routing data
--      paths to registers.
-- Essentially, this module routes address and data input from the reg_cntrl and
--      ICF modules to write to registers.
-- If a write happens to the same register at the same time (refered to as a
--      collision) then the data from ICF will be written. Avoid writing to the 
--      same register at the same time.
-- Outputs with "reg_" prefix is the output of a control unit register.
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

entity mem_intrcnnct is
    Port ( 
        -- INPUTS --
        data_from_reg_cntrl_in : in std_logic_vector(31 downto 0); -- data from register control submodule
        addr_from_reg_cntrl_in : in std_logic_vector(7 downto 0);  -- address from register control submodule
        data_from_ICF_in : in std_logic_vector(31 downto 0);       -- data from ICF module
        addr_from_ICF_in : in std_logic_vector(7 downto 0);        -- address from ICF module
        w_en_ICF_in : in std_logic;                                -- write enable ICF data input
        w_en_cntrl_regs_in: in std_logic;                          -- write enable cntrl_regs data input
        reset_in: in std_logic;
        clk_in : in std_logic;
        
        -- OUTPUTS --
        ato_fp_out : out std_logic_vector (4 downto 0);  -- address to fault parameter
        dto_fp_out : out std_logic_vector (31 downto 0); -- data to fault parameter
        w_en_fp_out : out std_logic;                     -- write enable for fault parameter module
        reg_fault_timer_out    : out std_logic_vector(31 downto 0);
        reg_sampling_timer_out : out std_logic_vector(31 downto 0);
        reg_set_num_counter_out: out std_logic_vector(31 downto 0);
        reg_trigger_pos_cu_out : out std_logic_vector(31 downto 0);
        reg_dut_addr_init_out  : out std_logic_vector(31 downto 0);
        reg_inj_time_init_out  : out std_logic_vector(31 downto 0);
        reg_flt_oprnd_init_out : out std_logic_vector(31 downto 0);
        reg_sample_data_a_out  : out std_logic_vector(31 downto 0);
        reg_dut_addr_cyc_len_out      : out std_logic_vector(31 downto 0);
        reg_inj_time_cyc_len_out      : out std_logic_vector(31 downto 0);
        reg_flt_oprnd_cyc_len_out     : out std_logic_vector(31 downto 0);
        reg_sampling_addr_a_out       : out std_logic_vector(31 downto 0);
        reg_sampling_addr_b_out       : out std_logic_vector(31 downto 0);
        reg_general_config_out        : out std_logic_vector(31 downto 0);
        reg_sample_shutdown_value_out : out std_logic_vector(31 downto 0)
    );
end mem_intrcnnct;

architecture Behavioral of mem_intrcnnct is
    
    constant FP_BIT_POS : integer := 7;
    
    -- if the three most sig. bits of the address is this, then its routed to Fault_Parameters
    constant FP_THREE_BIT : std_logic_vector(2 downto 0) := "100";
    
    -- register addresses
    constant FAULT_TIMER_ADDR:    std_logic_vector(7 downto 0) := x"03";
    constant SAMPLING_TIMER_ADDR: std_logic_vector(7 downto 0) := x"04";
    constant SET_NUM_COUNTER_ADDR:std_logic_vector(7 downto 0) := x"05";
    constant TRIGGER_POS_CU_ADDR: std_logic_vector(7 downto 0) := x"06";
    constant DUT_ADDR_INIT_ADDR:  std_logic_vector(7 downto 0) := x"07";
    constant INJ_TIME_INIT_ADDR:  std_logic_vector(7 downto 0) := x"08";
    constant FLT_OPRND_INIT_ADDR: std_logic_vector(7 downto 0) := x"09";
    constant SAMPLE_DATA_A_ADDR:  std_logic_vector(7 downto 0) := x"0A";
    constant DUT_ADDR_CYC_LEN_ADDR:      std_logic_vector(7 downto 0) := x"0D";
    constant INJ_TIME_CYC_LEN_ADDR:      std_logic_vector(7 downto 0) := x"0E";
    constant FLT_OPRND_CYC_LEN_ADDR:     std_logic_vector(7 downto 0) := x"0F";
    constant SAMPLING_ADDRA_ADDR:        std_logic_vector(7 downto 0) := x"10";
    constant SAMPLING_ADDRB_ADDR:        std_logic_vector(7 downto 0) := x"11";
    constant GENERAL_CONFIG_ADDR:        std_logic_vector(7 downto 0) := x"12";
    constant SAMPLE_SHUTDOWN_VALUE_ADDR: std_logic_vector(7 downto 0) := x"13";

    signal valid_addr_s : std_logic_vector(31 downto 0) := x"00000000";
    signal valid_data_s : std_logic_vector(31 downto 0) := x"00000000";
    signal sim_writes_s: std_logic := '0'; -- set if there are simultaneous writes 
    signal same_addr_s: std_logic := '0'; -- set addresses on address inputs are the same
    signal collision_s: std_logic := '0'; -- set if writing to the same register at the same time
    signal w_en_fp_s: std_logic := '0'; -- buffer for w_en_fp_out port

    -- registers
    signal reg_fault_timer_s             : std_logic_vector(31 downto 0); 
    signal reg_sampling_timer_s          : std_logic_vector(31 downto 0);
    signal reg_set_num_counter_s         : std_logic_vector(31 downto 0);
    signal reg_trigger_pos_cu_s          : std_logic_vector(31 downto 0);
    signal reg_dut_addr_init_s           : std_logic_vector(31 downto 0);
    signal reg_inj_time_init_s           : std_logic_vector(31 downto 0);
    signal reg_flt_oprnd_init_s          : std_logic_vector(31 downto 0);
    signal reg_sample_data_a_s           : std_logic_vector(31 downto 0);
    signal reg_dut_addr_cyc_len_s        : std_logic_vector(31 downto 0);
    signal reg_inj_time_cyc_len_s        : std_logic_vector(31 downto 0);
    signal reg_flt_oprnd_cyc_len_s       : std_logic_vector(31 downto 0);
    signal reg_sampling_addr_a_s         : std_logic_vector(31 downto 0);
    signal reg_sampling_addr_b_s         : std_logic_vector(31 downto 0);
    signal reg_general_config_s          : std_logic_vector(31 downto 0);
    signal reg_sample_shutdown_value_s   : std_logic_vector(31 downto 0);

begin
    w_en_fp_out <= w_en_fp_s;

    sim_writes_s <= w_en_cntrl_regs_in and w_en_ICF_in;
    same_addr_s <= '1' when (addr_from_reg_cntrl_in = addr_from_ICF_in) else '0';    
    collision_s <= sim_writes_s and same_addr_s;
    
    -- registers out
    reg_fault_timer_out      <=         reg_fault_timer_s           ;
    reg_sampling_timer_out   <=         reg_sampling_timer_s        ;
    reg_set_num_counter_out  <=         reg_set_num_counter_s       ;
    reg_trigger_pos_cu_out   <=         reg_trigger_pos_cu_s        ;
    reg_dut_addr_init_out    <=         reg_dut_addr_init_s         ;
    reg_inj_time_init_out    <=         reg_inj_time_init_s         ;
    reg_flt_oprnd_init_out   <=         reg_flt_oprnd_init_s        ;
    reg_sample_data_a_out    <=         reg_sample_data_a_s         ;
    reg_dut_addr_cyc_len_out      <=    reg_dut_addr_cyc_len_s      ;
    reg_inj_time_cyc_len_out      <=    reg_inj_time_cyc_len_s      ;
    reg_flt_oprnd_cyc_len_out     <=    reg_flt_oprnd_cyc_len_s     ;
    reg_sampling_addr_a_out       <=    reg_sampling_addr_a_s       ;
    reg_sampling_addr_b_out       <=    reg_sampling_addr_b_s       ;
    reg_general_config_out        <=    reg_general_config_s        ;
    reg_sample_shutdown_value_out <=    reg_sample_shutdown_value_s ;
    
    
    -- fault parameter routing
    fault_param_routing: process(w_en_cntrl_regs_in, w_en_ICF_in, reset_in)
    begin
        if (rising_edge(reset_in)) then
            ato_fp_out <= "00000";
            dto_fp_out <= x"00000000";
        end if;
        
        if (rising_edge(w_en_cntrl_regs_in) and (collision_s = '0') and (FP_THREE_BIT = addr_from_reg_cntrl_in(7 downto 5))) then
            ato_fp_out <= addr_from_reg_cntrl_in(4 downto 0);
            dto_fp_out <= data_from_reg_cntrl_in;
        end if;
        
        if (rising_edge(w_en_ICF_in) and (collision_s = '0') and (FP_THREE_BIT = addr_from_ICF_in(7 downto 5))) then
           
            ato_fp_out <= addr_from_ICF_in(4 downto 0);
            dto_fp_out <= data_from_ICF_in;
         
        end if;    
    end process;
    
    -- creates write enable pulse for w_en_fp
    fault_param_write_en: process(clk_in, w_en_cntrl_regs_in, w_en_ICF_in)
    begin
        if (rising_edge(reset_in)) then
            w_en_fp_s <= '0';
        end if;
    
        if (w_en_fp_s = '1') then
            w_en_fp_s <= '0';
        end if;
    
        if ((FP_THREE_BIT = addr_from_reg_cntrl_in(7 downto 5)) and (FP_THREE_BIT = addr_from_ICF_in(7 downto 5))) then  
            if (rising_edge(w_en_cntrl_regs_in) and (collision_s = '0')) then
                w_en_fp_s <= '1';
            end if;
            
            if (rising_edge(w_en_ICF_in) and (collision_s = '0')) then
                w_en_fp_s <= '1';
            end if;    
        end if;
    end process;
    
    -- routes data to a register residing in the Control_Unit module
    control_unit_routing: process(w_en_cntrl_regs_in, w_en_ICF_in, reset_in)
    begin
        if (rising_edge(reset_in)) then
            reg_fault_timer_s     <= x"00000000";
            reg_sampling_timer_s  <= x"00000000";
            reg_set_num_counter_s <= x"00000000";
            reg_trigger_pos_cu_s  <= x"00000000";
            reg_dut_addr_init_s   <= x"00000000";
            reg_inj_time_init_s   <= x"00000000";
            reg_flt_oprnd_init_s  <= x"00000000";
            reg_sample_data_a_s   <= x"00000000";
            reg_dut_addr_cyc_len_s      <= x"00000000";
            reg_inj_time_cyc_len_s      <= x"00000000";
            reg_flt_oprnd_cyc_len_s     <= x"00000000";
            reg_sampling_addr_a_s       <= x"00000000";
            reg_sampling_addr_b_s       <= x"00000000";
            reg_general_config_s        <= x"00000000";
            reg_sample_shutdown_value_s <= x"00000000";
        end if;
    
        if (rising_edge(w_en_cntrl_regs_in) and (collision_s = '0')) then
            case addr_from_reg_cntrl_in is
                when FAULT_TIMER_ADDR =>
                    reg_fault_timer_s <= data_from_reg_cntrl_in;
                when SAMPLING_TIMER_ADDR =>
                    reg_sampling_timer_s <= data_from_reg_cntrl_in;
                when SET_NUM_COUNTER_ADDR =>
                    reg_set_num_counter_s <= data_from_reg_cntrl_in;
                when TRIGGER_POS_CU_ADDR =>
                    reg_trigger_pos_cu_s <= data_from_reg_cntrl_in;
                when DUT_ADDR_INIT_ADDR =>
                    reg_dut_addr_init_s <= data_from_reg_cntrl_in; 
                when INJ_TIME_INIT_ADDR =>
                    reg_inj_time_init_s <= data_from_reg_cntrl_in;  
                when FLT_OPRND_INIT_ADDR =>
                    reg_flt_oprnd_init_s <= data_from_reg_cntrl_in; 
                when SAMPLE_DATA_A_ADDR =>
                    reg_sample_data_a_s <= data_from_reg_cntrl_in;  
                when DUT_ADDR_CYC_LEN_ADDR      =>
                    reg_dut_addr_cyc_len_s <= data_from_reg_cntrl_in;
                when INJ_TIME_CYC_LEN_ADDR      =>
                    reg_inj_time_cyc_len_s <= data_from_reg_cntrl_in;
                when FLT_OPRND_CYC_LEN_ADDR     =>
                    reg_flt_oprnd_cyc_len_s <= data_from_reg_cntrl_in;
                when SAMPLING_ADDRA_ADDR        =>
                    reg_sampling_addr_a_s <= data_from_reg_cntrl_in;
                when SAMPLING_ADDRB_ADDR        =>
                    reg_sampling_addr_b_s <= data_from_reg_cntrl_in;
                when GENERAL_CONFIG_ADDR        =>
                    reg_general_config_s <= data_from_reg_cntrl_in;
                when SAMPLE_SHUTDOWN_VALUE_ADDR =>
                    reg_sample_shutdown_value_s <= data_from_reg_cntrl_in;
                when others =>
                    null;
            end case;
        end if;
        
        if (rising_edge(w_en_ICF_in) and (collision_s = '0')) then
            case addr_from_ICF_in is
                when FAULT_TIMER_ADDR =>
                    reg_fault_timer_s <= data_from_ICF_in;
                when SAMPLING_TIMER_ADDR =>
                    reg_sampling_timer_s <= data_from_ICF_in;
                when SET_NUM_COUNTER_ADDR =>
                    reg_set_num_counter_s <= data_from_ICF_in;
                when TRIGGER_POS_CU_ADDR =>
                    reg_trigger_pos_cu_s <= data_from_ICF_in; 
                when DUT_ADDR_INIT_ADDR =>
                    reg_dut_addr_init_s <= data_from_ICF_in; 
                when INJ_TIME_INIT_ADDR =>
                    reg_inj_time_init_s <= data_from_ICF_in;  
                when FLT_OPRND_INIT_ADDR =>
                    reg_flt_oprnd_init_s <= data_from_ICF_in;
                when SAMPLE_DATA_A_ADDR =>
                    reg_sample_data_a_s <= data_from_ICF_in;  
                when DUT_ADDR_CYC_LEN_ADDR      =>
                    reg_dut_addr_cyc_len_s <= data_from_ICF_in;
                when INJ_TIME_CYC_LEN_ADDR      =>
                    reg_inj_time_cyc_len_s <= data_from_ICF_in;
                when FLT_OPRND_CYC_LEN_ADDR     =>
                    reg_flt_oprnd_cyc_len_s <= data_from_ICF_in;
                when SAMPLING_ADDRA_ADDR        =>
                    reg_sampling_addr_a_s <= data_from_ICF_in;
                when SAMPLING_ADDRB_ADDR        =>
                    reg_sampling_addr_b_s <= data_from_ICF_in;
                when GENERAL_CONFIG_ADDR        =>
                    reg_general_config_s <= data_from_ICF_in;
                when SAMPLE_SHUTDOWN_VALUE_ADDR =>
                    reg_sample_shutdown_value_s <= data_from_ICF_in;
                when others =>
                    null;
            end case;
        end if;    
    end process;

end Behavioral;
