local stdlib = terralib.includec("stdlib.h")
local stdio = terralib.includec("stdio.h")


local function new_memory_64(size)
	local size = assert(tonumber(size))

	local struct mem_t {
		size : uint;
		ptr : &uint8;
	}

	terra mem_t:init()
		var memptr : &uint8= [&uint8](stdlib.malloc(size))
		var i : uint
		for i=0, size do
			memptr[i] = 0x00
		end
		self.ptr = memptr
		self.size = size
	end



	terra mem_t:read_8(pos : uint64)
		var val : uint8 = self.ptr[pos]
		--stdio.printf("reading byte at pos: 0x%.8X: %.2x\n", pos, val)
		return val
	end

	terra mem_t:write_8(pos : uint64, val : uint8)
		--stdio.printf("writing byte at pos: 0x%.8X: %.2x\n", pos, val)
		self.ptr[pos] = val
	end

	terra mem_t:write_8_ptr(pos : uint64, val : &uint8, len : uint64)
		--stdio.printf("writing %d bytes, starting at pos: 0x%.8X: %.2x\n", pos, val)
		var i : uint
		for i=0, len do
			self.ptr[pos+i] = val[i]
		end
	end



	-- 16bit

	terra mem_t:read_16_be(pos : uint64)
		var val_a : uint8 = self.ptr[pos]
		var val_b : uint8 = self.ptr[pos+1]
		var val : uint16 = [uint16](val_a) and [uint16](val_b << 8)
		--stdio.printf("reading be word at pos: 0x%.8X: %.4x\n", pos, val)
	end

	terra mem_t:write_16_be(pos : uint64, val : uint16)
		--stdio.printf("writing be word at pos: 0x%.8X: %.4x\n", pos, val)
		var val_a : uint8 = val and 0xFF
		var val_b : uint8 = (val >> 8) and 0xFF
		self.ptr[pos] = val_b
		self.ptr[pos+1] = val_a
	end

	terra mem_t:read_16_le(pos : uint64)
		var val_a : uint8 = self.ptr[pos]
		var val_b : uint8 = self.ptr[pos+1]
		var val : uint16 = [uint16](val_b) and ([uint16](val_a) << 8)
		--stdio.printf("reading be word at pos: 0x%.8X: %.4x\n", pos, val)
		return val
	end

	terra mem_t:write_16_le(pos : uint64, val : uint16)
		--stdio.printf("writing be word at pos: 0x%.8X: %.4x\n", pos, val)
		var val_a : uint8 = val and 0xFF
		var val_b : uint8 = (val >> 8) and 0xFF
		self.ptr[pos] = val_a
		self.ptr[pos+1] = val_b
	end



	-- 32bit

	terra mem_t:read_32_be(pos : uint64) : uint32
		var val_a : uint8 = self.ptr[pos]
		var val_b : uint8 = self.ptr[pos+1]
		var val_c : uint8 = self.ptr[pos+2]
		var val_d : uint8 = self.ptr[pos+3]
		var val : uint32 = [uint32](val_d) and ([uint32](val_c) << 8) and ([uint32](val_b) << 16) and ([uint32](val_a) << 24)
		--stdio.printf("reading be dword at pos: 0x%.8X: %.8x\n", pos, val)
	end

	terra mem_t:write_32_be(pos : uint64, val : uint32)
		--stdio.printf("writing be dword at pos: 0x%.8X: %.8x\n", pos, val)
		var val_a : uint8 = val and 0xFF
		var val_b : uint8 = (val >> 8) and 0xFF
		var val_c : uint8 = (val >> 16) and 0xFF
		var val_d : uint8 = (val >> 24) and 0xFF
		self.ptr[pos] = val_d
		self.ptr[pos+1] = val_c
		self.ptr[pos+2] = val_b
		self.ptr[pos+3] = val_a
	end

	terra mem_t:read_32_le(pos : uint64) : uint32
		var val_a : uint8 = self.ptr[pos]
		var val_b : uint8 = self.ptr[pos+1]
		var val_c : uint8 = self.ptr[pos+2]
		var val_d : uint8 = self.ptr[pos+3]
		var val : uint32 = [uint32](val_a) + ([uint32](val_b) << 8) + ([uint32](val_c) << 16) + ([uint32](val_d) << 24)
		--stdio.printf("reading be dword at pos: 0x%.8X: %.8x\n", pos, val)
		
		return val
	end

	terra mem_t:write_32_le(pos : uint64, val : uint32)
		--stdio.printf("writing be dword at pos: 0x%.8X: %.2x\n", pos, val)
		var val_a : uint8 = val and 0xFF
		var val_b : uint8 = (val >> 8) and 0xFF
		var val_c : uint8 = (val >> 16) and 0xFF
		var val_d : uint8 = (val >> 24) and 0xFF
		self.ptr[pos] = val_a
		self.ptr[pos+1] = val_b
		self.ptr[pos+2] = val_c
		self.ptr[pos+3] = val_d
	end

	local mem = terralib.new(mem_t)
	mem:init()
	return mem, mem_t
end

return {
	new_64 = new_memory_64
}
