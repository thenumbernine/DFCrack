--[[
main entry point
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
local df = require 'mem'

-- require this after doing the declarations in df
-- since some metatables will go looking in df
require 'df_mts'

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
				print('unit',
					i,
					u,

					'is citizen?', u:isCitizen(),
					
					-- did I have Lua bool rw worked out for bitfields in my ff6 hacking project?
					
					"if any are set then we're not a citizen",
					u.marauder ~= 0,
					u.invaderOrigin ~= 0,
					u.activeInvader ~= 0,
					u.activeInvader ~= 0,
					u.forest ~= 0,
					u.merchant ~= 0,
					u.diplomat ~= 0,
					u.visitor ~= 0,
					u.visitorUninvited ~= 0,
					u.underworld ~= 0,
					u.resident ~= 0,

					"isSane?", u:isSane(),
					"isDead?", u:isDead(),
					"isOpposedToLife?", u:isOpposedToLife(),
					"curse.removeTags1.OPPOSED_TO_LIFE", u.curse.removeTags1.OPPOSED_TO_LIFE ~= 0,
					"curse.addTags1.OPPOSED_TO_LIFE", u.curse.addTags1.OPPOSED_TO_LIFE ~= 0,
					"casteFlagSet(CasteRawFlags_OPPOSED_TO_LIFE)", u:casteFlagSet(ffi.C.CasteRawFlags_OPPOSED_TO_LIFE),
					"enemy.undead", u.enemy.undead,
					"enemy.normalRace", u.enemy.normalRace,
					"enemy.wereRace", u.enemy.wereRace,
					"isCrazed?", u:isCrazed(),
					"scuttle", u.scuttle,
					"curse.removeTags1.CRAZED", u.curse.removeTags1.CRAZED ~= 0,
					"curse.addTags1.CRAZED", u.curse.addTags1.CRAZED ~= 0,
					"casteFlagSet(ffi.C.CasteRawFlags_CRAZED)", u:casteFlagSet(ffi.C.CasteRawFlags_CRAZED),
					"mood", u.mood,
					"isOwnGroup?", u:isOwnGroup(),
					"histFigureID", u.histFigureID,
					"histfig", df.HistoricalFigure.find(u.histFigureID)
				)
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
