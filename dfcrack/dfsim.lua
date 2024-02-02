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
ffi = require 'ffi'
df = {}
require 'mem'

local dfsim = {}

function dfsim.update()
--[[ debugging
	print(('dfmain.update pthread_self: %x'):format(pthread.pthread_self()))
--]]
	print('version', df.version, df.version[0])
end

return dfsim
