package.path = package.path .. ';/home/chris/Projects/lua/?.lua'
package.path = package.path .. ';/home/chris/Projects/lua/?/?.lua'

local ffi = require 'ffi'
require 'ffi.req' 'c.pthread'
local pthread = ffi.C	-- luajit could stand to use some encapsulation of its ffi content

-- welp pthread_self is the same for sdlInit, sdlQuit, and update ... what about event?

print'dfc.lua begin'
local dfc = {}

function dfc.sdlInit()
	print(('dfc.sdlInit pthread_self: %x'):format(pthread.pthread_self()))
end

function dfc.sdlQuit()
	print(('dfc.sdlQuit pthread_self: %x'):format(pthread.pthread_self()))
end

--[[
function dfc.update()
	print(('dfc.update pthread_self: %x'):format(pthread.pthread_self()))
end
--]]

function dfc.event(ev)
	print(('dfc.event pthread_self: %x'):format(pthread.pthread_self()))
	return true	-- has to return true
end

print'dfc.lua end'
return dfc
