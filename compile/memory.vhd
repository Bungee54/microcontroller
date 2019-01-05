-------------------------------------------------------------------------------
--
-- Title       : 
-- Design      : Microcontroller
-- Author      : Evan
-- Company     : Old Dominion University
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Aldec_Designs\test_workspace\Microcontroller\compile\memory.vhd
-- Generated   : Fri Jan  4 17:41:23 2019
-- From        : c:\My_Aldec_Designs\test_workspace\Microcontroller\src\memory.bde
-- By          : Bde2Vhdl ver. 2.6
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-- Design unit header --
library std;
        use std.TEXTIO.all;
library ieee;
        use ieee.std_logic_1164.all;
        use ieee.NUMERIC_STD.all;

entity memory is
  generic(
       mem_file : STRING
  );
  port(
       i_clk : in STD_LOGIC;
       i_rw : in STD_LOGIC;
       i_address : in STD_LOGIC_VECTOR;
       io_data : inout STD_LOGIC_VECTOR
  );
end memory;

architecture behavioral of memory is

---- Architecture declarations -----
constant word_size : NATURAL := io_data'length;
impure function memory_readMemFile (constant file_name : in STRING) return MEM_T is 
                       file file_handle : TEXT open READ_MODE is file_name;
                       variable current_line : LINE;
                       variable result_mem : mem_T := (others => (others => '0'));
                     begin
                       assert (word_size mod 4 = 0) report "Size of io_data must be divisible by 4." severity error;
                       for i in 0 to MEM_T'length - 1 loop
                           exit when endfile(file_handle);
                           READLINE(file_handle,current_line);
                           HREAD(current_line,result_mem(i));
                       end loop;
                       return result_mem;
                     end function memory_readMemFile;
--Added by Active-HDL. Do not change code inside this section.
type MEM_T is array (0 to (2 ** i_address'length) - 1) of STD_LOGIC_VECTOR(io_data'range);
--End of extra code.


---- Signal declarations used on the diagram ----

signal w_data : STD_LOGIC_VECTOR := (others => 'Z');
signal mem : MEM_T(0 to (2 ** i_address'length) - 1) := memory_readMemFile(mem_file);

begin

---- Processes ----

UPDATE : process (i_clk)
                       begin
                         if (rising_edge(i_clk)) then
                            if (i_rw = '0' or i_rw = 'U') then
                               w_data <= mem(to_integer(UNSIGNED(i_address)));
                            else 
                               w_data <= (others => 'Z');
                               mem(to_integer(UNSIGNED(i_address))) <= io_data;
                            end if;
                         end if;
                       end process;
                      

---- User Signal Assignments ----
io_data <= w_data;

end behavioral;
