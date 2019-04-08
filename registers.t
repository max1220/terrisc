local stdlib = terralib.includec("stdlib.h")
local stdio = terralib.includec("stdio.h")


local function new_registers_64()

	-- this struct will hold all the register values
	local struct registers_t {
		pc : uint64;
	}
	
	-- add the actual register uints to the struct
	-- note that register 0 does not exist. This is intentional:
	-- register 0 is hard-wired to 0
	for i=1, 31 do
		table.insert(cpu_t.entries, {"x" .. i, uint64})
	end

	terra registers_t:init()
		-- all registers are initialized to 0
		local start_ptr : &uint64
		for i=0, 33 do
			start_ptr[i] = 0
		end
	end

	terra registers_t:set_register(reg_i : uint8, value : uint64)
		-- set the register indicated by reg_i to value
		if reg_i == 0 then
			stdio.printf("Warning: Trying to set register 0!")
		else
			stdio.printf("setting register: %d: %.8x\n", reg_i, value)
			var ptr : &uint64 = self.pc
			ptr[reg_i] = value
		end
	end

	terra registers_t:get_register(reg_i : uint8) : uint64
		-- get the register indicated by reg_i
		if reg_i == 0 then
			return 0
		else
			stdio.printf("getting register: %d -> %.8x\n", reg_i, value)
			var ptr : &uint64 = self.pc
			return ptr[reg_i]
		end
	end

	local registers = terralib.new(registers_t)
	registers:init()
	return registers
end

return {
	new_64 = new_registers_64
}
