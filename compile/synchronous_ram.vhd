-------------------------------------------------------------------------------
--
-- Title       : 
-- Design      : Microcontroller
-- Author      : Evan
-- Company     : Old Dominion University
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Aldec_Designs\test_workspace\Microcontroller\compile\synchronous_ram.vhd
-- Generated   : Tue Jul 31 22:58:40 2018
-- From        : c:\My_Aldec_Designs\test_workspace\Microcontroller\graphics\synchronous_ram.bde
-- By          : Bde2Vhdl ver. 2.6
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-- Design unit header --
library ieee;
        use ieee.std_logic_1164.all;
        use ieee.NUMERIC_STD.all;

entity synchronous_ram is
  port(
       i_clk : in STD_LOGIC;
       i_rw : in STD_LOGIC;
       i_address : in STD_LOGIC_VECTOR(7 downto 0);
       io_data : inout STD_LOGIC_VECTOR
  );
end synchronous_ram;

architecture structural of synchronous_ram is

---- Architecture declarations -----
--Added by Active-HDL. Do not change code inside this section.
type SRAM_T is array (0 to (2 ** i_address'length) - 1) of STD_LOGIC_VECTOR(io_data'range);
--End of extra code.


---- Signal declarations used on the diagram ----

signal w_data : STD_LOGIC_VECTOR := "ZZZZZZZZ";
signal sram : SRAM_T(0 to (2 ** i_address'length) - 1) := (others => (others => '0'));

begin

---- Processes ----

UPDATE : process (i_clk)
                       begin
                         if (rising_edge(i_clk)) then
                            if (i_rw = '0' or i_rw = 'U') then
                               w_data <= sram(to_integer(unsigned(i_address)));
                            else 
                               w_data <= "ZZZZZZZZ";
                               sram(to_integer(unsigned(i_address))) <= io_data;
                            end if;
                         end if;
                       end process;
                      

---- User Signal Assignments ----
io_data <= w_data;

end structural;
