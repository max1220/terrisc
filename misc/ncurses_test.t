#!/usr/bin/env terra
terralib.linklibrary("/lib/x86_64-linux-gnu/libncurses.so.5")

local unistd = terralib.includec("unistd.h")
local ncurses = terralib.includec("ncurses.h")

terra test ()
	ncurses.initscr()
	ncurses.mvaddstr(13, 33, "Hello, World!")
	ncurses.refresh()
	unistd.sleep(3)
	ncurses.endwin()
	ncurses.refresh()
	return 0
end

print("running test")
test()
