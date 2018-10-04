-- This file defines and implements the RV32I base instruction set
-- based on RISC-V v2.2 (https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf)

-- I recommend a text editor with code folding support, as this file is quite
-- long(not only because it contains lots of excerpts from the RISC-V spec).

local stdio = terralib.includec("stdio.h")
-- TODO: Remove this dependency

local function register(register_instruction, cpu)
	-- this function is with called with 2 argument, the function
	-- register_instruction, which is to be called with the bitmask,
	-- bitpattern and callback function for each instruction, and
	-- the cpu_t struct the instructions act on.

	print("=== Registering RV32I base instruction set")





	-- [[ Utillity functions ]] --

	local function decode_bin_str(str)
		-- decodes a string in the format of "1001????" into a mask and
		-- pattern so that ? represents the bits not set in the mask,
		-- and 1 or 0 represent their value in the pattern
		assert(#str == 32, "Bad lenght")
		local str = str:reverse()
		local mask = 0xFFFFFFFF
		local pattern = 0
		for i=1, #str do
			local char = str:sub(i,i)
			local cp = 2^(i-1)
			if char == "1" then
				-- set bit in pattern
				pattern = pattern + cp
			elseif char == "0" then
				-- ignored
			elseif char == "?" then
				-- unset bit in mask
				mask = mask - cp
			else
				error("Unknown char in binary: '".. tostring(char) .. "'")
			end
		end
		return mask, pattern
	end


	local function num_to_bin(num)
		-- converts a number to a string of 32 1's and 0's.
		local ret = {}
		for i=1, 32 do
			local p = 2^(i-1)
			local bit = (bit.band(num, p) ~= 0)
			if bit then
				table.insert(ret, "1")
			else
				table.insert(ret, "0")
			end
		end
		return table.concat(ret):reverse()
	end


	local function add_instruction(title, pattern_str, callback)
		-- This convenience-function adds an instruction by it's
		-- title (ignored for now), the bitmask and bitpattern (encoded in the
		-- pattern_str), and the callback function that implements the
		-- instruction
		local mask, pattern = decode_bin_str(pattern_str)
		local mask_bin = num_to_bin(mask)
		local pattern_bin = num_to_bin(pattern)
		print(("Adding instruction %-6s to instruction set:\t mask=0x%.8x(0b%s)  pattern=0x%.8x(0b%s)  callback=%s"):format(title, mask,mask_bin, pattern,pattern_bin,tostring(callback:getpointer())))
		register_instruction(mask, pattern, callback:getpointer())
	end



	-- [[ Instruction argument decoders ]] --
	--[[
		The instructions use these functions to get their arguments from
		the instruction opcode. Because they are used in almost all
		instructions, they are performance-critical, and should always
		be inlined.
		TODO: write test cases for all of these, including test cases for
		sign-extension
	]]


	local terra arg_rd(instr : uint32) -- bits 7-11
		return [uint8]((instr >> 7) and 0x1F)
	end
	arg_rd:setinlined(true)

	local terra arg_func3(instr : uint32) -- bits 12-14, usually bit-matched in instruction
		return [uint8]((instr >> 12) and 0x03)
	end
	arg_func3:setinlined(true)

	local terra arg_rs1(instr : uint32) -- bits 15-19
		return [uint8]((instr >> 15) and 0x1F)
	end
	arg_rs1:setinlined(true)

	local terra arg_rs2(instr : uint32) -- bits 20-24
		return [uint8]((instr >> 20) and 0x1F)
	end
	arg_rs2:setinlined(true)

	local terra arg_func7(instr : uint32) -- bits 25-31, usually bit-matched in instruction
		return [uint8]((instr >> 25) and 0x7f)
	end
	arg_func7:setinlined(true)



	-- [[ Instruction immediate argument decoders ]] --
	--[[
		The instructions use these functions to get the immediate argument value
		from the instruction opcode. Because they are used in almost all
		instructions, they are performance-critical, and should always
		be inlined.
		TODO: write test cases for all of these, including test cases for
		sign-extension
	]]

	local terra arg_imm_i(instr : uint32) -- bits 20-31 as bits 0-11
		return [uint32]((instr >> 20) and 0x0FFF)
	end
	arg_imm_i:setinlined(true)

	local terra arg_imm_s(instr : uint32) -- bits 7-11 as bits 0-4, 25-31 as bits 5-11
		return [uint32](((instr >> 7) and 0x1F) and (instr and (0x7f << 25)))
	end
	arg_imm_s:setinlined(true)

	local terra arg_imm_b(instr : uint32) -- bit 7 as bit 11, bits 8-11 as bits 1-4, 25-30 as bits 5-10
		-- bits 8-11 encode bits 1-4
		var imm_1_4 : uint32 = (instr and 0x0F00) >> 7

		-- bit 7 encodes bit 11
		var imm_11 : uint32 = (instr and 0x80) << 4

		-- bits 25-30 encode bits 5-10
		var imm_5_10 : uint32 = (instr and 0x7E000000) >> 20

		return imm_1_4 and imm_5_10 and imm_11
	end
	arg_imm_b:setinlined(true)

	local terra arg_imm_u(instr : uint32) -- bits 12-31 as bits 12-31
		return [uint32](instr and 0xFFFFF000)
	end
	arg_imm_u:setinlined(true)

	local terra arg_imm_j(instr : uint32)
		-- bits 12-19 as bits 12-19
		var imm_12_19 : uint32 = (instr and 0x000FF000)

		-- bit 20 as bit 11
		var imm_11 : uint32 = (instr and 0x00100000) >> 9

		-- bits 21-30 as bits 1-10
		var imm_1_10 : uint32 = (instr and 0x7FE00000) >> 20

		-- bit 31 as bit 20
		var imm_20 : uint32 = (instr and 0xFF000000) >> 11

		return [uint32](imm_1_10 or imm_11 or imm_12_19  or imm_20)
	end
	arg_imm_j:setinlined(true)

	local terra arg_imm_sign_extend(instr : uint32, imm : uint32) : int32
		-- convert the unsigned imm to a signed imm, by copying bit 31,
		-- the sign bit to the imm.
		var sign = instr and 0x80000000 -- sign is bit 31
		return [int32](imm or sign) -- TODO: is or the correct operation?
	end
	arg_imm_sign_extend:setinlined(true)





	-- [[ Instruction implementation ]] --
	--[[
		In the risc-v spec v2.2 pdf, the desciption this is based on
		starts on page 22 and 115.

		Each of the chapters there is implemented below. A comment at
		the start of each segment in this file should contain an excerpt
		from the spec, outlining what the instruction should do.
	]]



	--[[
		 Integer Computational Instructions, Register-Immediate Instructions
		 (from page 25)
		 LUI, AUIPC, ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
	]]

	--[[
		 ADDI adds the sign-extended 12-bit immediate to register rs1.
		 Arithmetic overflow is ignored and the result is simply the low XLEN
		 bits of the result. ADDI rd, rs1, 0 is used to implement the
		 MV rd, rs1 assembler pseudo-instruction.
		 SLTI (set less than immediate) places the value 1 in register rd if
		 register rs1 is less than the signextended immediate when both are
		 treated as signed numbers, else 0 is written to rd. SLTIU is similar
		 but compares the values as unsigned numbers (i.e., the immediate is
		 first sign-extended to XLEN bits then treated as an unsigned number).
		 Note, SLTIU rd, rs1, 1 sets rd to 1 if rs1 equals zero, otherwise sets
		 rd to 0 (assembler pseudo-op SEQZ rd, rs).
		 ANDI, ORI, XORI are logical operations that perform bitwise AND, OR,
		 and XOR on register rs1 and the sign-extended 12-bit immediate and
		 place the result in rd. Note, XORI rd, rs1, -1 performs a bitwise
		 logical inversion of register rs1 (assembler pseudo-instruction
		 NOT rd, rs).
		 Shifts by a constant are encoded as a specialization of the I-type
		 format. The operand to be shifted is in rs1, and the shift amount is
		 encoded in the lower 5 bits of the I-immediate field. The right shift
		 type is encoded in a high bit of the I-immediate. SLLI is a logical
		 left shift (zeros are shifted into the lower bits); SRLI is a logical
		 right shift (zeros are shifted into the upper bits); and SRAI is an
		 arithmetic right shift (the original sign bit is copied into the
		 vacated upper bits).
	]]

	add_instruction( "LUI",		"?????????????????????????0110111",
		terra(instr : uint32)
			-- rd, imm_u
			var rd : uint8 = arg_rd(instr)
			var imm : uint32 = arg_imm_u(instr)
			cpu:set_register(rd, imm)
		end
	)

	add_instruction( "AUIPC",	"?????????????????????????0010111",
		terra(instr : uint32)
			-- rd, imm_u
			var rd : uint8 = arg_rd(instr)
			var imm : uint32 = arg_imm_u(instr)
			cpu:set_register(rd, imm + cpu.pc)
		end
	)

	add_instruction( "ADDI",	"?????????????????000?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : int32 = arg_imm_sign_extend(instr, arg_imm_i(instr)) -- sign-extend i-imm
			cpu:set_register(rd, cpu:get_register(rs1) + imm)
		end
	)

	add_instruction( "SLTI",	"?????????????????010?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : int32 = arg_imm_sign_extend(instr, arg_imm_i(instr)) -- sign-extend i-imm
			if [int64](cpu:get_register(rs1)) < imm then
				cpu:set_register(rd, 1)
			else
				cpu:set_register(rd, 0)
			end
		end
	)

	add_instruction( "SLTIU",	"?????????????????011?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_sign_extend(instr, arg_imm_i(instr)) -- sign-extend i-imm as uint
			if cpu:get_register(rs1) < imm then
				cpu:set_register(rd, 1)
			else
				cpu:set_register(rd, 0)
			end
		end
	)

	add_instruction( "XORI",	"?????????????????100?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : int32 = arg_imm_sign_extend(instr, arg_imm_i(instr)) -- sign-extend i-imm
			cpu:set_register(rd, cpu:get_register(rs1) ^ imm)
		end
	)

	add_instruction( "ORI",		"?????????????????110?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : int32 = arg_imm_sign_extend(instr, arg_imm_i(instr)) -- sign-extend i-imm
			cpu:set_register(rd, cpu:get_register(rs1) or imm)
		end
	)

	add_instruction( "ANDI",	"?????????????????111?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : int32 = arg_imm_sign_extend(instr, arg_imm_i(instr)) -- sign-extend i-imm
			cpu:set_register(rd, cpu:get_register(rs1) and imm)
		end
	)


	add_instruction( "SLLI",	"0000000??????????001?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr) and 0x1F
			cpu:set_register(rd, cpu:get_register(rs1) << imm)
		end
	)

	add_instruction( "SRLI",	"0000000??????????101?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr) and 0x1F
			cpu:set_register(rd, cpu:get_register(rs1) >> imm)
		end
	)

	add_instruction( "SRAI",	"0100000??????????101?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr) and 0x1F
			if (instr and 0x80000000) == 0 then
				cpu:set_register(rd, cpu:get_register(rs1) >> imm)
			else
				-- copy sign bit
				cpu:set_register(rd, (cpu:get_register(rs1) >> imm) or 0x80000000)
			end
		end
	)


	--[[
		Control Transfer Instructions, Unconditional Jumps
		JAL, JALR
		(from page 27)

		The jump and link (JAL) instruction uses the J-type format, where the
		J-immediate encodes a signed offset in multiples of 2 bytes. The offset
		is sign-extended and added to the pc to form the jump target address.
		Jumps can therefore target a ±1 MiB range. JAL stores the address of the
		instruction following the jump (pc+4) into register rd.
		The indirect jump instruction JALR (jump and link register) uses the
		I-type encoding. The target address is obtained by adding the 12-bit
		signed I-immediate to the register rs1, then setting the
		least-significant bit of the result to zero. The address of the
		instruction following the jump (pc+4) is written to register rd.
	]]



	add_instruction( "JAL",		"?????????????????????????1101111",
		terra(instr : uint32)
			-- rd, imm_j
			var rd : uint8 = arg_rd(instr)
			var imm : int32 = arg_imm_sign_extend(instr, arg_imm_j(instr))
			var cur_pc : uint64 = cpu:get_pc()
			cpu:set_register(rd, cur_pc + 4)
			cpu:set_pc(cur_pc + imm)
		end
	)

	add_instruction( "JALR",	"?????????????????000?????1100111",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : int32 = arg_imm_sign_extend(instr, arg_imm_i(instr)) -- sign-extend i-imm
			var target : uint64 = ((cpu:get_register(rs1) + imm) or 1) not 1 -- target is rs1 + imm with the LSB removed
			var cur_pc : uint64 = cpu:get_pc()
			cpu:set_register(rd, cur_pc + 4)
			cpu:set_pc(target)
		end
	)

	add_instruction( "BEQ",		"?????????????????000?????1100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_b
		end
	)

	add_instruction( "BNE",		"?????????????????001?????1100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_b
		end
	)

	add_instruction( "BLT",		"?????????????????100?????1100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_b
		end
	)

	add_instruction( "BGE",		"?????????????????101?????1100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_b
		end
	)

	add_instruction( "BLTU",	"?????????????????110?????1100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_b
		end
	)

	add_instruction( "BGEU",	"?????????????????111?????1100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_b
		end
	)

	add_instruction( "LB",		"?????????????????000?????0000011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)

	add_instruction( "LH",		"?????????????????001?????0000011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)

	add_instruction( "LW",		"?????????????????010?????0000011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)

	add_instruction( "LBU",		"?????????????????100?????0000011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)

	add_instruction( "LHU",		"?????????????????101?????0000011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)

	add_instruction( "SB",		"?????????????????000?????0100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_s
		end
	)

	add_instruction( "SH",		"?????????????????001?????0100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_s
		end
	)

	add_instruction( "SW",		"?????????????????010?????0100011",
		terra(instr : uint32)
			-- rs1, rs2, imm_s
		end
	)












	--[[
		Integer Computational Instructions, Register-Register Operations
		(from page 22)
		ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
	]]

	--[[
		ADD and SUB perform addition and subtraction respectively. Overflows
		are ignored and the low XLEN bits of results are written to the
		destination. SLT and SLTU perform signed and unsigned compares
		respectively, writing 1 to rd if rs1 < rs2, 0 otherwise. Note,
		SLTU rd, x0, rs2 sets rd to 1 if rs2 is not equal to zero, otherwise
		sets rd to zero (assembler pseudo-op SNEZ rd, rs). AND, OR, and XOR
		perform bitwise logical operations. SLL, SRL, and SRA perform
		logical left, logical right, and arithmetic right shifts on the
		value in register rs1 by the shift amount held in the lower 5 bits
		of register rs2.
	]]

	add_instruction( "ADD",		"0000000??????????000?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			cpu:set_register(rd, cpu:get_register(rs1) + cpu:get_register(rs2))
		end
	)

	add_instruction( "SUB",		"0100000??????????000?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			cpu:set_register(rd, cpu:get_register(rs1) - cpu:get_register(rs2))
		end
	)

	add_instruction( "SLL",		"0000000??????????001?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			cpu:set_register(rd, cpu:get_register(rs1) << cpu:get_register(rs2) and 0x1F)
		end
	)

	add_instruction( "SLT",		"0000000??????????010?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			if [int64](cpu:get_register(rs1)) < [int64](cpu:get_register(rs2)) then
				cpu:set_register(rd, 1)
			else
				cpu:set_register(rd, 0)
			end
		end
	)

	add_instruction( "SLTU",	"0000000??????????011?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			if cpu:get_register(rs1) < cpu:get_register(rs2) then
				cpu:set_register(rd, 1)
			else
				cpu:set_register(rd, 0)
			end
		end
	)

	add_instruction( "XOR",		"0000000??????????100?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			cpu:set_register(rd, cpu:get_register(rs1) ^ cpu:get_register(rs2))
		end
	)

	add_instruction( "SRL",		"0000000??????????101?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			cpu:set_register(rd, cpu:get_register(rs1) >> cpu:get_register(rs2) and 0x1F)
		end
	)

	add_instruction( "SRA",		"0100000??????????101?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			if (cpu:get_register(rs1) and 0x8000000000000000) == 0 then
				cpu:set_register(rd, cpu:get_register(rs1) >> (cpu:get_register(rs2) and 0x1F))
			else
				-- copy sign bit
				cpu:set_register(rd, (cpu:get_register(rs1) >> (cpu:get_register(rs2) and 0x1F)) or [uint64](1)<<63)
			end

		end
	)

	add_instruction( "OR",		"0000000??????????110?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			cpu:set_register(rd, cpu:get_register(rs1) or cpu:get_register(rs2))
		end
	)

	add_instruction( "AND",		"0000000??????????111?????0110011",
		terra(instr : uint32)
			-- rd, rs1, rs2
			var rd : uint8 = arg_rd(instr)
			var rs1 : uint8 = arg_rs1(instr)
			var rs2 : uint8 = arg_rs2(instr)
			cpu:set_register(rd, cpu:get_register(rs1) and cpu:get_register(rs2))
		end
	)

end
return { register = register }
