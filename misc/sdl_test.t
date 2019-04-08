#!/usr/bin/env terra
terralib.linklibrary("/usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0")
local stdio = terralib.includec("stdio.h")
local stdlib = terralib.includec("stdlib.h")
local sdl = terralib.includec("SDL2/SDL.h")


terra test(title : &int8, w : uint, h : uint)
	var window : &sdl.SDL_Window
	var screen : &sdl.SDL_Surface
	var rect : sdl.SDL_Rect
	var event : sdl.SDL_Event
	
	var run : uint = 1;
	
	rect.w = 100
	rect.h = 100
	
	sdl.SDL_Init(sdl.SDL_INIT_VIDEO)
	
	window = sdl.SDL_CreateWindow(title, 0,0, w,h, 0)
	
	screen = sdl.SDL_GetWindowSurface(window)
	
	while run ~= 0 do
	
		rect.x = [uint](stdlib.rand()) % (w - 100)
		rect.y = [uint](stdlib.rand()) % (h - 100)
	
		sdl.SDL_FillRect(screen, &rect, [uint32](stdlib.rand()))
		
		sdl.SDL_UpdateWindowSurface(window)
		
		while sdl.SDL_PollEvent(&event) == 1 do
			if event.type == sdl.SDL_QUIT then
				run = 0
			end
		end
		
	end
	
end





terra main(argc : int, argv : &rawstring)
	test("hello world from main", 800, 600)
end


print("generating executable")
terralib.saveobj(
	"terra-sdl_test",
	"executable",
	 { main = main },
	 { "-lSDL2" }
)

print("running test in terra")
test("hello world from terra", 800, 600)
