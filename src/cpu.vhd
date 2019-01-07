--      CPU
--      Evan Allen, 7/19/2018, 9:15 PM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use microcontroller_package.all;

entity cpu is
    port (
        i_clk : in STD_LOGIC;
        i_rst : in STD_LOGIC;
        i_input : in T_WORD;
        o_output : out T_WORD
        );
end cpu;

architecture rtl of cpu is
    component control_unit port (
        i_clk : in STD_LOGIC;
        i_rst : in STD_LOGIC;
        i_BUS0 : in T_WORD;
        i_BUS1 : in T_WORD;

        i_FLAG_CARRY : in STD_LOGIC;
        i_FLAG_OVERFLOW : in STD_LOGIC;
        i_FLAG_NEGATIVE : in STD_LOGIC;
        i_FLAG_ZERO : in STD_LOGIC;

        i_num_fetches : in UNSIGNED(1 downto 0);

        out_BUS0_sel : out T_BUS_SELECT;
        out_BUS1_sel : out T_BUS_SELECT;

        out_ALU_loadA : out T_LOAD;
        out_ALU_loadB : out T_LOAD;
        out_RAM_loadAddr : out T_LOAD;
        out_RAM_loadData : out T_LOAD;
        out_regf_loadWData : out T_LOAD;
        out_fetchLUT_load : out T_LOAD;

        out_ALU_sel : out T_ALU_SELECT;
        out_regf_raddr1 : out T_REGF_ADDR;
        out_regf_raddr2 : out T_REGF_ADDR;
        out_regf_waddr : out T_REGF_ADDR;
        out_regf_rw : out STD_LOGIC;
        out_RAM_rw : out STD_LOGIC;
        out_ROM_addr : out T_WORD;

        out_fetched_word : out T_WORD
        );
    end component;

    component alu port (
        A : in T_WORD;
        B : in T_WORD;
        SEL : in T_ALU_SELECT;
        Y : out T_WORD;
        FLAG_CARRY : out STD_LOGIC;
        FLAG_OVERFLOW : out STD_LOGIC;
        FLAG_NEGATIVE : out STD_LOGIC;
        FLAG_ZERO : out STD_LOGIC);
    end component;

    component memory
    generic (
        mem_file : STRING); -- For memory initialization
    port (
        i_clk : in STD_LOGIC;
        i_address : in STD_LOGIC_VECTOR;
        i_rw : in STD_LOGIC;                -- '0'=read, '1'=write
        io_data : inout STD_LOGIC_VECTOR);
    end component;

    component register_file port (
        i_raddr1 : in STD_LOGIC_VECTOR(2 downto 0); -- First address to be read
        i_raddr2 : in STD_LOGIC_VECTOR(2 downto 0); -- Second address to be read
        i_waddr : in STD_LOGIC_VECTOR(2 downto 0); -- Address to be written to
        i_data : in T_WORD; -- Data to write to register at `i_waddr`
        i_rw : in STD_LOGIC; -- '0' => read, '1' => write
        o_data1 : out T_WORD; -- Contents of address @ first register
        o_data2 : out T_WORD -- Contents of address @ second register
        );
    end component;

    component instruction_fetch_lut port (
        i_opcode7 : in STD_LOGIC_VECTOR(opcode_size - 1 downto 0); -- Opcode to look up (5-bit main opcode and 2-bit flag section)
        o_num_fetches : out UNSIGNED(1 downto 0) -- Set to the LUT result
        );
    end component;

    -- Arithmetic Logic Unit (ALU) signals
    signal alu_in1 : T_WORD;
    signal alu_in2 : T_WORD;
    signal alu_output : T_WORD;
    signal alu_status_out : STD_LOGIC_VECTOR(7 downto 0);

    -- RAM signals
    signal ram_addr : T_WORD;
    signal ram_data : T_WORD;

    -- ROM signals
    signal rom_addr : T_WORD;
    signal rom_data : T_WORD;

    -- Fetch table signals
    signal fetch_lut_result : UNSIGNED(1 downto 0);
    signal fetch_opcode7 : T_OPCODE;

    -- Register file signals
    signal regf_rdata1 : T_WORD;
    signal regf_rdata2 : T_WORD;
    signal regf_wdata : T_WORD;

    -- Control signals (originate from control unit)
    signal ctrl_regf_raddr1 : STD_LOGIC_VECTOR(2 downto 0);
    signal ctrl_regf_raddr2 : STD_LOGIC_VECTOR(2 downto 0);
    signal ctrl_regf_waddr : STD_LOGIC_VECTOR(2 downto 0);
    signal ctrl_regf_rw : STD_LOGIC;

    signal ctrl_ALU_loadA : T_LOAD;
    signal ctrl_ALU_loadB : T_LOAD;
    signal ctrl_ALU_sel : T_ALU_SELECT;
    signal ctrl_RAM_loadAddr : T_LOAD;
    signal ctrl_RAM_loadData : T_LOAD;
    signal ctrl_RAM_rw : STD_LOGIC;
    signal ctrl_regf_loadWData : T_LOAD;
    signal ctrl_BUS0_sel : T_BUS_SELECT;
    signal ctrl_BUS1_sel : T_BUS_SELECT;
    signal ctrl_fetchLUT_load : T_LOAD;

    signal ctrl_fetched_word : T_WORD;

    -- General-purpose buses
    signal BUS0 : T_WORD;
    signal BUS1 : T_WORD;

