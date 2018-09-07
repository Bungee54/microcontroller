--    Synchronous RAM
--    Evan Allen, 7/19/2018, 10:37 AM

library STD;
use STD.textio.all;
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity synchronous_ram is
    port (
        i_clk : in STD_LOGIC;
        i_address : in STD_LOGIC_VECTOR(7 downto 0);
        i_rw : in STD_LOGIC;                -- '0'=read, '1'=write
        io_data : inout STD_LOGIC_VECTOR
    );
end synchronous_ram;

architecture structural of synchronous_ram is
    type SRAM_T is array(0 to (2**i_address'length)-1) of STD_LOGIC_VECTOR(io_data'range);
    constant word_size : NATURAL := io_data'length;

    -- Based off https://electronics.stackexchange.com/questions/180446/how-to-load-std-logic-vector-array-from-text-file-at-start-of-simulation
    impure function sram_readMemFile(file_name : STRING) return SRAM_T is
        file file_handle        : TEXT open READ_MODE is file_name;
        variable current_line   : LINE;
        variable result_ram     : SRAM_T := (others => (others => '0'));
    begin
        assert (word_size mod 4 = 0) report "Size of io_data must be divisible by 4." severity error;

        for i in 0 to SRAM_T'length - 1 loop
            exit when endfile(file_handle);

            readline(file_handle, current_line);
            hread(current_line, result_ram(i));
        end loop;

        return result_ram;
    end function;

    signal sram : SRAM_T := sram_readMemFile("initial_mem.txt");
    signal w_data : STD_LOGIC_VECTOR(io_data'range) := "ZZZZZZZZ";
begin

    UPDATE : process (i_clk)
    begin
        if (rising_edge(i_clk)) then
            if (i_rw = '0' or i_rw = 'U') then
                w_data <= sram(to_integer(UNSIGNED(i_address)));
            else
                w_data <= "ZZZZZZZZ";
                sram(to_integer(UNSIGNED(i_address))) <= io_data;
            end if;
        end if;
    end process UPDATE;

    io_data <= w_data;
end structural;