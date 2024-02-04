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

local haveRunFastDwarf

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
	
	-- wait for the world to be loaded...
	if df.world ~= nil 
	and df.world.map.blockIndex ~= nil
	then
		-- world is loaded
		if not haveRunFastDwarf then
			haveRunFastDwarf = true
			for i,u in ipairs(df.world.units.active) do
				print('unit', i, u, u:isCitizen())
			end
		end
	else
		-- not loaded? clear state flags
		haveRunFastDwarf = false
	end
end

-- make sure jit is on ... i think it is by default, right? looks like it.
print(jit.status())

return dfsim
