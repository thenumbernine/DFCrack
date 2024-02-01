--[[
main entry point
called by the lua state that is run on the simulation thread (callback via SDL_NumJoysticks)
--]]
local codegen = require 'codegen'

--[[ debugging
local ffi = require 'ffi'
require 'ffi.req' 'c.pthread'
local pthread = ffi.C
--]]

local dfsim = {}

function dfsim.update()
--[[ debugging
	print(('dfmain.update pthread_self: %x'):format(pthread.pthread_self()))
--]]
end

return dfsim
