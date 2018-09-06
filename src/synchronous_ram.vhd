--    Synchronous RAM
--    Evan Allen, 7/19/2018, 10:37 AM

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
    signal sram : SRAM_T := (others => (others => '0'));
    signal w_data : STD_LOGIC_VECTOR(io_data'range) := "ZZZZZZZZ";
begin
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
    end process UPDATE;

    io_data <= w_data;
end structural;