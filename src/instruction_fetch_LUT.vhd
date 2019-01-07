-------------------------------------------------------------------------------
--
-- Title       : instruction_fetch_LUT
-- Design      : Microcontroller
-- Author      : Evan Allen
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity instruction_fetch_LUT is
	 port(
		 i_opcode7 : in STD_LOGIC_VECTOR(6 downto 0);
		 o_num_fetches : out UNSIGNED(1 downto 0)
	     );
end instruction_fetch_LUT;

architecture instruction_fetch_LUT of instruction_fetch_LUT is
    signal w_num_fetches : UNSIGNED(1 downto 0);
begin
    process (i_opcode7)
    begin
        -- REFER TO TABLE IN ASSEMBLER FILES
        -- Describes how many extension words the CPU must
        -- retrieve for a given instruction. Most are none ("00"),
        -- but the ones that do require one, two, or three extension
        -- words are listed here.
        --
        -- MUST BE _UP TO DATE_ WITH ASSEMBLER FILES
        -- LAST UPDATED [1/6/2018]
        case i_opcode7 is
            when "00000" & "01" => w_num_fetches <= "01";
            when "00001" & "01" => w_num_fetches <= "01";
            when "00101" & "01" => w_num_fetches <= "01";
            when "00110" & "01" => w_num_fetches <= "01";
            when "00111" & "01" => w_num_fetches <= "01";
            when "01001" & "01" => w_num_fetches <= "01";
            when "01010" & "01" => w_num_fetches <= "01";
            when "01011" & "01" => w_num_fetches <= "01";
            when "01100" & "01" => w_num_fetches <= "01";
            when "01101" & "01" => w_num_fetches <= "01";
            when "01110" & "01" => w_num_fetches <= "01";
            when "01111" & "01" => w_num_fetches <= "01";
            when "10000" & "01" => w_num_fetches <= "01";
            when others         => w_num_fetches <= "00";
        end case;
    end process;

    o_num_fetches <= w_num_fetches;
end instruction_fetch_LUT;
