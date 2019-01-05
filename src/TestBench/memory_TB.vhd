library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;
use microcontroller_package.all;

	-- Add your library and packages declaration here ...

entity memory_tb is
end memory_tb;

architecture TB_ARCHITECTURE of memory_tb is
	-- Component declaration of the tested unit
	component memory
    generic (
        mem_file : STRING);
	port(
		i_clk : in STD_LOGIC;
		i_address : in STD_LOGIC_VECTOR;
		i_rw : in STD_LOGIC;
		io_data : inout STD_LOGIC_VECTOR );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal i_clk : STD_LOGIC := '0';
	signal i_address : T_WORD := (others => '0');
	signal i_rw : STD_LOGIC := '0';
	signal io_data : T_WORD := (others => 'Z');
	-- Observed signals - signals mapped to the output ports of tested entity

	constant c_CLK_PERIOD : TIME := 20 ns;

begin

	-- Unit Under Test port map
	UUT : memory
        generic map (
            mem_file => "initial_RAM.txt"
        )
		port map (
			i_clk => i_clk,
			i_address => i_address,
			i_rw => i_rw,
			io_data => io_data
		);

	CLK_UPDATE : process
    begin
        i_clk <= '0';
        wait for c_CLK_PERIOD/2;
        i_clk <= '1';
        wait for c_CLK_PERIOD/2;
    end process CLK_UPDATE;

    STIMULUS : process -- Entire write cycle must take one clock period (40 ns)
        variable counter : UNSIGNED(io_data'range) := to_unsigned(0, io_data'length);
        variable writing : BOOLEAN := true;
    begin
        if (writing) then
            i_address <= STD_LOGIC_VECTOR(counter);
            i_rw <= '1';
            io_data <= STD_LOGIC_VECTOR(counter);

            wait for c_CLK_PERIOD * 0.6;

            if (counter < (2**io_data'length)-1) then
                counter := counter + 1;
            else
                writing := false;
                counter := to_unsigned(0, io_data'length);
                i_rw <= '0';
                io_data <= (others => 'Z');
            end if;

            wait for c_CLK_PERIOD * 0.4;
        else
            i_address <= STD_LOGIC_VECTOR(counter);

            wait for c_CLK_PERIOD * 0.6;

            if (counter < (2**io_data'length)-1) then
                counter := counter + 1;
            end if;

            wait for c_CLK_PERIOD * 0.4;
        end if;
    end process STIMULUS;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_memory of memory_tb is
	for TB_ARCHITECTURE
		for UUT : memory
			use entity work.memory(structural);
		end for;
	end for;
end TESTBENCH_FOR_memory;

