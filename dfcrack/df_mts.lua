--[[
put your custom metatable code here
--]]
local ffi = require 'ffi'


-- set up Unit metatable
do
	local mt = {}
	mt.__index = mt

	function mt:isDead()
		return self.killed ~= 0
			or self.ghostly ~= 0
	end

	function mt:casteFlagSet(flag, race, caste)
		race = race or self.race
		caste = caste or self.caste
	
		local creature = df::creature_raw::find(race);
		if not creature then return false end

		local craw = vector_get(creature.caste, caste)
		if not craw then return false end

		return bit.band(craw.flags, flag) ~= 0
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
		if self.curse.addTags1.bits.OPPOSED_TO_LIFE ~= 0 then return true end
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
			return false;
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
		if histfig == nil then return false end
		for i,link in ipairs(histfig.entityLinks) do
			if link.entityID == ui.groupID 
			and link:getType() == HistoricalFigureEntityLinkType_MEMBER
			then
				return true
			end
		end
		return false
	end

	ffi.metatype('Unit', mt)
end
