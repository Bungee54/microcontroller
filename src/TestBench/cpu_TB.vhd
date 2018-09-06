library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity cpu_tb is
end cpu_tb;

architecture TB_ARCHITECTURE of cpu_tb is
	-- Component declaration of the tested unit
	component cpu
	port(
		i_clk : in STD_LOGIC;
		i_rst : in STD_LOGIC;
		i_input : in STD_LOGIC_VECTOR(7 downto 0);
		o_output : out STD_LOGIC_VECTOR(7 downto 0) );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal i_clk : STD_LOGIC;
	signal i_rst : STD_LOGIC;
	signal i_input : STD_LOGIC_VECTOR(7 downto 0);
	-- Observed signals - signals mapped to the output ports of tested entity
	signal o_output : STD_LOGIC_VECTOR(7 downto 0);

	constant c_CLK_PERIOD : TIME := 20 ns;

begin

	-- Unit Under Test port map
	UUT : cpu
		port map (
			i_clk => i_clk,
			i_rst => i_rst,
			i_input => i_input,
			o_output => o_output
		);

	CLK_UPDATE : process
    begin
        i_clk <= '0';
        wait for c_CLK_PERIOD/2;
        i_clk <= '1';
        wait for c_CLK_PERIOD/2;
    end process CLK_UPDATE;

    STIMULUS : process
    begin
        i_rst <= '0';
        wait for 10 ns;
        i_rst <= '1';
        wait for 10 ns;
        i_rst <= '0';
        wait for 1 sec;
    end process STIMULUS;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_cpu of cpu_tb is
	for TB_ARCHITECTURE
		for UUT : cpu
			use entity work.cpu(rtl);
		end for;
	end for;
end TESTBENCH_FOR_cpu;

