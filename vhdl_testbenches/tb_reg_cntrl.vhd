--====================================================================
-- tb_reg_cntrl.vhd
-- Author: Froylan Aguirre
-- Test bench for register control module.
--====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_reg_cntrl is
--  Port ( );
end tb_reg_cntrl;

architecture Behavioral of tb_reg_cntrl is
    constant CLOCK_PERIOD: time := 10ns;

    component reg_cntrl is
    Port (
        -- INPUTS --
        p_data_in : in std_logic_vector(31 downto 0);
        p_addr_in : in std_logic_vector(7 downto 0);
        p_read_in : in std_logic;
        
        campaign_done_in: in std_logic;                      
        data_ICF_in : in std_logic_vector(31 downto 0);
        addr_ICF_in : in std_logic_vector(31 downto 0);
        ICF_sample_in : in std_logic;
        ICF_samp_inj_in : in std_logic;
        ICF_inject_in : in std_logic;

        clk_in: in std_logic;
        reset_in: in std_logic;
        
        -- OUTPUTS --
        p_data_out: out std_logic_vector(31 downto 0);
        p_addr_out : out std_logic_vector(7 downto 0);
        p_write_out : out std_logic;
        
        data_to_regs_out: out std_logic_vector(31 downto 0); 
        addr_to_regs_out: out std_logic_vector(7 downto 0);  
        write_data_out: out std_logic;                       
        campaign_status_out: out std_logic;      
        sampling_out: out std_logic; 
        samp_inj_out : out std_logic;
        injection_out: out std_logic;              
        resume_out: out std_logic
    );
    end component;

    signal p_data_in : std_logic_vector(31 downto 0);
    signal p_addr_in : std_logic_vector(7 downto 0);
    signal p_read_in : std_logic;
    
    signal campaign_done_in: std_logic;                      
    signal data_ICF_in : std_logic_vector(31 downto 0);
    signal addr_ICF_in : std_logic_vector(31 downto 0);
    signal ICF_sample_in : std_logic;
    signal ICF_inject_in : std_logic;

    signal clk_in: std_logic;
    signal reset_in: std_logic;
    
    signal p_data_out: std_logic_vector(31 downto 0);
    signal p_addr_out : std_logic_vector(7 downto 0);
    signal p_write_out : std_logic;
    
    signal data_to_regs_out: std_logic_vector(31 downto 0); 
    signal addr_to_regs_out: std_logic_vector(7 downto 0);  
    signal write_data_out: std_logic;                       
    signal campaign_status_out: std_logic;                  
    signal resume_out: std_logic;
    signal sampling_out, injection_out: std_logic := '0';
    signal samp_inj_out, ICF_samp_inj_in : std_logic;

