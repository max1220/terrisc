#!/usr/local/bin/terra
local mem = require("mem")
local cpu = require("cpu")

local pc_mem = mem.new_64(65536)
print("got memory:", pc_mem)

local pc_cpu = cpu.new_rv64(pc_mem)
print("got cpu:", pc_cpu)




pc_cpu:step()
