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

    constant index_FLAG_CARRY : NATURAL := 7;
    constant index_FLAG_OVERFLOW : NATURAL := 6;
    constant index_FLAG_NEGATIVE : NATURAL := 5;
    constant index_FLAG_ZERO : NATURAL := 4;

    subtype T_WORD is STD_LOGIC_VECTOR(word_size - 1 downto 0);
    type T_FETCH_TABLE is array(opcode_size - 1 downto 0) of NATURAL;
    subtype T_LOAD is STD_LOGIC_VECTOR(1 downto 0);
    subtype T_OPCODE is STD_LOGIC_VECTOR(opcode_size - 1 downto 0);
    type T_FETCH_REGFILE is array(0 to num_fetch_registers - 1) of T_WORD;
    subtype T_REGF_ADDR is STD_LOGIC_VECTOR(reg_addr_size - 1 downto 0);
    subtype T_SUBSTATE is INTEGER range 0 to 7;
    subtype T_STATUS is STD_LOGIC_VECTOR(7 downto 0);
    
    type T_BUS_SELECT is (          -- Prefixed with 'SEL' to distinguish it from actual signals
        SEL_ALU_OUT,
        SEL_RAM_DATA,
        SEL_ROM_DATA,
        SEL_REGF_RDATA1,
        SEL_REGF_RDATA2,
        SEL_FETCH_REG
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
        SEL_LSL,
        SEL_LSR,
        SEL_ASR
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

    --  Type to specify the set of arguments to a certain instruction.
    -- For example, the "ADD rA, rB" instruction would take ARGSET_REG_REG,
    -- "ADD rA, 234" would take ARGSET_REG_NUM, and "NOT rA" would take ARGSET_REG.
    -- Useful for having a single procedure conduct all substeps of an instruction
    -- that requires an ALU computation, but with multiple sets of arguments. 
    type T_ARGSET is (
        ARGSET_REG_REG,
        ARGSET_REG_NUM,
        ARGSET_REG
    );
end microcontroller_package;