begin

    dut: reg_cntrl
        port map(
            p_data_in => p_data_in,
            p_addr_in => p_addr_in,
            p_read_in => p_read_in,
            campaign_done_in => campaign_done_in,
            data_ICF_in => data_ICF_in,
            addr_ICF_in => addr_ICF_in,
            ICF_sample_in => ICF_sample_in,
            ICF_inject_in => ICF_inject_in,
            clk_in => clk_in,
            reset_in => reset_in,
            p_data_out => p_data_out,
            p_addr_out => p_addr_out,
            p_write_out => p_write_out,        
            data_to_regs_out => data_to_regs_out,
            addr_to_regs_out => addr_to_regs_out,  
            write_data_out => write_data_out,                      
            campaign_status_out => campaign_status_out,   
            sampling_out => sampling_out, 
            injection_out => injection_out,               
            resume_out => resume_out,
            samp_inj_out => samp_inj_out,
            ICF_samp_inj_in => ICF_samp_inj_in   
        );
        
    clk_sig: process
    begin
        clk_in <= '1';
        wait for CLOCK_PERIOD/2;
        clk_in <= '0';
        wait for CLOCK_PERIOD/2;
    end process;
    
    stim_proc: process
    begin
        p_data_in <= x"00000000";
        p_addr_in <= x"00";
        p_read_in <= '0';
        campaign_done_in <= '0';
        data_ICF_in <= x"00000000";
        addr_ICF_in <= x"00000000";
        ICF_sample_in <= '0';
        ICF_inject_in <= '0';
        ICF_samp_inj_in <= '0';
        reset_in <= '0';
        wait for CLOCK_PERIOD;
        reset_in <= '1';
        wait for CLOCK_PERIOD;
        reset_in <= '0';
        wait for CLOCK_PERIOD;
        
        -- testing external commmunication
        p_data_in <= x"11112222";
        p_addr_in <= x"06";
        wait for CLOCK_PERIOD;
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        p_data_in <= x"33334444";
        p_addr_in <= x"01";
        wait for CLOCK_PERIOD;
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        wait for CLOCK_PERIOD;
        p_data_in <= x"AABBCCDD";
        wait for CLOCK_PERIOD;
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        wait for CLOCK_PERIOD*3;
        p_data_in <= x"FFEEDDCC";
        p_addr_in <= x"02";
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        
        -- testing sampling after ICF_sample_in is asserted
        addr_ICF_in <= x"AABBCCDD";
        data_ICF_in <= x"12345678";
        wait for CLOCK_PERIOD;
        ICF_sample_in <= '1';
        wait for CLOCK_PERIOD/2;
        ICF_sample_in <= '0';
        wait for CLOCK_PERIOD * 5;
        p_data_in <= x"12345678";
        p_addr_in <= x"0A";
        wait for CLOCK_PERIOD;
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        wait for CLOCK_PERIOD;
        
        -- testing sampling after ICF_samp_inj_in is asserted
        addr_ICF_in <= x"FF00DD00";
        data_ICF_in <= x"22448811";
        -- wait for CLOCK_PERIOD;
        ICF_samp_inj_in <= '1';
        wait for CLOCK_PERIOD/2;
        ICF_samp_inj_in <= '0';
        wait for CLOCK_PERIOD * 5;
        p_data_in <= x"01010101";
        p_addr_in <= x"0A";
        --wait for CLOCK_PERIOD;
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        wait for CLOCK_PERIOD;
        
        -- testing injection after ICF_inject_in is asserted
        addr_ICF_in <= x"20002222";
        data_ICF_in <= x"0000DDDD";
        wait for CLOCK_PERIOD;
        ICF_inject_in <= '1';
        wait for CLOCK_PERIOD;
        ICF_inject_in <= '0';
        wait for CLOCK_PERIOD * 5;
        p_data_in <= x"1F1F1F1F";
        p_addr_in <= x"0B";
        wait for CLOCK_PERIOD;
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        wait for CLOCK_PERIOD;
        
        -- testing if ICF inputs are synchronous with ICF_sample_in
        addr_ICF_in <= x"AABBCCDD";
        data_ICF_in <= x"12345678";
        ICF_sample_in <= '1';
        wait for CLOCK_PERIOD/2;
        ICF_sample_in <= '0';
        wait for CLOCK_PERIOD * 5;
        p_data_in <= x"12345678";
        p_addr_in <= x"0A";
        wait for CLOCK_PERIOD;
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        wait for CLOCK_PERIOD;
        
        -- testing if ICF inputs are synchronous with ICF_inject_in
        addr_ICF_in <= x"20002222";
        data_ICF_in <= x"0000DDDD";
        ICF_inject_in <= '1';
        wait for CLOCK_PERIOD/2;
        ICF_inject_in <= '0';
        wait for CLOCK_PERIOD * 5;
        p_data_in <= x"1F1F1F1F";
        p_addr_in <= x"0B";
        wait for CLOCK_PERIOD;
        p_read_in <= '1';
        wait for CLOCK_PERIOD;
        p_read_in <= '0';
        wait for CLOCK_PERIOD;
        
        wait;
    end process;
    

end Behavioral;
