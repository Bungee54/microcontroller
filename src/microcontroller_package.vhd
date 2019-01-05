-- Evan Allen, 9/7/2018

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

package microcontroller_package is
    constant word_size : NATURAL := 16;
    constant opcode_size : NATURAL := 7;
    constant reg_addr_size : NATURAL := 3;
    constant num_general_registers : NATURAL := 8;
    constant num_fetch_registers : NATURAL := 2;

    subtype T_WORD is STD_LOGIC_VECTOR(word_size - 1 downto 0);
    type T_FETCH_TABLE is array(opcode_size - 1 downto 0) of NATURAL;
    subtype T_LOAD is STD_LOGIC_VECTOR(1 downto 0);
    subtype T_OPCODE is STD_LOGIC_VECTOR(opcode_size - 1 downto 0);
    type T_FETCH_REGFILE is array(0 to num_fetch_registers - 1) of T_WORD;
    subtype T_REGF_ADDR is STD_LOGIC_VECTOR(reg_addr_size - 1 downto 0);
    subtype T_SUBSTATE is INTEGER range 0 to 7;
    
    type T_BUS_SELECT is (          -- Prefixed with 'SEL' to distinguish it from actual signals
        SEL_ALU_OUT,
        SEL_RAM_DATA,
        SEL_ROM_DATA,
        SEL_REGF_RDATA1,
        SEL_REGF_RDATA2
    );

    type T_ALU_SELECT is (
        SEL_ADD,
        SEL_SUB,
        SEL_NEG,
        SEL_INC,
        SEL_DEC,
        SEL_PASS,
        SEL_AND,
        SEL_OR,
        SEL_XOR,
        SEL_NOT,
        SEL_SHL,
        SEL_SHR
    );

    type T_CPU_STATE is (
        -- FETCH Phase
        FETCH_REQ_INSTRUCTION,
        FETCH_READ_INSTRUCTION,

        -- DECODE Phase
        DECODE_REQ_EXTENSION,
        DECODE_READ_EXTENSION,
        DECODE_REQ_EFFECTIVE,
        DECODE_READ_EFFECTIVE,

        -- EXECUTE Phase
        EXECUTE_INSTRUCTION,

        -- HALT state (do nothing more)
        HALT
    );
end microcontroller_package;