----------------------------------------------------------------------------------
-- grouping_unit.vhd
-- Author: Froylan Aguirre
-- A grouping of elements used in Fault Parameter module.
-- Addresses correspond to a grouping element in the following way:
--  name (0b000)
--  oprnd (0b001)
--  op (0b010)
--  min (0b011)
--  max (0b100)
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

entity grouping_unit is
    Port ( 
        data_in : in std_logic_vector (31 downto 0);
        element_sel : in std_logic_vector (2 downto 0);
        enable : in std_logic;
        write : in std_logic;
        var_name : out std_logic_vector (31 downto 0);
        var_oprnd : out std_logic_vector (31 downto 0);
        var_op : out std_logic_vector (3 downto 0);
        var_min : out std_logic_vector (31 downto 0);
        var_max : out std_logic_vector (31 downto 0)
    );
end grouping_unit;

architecture Behavioral of grouping_unit is
    
    -- Usefull Constants
    constant NOT_EN : std_logic_vector (2 downto 0) := "101";
    constant ZERO_FOUR_BYTES : std_logic_vector(31 downto 0) := (others => '0');
    constant VAR_NAME_IDX : integer := 0;
    constant OPRND_IDX : integer := 1;
    constant OP_IDX : integer := 2;
    constant MIN_IDX : integer := 3;
    constant MAX_IDX : integer := 4;

    -- Intermediate signals
    type grouping_elems is array (4 downto 0) of std_logic_vector (31 downto 0);
    signal t_g_elems_regs : grouping_elems := (0 => ZERO_FOUR_BYTES, 1 => ZERO_FOUR_BYTES, 
                                               2 => ZERO_FOUR_BYTES, 3 => ZERO_FOUR_BYTES,
                                               4 => ZERO_FOUR_BYTES);
    signal t_en_and_write : std_logic := '0';
    signal t_en_mux : std_logic_vector (2 downto 0);
    
begin

    t_en_and_write <= (enable and write) and enable;
    t_en_mux <= element_sel when (enable = '1') else
        NOT_EN;
    
    var_name <= t_g_elems_regs(VAR_NAME_IDX);
    var_oprnd <= t_g_elems_regs(OPRND_IDX);
    var_op <= t_g_elems_regs(OP_IDX) (3 downto 0);
    var_min <= t_g_elems_regs(MIN_IDX);
    var_max <= t_g_elems_regs(MAX_IDX);

    write_elem : process (t_en_and_write)
    begin
        if (rising_edge(t_en_and_write)) then
            case t_en_mux is
                when "000" =>
                    t_g_elems_regs(VAR_NAME_IDX) <= data_in;  
                when "001" =>
                    t_g_elems_regs(OPRND_IDX) <= data_in;
                when "010" =>
                    -- only using least significant nibble
                    t_g_elems_regs(OP_IDX) <= data_in;
                when "011" =>
                    t_g_elems_regs(MIN_IDX) <= data_in;
                when "100" =>
                    t_g_elems_regs(MAX_IDX) <= data_in;
                when others =>
                    null;
            end case;
        end if;
    end process write_elem;

end Behavioral;
