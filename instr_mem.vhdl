library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity instr_mem is
    Port (
        addr    : in  STD_LOGIC_VECTOR(31 downto 0);
        instr   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end instr_mem;

-- Note: the Real RISC-V uses the ADDI for the NOP instruction, but I'm pretending 0x0000000000000000 is a NOP
-- inserting NOPs to avoid hazards
-- ORDER OF INSTRUCTIONS
-- addi 1 - check
-- la - check
-- S
-- S
-- S
-- lw
-- LOOP: Addi
-- S
-- S
-- S
-- lw
-- S
-- S
-- S
-- add
-- subi
-- S
-- S
-- S
-- bne
-- S
-- S
-- S
-- OUT OF LOOP: j
architecture Behavioral of instr_mem is
    type memory_array is array (0 to 255) of STD_LOGIC_VECTOR(31 downto 0);
    signal memory : memory_array := (
        0 => x"00900293", -- addi x5, x0, 9         000000001001 00000 000 00101 0010011
        1 => x"00000317", -- load_addr x6, array (custom instruction), where array is 0x10000000
        2 => x"00000000", -- 3x Stalls
        3 => x"00000000",
        4 => x"00000000",
        5 => x"00032383", -- lw x7, 0(x6)           
        6 => x"00430313", -- loop: addi x6, x6, 4  
        7 => x"00000000", -- 3x Stalls
        8 => x"00000000",
        9 => x"00000000",         
        10 => x"00032503",--       lw x10, 0(x6) 
        11 => x"00000000",-- 3x Stalls
        12 => x"00000000",
        13 => x"00000000",           
        14 => x"007503B3",--       add x7, x10, x7 
        15 => x"00129293",--       subi x5, x5, 1 (or   addi x5, x5, -1) 
        16 => x"00000000",-- 4x Stalls
        17 => x"00000000",
        18 => x"00000000",
        19 => x"00000000", 
        20 => x"F00298E3",--       bne x5, x0, loop   [jump needs to be -60]
        -- <imm[11]><imm[9:4]><5 bit rs2><5 bit rs1><3 bit funct3><imm[3:1]><unused bit><imm[10]><7 bit opcode>
        -- imm: -112/2 = -56 => 111110010000
        -- imm: -120/2 = -60 => 111110001000 
        -- Ver1: 1 111001 00000 00101 001 000 0 1 1100011
        -- Ver2: 1 111000 00000 00101 001 100 0 1 1100011
        -- Ver1: F 2 0 2 9 0 E 3
        -- Ver2: F 0 0 2 9 8 E 3 
        21 => x"00000000",-- 2x Stalls because it will only go 2 stalls once the BNE instruction is loaded
        22 => x"00000000",
        23 => x"FF9FF06F",-- done: j done            [-4; note: assumes PC is already incremented by 4]
        others => (others => '0')
    );
begin
    process(addr)
    begin
        instr <= memory(to_integer(unsigned(addr(7 downto 0))));
    end process;
end Behavioral;
