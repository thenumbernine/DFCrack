--[[
main entry point of the simulation thread
called by the lua state that is run on the simulation thread (callback via SDL_NumJoysticks)
--]]

-- hack to run this standalone and test the xml-gen code
local testXmlGen = ... == 'testxmlgen'

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

local df
if testXmlGen then
	-- here's me working on the xml->luajit port
	df = require 'df.globals'
else
	-- here's the by-hand port of the headers to luajit ...
	df = require 'byhand.globals'

	-- require this after doing the declarations in df
	-- because it itself requires 'byhand.globals'
	require 'byhand.setup-mt-ffi'
end

print('dfcrack df.version', df.version, df.version[0])

local dfsim = {}

local haveRunFastDwarf

local prospector = require 'prospector'
local fastdwarf = require 'fastdwarf'

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
	if df.Maps.isValid() then
		-- world is loaded
		if not haveRunFastDwarf then
			haveRunFastDwarf = true
			
			-- printing dwarf info
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
			
			--fastdwarf{df=df, fast=true, tele=false}
			prospector{df=df}
		end
	else
		-- not loaded? clear state flags
		haveRunFastDwarf = false
	end
end

-- make sure jit is on ... i think it is by default, right? looks like it.
print(jit.status())

return dfsim
