local cpu_t = require("cpu_new")
local mem_t = require("mem_new")


local mem = terralib.new(mem_t)
mem:init(1024*1024) -- 8 mebibit

local cpu = terralib.new(cpu_t)
cpu:init()
