library ieee;
use ieee.NUMERIC_STD.all;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity register_file_tb is
end register_file_tb;

architecture TB_ARCHITECTURE of register_file_tb is
	-- Component declaration of the tested unit
	component register_file
	port(
		i_raddr1 : in STD_LOGIC_VECTOR(2 downto 0);
		i_raddr2 : in STD_LOGIC_VECTOR(2 downto 0);
		i_waddr : in STD_LOGIC_VECTOR(2 downto 0);
		i_data : in STD_LOGIC_VECTOR(7 downto 0);
		i_rw : in STD_LOGIC;
		o_data1 : out STD_LOGIC_VECTOR(7 downto 0);
		o_data2 : out STD_LOGIC_VECTOR(7 downto 0) );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal i_raddr1 : STD_LOGIC_VECTOR(2 downto 0);
	signal i_raddr2 : STD_LOGIC_VECTOR(2 downto 0);
	signal i_waddr : STD_LOGIC_VECTOR(2 downto 0);
	signal i_data : STD_LOGIC_VECTOR(7 downto 0);
	signal i_rw : STD_LOGIC;
	-- Observed signals - signals mapped to the output ports of tested entity
	signal o_data1 : STD_LOGIC_VECTOR(7 downto 0);
	signal o_data2 : STD_LOGIC_VECTOR(7 downto 0);

	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : register_file
		port map (
			i_raddr1 => i_raddr1,
			i_raddr2 => i_raddr2,
			i_waddr => i_waddr,
			i_data => i_data,
			i_rw => i_rw,
			o_data1 => o_data1,
			o_data2 => o_data2
		);

	STIMULUS : process
    begin
        i_rw <= '0';
        i_raddr1 <= std_logic_vector(to_unsigned(0, 3));
        i_raddr2 <= std_logic_vector(to_unsigned(0, 3));

        i_waddr <= std_logic_vector(to_unsigned(0, 3));
        i_data <= "01010101"; -- Should not write, since i_rw = '0'

        wait for 20 ns;

        i_data <= std_logic_vector(to_unsigned(0, 8));
        i_rw <= '1';

        INITIALIZE_LOOP : for counter in 0 to 7 loop
            i_waddr <= std_logic_vector(to_unsigned(counter, 3));
            i_data <= std_logic_vector(to_unsigned(counter, 8));
            wait for 10 ns;
        end loop INITIALIZE_LOOP;

        i_rw <= '0';

        i_raddr1 <= "001";
        i_raddr2 <= "101";

        wait for 20 ns;

        i_raddr1 <= "110";
        i_waddr <= "000";

        wait for 5 ns;

        i_data <= o_data1;

        wait for 5 ns;

        i_rw <= '1';

        wait for 20 ns;
    end process STIMULUS;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_register_file of register_file_tb is
	for TB_ARCHITECTURE
		for UUT : register_file
			use entity work.register_file(behavioral);
		end for;
	end for;
end TESTBENCH_FOR_register_file;

