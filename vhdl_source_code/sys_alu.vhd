----------------------------------------------------------------------------------
-- Module: sys_alu (Behavioral)
-- Author: Froylan Aguirre
-- The ALU module for the fault injection system.
-- Select operation using func_sel_in with the following values:
--                      no operation : 0x00   
--                          addition : 0x1
--                  increment by one : 0x2
--                  decrement by one : 0x3
--         single left bitwise shift : 0x4 
--        single right bitwise shift : 0x5 
--                        bitwise OR : 0x6
--                       bitwise AND : 0x7
--                       subtraction : 0x8
--   gaussian, unimodal random value : 0x9
--     uniform, uniform random value : 0xA
--         uniform, avg random value : 0xB
--    gaussian, bimodal random value : 0xC
--                        SEU on LSB : 0xD 
-- Select oprnd_b_in as the second operand by clearing oprnd_sel_in. Select
--      oprnd_c_in as the second operand by setting oprnd_sel_in.
-- If op_res_out is not within the range [min_res_in, max_res_in], range_vio_out
--      is set.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Functionality to add or improve:
-- Expand random number generation to 32-bits if possible.
-- Add another SEU function but this function inverts random bit over entire 32-bit input.

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sys_alu is
    Port (
        -- operand A
        oprnd_a_in : in std_logic_vector(31 downto 0);
        
        -- operand B
        oprnd_b_in : in std_logic_vector(31 downto 0);
        
        -- operand C
        oprnd_c_in : in std_logic_vector(31 downto 0);
        
        -- minimum value of valid result 
        min_res_in : in std_logic_vector(31 downto 0);
        
        -- maximum value of valid result
        max_res_in : in std_logic_vector(31 downto 0);
        
        -- select ALU function
        func_sel_in : in std_logic_vector(3 downto 0);
        
        -- select operand B or C to use as second operand
        oprnd_sel_in : in std_logic;
        
        clk_in : in std_logic;
        
        -- range violation
        range_vio_out : out std_logic;
        
        -- range violation for random operations
        rand_range_vio_out: out std_logic;
        
        -- operation result
        op_res_out : out std_logic_vector(31 downto 0)
    );
end sys_alu;

architecture Behavioral of sys_alu is
    
    constant LAST_COMB_ALU_FUNC : integer := 8;
    constant BYTE_SEU: std_logic_vector(3 downto 0) := x"D";

    component comb_alu is
		Port (
			oprnd_a : in std_logic_vector(31 downto 0);
			oprnd_b : in std_logic_vector(31 downto 0);
			oprtn_sel : in std_logic_vector(3 downto 0);
			oprtn_res : out std_logic_vector(31 downto 0)
		);
    end component comb_alu;

    component noise_gen
		generic(
            W : integer := 16;		-- LFSR scaleable from 24 down to 4 bits
            V : integer := 18;		-- LFSR for non uniform clocking scalable 
            g_type : integer := 0;  -- gausian distribution type, 0 = unimodal, 1 = bimodal, from g_noise_out
            u_type : integer := 1   -- uniform distribution type, 0 = uniform, 1 =  ave-uniform, from u_noise_out
        );
		port(
            clk 		: IN std_logic;
			n_reset 	: IN std_logic;          
			enable 		: IN std_logic;
			g_noise_out : OUT std_logic_vector(W-1 downto 0);
			u_noise_out : OUT std_logic_vector(W-1 downto 0)
        );
	end component;

    -- Intermitent Signal Declarations
    signal second_oprnd_s : std_logic_vector(31 downto 0);
    signal comb_res_s : std_logic_vector(31 downto 0);
    signal rand_res_s : std_logic_vector(31 downto 0);
    signal mux1_res_s : std_logic_vector(31 downto 0);
    signal is_greater_than_eight_s : std_logic;
    signal min_violation_s : std_logic;
    signal max_violation_s : std_logic;
    signal single_reset_s: std_logic;
    signal unimodal_gaussian_s, bimodal_gaussian_s: std_logic_vector(15 downto 0);
    signal uniform_uniform_s, uniform_avg_s: std_logic_vector(15 downto 0);
    signal seu_result_s: std_logic_vector(31 downto 0);
