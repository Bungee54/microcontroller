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
		OPCODE : in STD_LOGIC_VECTOR(3 downto 0);
		Y : out STD_LOGIC_VECTOR(word_size - 1 downto 0);
		FLAG_CARRY : out STD_LOGIC;
		FLAG_OVERFLOW : out STD_LOGIC;
		FLAG_NEGATIVE : out STD_LOGIC;
		FLAG_ZERO : out STD_LOGIC );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal A : STD_LOGIC_VECTOR(word_size - 1 downto 0);
	signal B : STD_LOGIC_VECTOR(word_size - 1 downto 0);
	signal OPCODE : STD_LOGIC_VECTOR(3 downto 0);
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
			OPCODE => OPCODE,
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
        OPCODE <= "0101";
        wait for 20 ns;

        -- Negative test
        A <= "1111111111111111";
        OPCODE <= "0101";
        wait for 20 ns;

        -- ################### --
        -- ### Add tests   ### --
        -- ################### --
        -- No carry, no overflow
        A <= "0101010101010101";
        B <= "0000000000000011";
        OPCODE <= "0000";
        wait for 20 ns;

        -- Carry, no overflow
        A <= "0101010101010101";
        B <= "1100000000000000";
        OPCODE <= "0000";
        wait for 20 ns;

        -- Overflow, no carry
        A <= "0111111111111111";
        B <= "0000000000000001";
        OPCODE <= "0000";
        wait for 20 ns;

        -- ##################### --
        -- ### Other tests   ### --
        -- ##################### --
        -- Subtract
        A <= "0000000000000011";
        B <= "0000000000000101";
        OPCODE <= "0001";
        wait for 20 ns;

        -- Negate
        A <= "0000000000000001";
        OPCODE <= "0010";
        wait for 20 ns;

        -- Increment
        A <= "0000000000000001";
        OPCODE <= "0011";
        wait for 20 ns;

        -- Decrement
        A <= "0000000000000001";
        OPCODE <= "0100";
        wait for 20 ns;

        -- Pass Thru
        A <= "0101010101010101";
        OPCODE <= "0101";
        wait for 20 ns;

        -- AND
        A <= "0101010101010101";
        B <= "0000111100001111";
        OPCODE <= "0110";
        wait for 20 ns;

        -- OR
        A <= "0101010101010101";
        B <= "0000111100001111";
        OPCODE <= "0111";
        wait for 20 ns;

        -- XOR
        A <= "0101010101010101";
        B <= "0000111100001111";
        OPCODE <= "1000";
        wait for 20 ns;

        -- NOT
        A <= "0101010101010101";
        OPCODE <= "1001";
        wait for 20 ns;

        -- Shift L
        A <= "0000100000000000";
        B <= "0000000000000010";
        OPCODE <= "1010";
        wait for 20 ns;

        -- Shift R
        A <= "0000100000000000";
        B <= "0000000000000010";
        OPCODE <= "1011";
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

