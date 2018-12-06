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
        i_input : in STD_LOGIC_VECTOR(7 downto 0);
        o_output : out STD_LOGIC_VECTOR(7 downto 0)
        );
end cpu;

architecture rtl of cpu is
    component alu port (
        A : in STD_LOGIC_VECTOR(7 downto 0);
        B : in STD_LOGIC_VECTOR(7 downto 0);
        OPCODE : in STD_LOGIC_VECTOR(3 downto 0);
        Y : out STD_LOGIC_VECTOR(7 downto 0);
        FLAG_CARRY : out STD_LOGIC;
        FLAG_OVERFLOW : out STD_LOGIC;
        FLAG_NEGATIVE : out STD_LOGIC;
        FLAG_ZERO : out STD_LOGIC);
    end component;

    component memory
    generic (
        mem_file : STRING);
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
        i_data : in STD_LOGIC_VECTOR(7 downto 0); -- Data to write to register at `i_waddr`
        i_rw : in STD_LOGIC; -- '0' => read, '1' => write
        o_data1 : out STD_LOGIC_VECTOR(7 downto 0); -- Contents of address @ first register
        o_data2 : out STD_LOGIC_VECTOR(7 downto 0) -- Contents of address @ second register
        );
    end component;

    component instruction_fetch_lut port (
        i_opcode7 : in STD_LOGIC_VECTOR(opcode_size - 1 downto 0); -- Opcode to look up (5-bit main opcode and 2-bit flag section)
        o_num_fetches : out UNSIGNED(1 downto 0) -- Set to the LUT result
        );
    end component;

    signal r_status : STD_LOGIC_VECTOR(7 downto 0); -- Status register (zero, carry, neg, overflow, TBD, TBD, TBD, TBD) <- 7 downto 0
    signal r_pc : STD_LOGIC_VECTOR(addr_size - 1 downto 0); -- Program counter
    signal r_ir : STD_LOGIC_VECTOR(word_size - 1 downto 0); -- Instruction register
    signal r_opcode_alias : STD_LOGIC_VECTOR(opcode_size - 1 downto 0) -- Points to opcode section of r_ir (first few bits of instruction)
        := r_ir(r_ir'left downto (r_ir'left - (opcode_size - 1)));

    type T_FETCH_REGFILE is array(0 to num_fetch_registers - 1) of STD_LOGIC_VECTOR(word_size - 1 downto 0);
    signal r_fetch : T_FETCH_REGFILE; -- Holds extra information such as immediate addresses and their contents
                                                   -- Space for 2 words of information.

    signal alu_in1 : STD_LOGIC_VECTOR(7 downto 0);
    signal alu_in2 : STD_LOGIC_VECTOR(7 downto 0);
    signal alu_opcode : STD_LOGIC_VECTOR(3 downto 0);
    signal alu_output : STD_LOGIC_VECTOR(7 downto 0);

    signal ram_addr : STD_LOGIC_VECTOR(addr_size - 1 downto 0);
    signal ram_data : STD_LOGIC_VECTOR(word_size - 1 downto 0);
    signal ram_rw : STD_LOGIC;

    signal rom_addr : STD_LOGIC_VECTOR(addr_size - 1 downto 0);
    signal rom_data : STD_LOGIC_VECTOR(word_size - 1 downto 0);

    signal regf_raddr1 : STD_LOGIC_VECTOR(2 downto 0);
    signal regf_raddr2 : STD_LOGIC_VECTOR(2 downto 0);
    signal regf_waddr : STD_LOGIC_VECTOR(2 downto 0);
    signal regf_wdata : STD_LOGIC_VECTOR(7 downto 0);
    signal regf_rw : STD_LOGIC;
    signal regf_rdata1 : STD_LOGIC_VECTOR(7 downto 0);
    signal regf_rdata2 : STD_LOGIC_VECTOR(7 downto 0);

    signal fetch_lut_result : UNSIGNED(1 downto 0);

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
        EXEC_CALCULATE,
        EXEC_STORE
    );
    signal ctrl_state : T_CPU_STATE;
    signal ctrl_fetches_remaining : UNSIGNED(1 downto 0);

begin
    comp_ALU : ALU
    port map (
        A => alu_in1,
        B => alu_in2,
        OPCODE => alu_opcode,
        Y => alu_output,
        FLAG_CARRY => r_status(6),
        FLAG_OVERFLOW => r_status(4),
        FLAG_NEGATIVE => r_status(5),
        FLAG_ZERO => r_status(7)
    );

    comp_RAM : MEMORY
    generic map (
        mem_file => "initial_RAM.txt"
    )
    port map (
        i_clk => i_clk,
        i_address => ram_addr,
        i_rw => ram_rw,                -- '0'=read, '1'=write
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
        i_raddr1 => regf_raddr1, -- First address to be read
        i_raddr2 => regf_raddr2, -- Second address to be read
        i_waddr => regf_waddr, -- Address to be written to
        i_data => regf_wdata, -- Data to write to register at `i_waddr`
        i_rw => regf_rw, -- '0' => read, '1' => write
        o_data1 => regf_rdata1, -- Contents of address @ first register
        o_data2 => regf_rdata2 -- Contents of address @ second register
    );

    comp_FETCH_LUT : INSTRUCTION_FETCH_LUT
    port map (
        i_opcode7 => r_opcode_alias,
        o_num_fetches => fetch_lut_result
    );

    RUN : process (i_clk, i_rst)
    begin
        if (rising_edge(i_rst)) then -- Reset
            r_status <= "ZZZZ0000";
            r_pc <= (others => '0');
            r_ir <= (others => '0');

            alu_in1 <= (others => '0');
            alu_in2 <= (others => '0');
            alu_opcode <= (others => '0');

            ram_addr <= (others => '0');
            ram_data <= (others => 'Z');
            ram_rw <= '0';

            rom_addr <= (others => '0');
            rom_data <= (others => 'Z');

            regf_raddr1 <= (others => '0');
            regf_raddr2 <= (others => '0');
            regf_waddr <= (others => '0');
            regf_wdata <= (others => '0');
            regf_rw <= '0';

            ctrl_state <= FETCH_REQ_INSTRUCTION;
            ctrl_fetches_remaining <= to_unsigned(0, ctrl_fetches_remaining'length);
        elsif (rising_edge(i_clk)) then

            -- CPU CONTROL LOGIC
            case ctrl_state is
                -- FETCH Phase
                when FETCH_REQ_INSTRUCTION =>
                    rom_addr <= r_pc;                       -- Ask ROM for instruction
                    ctrl_state <= FETCH_READ_INSTRUCTION;
                when FETCH_READ_INSTRUCTION =>
                    r_ir <= rom_data;                       -- Read instruction from ROM next cycle
                    ctrl_fetches_remaining <= fetch_lut_result;
                    ctrl_state <= DECODE_REQ_EXTENSION;

                -- DECODE Phase
                when DECODE_REQ_EXTENSION =>

                when others =>

            end case;
        end if;
    end process RUN;
end rtl;