-- this file implements the registers, and step function for the CPU

local stdio = terralib.includec("stdio.h")
local mem_t = require("mem_new")
local Instruction_decoder = require("instruction_decoder")
local logf = stdio.printf


-- the struct that will hold all information about the state of the cpu

local instr_cb_t : {uint32} -> {}

local struct cpu_t {
	running : uint8;
	pc : uint64;
	mem : mem_t;
	decode_instr : {uint32} -> instr_cb_t;
}


-- append 31(yes, this is correct, not 32) registers to the cpu_t definition.
for i=1, 31 do
	table.insert(cpu_t.entries, {"x" .. i, uint64})
end


terra cpu_t:dump_registers()
	-- dump registers to stdout
	logf("----- registers -----\n")
	logf("pc:\t0x%.8x\n", self.pc)
	var offset : &uint64 = &self.x1
	for i=0, 31 do
		logf("x%.2d:\t0x%.8x\n", i+1, @(offset+i))
	end
	logf("----- end -----\n")
end

terra cpu_t:set_register(reg_i : uint8, value : uint64)
	-- set the register indicated by reg_i to value
	-- TODO: I guess this should always be inlined?
	if reg_i == 0 then
		logf("Warning: Trying to set register 0!")
	else
		logf("setting register: %d: %.8x\n", reg_i, value)
		var ptr : &uint64 = &self.pc
		ptr[reg_i] = value
	end
end

terra cpu_t:get_register(reg_i : uint8) : uint64
	-- get the register indicated by reg_i
	-- TODO: I guess this should always be inlined?
	if reg_i == 0 then
		stdio.printf("getting register: 0 -(always)-> 0\n")
		return 0
	else
		var ptr : &uint64 = &self.pc
		stdio.printf("getting register: %d -> %.8x\n", reg_i, ptr[reg_i])
		return ptr[reg_i]
	end
end

terra cpu_t:get_pc() : uint64
	-- get the program counter value
	-- TODO: I guess this should always be inlined?
	return self.pc
end

terra cpu_t:set_pc(new_pc : uint64)
	-- set the program counter to a value
	-- TODO: Great performance gains can be archived by JITing, this would
	-- require creating a list of jump targets.
	-- TODO: I guess this should always be inlined?
	self.pc = new_pc
end


-- parse & execute a single instruction
terra cpu_t:step()
	logf("----- stepping at PC=0x%.8x -----\n", self.pc)
	var instr : uint32 = self.mem:read_32_le(self.pc)
	var instr_f : {uint32} -> {} = self.decode_instr(instr)
	
	if instr_f == nil then
		logf("instruction not found! Stopping...\n")
		self.running = 0
	else
		instr_f(instr)
		self.pc = self.pc + 4
		logf("instruction found: 0x%.8x --> %p\n", instr, &instr_f)
	end
	
end


-- run until stopped internally or externally
terra cpu_t:run()
	logf("----- running -----\n")
	self.running = 1
	while self.running ~= 0 do
		self:step()
	end
	logf("----- aborted -----\n")
end


-- initialize an instance of cpu_t, making it ready to run(terra part)
terra cpu_t:init()
	logf("Initializing CPU")
	self.pc = 0
	var reg_ptr : &uint64 = &self.x1

	-- this should be equivalent of: self.pc = 0, self.x1 = 0, self.x2 = 0 (...) self.x31 = 0
	for i=0, 31 do
		reg_ptr[i] = 0
	end
end













return {
	cpu_t = cpu_t
}
