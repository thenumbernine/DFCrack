--[[
main entry point
called by the lua state that is run on the simulation thread (callback via SDL_NumJoysticks)
--]]

--[[ debugging
local ffi = require 'ffi'
require 'ffi.req' 'c.pthread'
local pthread = ffi.C
--]]

-- TODO clean this up
local df = require 'mem'

local dfsim = {}

function dfsim.update()
--[[ debugging -- verify thread
	print(('dfmain.update pthread_self: %x'):format(pthread.pthread_self()))
--]]
	-- works
--	print('version', df.version, df.version[0])
	-- works
--	print('cursor', df.cursor[0])

--[[ TODO monitor a file for timestamp, something like 'exec-sim.lua'
-- and upon timestamp update, read and execute its contents
--]]

end

-- make sure jit is on ... i think it is by default, right? looks like it.
print(jit.status())

return dfsim