begin

    range_vio_out <= (min_violation_s OR max_violation_s) AND (not is_greater_than_eight_s);
    rand_range_vio_out <= (min_violation_s OR max_violation_s) AND is_greater_than_eight_s;
    op_res_out <= mux1_res_s;
    
    -- mux0
    with oprnd_sel_in select
        second_oprnd_s <= oprnd_b_in when '0',
            oprnd_c_in when '1',
            x"00000000" when others;

    -- mux1
    with is_greater_than_eight_s select
        mux1_res_s <= comb_res_s when '0',
            rand_res_s when '1',
            x"00000000" when others;

    with func_sel_in select
        rand_res_s <= seu_result_s when x"D",
            x"0000" & unimodal_gaussian_s when x"9",
            x"0000" & uniform_uniform_s when x"A",
            x"0000" & bimodal_gaussian_s when x"C",
            x"0000" & uniform_avg_s when x"B",
            x"00000000" when others;

    simple_alu : comb_alu
		port map (
			oprnd_a   => oprnd_a_in,
			oprnd_b   => second_oprnd_s,
			oprtn_sel => func_sel_in,
			oprtn_res => comb_res_s
		);
    
    noise_gen_A : noise_gen
        generic map(
            g_type => 0,
            u_type => 0
        )
        port map(
            clk => clk_in,
            n_reset => single_reset_s,
            enable => '1',
            g_noise_out => unimodal_gaussian_s,
            u_noise_out => uniform_uniform_s
        );
        
    noise_gen_B : noise_gen
        generic map(
            g_type => 1,
            u_type => 1
        )
        port map(
            clk => clk_in,
            n_reset => single_reset_s,
            enable => '1',
            g_noise_out => bimodal_gaussian_s,
            u_noise_out => uniform_avg_s
        );
    
    -- creates a one time reset noise gen reset signal
    noise_gen_reseter: process
    begin
        single_reset_s <= '0';
        wait for 30ns;
        single_reset_s <= '1';
        wait;
    end process;
    
    -- checks that func_sel_in is greater than LAST_COMB_ALU_FUNC
    process(func_sel_in)
    begin
        if (to_integer(unsigned(func_sel_in)) > LAST_COMB_ALU_FUNC) then
            is_greater_than_eight_s <= '1';
        else
            is_greater_than_eight_s <= '0';
        end if;
    end process;
    
    -- checks that result of operation is NOT greater than max_res_in
    process(mux1_res_s, max_res_in)
    begin
        if (unsigned(mux1_res_s) > unsigned(max_res_in)) then
             max_violation_s <= '1';
        else
             max_violation_s <= '0';
        end if;
    end process;
    
    -- checks that result of operation is NOT less than min_res_in
    process(mux1_res_s, min_res_in)
    begin
      if (unsigned(mux1_res_s) < unsigned(min_res_in)) then
           min_violation_s <= '1';
      else
           min_violation_s <= '0';
      end if;
    end process;
    
    -- selects a random bit to flip based on uniform uniform random variable
    -- only flips bit within least significant byte
    random_bit_flip_byte: process(func_sel_in, clk_in)
    begin
        if (func_sel_in = BYTE_SEU) then
            case uniform_uniform_s(2 downto 0) is
                when "000" =>
                    seu_result_s <= oprnd_a_in xor x"00000001";
                when "001" =>
                    seu_result_s <= oprnd_a_in xor x"00000002";
                when "010" =>
                    seu_result_s <= oprnd_a_in xor x"00000004";
                when "011" =>
                    seu_result_s <= oprnd_a_in xor x"00000008";
                when "100" =>
                    seu_result_s <= oprnd_a_in xor x"00000010";
                when "101" =>
                    seu_result_s <= oprnd_a_in xor x"00000020";
                when "110" =>
                    seu_result_s <= oprnd_a_in xor x"00000040";
                when "111" =>
                    seu_result_s <= oprnd_a_in xor x"00000080";
                when others =>
                    seu_result_s <= x"00000000";
            end case;
        end if;
    end process;

end Behavioral;
