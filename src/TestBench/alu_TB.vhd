library ieee;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use microcontroller_package.all;

	-- Add your library and packages declaration here ...

entity alu_tb is
end alu_tb;

architecture TB_ARCHITECTURE of alu_tb is
	-- Component declaration of the tested unit
	component alu
	port(
		A : in STD_LOGIC_VECTOR(word_size - 1 downto 0);
		B : in STD_LOGIC_VECTOR(word_size - 1 downto 0);
		SEL : in T_ALU_SELECT;
		Y : out STD_LOGIC_VECTOR(word_size - 1 downto 0);
		FLAG_CARRY : out STD_LOGIC;
		FLAG_OVERFLOW : out STD_LOGIC;
		FLAG_NEGATIVE : out STD_LOGIC;
		FLAG_ZERO : out STD_LOGIC );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal A : STD_LOGIC_VECTOR(word_size - 1 downto 0);
	signal B : STD_LOGIC_VECTOR(word_size - 1 downto 0);
	signal SEL : T_ALU_SELECT;
	-- Observed signals - signals mapped to the output ports of tested entity
	signal Y : STD_LOGIC_VECTOR(word_size - 1 downto 0);
	signal FLAG_CARRY : STD_LOGIC;
	signal FLAG_OVERFLOW : STD_LOGIC;
	signal FLAG_NEGATIVE : STD_LOGIC;
	signal FLAG_ZERO : STD_LOGIC;

	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : alu
		port map (
			A => A,
			B => B,
			SEL => SEL,
			Y => Y,
			FLAG_CARRY => FLAG_CARRY,
			FLAG_OVERFLOW => FLAG_OVERFLOW,
			FLAG_NEGATIVE => FLAG_NEGATIVE,
			FLAG_ZERO => FLAG_ZERO
		);

	STIMULUS : process
    begin
        wait for 10 ns;

        A <= std_logic_vector(to_unsigned(0, word_size));
        B <= std_logic_vector(to_unsigned(0, word_size));

        -- ################### --
        -- ### Flag tests  ### --
        -- ################### --

        -- Zero test
        SEL <= SEL_PASS;
        wait for 20 ns;

        -- Negative test
        A <= "1111111111111111";
        SEL <= SEL_PASS;
        wait for 20 ns;

        -- ################### --
        -- ### Add tests   ### --
        -- ################### --
        -- No carry, no overflow
        A <= "0101010101010101";
        B <= "0000000000000011";
        SEL <= SEL_ADD;
        wait for 20 ns;

        -- Carry, no overflow
        A <= "0101010101010101";
        B <= "1100000000000000";
        SEL <= SEL_ADD;
        wait for 20 ns;

        -- Overflow, no carry
        A <= "0111111111111111";
        B <= "0000000000000001";
        SEL <= SEL_ADD;
        wait for 20 ns;

        -- ##################### --
        -- ### Other tests   ### --
        -- ##################### --
        -- Subtract
        A <= "0000000000000011";
        B <= "0000000000000101";
        SEL <= SEL_SUB;
        wait for 20 ns;

        -- Negate
        A <= "0000000000000001";
        SEL <= SEL_NEG;
        wait for 20 ns;

        -- Increment
        A <= "0000000000000001";
        SEL <= SEL_INC;
        wait for 20 ns;

        -- Decrement
        A <= "0000000000000001";
        SEL <= SEL_DEC;
        wait for 20 ns;

        -- Pass Thru
        A <= "0101010101010101";
        SEL <= SEL_PASS;
        wait for 20 ns;

        -- AND
        A <= "0101010101010101";
        B <= "0000111100001111";
        SEL <= SEL_AND;
        wait for 20 ns;

        -- OR
        A <= "0101010101010101";
        B <= "0000111100001111";
        SEL <= SEL_OR;
        wait for 20 ns;

        -- XOR
        A <= "0101010101010101";
        B <= "0000111100001111";
        SEL <= SEL_XOR;
        wait for 20 ns;

        -- NOT
        A <= "0101010101010101";
        SEL <= SEL_NOT;
        wait for 20 ns;

        -- Shift L
        A <= "0000100000000000";
        B <= "0000000000000010";
        SEL <= SEL_LSL;
        wait for 20 ns;

        -- Shift R
        A <= "0000100000000000";
        B <= "0000000000000010";
        SEL <= SEL_LSR;
        wait for 20 ns;
    end process STIMULUS;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_alu of alu_tb is
	for TB_ARCHITECTURE
		for UUT : alu
			use entity work.alu(behavioral);
		end for;
	end for;
end TESTBENCH_FOR_alu;

