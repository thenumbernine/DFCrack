--[[
put your custom metatable code here.
TODO put this in its own folder somewhere, like dfcrack/mt/
--]]
local ffi = require 'ffi'

-- TODO df.globals instead
local df = require 'mem'

-- CreatureRaw
do
	local mt = {}
	mt.__index = mt

	-- [[ TODO these are in the namespace because of association
	-- but really
	-- really
	-- how hard is it to type df.world[0].raws.creatures.all[id]
	-- or if its hard, then why all these needless namespace structs that are only used once? just flatten them.

	-- static method
	function mt.getVectorPtr()
		-- of type vector_CreatureRaw_ptr 
		return df.world[0].raws.creatures.all
	end

	-- static method
	-- returns ptr to element or nil if oob
	-- hmm but most these vectors are vectors-of-pointers anyways
	-- that means this will need a double-dereference when its valid ...
	function mt.find(id)
		return mt.getVectorPtr():at(id)
	end
	--]]

	df.CreatureRaw = ffi.metatype('CreatureRaw', mt)
end

-- HistoricalFigureEntityLink
do
	local mt = {}
	mt.__index = mt

	df.HistfigEntityLink = ffi.metatype('HistfigEntityLink', mt)
end


-- HistoricalFigure
do
	local mt = {}
	mt.__index = mt

	-- [[ vtable method wrappers
	function mt:getType()
		return mt.vtable.getType(mt)
	end
	--]]
	
	-- static method
	function mt.getVectorPtr()
		-- of type vector_HistoricalFigure_ptr
		return df.world[0].history.figures
	end

	-- static method
	function mt.find(id)
		local vec = mt.getVectorPtr()
		-- TODO binary search
		for i=0,vec:size()-1 do
			local o = vec.v[i]
			if o ~= nil and o[0].id == id then
				return o
			end
		end
	end

	df.HistoricalFigure = ffi.metatype('HistoricalFigure', mt)
end

-- Unit
do
	local mt = {}
	mt.__index = mt

	function mt:isDead()
		return self.killed ~= 0
			or self.ghostly ~= 0
	end

	function mt:casteFlagSet(flag, race, caste)
-- TODO segfaulting
do return false end		
		race = race or self.race
		caste = caste or self.caste
	
		local creature = df.CreatureRaw.find(race);
		-- need explicit nil test to detect null pointer cdata
--print('creature', creature)
		if creature == nil then return false end
--print('creature[0]', creature[0])
		if creature[0] == nil then return false end

--print('creature caste', creature[0].caste)
		local craw = creature[0].caste:at(caste)
--print('craw', craw)		
		if craw == nil then return false end
--print('craw[0]', craw[0])
		if craw[0] == nil then return false end

--print('craw flags', craw[0].flags)
		return bit.band(craw[0].flags, flag) ~= 0
	end

	function mt:isCitizen(ignoreSanity)
		if self.marauder ~= 0
		or self.invaderOrigin ~= 0
		or self.activeInvader ~= 0
		or self.forest ~= 0
		or self.merchant ~= 0
		or self.diplomat ~= 0
		or self.visitor ~= 0
		or self.visitorUninvited ~= 0
		or self.underworld ~= 0
		or self.resident ~= 0
		then
			return false
		end

		if not (ignoreSanity or self:isSane()) then
			return false
		end

		return self:isOwnGroup()
	end

	function mt:isOpposedToLife()
		if self.curse.removeTags1.OPPOSED_TO_LIFE ~= 0 then return false end
		if self.curse.addTags1.OPPOSED_TO_LIFE ~= 0 then return true end
		return self:casteFlagSet(CasteRawFlags_OPPOSED_TO_LIFE)
	end

	function mt:isSane()
		if self:isDead() 
		or self:isOpposedToLife() 
		or self.enemy.undead
		then
			return false
		end

		if self.enemy.normalRace == self.enemy.wereRace
		and self:isCrazed()
		then
			return false
		end
		
		if self.mood == MoodType_Melancholy
		or self.mood == MoodType_Raving
		or self.mood == MoodType_Berserk
		then
			return false
		end

		return true
	end

	function mt:isCrazed()
		if self.scuttle ~= 0 then return false end
		if self.curse.removeTags1.CRAZED ~= 0 then return false end
		if self.curse.addTags1.CRAZED ~= 0 then return true end
		return self:casteFlagSet(CasteRawFlags_CRAZED)
	end

	function mt:isOwnGroup()
		local histfig = df.HistoricalFigure.find(unit.historicFigureID);
		if histfig == nil or histfig[0] == nil then return false end
		for i,link in ipairs(histfig[0].entityLinks) do
			if link.entityID == ui.groupID 
			and link:getType() == HistfigEntityLinkType_MEMBER
			then
				return true
			end
		end
		return false
	end

	df.Unit = ffi.metatype('Unit', mt)
end

-- get metatypes here or just from the ffi.typeof(name)
return df
