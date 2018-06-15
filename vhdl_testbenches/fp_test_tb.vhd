----------------------------------------------------------------------------------
-- fp_test_tb.vhd
-- Author: Froylan Aguirre
-- Testbench for fault_param_regs.vhd.
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

entity fp_test_tb is
--  Port ( );
end fp_test_tb;

architecture Behavioral of fp_test_tb is

    component fault_param_regs is
        Port (
            data_in : in std_logic_vector(31 downto 0);
            addr : in std_logic_vector(4 downto 0);
            wr_en : in std_logic;
            wr : in std_logic;
            var_out     : out std_logic_vector(31 downto 0);
            oprnd_out   : out std_logic_vector(31 downto 0);
            alu_op_out  : out std_logic_vector(3 downto 0);
            min_val_out : out std_logic_vector(31 downto 0);
            max_val_out : out std_logic_vector(31 downto 0) 
        );
    end component fault_param_regs;

    constant ZERO_WORD : std_logic_vector(31 downto 0) := x"00000000";

    signal data_in       : std_logic_vector(31 downto 0);
    signal addr          : std_logic_vector(4 downto 0);
    signal wr_en         : std_logic;
    signal wr            : std_logic;
    signal var_out       : std_logic_vector(31 downto 0);
    signal oprnd_out     : std_logic_vector(31 downto 0);
    signal alu_op_out    : std_logic_vector(3 downto 0); 
    signal min_val_out   : std_logic_vector(31 downto 0);
    signal max_val_out   : std_logic_vector(31 downto 0);

begin

    dut : fault_param_regs
        port map(
            data_in     => data_in,
            addr        => addr,
            wr_en       => wr_en,
            wr          => wr,
            var_out     => var_out,
            oprnd_out   => oprnd_out,
            alu_op_out  => alu_op_out,
            min_val_out => min_val_out,
            max_val_out => max_val_out
        );
        
    stim_proc: process
    begin
        data_in  <=  x"00000000";
        addr     <=  "00000";
        wr_en    <=  '0';
        wr       <=  '0';
        wait for 10 ns;
        wr <= '1';
        data_in <= x"12345678";
        wait for 10 ns;
        wr <= '0';
        wait for 10 ns;
        wr <= '1';
        wr_en <= '1';
        data_in <= x"FFFFFFFF";
        wait for 10 ns;
        wr <= '0';
        wr_en <= '1';
    
        wait;
    end process;

end Behavioral;
