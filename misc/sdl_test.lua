#!/usr/bin/env luajit


local ffi = require("ffi")
local sdl = require("sdl2")


function test(w,h,title)
	
	
	local rect = ffi.typeof("SDL_Rect")({ x = 0, y = 0, w = 100, h = 100 })
	local event = ffi.typeof("SDL_Event")()
	
	local run = true
	
	
	
	
	sdl.init(sdl.INIT_VIDEO)
	
	window = sdl.createWindow(title, 0,0, w,h, 0)
	
	screen = sdl.getWindowSurface(window)
	
	while run do
	
		rect.x = math.random(0, w-100)
		rect.y = math.random(0, h-100)
	
		sdl.fillRect(screen, rect, math.random(0, 0xFFFFFF))
		
		sdl.updateWindowSurface(window)
		
		while sdl.pollEvent(event) == 1 do
			if event.type == sdl.QUIT then
				run = false
			end
		end
		
	end
	
end


test(800,600, "hello world")
