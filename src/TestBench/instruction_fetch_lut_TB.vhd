library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity instruction_fetch_lut_tb is
end instruction_fetch_lut_tb;

architecture TB_ARCHITECTURE of instruction_fetch_lut_tb is
	-- Component declaration of the tested unit
	component instruction_fetch_lut
	port(
		i_opcode7 : in STD_LOGIC_VECTOR(6 downto 0);
		o_num_fetches : out UNSIGNED(1 downto 0) );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal i_opcode7 : STD_LOGIC_VECTOR(6 downto 0) := (others => '0');
	-- Observed signals - signals mapped to the output ports of tested entity
	signal o_num_fetches : UNSIGNED(1 downto 0);

	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : instruction_fetch_lut
		port map (
			i_opcode7 => i_opcode7,
			o_num_fetches => o_num_fetches
		);

	STIMULUS : process
    begin
        wait for 20 ns;
        i_opcode7 <= std_logic_vector(unsigned(i_opcode7) + 1);
    end process STIMULUS;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_instruction_fetch_lut of instruction_fetch_lut_tb is
	for TB_ARCHITECTURE
		for UUT : instruction_fetch_lut
			use entity work.instruction_fetch_lut(instruction_fetch_lut);
		end for;
	end for;
end TESTBENCH_FOR_instruction_fetch_lut;

