#!/usr/bin/env terra
local bit = require("bit")

local Mem = require("mem")
local Cpu = require("cpu")

local mem = Mem.new_64(1024*1024)
local cpu = Cpu.new_rv64(mem)




--[[

implemented opcodes:
ADDI
SLTI
SLTIU
XORI
ORI
ANDI


imm_i
op:  00000000  00000000  0XXX0000  0XXXXXXX
rd:  00000000  00000000  0000XXXX  X0000000
rs1: 00000000  0000XXXX  X0000000  00000000
imm: XXXXXXXX  XXXX0000  00000000  00000000

ADDI rd=1 rs1=0 imm=0x00F
op:  --------  --------  -000----  -0010011
rd:  --------  --------  ----0000  1-------
rs1: --------  ----0000  0-------  --------
imm: 00000000  1111----  --------  --------

0b:  00000000  11110000  00000000  10010011
0x:     00        F0        00        93

ADDI rd=1 rs1=1 imm=0x00F
op:  --------  --------  -000----  -0010011
rd:  --------  --------  ----0000  1-------
rs1: --------  ----0000  1-------  --------
imm: 00001111  0000----  --------  --------

0b:  00001111  00000000  10000000  10010011
0x:     0F        00        80        93

ANDI rd=2 rs1=1 imm=0x0AA
op:  --------  --------  -111----  -0010011
rd:  --------  --------  ----0001  0-------
rs1: --------  ----0000  1-------  --------
imm: 00001010  1010----  --------  --------

0b:  00001111  11110000  00000000  00010011
0x:     0A        A0        F1        13
--]]

mem:write_32_le(0, 0x00F00093)
mem:write_32_le(4, 0x0F008093)
mem:write_32_le(8, 0x0AA0F113)
cpu:run()
-- register x1 should be 0x00 00 00 0F (ADDI  0 0x00F -> x1, ADDI x1, 0x0F0 -> x1)
-- register x2 should be 0x00 00 00 AA (ANDI x1 0x0AA -> x2)
cpu:dump_registers()
