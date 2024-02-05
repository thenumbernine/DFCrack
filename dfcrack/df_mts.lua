--[[
put your custom metatable code here
--]]
local ffi = require 'ffi'


-- set up Unit metatable
do
	local mt = {}
	mt.__index = mt

	function mt:isDead()
		assert(self ~= nil, "self is nil")
		return self.killed ~= 0
			or self.ghostly ~= 0
	end

	function mt:isOpposedToLife()
		assert(self ~= nil, "self is nil")
		if self.curse.removeTags1.OPPOSED_TO_LIFE then
			return false
		end
		if self.curse.addTags1.bits.OPPOSED_TO_LIFE then
			return true
		end
		return casteFlagSet(
			self.race,
			self.caste,
			CasteRawFlags_OPPOSED_TO_LIFE
		)
	end


	function mt:isSane()
		assert(self ~= nil, "self is nil")
	
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

	function mt:isCitizen(ignoreSanity)
		assert(self ~= nil, "self is nil")

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

		return self:isOwnGroup(unit)
	end
	ffi.metatype('Unit', mt)
end