begin
    comp_CONTROL_UNIT : CONTROL_UNIT
    port map (
        i_clk => i_clk,
        i_rst => i_rst,
        i_BUS0 => BUS0,
        i_BUS1 => BUS1,

        i_FLAG_CARRY => alu_status_out(6),
        i_FLAG_OVERFLOW => alu_status_out(4),
        i_FLAG_NEGATIVE => alu_status_out(5),
        i_FLAG_ZERO => alu_status_out(7),

        i_num_fetches => fetch_lut_result,

        out_BUS0_sel => ctrl_BUS0_sel,
        out_BUS1_sel => ctrl_BUS1_sel,

        out_ALU_loadA => ctrl_ALU_loadA,
        out_ALU_loadB => ctrl_ALU_loadB,
        out_RAM_loadAddr => ctrl_RAM_loadAddr,
        out_RAM_loadData => ctrl_RAM_loadData,
        out_regf_loadWData => ctrl_regf_loadWData,
        out_fetchLUT_load => ctrl_fetchLUT_load,

        out_ALU_sel => ctrl_ALU_sel,
        out_regf_raddr1 => ctrl_regf_raddr1,
        out_regf_raddr2 => ctrl_regf_raddr2,
        out_regf_waddr => ctrl_regf_waddr,
        out_regf_rw => ctrl_regf_rw,
        out_RAM_rw => ctrl_RAM_rw,
        out_ROM_addr => rom_addr,

        out_fetched_word => ctrl_fetched_word
    );

    comp_ALU : ALU
    port map (
        A => alu_in1,
        B => alu_in2,
        SEL => ctrl_ALU_sel,
        Y => alu_output,
        FLAG_CARRY => alu_status_out(6),
        FLAG_OVERFLOW => alu_status_out(4),
        FLAG_NEGATIVE => alu_status_out(5),
        FLAG_ZERO => alu_status_out(7)
    );

    comp_RAM : MEMORY
    generic map (
        mem_file => "initial_RAM.txt"
    )
    port map (
        i_clk => i_clk,
        i_address => ram_addr,
        i_rw => ctrl_RAM_rw,                -- '0'=read, '1'=write
        io_data => ram_data
    );

    comp_ROM : MEMORY
    generic map (
        mem_file => "initial_ROM.txt"
    )
    port map (
        i_clk => i_clk,
        i_address => rom_addr,
        i_rw => '0',                    -- We never write to ROM
        io_data => rom_data
    );

    comp_REGFILE : REGISTER_FILE
    port map (
        i_raddr1 => ctrl_regf_raddr1, -- First address to be read
        i_raddr2 => ctrl_regf_raddr2, -- Second address to be read
        i_waddr => ctrl_regf_waddr, -- Address to be written to
        i_data => regf_wdata, -- Data to write to register at `i_waddr`
        i_rw => ctrl_regf_rw, -- '0' => read, '1' => write
        o_data1 => regf_rdata1, -- Contents of address @ first register
        o_data2 => regf_rdata2 -- Contents of address @ second register
    );

    comp_FETCH_LUT : INSTRUCTION_FETCH_LUT
    port map (
        i_opcode7 => fetch_opcode7,
        o_num_fetches => fetch_lut_result
    );

    -- Bus logic
    process (ctrl_BUS0_sel, BUS0, alu_output, ram_data, rom_data, regf_rdata1,
             regf_rdata2)
    begin
        case ctrl_BUS0_sel is
            when SEL_ALU_OUT => BUS0 <= alu_output;
            when SEL_RAM_DATA => BUS0 <= ram_data;
            when SEL_ROM_DATA => BUS0 <= rom_data;
            when SEL_REGF_RDATA1 => BUS0 <= regf_rdata1;
            when SEL_REGF_RDATA2 => BUS0 <= regf_rdata2;
            when SEL_FETCH_REG => BUS0 <= ctrl_fetched_word;
        end case;
    end process;

    process (ctrl_BUS1_sel, BUS1, alu_output, ram_data, rom_data, regf_rdata1,
             regf_rdata2)
    begin
        case ctrl_BUS1_sel is
            when SEL_ALU_OUT => BUS1 <= alu_output;
            when SEL_RAM_DATA => BUS1 <= ram_data;
            when SEL_ROM_DATA => BUS1 <= rom_data;
            when SEL_REGF_RDATA1 => BUS1 <= regf_rdata1;
            when SEL_REGF_RDATA2 => BUS1 <= regf_rdata2;
            when SEL_FETCH_REG => BUS1 <= ctrl_fetched_word;
        end case;
    end process;

    -- ALU input A
    process (ctrl_ALU_loadA, BUS0, BUS1)
    begin
        if (ctrl_ALU_loadA(1) = '1') then
            if (ctrl_ALU_loadA(0) = '0') then
                alu_in1 <= BUS0;
            else
                alu_in1 <= BUS1;
            end if;
        end if;
    end process;

    -- ALU input B
    process (ctrl_ALU_loadB, BUS0, BUS1)
    begin
        if (ctrl_ALU_loadB(1) = '1') then
            if (ctrl_ALU_loadB(0) = '0') then
                alu_in2 <= BUS0;
            else
                alu_in2 <= BUS1;
            end if;
        end if;
    end process;

    -- RAM address
    process (ctrl_RAM_loadAddr, BUS0, BUS1)
    begin
        if (ctrl_RAM_loadAddr(1) = '1') then
            if (ctrl_RAM_loadAddr(0) = '0') then
                ram_addr <= BUS0;
            else
                ram_addr <= BUS1;
            end if;
        end if;
    end process;

    -- RAM data
    process (ctrl_RAM_loadData, BUS0, BUS1)
    begin
        if (ctrl_RAM_loadData(1) = '1') then
            if (ctrl_RAM_loadData(0) = '0') then
                ram_data <= BUS0;
            else
                ram_data <= BUS1;
            end if;
        end if;
    end process;

    -- Register file input data
    process (ctrl_regf_loadWData, BUS0, BUS1)
    begin
        if (ctrl_regf_loadWData(1) = '1') then
            if (ctrl_regf_loadWData(0) = '0') then
                regf_wdata <= BUS0;
            else
                regf_wdata <= BUS1;
            end if;
        end if;
    end process;

    process (ctrl_fetchLUT_load, BUS0, BUS1)
    begin
        if (ctrl_fetchLUT_load(1) = '1') then
            if (ctrl_fetchLUT_load(0) = '0') then
                -- This long expression just takes the opcode bits off the instruction.
                -- (The opcode is the most significant `opcode_size` bits of each BUS)
                fetch_opcode7 <= BUS0((BUS0'left) downto (BUS0'left - (opcode_size - 1)));
            else
                fetch_opcode7 <= BUS1((BUS1'left) downto (BUS1'left - (opcode_size - 1)));
            end if;
        end if;
    end process;
end rtl;