-- this file loads all instruction sets and generates an instruction
-- decoder.

local stdio = terralib.includec("stdio.h")
local stdlib = terralib.includec("stdlib.h")

function new_instruction_decoder(instruction_sets, cpu)
	-- this function creates a function decoder terra function.
	-- instructions are defined by a bitmask, bitpattern and a callback
	-- function. Each instruction subset registers its opcodes in the
	-- register function via the register_instruction function.

	-- lua parsed version of the instructions
	local instructions = {}

	-- used to register instructions
	local function register_instruction(mask, pattern, callback)
		table.insert(instructions, {
			mask = assert(tonumber(mask)),
			pattern = assert(tonumber(pattern)),
			callback = callback
		})
	end

	for _, instruction_set in ipairs(instruction_sets) do
		-- load the actual instruction definitions and functions ...
		-- ... by calling all the subset's register function with the
		-- register_instruction function as argument
		require(instruction_set).register(register_instruction, cpu)
	end
	

	-- a struct for entrys in the instruction definitions used at runtime to
	-- decode instructions
	local struct instruction_table_entry {
		mask : uint32;
		pattern : uint32;
		callback : {uint32} -> {}
	}


	print("=== Creating instruction decoder")

	-- prepare instruction_array, the array containing the instruction
	-- definitions used at runtime to decode instructions
	local instruction_array = terralib.new(instruction_table_entry[#instructions])	
	local terra load_instruction(i : uint, mask : uint32, pattern : uint32, callback : {uint32} -> {})
		-- load an instruction, described by it's mask, pattern and
		-- callback, into the instruction_array
		-- stdio.printf("Adding instruction %.3d to binary cache: mask=%.8x, pattern=%.8x, callback=%p\n",i,mask,pattern,callback)
		var instr : instruction_table_entry
		instr.mask = mask
		instr.pattern = pattern
		instr.callback = callback
		instruction_array[i] = instr
	end
	for i,instr in ipairs(instructions) do
		load_instruction(i-1, instr.mask, instr.pattern, instr.callback)
	end
	
	local instruction_count = #instructions
	local terra decode_instruction(instr : uint32) : {uint32} -> {}
		-- decode an instruction, returning the instruction's
		-- callback if found
		var i = 0
		for i = 0, instruction_count do
			var cinstr = instruction_array[i]
			var masked = instr and cinstr.mask
			if masked == cinstr.pattern then
				-- instruction matched pattern!
				return cinstr.callback
			end
		end
		-- instruction not found!
		return nil
	end

	local instruction_decoder = {
		decode = decode_instruction
	}
	
	return instruction_decoder
end

return {
	new = new_instruction_decoder
}
