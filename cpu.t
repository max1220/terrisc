-- this file implements the registers, and step function for the CPU

local stdio = terralib.includec("stdio.h")
local Instruction_decoder = require("instruction_decoder")

local function new_cpu_rv64(mem)
	local mem = assert(mem)

	local struct cpu_t {
		running : uint8;
		pc : uint64;
	}
	for i=1, 31 do
		table.insert(cpu_t.entries, {"x" .. i, uint64})
	end

	terra cpu_t:init()
		var reg_ptr : &uint64 = &self.pc
		for i=0, 32 do
			reg_ptr[i] = 0
		end
	end

	terra cpu_t:dump_registers()
		-- dump registers to stdout
		stdio.printf("----- registers -----\n")
		stdio.printf("pc:\t0x%.8x\n", self.pc)
		var offset : &uint64 = &self.x1
		for i=0, 31 do
			stdio.printf("x%.2d:\t0x%.8x\n", i+1, @(offset+i))
		end
		stdio.printf("----- end -----\n")
	end
	
	terra cpu_t:set_register(reg_i : uint8, value : uint64)
		-- set the register indicated by reg_i to value
		if reg_i == 0 then
			stdio.printf("Warning: Trying to set register 0!")
		else
			stdio.printf("setting register: %d: %.8x\n", reg_i, value)
			var ptr : &uint64 = &self.pc
			ptr[reg_i] = value
		end
	end

	terra cpu_t:get_register(reg_i : uint8) : uint64
		-- get the register indicated by reg_i
		if reg_i == 0 then
			stdio.printf("getting register: 0 -(always)-> 0\n")
			return 0
		else
			var ptr : &uint64 = &self.pc
			stdio.printf("getting register: %d -> %.8x\n", reg_i, ptr[reg_i])
			return ptr[reg_i]
		end
	end
	

	local cpu = terralib.new(cpu_t)
	cpu:init()
	local instruction_decoder = Instruction_decoder.new({"instructions_RV32I"}, cpu)
	local decode_instr = instruction_decoder.decode
	terra cpu_t:step()
		-- parse & execute a single instruction
		stdio.printf("----- stepping at PC=0x%.8x -----\n", self.pc)
		var instr : uint32 = mem:read_32_le(self.pc)
		var instr_f = decode_instr(instr)
		if instr_f == nil then
			stdio.printf("instruction not found! Stopping...\n")
			self.running = 0
		else
			stdio.printf("instruction found: 0x%.8x --> %p\n", instr, &instr_f)
			instr_f(instr)
			self.pc = self.pc + 4
		end
	end

	terra cpu_t:run()
		-- run in a loop
		stdio.printf("----- running -----\n")
		self.running = 1
		while self.running ~= 0 do
			self:step()
		end
		stdio.printf("----- aborted -----\n")
	end

	
	return cpu
end


return {
	new_rv64 = new_cpu_rv64
}
