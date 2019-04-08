#!/usr/bin/env terra

local instruction = require("instructions")
local decoder = instruction.new({"instructions_RV32I"})

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

local function bin_to_num(bin_str)
	local num = 0
	for i=1, 32 do
		local p = 2^(i-1)
		local c = bin_str:sub(i,i)
		if c == "0" then
			
		elseif c == "1" then
			num = bit.band(num, p)
		else
			error("Invalid char:".. tostring(c))
		end
	end
	return num
end

local function test_instr(instr)
	local instr_bin = num_to_bin(instr)
	local instr_f = decoder.decode(instr)
	if instr_f == nil then
		print(("test_instr: not found: instruction 0x%.8x (0b%s)"):format(instr, instr_bin))
	else
		print(("test_instr: found:     instruction 0x%.8x (0b%s) --> %s"):format(instr, instr_bin, tostring(instr_f)))
		instr_f(instr)
	end
end




print("=== TEST")
for i=0, 0x7FFF do
	test_instr(i)
end

print("=== TEST 2")
test_instr(0x37)
test_instr(0x17)
test_instr(0x6f)
test_instr(0x67)
test_instr(0x13)

