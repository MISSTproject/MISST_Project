----------------------------------------------------------------------------------
-- tb_icf.vhd
-- Author: Froylan Aguirre
-- Testbench for ICF (cu_icf.vhd) component.
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

entity tb_icf is
--  Port ( );
end tb_icf;

architecture Behavioral of tb_icf is

    type TEST_NAME is (SETUP, RESET_FUNC, ONE_SAMPLE, TWO_SAMPLE);

    constant CLOCK : time := 10 ns;

    component cu_icf is
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
    end component;

    signal test : TEST_NAME := SETUP;
    signal start_campaign_in      : std_logic;                       
    signal resume_in              : std_logic;                       
    signal alu_data_in            : std_logic_vector(31 downto 0);   
    signal alu_range_vio_in       : std_logic;                       
    signal alu_rand_range_vio_in  : std_logic;                       
    signal reset_in               : std_logic;                       
    signal fault_trigger_in       : std_logic;                       
    signal sampling_trigger_in    : std_logic;                       
    signal set_cnt_trigger_in     : std_logic;                       
    signal clk_in                 : std_logic;                       
                                                                 
    signal samp_inj_start_out     : std_logic;                      
    signal sample_start_out       : std_logic;                      
    signal inj_start_out          : std_logic;                      
    signal data_to_regs_out       : std_logic_vector(31 downto 0);  
    signal addr_to_regs_out       : std_logic_vector(31 downto 0);  
    signal write_data_out         : std_logic;                      
    signal fp_wr_out              : std_logic;                      
    signal fp_wr_en_out           : std_logic;                      
    signal mux0_sel_out           : std_logic;                      
    signal alu_oprnd_sel_out      : std_logic;                      
    signal mux1_data_out          : std_logic_vector(31 downto 0);  
    signal mux1_sel_out           : std_logic;                      
    signal reset_fault_cnt_out    : std_logic;                      
    signal reset_sampling_cnt_out : std_logic;                      
    signal reset_set_cnt_out      : std_logic;                      
    signal dut_clk_disable_out    : std_logic;                      
    signal campaign_done_out      : std_logic;                      
                                                                 
    -- register inputs (from output of memory interconnect module
    signal dut_addr_init_in       : std_logic_vector(31 downto 0);   
    signal inj_time_init_in       : std_logic_vector(31 downto 0);   
    signal flt_oprnd_init_in      : std_logic_vector(31 downto 0);   
    signal sample_dataA_in        : std_logic_vector(31 downto 0);   
    signal dut_addr_cyc_len_in    : std_logic_vector(31 downto 0);   
    signal inj_time_cyc_len_in    : std_logic_vector(31 downto 0);   
    signal flt_oprnd_cyc_len_in   : std_logic_vector(31 downto 0);   
    signal sampling_addr_a_in     : std_logic_vector(31 downto 0);   
    signal sampling_addr_b_in     : std_logic_vector(31 downto 0);   
    signal general_config_in      : std_logic_vector(31 downto 0);   
    signal sample_shutdown_value_in : std_logic_vector(31 downto 0);  

begin

    clock_gen : process
    begin
        clk_in <= '1';
        wait for CLOCK/2;
        clk_in <= '0';
        wait for CLOCK/2;
    end process;

    dut : cu_icf
    port map(
        start_campaign_in      => start_campaign_in      ,
        resume_in              => resume_in              ,
        alu_data_in            => alu_data_in            ,
        alu_range_vio_in       => alu_range_vio_in       ,
        alu_rand_range_vio_in  => alu_rand_range_vio_in  ,
        reset_in               => reset_in               ,
        fault_trigger_in       => fault_trigger_in       ,
        sampling_trigger_in    => sampling_trigger_in    ,
        set_cnt_trigger_in     => set_cnt_trigger_in     ,
        clk_in                 => clk_in                 ,
                                                         
        samp_inj_start_out     => samp_inj_start_out     ,
        sample_start_out       => sample_start_out       ,
        inj_start_out          => inj_start_out          ,
        data_to_regs_out       => data_to_regs_out       ,
        addr_to_regs_out       => addr_to_regs_out       ,
        write_data_out         => write_data_out         ,
        fp_wr_out              => fp_wr_out              ,
        fp_wr_en_out           => fp_wr_en_out           ,
        mux0_sel_out           => mux0_sel_out           ,
        alu_oprnd_sel_out      => alu_oprnd_sel_out      ,
        mux1_data_out          => mux1_data_out          ,
        mux1_sel_out           => mux1_sel_out           ,
        reset_fault_cnt_out    => reset_fault_cnt_out    ,
        reset_sampling_cnt_out => reset_sampling_cnt_out ,
        reset_set_cnt_out      => reset_set_cnt_out      ,
        dut_clk_disable_out    => dut_clk_disable_out    ,
        campaign_done_out      => campaign_done_out      ,
        -- registers        
        dut_addr_init_in         => dut_addr_init_in       ,
        inj_time_init_in         => inj_time_init_in       ,
        flt_oprnd_init_in        => flt_oprnd_init_in      ,
        sample_dataA_in          => sample_dataA_in        ,
        dut_addr_cyc_len_in      => dut_addr_cyc_len_in    ,
        inj_time_cyc_len_in      => inj_time_cyc_len_in    ,
        flt_oprnd_cyc_len_in     => flt_oprnd_cyc_len_in   ,
        sampling_addr_a_in       => sampling_addr_a_in     ,
        sampling_addr_b_in       => sampling_addr_b_in     ,
        general_config_in        => general_config_in      ,
        sample_shutdown_value_in => sample_shutdown_value_in  
    );

-- testing matrix
-- key: 
-- #s: # number of samples to take, either 1 or 2
-- sbs : sample based shutdown (sbs for off, SBS for on)
-- sinj: injection triggered at same time as sampling (sinj for not, SINJ for yes)

-- sampling trigger only
--    |    sbs    | SBS       |
--    |sinj |SINJ |sinj |SINJ |
-- 1s |  X  |     |  X  |     |
-- ===+=====+=====|=====|=====|=
-- 2s |  X  |     | X   |     |


    stim_proc : process
    begin
    
        test <= SETUP;
        start_campaign_in     <= '0'; 
        resume_in             <= '0';
        alu_data_in           <= x"00000000";
        alu_range_vio_in      <= '0';
        alu_rand_range_vio_in <= '0';
        reset_in              <= '0';
        fault_trigger_in      <= '0';
        sampling_trigger_in   <= '0';
        set_cnt_trigger_in    <= '0';
        -- registers
        dut_addr_init_in         <= x"00000000";
        inj_time_init_in         <= x"00000000";
        flt_oprnd_init_in        <= x"00000000";
        sample_dataA_in          <= x"00000000";
        dut_addr_cyc_len_in      <= x"00000000";
        inj_time_cyc_len_in      <= x"00000000";
        flt_oprnd_cyc_len_in     <= x"00000000";
        sampling_addr_a_in       <= x"00000000";
        sampling_addr_b_in       <= x"00000000";
        general_config_in        <= x"00000000";
        sample_shutdown_value_in <= x"00000000";
        wait for clock;
        
        -- testing reset functionality
        test <= RESET_FUNC;
        reset_in <= '1';
        wait for clock;
        reset_in <= '0';
        wait for clock;
        
        -- testing sampling for one address, without simultaneous inj, with/without sample-based shutdown
        test <= ONE_SAMPLE;
        start_campaign_in <= '1';
        wait for clock;
        sampling_addr_a_in <= x"AAAAAAAA";
        sampling_trigger_in <= '1';
        wait for clock*5;
        resume_in <= '1';
        sampling_trigger_in <= '0'; -- simulates reseting sampling timer
        wait for clock/2;
        resume_in <= '0';
        wait for clock*3; -- waiting for PS to reset DUT
        resume_in <= '1';
        wait for clock/2;
        resume_in <= '0';
        wait for clock;
        -- another sampling, but this time MISST will shutdown due to sample value
        sampling_trigger_in <= '1';
        general_config_in(9 downto 8) <= "10"; -- bitwise AND sample-based shutdown (should shutdown)
        wait for clock*5;
        resume_in <= '1';
        sampling_trigger_in <= '0'; -- simulates reseting sampling timer
        wait for clock/2;
        resume_in <= '0';
        wait for clock*2;
        resume_in <= '1'; -- PS resumes MISST after DUT reset
        wait for clock/2;
        resume_in <= '0';
        start_campaign_in <= '0';
        wait for clock;
        
        -- testing sampling for two address, without simultaneous inj, with/without sample-based shutdown
        test <= TWO_SAMPLE;
        start_campaign_in <= '1';
        wait for clock;
        sampling_addr_a_in <= x"FAAAAAAA";
        sampling_addr_b_in <= x"FBBBBBBB";
        general_config_in <= x"00000000";
        general_config_in(6)  <= '1';
        sampling_trigger_in <= '1';
        wait for clock*5;
        resume_in <= '1'; -- resumes after 1st sample is done
        sampling_trigger_in <= '0'; -- simulates reseting sampling timer
        wait for clock/2;
        resume_in <= '0';
        wait for clock*3; 
        resume_in <= '1'; -- resumes after 2nd sample is done, should now be in DUT_RESET state
        wait for clock/2;
        resume_in <= '0';
        wait for clock*2;
        resume_in <= '1'; -- resumes after a DUT reset
        wait for clock/2;
        resume_in <= '0'; -- at this point, should now be waiting for new sampling trigger
        wait for clock;
        -- another round of sampling, but now with sample-based shutdown
        general_config_in(9 downto 8) <= "10";
        -- sample_dataA_in          <= x"0000000F"; -- uncomment this and the line below to test that this test fails when uncommented
        -- sample_shutdown_value_in <= x"0000000F";
        sampling_trigger_in <= '1';
        wait for clock*5;
        resume_in <= '1';    -- first sample complete
        sampling_trigger_in <= '0'; -- simulates reseting sampling timer
        wait for clock/2;
        resume_in <= '0';
        wait for clock*2;
        resume_in <= '1'; -- second sample complete
        wait for clock/2;
        resume_in <= '0';
        wait for clock;   -- at this point, MISST should shutdown
        
        wait;
    end process;


end Behavioral;
