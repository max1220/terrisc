-- This file defines and implements the RV32I base instruction set

local stdio = terralib.includec("stdio.h")

local function register(register_instruction, cpu)
	-- this function is with 2 argument, the function
	-- register_instruction, which is to be called with the bitmask,
	-- bitpattern and callback function for each instruction, and
	-- the registers struct array
	
	print("=== Registering RV32I base instruction set")
	
	



	-- [[ Utillity functions ]] --
	
	local function decode_bin_str(str)
		-- decodes a string in the format of "1001????" into a mask and pattern so that ? represents the bits not set in the mask, and 1 or 0 represent their value in the pattern
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
		-- adds an instruction by it's description
		local mask, pattern = decode_bin_str(pattern_str)
		local mask_bin = num_to_bin(mask)
		local pattern_bin = num_to_bin(pattern)
		print(("Adding instruction %-6s to instruction set:\t mask=0x%.8x(0b%s)  pattern=0x%.8x(0b%s)  callback=%s"):format(title, mask,mask_bin, pattern,pattern_bin,tostring(callback:getpointer())))
		register_instruction(mask, pattern, callback:getpointer())
	end



	-- [[ Instruction argument decoders ]] --
	-- these functions should always be inlined
	
	local terra arg_rd(instr : uint32) -- bits 7-11
		return [uint8]((instr >> 7) and 0x1F)
	end
	arg_rd:setinlined(true)

	local terra arg_func3(instr : uint32) -- bits 12-14
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

	local terra arg_func7(instr : uint32) -- bits 25-31
		return [uint8]((instr >> 25) and 0x7f)
	end
	arg_func7:setinlined(true)


	
	-- [[ Instruction immediate argument decoders ]] --
	-- these functions should always be inlined
	
	local terra arg_imm_i(instr : uint32) -- bits 20-31
		return [uint32]((instr >> 20) and 0x0FFF)
	end
	arg_imm_i:setinlined(true)

	local terra arg_imm_s(instr : uint32) -- bits 7-11 as bits 0-4, 25-31 as bits 5-11
		return [uint32](((instr >> 7) and 0x1F) and (instr and (0x7f << 25)))
	end
	arg_imm_s:setinlined(true)
	
	local terra arg_imm_b(instr : uint32) -- bit 7 as bit 11, bits 8-11 as bits 1-4, 25-30 as bits 5-10
		-- bits 8-11 encode bits 1-4
		var imm_1_4 : uint32 = (instr and 0x0F00) << 8
		
		-- bit 7 encodes bit 11
		var imm_11 : uint32 = (instr and 0x80) << 3
		
		-- bits 25-30 encode bits 5-10
		var imm_5_10 : uint32 = (instr and 0x7E000000) >> 20
		
		return imm_1_4 and imm_5_10 and imm_11
	end
	arg_imm_b:setinlined(true)

	local terra arg_imm_u(instr : uint32) -- bits 12-31
		return [uint32]((instr >> 12) and 0x0FFFFF)
	end
	arg_imm_u:setinlined(true)
	
	local terrra arg_imm_sign_extend(instr : uint32, imm : uint32) : int32
		local sign = instr and 0x80000000 -- sign is bit 31
		return [int32](imm or sign) -- TODO: is or the correct operation?
	end
	arg_imm_u:arg_imm_sign_extend(true)
	
	-- [[ Instruction implementation ]] --
	
	add_instruction( "LUI",		"?????????????????????????0110111",
		terra(instr : uint32)
			-- rd, imm_u
			var rd : uint8 = arg_rd(instr)
			var imm : uint32 = arg_imm_u(instr)
			cpu:set_register(rd, imm << 12)
		end
	)
	
	add_instruction( "AUIPC",	"?????????????????????????0010111",
		terra(instr : uint32)
			-- rd, imm_u
		end
	)
	
	add_instruction( "JAL",		"?????????????????????????1101111",
		terra(instr : uint32)
			-- rd, imm_u
		end
	)
	
	add_instruction( "JALR",	"?????????????????000?????1100111",
		terra(instr : uint32)
			-- rd, rs1, imm_i
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

	add_instruction( "ADDI",	"?????????????????000?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr)
			cpu:set_register(rd, cpu:get_register(rs1) + imm)
		end
	)
	
	add_instruction( "SLTI",	"?????????????????010?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			-- TODO: Check sign
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr)
			if cpu:get_register(rs1) < imm then
				cpu:set_register(rd, 1)
			else
				cpu:set_register(rd, 0)
			end
		end
	)
	
	add_instruction( "SLTIU",	"?????????????????011?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			-- TODO: Check sign
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr)
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
			-- TODO: Check sign
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr)
			cpu:set_register(rd, cpu:get_register(rs1) ^ imm)
		end
	)
	
	add_instruction( "ORI",		"?????????????????110?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			-- TODO: Check sign
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr)
			cpu:set_register(rd, cpu:get_register(rs1) or imm)
		end
	)
	
	add_instruction( "ANDI",	"?????????????????111?????0010011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
			-- TODO: Check sign
			var rd : uint8 = arg_rd(instr) -- dest
			var rs1 : uint8 = arg_rs1(instr) -- src
			var imm : uint32 = arg_imm_i(instr)
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
			var sign : bool = (imm and 0x800) == 0
			cpu:set_register(rd, cpu:get_register(rs1) >> imm)
		end
	)
	
	add_instruction( "ADD",		"0000000??????????000?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "SUB",		"0100000??????????000?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "SLL",		"0000000??????????001?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "SLT",		"0000000??????????010?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "SLTU",	"0000000??????????011?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "XOR",		"0000000??????????100?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "SRL",		"0000000??????????101?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "SRA",		"0100000??????????101?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "OR",		"0000000??????????110?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
	add_instruction( "AND",		"0000000??????????111?????0110011",
		terra(instr : uint32)
			-- rd, rs1, imm_i
		end
	)
	
end
return { register = register }
