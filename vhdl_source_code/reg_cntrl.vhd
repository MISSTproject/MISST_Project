----------------------------------------------------------------------------------
-- reg_cntrl.vhd
-- Author: Froylan Aguirre
-- register_control module
-- Responsible from interfacing with IO module and "executing" register saves 
--      within the control unit module.
-- Within the MISST core, ports with prefix "p_", campaign_status_out, 
--     sampling_out, samp_inj_out, and injection_out compose the interface that
--     communicates with the Adapter module.
-- write_data_out is a write enable signal. When asserted, data on 
--      data_to_regs_out is written at address on addr_to_regs_out (assuming
--      register control is connected to the memory interconnect submodule.
-- campaign_status_out is asserted when module receives 0xAABBCCDD at address 0x1.
-- campaign_status_out is cleared when module receives 0xFFEEDDCC at address 0x2 
--      or when campaign_done_in is set high.
-- sampling_out and injection_out are also connected to IO_Bridge to signal
--      system status.
-- Note: IO bridge, Adapater module, and IO_Bridge used interchangably.
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

entity reg_cntrl is
    Port (
        -- INPUTS --
        p_data_in : in std_logic_vector(31 downto 0);        -- data from IO_Bridge
        p_addr_in : in std_logic_vector(7 downto 0);         -- register address to write to 
        p_read_in : in std_logic;                            -- logic high on rising edge of clk_in writes to register
        
        campaign_done_in: in std_logic;                      -- signals end of campaign on rising edge
        data_ICF_in : in std_logic_vector(31 downto 0);      -- data from ICF to be sent externally
        addr_ICF_in : in std_logic_vector(31 downto 0);      -- address (in DUT memory space) from ICF for sampling or injection location 
        ICF_sample_in : in std_logic;                        -- initiates sampling process on rising edge
        ICF_samp_inj_in : in std_logic;                      -- initiates sampling process (for injection) on rising edge
        ICF_inject_in : in std_logic;                        -- initiates injection process on rising edge

        clk_in: in std_logic;                                -- clock input
        reset_in: in std_logic;                              -- initializes key values to 0 on rising edge
        
        -- OUTPUTS --
        p_data_out: out std_logic_vector(31 downto 0);       -- data to send to IO_Bridge
        p_addr_out : out std_logic_vector(7 downto 0);       -- address (in IO_Bridge) to store data
        p_write_out : out std_logic;
        
        data_to_regs_out: out std_logic_vector(31 downto 0); -- data to memory interconnect submodule
        addr_to_regs_out: out std_logic_vector(7 downto 0);  -- addr to memory interconnect submodule
        write_data_out: out std_logic;                       -- signals new data available from IO_Bridge
        campaign_status_out: out std_logic;                  -- asserted during fault campaign duration
        sampling_out: out std_logic;                         -- signals sampling process in progress
        samp_inj_out : out std_logic;                        -- sampling data for injection process
        injection_out: out std_logic;                        -- signals injection process in process
        resume_out: out std_logic                            -- signals wait for injection/sampling is over and to resume 
    );
end reg_cntrl;

architecture Behavioral of reg_cntrl is
    type INJ_PROCESS_STAGE is (NOT_INJ, SET_ADDR, SET_DATA, START_INJ, WAIT_ACK);

    constant START_INJ_CMD_ADDR: std_logic_vector(7 downto 0) := x"01";
    constant START_INJ_CMD_DATA: std_logic_vector(31 downto 0) := x"AABBCCDD";
    constant STOP_INJ_CMD_ADDR: std_logic_vector(7 downto 0) := x"02";
    constant STOP_INJ_CMD_DATA: std_logic_vector(31 downto 0) := x"FFEEDDCC";
    constant SAMPLE_DATA_A_ADDR: std_logic_vector(7 downto 0) := x"0A";
    constant CONT_AFTER_INJ_ADDR: std_logic_vector(7 downto 0) := x"0B";
    constant RESUME_AFTER_INJ_CMD: std_logic_vector(31 downto 0) := x"1F1F1F1F";
    constant IO_BRIDGE_DUT_SAMP_ADDR: std_logic_vector(7 downto 0) := x"C0";
    constant IO_BRIDGE_DUT_DATA_OUT: std_logic_vector(7 downto 0) := x"C2";
    constant IO_BRIDGE_DUT_INJ_ADDR: std_logic_vector(7 downto 0) := x"C1";
    
    signal ack_a_s, ack_b_s: std_logic := '0';
    signal p_write_s, p_w_out_s, p_start_send_s: std_logic := '0';
    signal data_to_regs_s : std_logic_vector(31 downto 0) := x"00000000";
    signal addr_to_regs_s: std_logic_vector(7 downto 0) := x"00";
    signal stat_campaign_s: std_logic := '0';
    signal start_send_s : std_logic := '0'; -- when set, starts a transmission to IO_Bridge
    signal wr_during_inj_s : std_logic := '0'; -- high when writing to an address that can be written to during an injection campaign
    signal sample_addr_s, inj_addr_s: std_logic_vector(31 downto 0) := x"00000000"; -- DUT address for sampling or injection respectively
    signal sample_p_addr_s, inj_p_addr_s: std_logic_vector(7 downto 0) := x"00"; -- p_addr_out values for sampling and injection
    signal wait_for_sample_s, wait_for_inj_samp_s: std_logic := '0'; -- if set, we are waiting for sample data
    signal wait_for_inj_s: std_logic := '0'; -- if set, we are waiting for injection acknowledgement/resume
    signal inj_data_s: std_logic_vector(31 downto 0) := x"00000000"; -- injection address and data to be injected
begin
    
    data_to_regs_out <= data_to_regs_s;
    addr_to_regs_out <= addr_to_regs_s;
    campaign_status_out <= stat_campaign_s;
    write_data_out <= start_send_s;
    p_write_out <= p_w_out_s;
    sampling_out <= wait_for_sample_s;
    samp_inj_out <= wait_for_inj_samp_s;
            
    p_write_s <= ack_a_s xor ack_b_s;
       
    -- generates single clock pulse to Control_Unit submodules
    write_out_pulse_generation: process(clk_in, reset_in)    
    begin
        if (rising_edge(reset_in)) then
            ack_a_s <= '0';
            ack_b_s <= '0';
        end if;
        
        if (rising_edge(clk_in)) then
            if (start_send_s = '1') then
                ack_a_s <= not ack_a_s;
            end if;
            
            if (p_write_s = '1') then
                ack_b_s <= not ack_b_s;
            end if;
            
        end if;
    end process;
    
    -- Detects a start or stop injection command and sets campaign_status_out appropriately.
    -- Also clears campaign_status if campaign_done_in is asserted
    update_campaign_status: process(start_send_s, clk_in, campaign_done_in, reset_in)
    begin
        if (rising_edge(reset_in)) then
            stat_campaign_s <= '0';
        end if;
        
        if (rising_edge(start_send_s)) then
            if ((data_to_regs_s = START_INJ_CMD_DATA) and (addr_to_regs_s = START_INJ_CMD_ADDR)) then
                stat_campaign_s <= '1';
            elsif ((data_to_regs_s = STOP_INJ_CMD_DATA) and (addr_to_regs_s = STOP_INJ_CMD_ADDR)) then
                stat_campaign_s <= '0';
            end if;
        end if;
        
        if (rising_edge(campaign_done_in)) then
            stat_campaign_s <= '0';          
        end if;
        
    end process;
    
    -- during an injection campaign, you can't write to registers 
    -- HOWEVER, you can write to the following registers:
    wr_during_inj_s <= '1' when (p_addr_in =  START_INJ_CMD_ADDR) else
        '1' when (p_addr_in = STOP_INJ_CMD_ADDR) else
        '1' when (p_addr_in = SAMPLE_DATA_A_ADDR) else
        '1' when (p_addr_in = CONT_AFTER_INJ_ADDR) else
        '0'; 
    

    -- receives data from external adapter and writes registers within system core
    recv_data_and_send: process(clk_in, reset_in)
    begin
        if (rising_edge(reset_in)) then
            start_send_s <= '0';
            data_to_regs_s <= x"00000000";
            addr_to_regs_s <= x"00";
        end if;
    
        if (start_send_s = '1') then
            start_send_s <= '0';
            addr_to_regs_s <= x"00";
        end if;
    
        if (rising_edge(clk_in) and p_read_in = '1') then
            if (not (wr_during_inj_s = '0' and stat_campaign_s = '1')) then
                data_to_regs_s <= p_data_in;
                addr_to_regs_s <= p_addr_in;
                start_send_s <= '1';
            end if;
        end if;
    end process;
    
    -- sets or clears wait_for_sample_s depending on signals from ICF inputs
    sampling_state_update : process(ICF_sample_in, ICF_samp_inj_in, addr_to_regs_s, reset_in)
    begin
        if (rising_edge(reset_in)) then
            sample_addr_s <= x"00000000";
            sample_p_addr_s <= x"00";
            wait_for_sample_s <= '0';
        end if;
    
        if (rising_edge(ICF_sample_in)) then
            sample_addr_s <= addr_ICF_in;
            sample_p_addr_s <= IO_BRIDGE_DUT_SAMP_ADDR;
            wait_for_sample_s <= '1';
        end if;
        
        if ((not rising_edge(ICF_sample_in)) and (SAMPLE_DATA_A_ADDR = addr_to_regs_s)) then
            wait_for_sample_s <= '0';
        end if;
        
        if (rising_edge(ICF_samp_inj_in)) then
            sample_addr_s <= addr_ICF_in;
            sample_p_addr_s <= IO_BRIDGE_DUT_SAMP_ADDR;
            wait_for_inj_samp_s <= '1';
        end if;
        
        if ((not rising_edge(ICF_samp_inj_in)) and (SAMPLE_DATA_A_ADDR = addr_to_regs_s)) then
            wait_for_inj_samp_s <= '0';   
        end if;
        
--        if (SAMPLE_DATA_A_ADDR = addr_to_regs_s) then
--            wait_for_sample_s <= '0';
--            wait_for_inj_samp_s <= '0';
--        end if;
    end process;
    
    -- sets or clears wait_for_inj_s depending on signals from ICF inputs
    injection_state_update: process(ICF_inject_in, addr_to_regs_s, data_to_regs_s, reset_in)
    begin
        if (rising_edge(reset_in)) then
            inj_addr_s <= x"00000000";
            inj_data_s <= x"00000000";
            wait_for_inj_s <= '0';
        end if;
    
        if (rising_edge(ICF_inject_in)) then
            inj_addr_s <= addr_ICF_in;
            inj_data_s <= data_ICF_in;
            wait_for_inj_s <= '1';
        end if;
        
        if ((addr_to_regs_s = CONT_AFTER_INJ_ADDR) and (data_to_regs_s = RESUME_AFTER_INJ_CMD)) then
            wait_for_inj_s <= '0';
        end if;
    end process;
    
    -- updates the resume_out port depending on injection and sampling completion 
    resume_out_driver: process(wait_for_sample_s, wait_for_inj_samp_s, wait_for_inj_s, clk_in, reset_in)
    begin
        if (rising_edge(reset_in)) then
            resume_out <= '0';
        end if;
    
        if (rising_edge(clk_in) and ((wait_for_sample_s = '0') or (wait_for_inj_s = '0') or (wait_for_inj_samp_s = '0'))) then
            resume_out <= '0';
        end if;
        
        if (falling_edge(wait_for_sample_s)) then
            resume_out <= '1';
        end if;
        
        if (falling_edge(wait_for_inj_samp_s)) then
            resume_out <= '1';
        end if;
    
        if (falling_edge(wait_for_inj_s)) then
            resume_out <= '1';
        end if;
    end process;
    
    -- drives p_write_out pulse for sending data to IO_Bridge
    external_comms: process(clk_in, wait_for_sample_s, wait_for_inj_samp_s, wait_for_inj_s, reset_in)
        variable inj_process: INJ_PROCESS_STAGE := NOT_INJ;
    begin
        if (rising_edge(reset_in)) then
            p_w_out_s <= '0';
            p_addr_out <= x"00";
            p_data_out <= x"00000000";
            inj_process := NOT_INJ;
            injection_out <= '0';
        end if;
    
        if (p_w_out_s = '1') then
            p_w_out_s <= '0';
        end if;
    
        if (rising_edge(wait_for_sample_s)) then
            p_w_out_s <= '1';
            p_addr_out <= sample_p_addr_s;
            p_data_out <= sample_addr_s;
        end if;
        
        if (rising_edge(wait_for_inj_samp_s)) then
            p_w_out_s <= '1';
            p_addr_out <= sample_p_addr_s;
            p_data_out <= sample_addr_s;
        end if;
        
        if (rising_edge(wait_for_inj_s)) then
            inj_process := SET_ADDR;
        end if;
        
        if ((wait_for_inj_s = '0') and (inj_process = WAIT_ACK)) then
            inj_process := NOT_INJ;
            injection_out <= '0';
        end if;
        
        if (rising_edge(clk_in)) then
            case (inj_process) is
                when SET_ADDR =>
                    p_w_out_s <= '1';
                    p_addr_out <= IO_BRIDGE_DUT_INJ_ADDR;
                    p_data_out <= inj_addr_s;
                    inj_process := SET_DATA;
                when SET_DATA =>
                    p_w_out_s <= '1';
                    p_addr_out <= IO_BRIDGE_DUT_DATA_OUT;
                    p_data_out <= inj_data_s;
                    inj_process := START_INJ;
                when START_INJ =>
                    injection_out <= '1';
                    inj_process := WAIT_ACK;
                when others =>
                    null;
            end case;
        end if;
    end process;

end Behavioral;
