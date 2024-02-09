--[[
main entry point of the simulation thread
called by the lua state that is run on the simulation thread (callback via SDL_NumJoysticks)
--]]

--[[ debugging
local ffi = require 'ffi'
require 'ffi.req' 'c.pthread'
local pthread = ffi.C
--]]

-- [[ TODO this as require()'s in the generated code
local ffi = require 'ffi'
ffi.cdef[[
typedef struct df_flagarray {
	uint8_t * bits;
	size_t size;
} df_flagarray;
]]
--]]

-- [[ here's the by-hand port of the headers to luajit ...
local df = require 'byhand.globals'

-- require this after doing the declarations in df
-- because it itself requires 'byhand.globals'
require 'byhand.setup-mt-ffi'

--]]
--[[ here's me working on the xml->luajit port
local df = require 'df.globals'
--]]

print('dfcrack df.version', df.version, df.version[0])

local dfsim = {}

local haveRunFastDwarf

function dfsim.update()
--[[ debugging -- verify thread
	print(('dfmain.update pthread_self: %x'):format(pthread.pthread_self()))
--]]
	-- works
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
				-- can we guarantee that everything in .active is ... active?
				assert(u ~= nil)
				if u.name.words[0] ~= -1 then
					print('unit',
						i,
						'isCitizen?', u:isCitizen(),
						'isAlive?', u:isAlive(),
						u.name:translate(false, false),	-- dwarven
						u.name:translate(true, false),	-- english
						u.name:translate(false, true),	-- dwarven last
						u.name:translate(true, true)	-- english last
					)
				end
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
