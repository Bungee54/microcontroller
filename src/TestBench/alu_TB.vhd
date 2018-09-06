library ieee;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	-- Add your library and packages declaration here ...

entity alu_tb is
end alu_tb;

architecture TB_ARCHITECTURE of alu_tb is
	-- Component declaration of the tested unit
	component alu
	port(
		A : in STD_LOGIC_VECTOR(7 downto 0);
		B : in STD_LOGIC_VECTOR(7 downto 0);
		OPCODE : in STD_LOGIC_VECTOR(3 downto 0);
		Y : out STD_LOGIC_VECTOR(7 downto 0);
		FLAG_CARRY : out STD_LOGIC;
		FLAG_OVERFLOW : out STD_LOGIC;
		FLAG_NEGATIVE : out STD_LOGIC;
		FLAG_ZERO : out STD_LOGIC );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal A : STD_LOGIC_VECTOR(7 downto 0);
	signal B : STD_LOGIC_VECTOR(7 downto 0);
	signal OPCODE : STD_LOGIC_VECTOR(3 downto 0);
	-- Observed signals - signals mapped to the output ports of tested entity
	signal Y : STD_LOGIC_VECTOR(7 downto 0);
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

        A <= std_logic_vector(to_unsigned(0, 8));
        B <= std_logic_vector(to_unsigned(0, 8));

        -- ################### --
        -- ### Flag tests  ### --
        -- ################### --

        -- Zero test
        OPCODE <= "0101";
        wait for 20 ns;

        -- Negative test
        A <= "11111111";
        OPCODE <= "0101";
        wait for 20 ns;

        -- ################### --
        -- ### Add tests   ### --
        -- ################### --
        -- No carry, no overflow
        A <= "01010101";
        B <= "00000011";
        OPCODE <= "0000";
        wait for 20 ns;

        -- Carry, no overflow
        A <= "01010101";
        B <= "11000000";
        OPCODE <= "0000";
        wait for 20 ns;

        -- Overflow, no carry
        A <= "01111111";
        B <= "00000001";
        OPCODE <= "0000";
        wait for 20 ns;

        -- ##################### --
        -- ### Other tests   ### --
        -- ##################### --
        -- Subtract
        A <= "00000011";
        B <= "00000101";
        OPCODE <= "0001";
        wait for 20 ns;

        -- Negate
        A <= "00000001";
        OPCODE <= "0010";
        wait for 20 ns;

        -- Increment
        A <= "00000001";
        OPCODE <= "0011";
        wait for 20 ns;

        -- Decrement
        A <= "00000001";
        OPCODE <= "0100";
        wait for 20 ns;

        -- Pass Thru
        A <= "01010101";
        OPCODE <= "0101";
        wait for 20 ns;

        -- AND
        A <= "01010101";
        B <= "00001111";
        OPCODE <= "0110";
        wait for 20 ns;

        -- OR
        A <= "01010101";
        B <= "00001111";
        OPCODE <= "0111";
        wait for 20 ns;

        -- XOR
        A <= "01010101";
        B <= "00001111";
        OPCODE <= "1000";
        wait for 20 ns;

        -- NOT
        A <= "01010101";
        OPCODE <= "1001";
        wait for 20 ns;

        -- Shift L
        A <= "00001000";
        B <= "00000010";
        OPCODE <= "1010";
        wait for 20 ns;

        -- Shift R
        A <= "00001000";
        B <= "00000010";
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

