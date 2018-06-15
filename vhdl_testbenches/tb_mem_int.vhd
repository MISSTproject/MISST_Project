--====================================================================
-- tb_mem_int.vhd
-- Testbench for memory interconnect module (mem_intrcnnct.vhd).
--====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_mem_int is
--  Port ( );
end tb_mem_int;

architecture Behavioral of tb_mem_int is

    constant CLOCK_PER: time := 10ns;

    type TEST_NAME is (RESET, FP_R_NC, FP_R_C, CU_R_NC, CU_R_C, PROP_DELAY);
    component mem_intrcnnct is                                           
        Port (                                                        
            data_from_reg_cntrl_in : in std_logic_vector(31 downto 0);
            addr_from_reg_cntrl_in : in std_logic_vector(7 downto 0); 
            data_from_ICF_in : in std_logic_vector(31 downto 0);      
            addr_from_ICF_in : in std_logic_vector(7 downto 0);       
            w_en_ICF_in : in std_logic;                               
            w_en_cntrl_regs_in: in std_logic;  
            reset_in: in std_logic;                       
            clk_in : in std_logic;                                   
            ato_fp_out : out std_logic_vector (4 downto 0);
            dto_fp_out : out std_logic_vector (31 downto 0); 
            --w_en_cu_out : out std_logic;
            reg_fault_timer_out: out std_logic_vector(31 downto 0);                     
            w_en_fp_out : out std_logic;
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
    end component;                                                

    signal current_test : TEST_NAME := RESET;
    signal data_from_reg_cntrl_in : std_logic_vector(31 downto 0);
    signal addr_from_reg_cntrl_in : std_logic_vector(7 downto 0); 
    signal data_from_ICF_in       : std_logic_vector(31 downto 0);      
    signal addr_from_ICF_in       : std_logic_vector(7 downto 0);       
    signal w_en_ICF_in            : std_logic;                               
    signal w_en_cntrl_regs_in     : std_logic;                         
    signal clk_in                 : std_logic;                                   
    signal ato_fp_out             : std_logic_vector (4 downto 0);
    signal dto_fp_out             : std_logic_vector (31 downto 0); 
    -- signal w_en_cu_out            : std_logic;                     
    signal w_en_fp_out            : std_logic; 
    signal reg_fault_timer_out    : std_logic_vector(31 downto 0); 
    signal reg_sampling_timer_out : std_logic_vector(31 downto 0);
    signal reg_set_num_counter_out: std_logic_vector(31 downto 0);
    signal reg_trigger_pos_cu_out : std_logic_vector(31 downto 0);
    signal reg_dut_addr_init_out  : std_logic_vector(31 downto 0);
    signal reg_inj_time_init_out  : std_logic_vector(31 downto 0);
    signal reg_flt_oprnd_init_out : std_logic_vector(31 downto 0);
    signal reg_sample_data_a_out  : std_logic_vector(31 downto 0); 
    signal reset_in               : std_logic;
    signal reg_dut_addr_cyc_len_out      : std_logic_vector(31 downto 0);
    signal reg_inj_time_cyc_len_out      : std_logic_vector(31 downto 0);
    signal reg_flt_oprnd_cyc_len_out     : std_logic_vector(31 downto 0);
    signal reg_sampling_addr_a_out       : std_logic_vector(31 downto 0);
    signal reg_sampling_addr_b_out       : std_logic_vector(31 downto 0);
    signal reg_general_config_out        : std_logic_vector(31 downto 0);
    signal reg_sample_shutdown_value_out : std_logic_vector(31 downto 0);       
    
begin

    dut: mem_intrcnnct
        port map(
            data_from_reg_cntrl_in => data_from_reg_cntrl_in,
            addr_from_reg_cntrl_in => addr_from_reg_cntrl_in,
            data_from_ICF_in       => data_from_ICF_in      ,
            addr_from_ICF_in       => addr_from_ICF_in      ,
            w_en_ICF_in            => w_en_ICF_in           ,
            w_en_cntrl_regs_in     => w_en_cntrl_regs_in    ,
            clk_in                 => clk_in                ,
            reset_in               => reset_in              ,
            ato_fp_out             => ato_fp_out            ,
            dto_fp_out             => dto_fp_out            ,
            --w_en_cu_out            => w_en_cu_out           ,
            reg_fault_timer_out    => reg_fault_timer_out,
            w_en_fp_out            => w_en_fp_out,
            reg_sampling_timer_out  => reg_sampling_timer_out ,
            reg_set_num_counter_out => reg_set_num_counter_out,
            reg_trigger_pos_cu_out  => reg_trigger_pos_cu_out ,
            reg_dut_addr_init_out   => reg_dut_addr_init_out  ,
            reg_inj_time_init_out   => reg_inj_time_init_out  ,
            reg_flt_oprnd_init_out  => reg_flt_oprnd_init_out ,
            reg_sample_data_a_out   => reg_sample_data_a_out,
            reg_dut_addr_cyc_len_out      => reg_dut_addr_cyc_len_out     ,
            reg_inj_time_cyc_len_out      => reg_inj_time_cyc_len_out     ,
            reg_flt_oprnd_cyc_len_out     => reg_flt_oprnd_cyc_len_out    ,
            reg_sampling_addr_a_out       => reg_sampling_addr_a_out      ,
            reg_sampling_addr_b_out       => reg_sampling_addr_b_out      ,
            reg_general_config_out        => reg_general_config_out       ,
            reg_sample_shutdown_value_out => reg_sample_shutdown_value_out
        );

    clock: process
    begin
        clk_in <= '1';
        wait for CLOCK_PER/2;
        clk_in <= '0';
        wait for CLOCK_PER/2;
    end process;
    
    stim_proc: process
    begin
        data_from_reg_cntrl_in <= x"00000000";
        addr_from_reg_cntrl_in <= x"00";
        data_from_ICF_in <= x"00000000";
        addr_from_ICF_in <= x"00";
        w_en_ICF_in <= '0';      
        w_en_cntrl_regs_in <= '0';
        reset_in <= '0';
        wait for CLOCK_PER;
        
        -- reset test
        current_test <= RESET;
        wait for CLOCK_PER;
        reset_in <= '1';
        wait for CLOCK_PER/2;
        reset_in <= '0';
        wait for CLOCK_PER/2;
        
        -- testing fault parameter routing (no collisions)
        current_test <= FP_R_NC;
        data_from_reg_cntrl_in <= x"12345678";
        addr_from_reg_cntrl_in <= x"81";
        wait for CLOCK_PER;
        w_en_ICF_in <= '1';
        wait for CLOCK_PER;
        w_en_ICF_in <= '0';
        w_en_cntrl_regs_in <= '1';
        wait for CLOCK_PER;
        w_en_cntrl_regs_in <= '0';
        wait for CLOCK_PER;
        data_from_ICF_in <= x"AAAADDDD";
        addr_from_ICF_in <= x"81";
        wait for CLOCK_PER;
        w_en_ICF_in <= '1';
        wait for CLOCK_PER;
        w_en_ICF_in <= '0';
        w_en_cntrl_regs_in <= '1';
        wait for CLOCK_PER;
        w_en_cntrl_regs_in <= '0';
        wait for CLOCK_PER;
        data_from_ICF_in <= x"98765432";
        addr_from_ICF_in <= x"1F";
        wait for CLOCK_PER;
        w_en_ICF_in <= '1';
        wait for CLOCK_PER;
        w_en_ICF_in <= '0';
        w_en_cntrl_regs_in <= '1';
        wait for CLOCK_PER;
        w_en_cntrl_regs_in <= '0';
        wait for CLOCK_PER;
        addr_from_ICF_in <= x"9F";
        w_en_ICF_in <= '1';
        wait for CLOCK_PER;
        w_en_ICF_in <= '0';
        wait for CLOCK_PER;
        
        -- testing Control_Unit routing without collisions
        current_test <= CU_R_NC;
        data_from_reg_cntrl_in <= x"CCCCCCCC";
        addr_from_reg_cntrl_in <= x"03"; 
        data_from_ICF_in <= x"11111111";
        addr_from_ICF_in <= x"03";
        w_en_ICF_in <= '0';      
        w_en_cntrl_regs_in <= '0';
        wait for CLOCK_PER;
        for addr in 3 to 19 loop -- there are 19 registers in total
            w_en_cntrl_regs_in <= '0';
            w_en_ICF_in <= '1';
            addr_from_ICF_in <= std_logic_vector(to_unsigned(addr, addr_from_ICF_in'length));
            wait for CLOCK_PER;
            w_en_cntrl_regs_in <= '1';
            w_en_ICF_in <= '0';
            addr_from_reg_cntrl_in <= std_logic_vector(to_unsigned(addr, addr_from_reg_cntrl_in'length));
            wait for CLOCK_PER;
        end loop;
        
        -- testing Control_Unit routing with collisions
        wait for CLOCK_PER;
        current_test <= CU_R_C;
        reset_in <= '1';
        wait for CLOCK_PER/2;
        reset_in <= '0';
        wait for CLOCK_PER/2;
        data_from_reg_cntrl_in <= x"DDDDDDDD";
        addr_from_reg_cntrl_in <= x"00";
        data_from_ICF_in <= x"22222222";
        addr_from_ICF_in <= x"00";
        wait for CLOCK_PER;
        for addr in 3 to 19 loop -- there are 19 registers in total
            w_en_cntrl_regs_in <= '1';
            w_en_ICF_in <= '1';
            addr_from_ICF_in <= std_logic_vector(to_unsigned(addr, addr_from_ICF_in'length));
            addr_from_reg_cntrl_in <= std_logic_vector(to_unsigned(addr, addr_from_reg_cntrl_in'length));
            wait for CLOCK_PER;
            w_en_cntrl_regs_in <= '0';
            w_en_ICF_in <= '0';
            wait for CLOCK_PER;
        end loop;
        
        -- propagation delay test
        current_test <= PROP_DELAY;
        data_from_reg_cntrl_in <= x"AAAAAAAA";
        addr_from_reg_cntrl_in <= x"81";
        w_en_cntrl_regs_in <= '1';
        wait for CLOCK_PER;
        w_en_cntrl_regs_in <= '0';
        wait for CLOCK_PER;
        w_en_ICF_in <= '1';
        data_from_ICF_in <= x"12345678";
        addr_from_ICF_in <= x"82";
        wait for CLOCK_PER;
        w_en_ICF_in <= '0';
        wait for CLOCK_PER;
        data_from_reg_cntrl_in <= x"BBBBBBBB";
        addr_from_reg_cntrl_in <= x"03";
        w_en_cntrl_regs_in <= '1';
        wait for CLOCK_PER;
        w_en_cntrl_regs_in <= '0';
        wait for CLOCK_PER;
        w_en_ICF_in <= '1';
        data_from_ICF_in <= x"09876543";
        addr_from_ICF_in <= x"03";
        wait for CLOCK_PER;
        w_en_ICF_in <= '0';
        wait for CLOCK_PER;
        wait;
    end process;

end Behavioral;
