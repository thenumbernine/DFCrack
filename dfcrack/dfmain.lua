-- or better TODO put this in the run-dfcrack.sh
-- or better TODO move what libs I use into the dfcrack folder
package.path = package.path .. ';/home/chris/Projects/lua/?.lua'
package.path = package.path .. ';/home/chris/Projects/lua/?/?.lua'

local ffi = require 'ffi'
require 'ffi.req' 'c.pthread'
local pthread = ffi.C	-- luajit could stand to use some encapsulation of its ffi content

print'dfmain.lua begin'
local dfmain = {}

function dfmain.sdlInit()
	print(('dfmain.sdlInit pthread_self: %x'):format(pthread.pthread_self()))
end

function dfmain.sdlQuit()
	print(('dfmain.sdlQuit pthread_self: %x'):format(pthread.pthread_self()))
end

function dfmain.sdlEvent(ev)
	print(('dfmain.sdlEvent pthread_self: %x'):format(pthread.pthread_self()))
	return true	-- has to return true
end

print'dfmain.lua end'
return dfmain
