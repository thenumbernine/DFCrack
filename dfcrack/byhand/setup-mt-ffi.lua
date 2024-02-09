--[[
put your custom metatable code here.
TODO later I will split this up per-type and put them in dfcrack/byhand/mt/*
and then once I convert dfcrack/byhand/types.lua to use struct(), then per-type I'll go looking for any override metatable functionality in this folder 
--]]
local ffi = require 'ffi'
local table = require 'ext.table'
local struct = require 'struct'

-- TODO df.globals instead
local df = require 'byhand.globals'

-- LanguageName
do
	local mt = {}
	mt.__index = mt

	function mt:translate(inEnglish, onlyLastPart)
		local out = table()

		local function addWordToOut(word)
			if type(word) == 'cdata' then
				if word == nil then return end	-- null std::string pointer?
				if ffi.typeof(word) == ffi.typeof'std_string*' then
					word = word[0]
				else
					assert(ffi.typeof(word) == ffi.typeof'std_string'
						or ffi.typeof(word) == ffi.typeof'std_string&')
				end
				word = word:str()
			end
			if word == '' then return end
			out:insert(word:sub(1,1):upper() .. word:sub(2))
		end

		-- concat lua str with std::string
		-- testing for nils and std_string's 
		-- do I need to test, or can I assert that the values will be valid?
		local function concatStdStr(a,b)
			assert(type(a) == 'string')
			assert(type(b) == 'cdata')
			if ffi.typeof(b) == ffi.typeof'std_string*' then
				assert(b ~= nil)
				b = b[0]
			else
				assert(ffi.typeof(b) == ffi.typeof'std_string'
					or ffi.typeof(b) == ffi.typeof'std_string&')
			end
			return a .. b:str()
		end

		if not onlyLastPart then
			if not self.firstName:empty() then
				addWordToOut(self.firstName)
			end

			if not self.nickname:empty() then
				local word = concatStdStr("`", self.nickname) .. "'"
				local switch = df.dInit ~= nil	-- cuz it's a pointer
					and df.gametype ~= nil		-- cuz it's a pointer
					and df.dInit.nickname[df.gametype[0]]
					or ffi.C.DInitNickname_CENTRALIZE
				if switch == DInitNickname_REPLACE_ALL then
					return word
				elseif switch == DInitNickname_REPLACE_FIRST then
					out = table()
				elseif switch == DInitNickname_CENTRALIZE then
				end
				addWordToOut(word)
			end
		end

		local lang = df.world.raws.language
		if not inEnglish then
			local tltn = lang.translations:at(self.language)
			if self.words[0] >= 0 
			or self.words[1] >= 0
			then
				local word = ''
				if self.words[0] >= 0 then
					word = concatStdStr(word, tltn.words:at(self.words[0]))
				end
				if self.words[1] >= 0 then
					word = concatStdStr(word, tltn.words:at(self.words[1]))
				end
				addWordToOut(word)
			end
			do
				local word = ''
				for i=2,5 do
					if self.words[i] >= 0 then
						word = concatStdStr(word, tltn.words:at(self.words[i]))
					end
				end
				addWordToOut(word)
			end
			if self.words[6] >= 0 then
				addWordToOut(tltn.words:at(self.words[6]))
			end
		else
			if self.words[0] >= 0 
			or self.words[1] >= 0
			then
				local word = ''
				if self.words[0] >= 0 then
					word = concatStdStr(
						word,
						lang.words:at(self.words[0])
							.forms[self.partsOfSpeech[0]]
					)
				end
				if self.words[1] >= 0 then
					word = concatStdStr(
						word,
						lang.words:at(self.words[1])
							.forms[self.partsOfSpeech[1]]
					)
				end
				addWordToOut(word)
			end
			if self.words[2] >= 0 
			or self.words[3] >= 0 
			or self.words[4] >= 0 
			or self.words[5] >= 0
			then
				if #out > 0 then
					out:insert'the'
				else
					out:insert'The'
				end
			end
			for i=2,5 do
				if self.words[i] >= 0 then
					addWordToOut(
						lang.words:at(self.words[i])
							.forms[self.partsOfSpeech[i]]
					)
				end
			end
			if self.words[6] >= 0 then
				if #out > 0 then
					out:insert'of'
				else
					out:insert'Of'
				end
				addWordToOut(
					lang.words:at(self.words[6])
						.forms[self.partsOfSpeech[6]]
				)
			end
		end

		return out:concat' '
	end

	df.LanguageName = ffi.metatype('LanguageName', mt)
end

-- CreatureRaw
do
	local mt = {}
	mt.__index = mt

	-- [[ TODO these are in the namespace because of association
	-- but really
	-- really
	-- how hard is it to type df.world[0].raws.creatures.all[id]
	-- or if its hard, then why all these needless namespace structs that are only used once?
	-- just flatten them.
	-- df.world[0].allCreatureRaws[id]

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
		local o = mt.getVectorPtr():at(id)
		-- if :at() fails then it returns nil
		-- if :at() succeeds then it returns a ptr, which could be null,
		--  and in luajit null ptrs implicitly cast to true for booleans but == nil will test true, so ...
		if o == nil then return nil end	
		-- now o is of type CreatureRaw* so ...
		return o
	end
	--]]

	df.CreatureRaw = ffi.metatype('CreatureRaw', mt)
end

-- HistfigEntityLink
do
	local mt = {}
	mt.__index = mt

	-- [[ vtable method wrappers
	function mt:getType()
		return self.vtable.getType(self)
	end
	--]]

	df.HistfigEntityLink = ffi.metatype('HistfigEntityLink', mt)
end


-- HistoricalFigure
do
	local mt = {}
	mt.__index = mt

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

	function mt:isInBox(x1, y1, z1, x2, y2, z2)
		return x1 <= self.pos.x and self.pos.x <= x2
			and y1 <= self.pos.y and self.pos.y <= y2
			and z1 <= self.pos.z and self.pos.z <= z2
	end

	function mt:isActive()
		return self.inactive == 0
	end

	function mt:isVisible()
		-- TODO Maps ...
		return df.Maps.isTileVisible(self.pos:unpack())
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

		if not ignoreSanity and not self:isSane() then
			return false
		end

		return self:isOwnGroup()
	end

	function mt:isFortControlled()
		if df.gamemode[0] ~= GameMode_DWARF then 
			return false 
		end

		if self.mood == MoodType_Berserk
		or self:isCrazed()
		or self:isOpposedToLife() 
		or self.enemy.undead ~= nil -- ptr
		or self.ghostly ~= 0
		then
			return false
		end

		if self.marauder ~= 0
		or self.invaderOrigin ~= 0
		or self.activeInvader ~= 0
		or self.forest ~= 0
		or self.merchant ~= 0
		or self.diplomat ~= 0
		then
			return false
		end

		if self.tame ~= 0 then
			return true
		end

		if self.visitor ~= 0
		or self.visitorUninvited ~= 0
		or self.underworld ~= 0
		or self.resident ~= 0
		then
			return false
		end

		return self.civID ~= -1 
		and self.civID == df.ui.civID
	end

	function mt:isOwnCiv()
		return self.civID == df.ui.civID
	end

	function mt:isOwnGroup()
		local histfig = df.HistoricalFigure.find(self.histFigureID)
		if histfig == nil or histfig[0] == nil then return false end
		for i,link in ipairs(histfig[0].entityLinks) do
			if link.entityID == df.ui.groupID
			and link:getType() == ffi.C.HistfigEntityLinkType_MEMBER
			then
				return true
			end
		end
		return false
	end

	function mt:isOwnRace()
		return self.race == df.ui.raceID
	end

	function mt:isAlive()
		return self.killed == 0
			and self.ghostly == 0
			and self.curse.addTags1.NOT_LIVING == 0
	end

	-- hmm why not just !isAlive ?
	-- why does isAlive also check the curse add tags?
	-- can a unit be neither dead nor alive?
	function mt:isDead()
		return self.killed ~= 0
			or self.ghostly ~= 0
	end

	function mt:isKilled()
		return self.killed ~= 0
	end

	function mt:isSane()
		if self:isDead()
		or self:isOpposedToLife()
		or self.enemy.undead ~= nil	-- cuz it's a pointer ...
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
		return self:casteFlagSet(ffi.C.CasteRawFlags_CRAZED)
	end

	function mt:isGhost()
		return self.ghostly ~= 0
	end

	-- isHidden
	-- isHidingCurse
	-- isMale
	-- isFemale
	-- isBaby
	-- isChild
	-- isAdult
	-- isGay
	-- isNaked
	-- isVisiting
	-- isTrainableHunting
	-- isTrainableWar
	-- isTrained
	-- isHunter
	-- isWar
	-- isTame
	-- isTamable
	-- isDomesticated
	-- isMarkedForSlaughter
	-- isGelded
	-- isEggLayer
	-- isGrazer
	-- isMilkable
	-- isForest
	-- isMichievous
	-- isAvailableForAdoption
	-- hasExtravision

	function mt:isOpposedToLife()
		if self.curse.removeTags1.OPPOSED_TO_LIFE ~= 0 then return false end
		if self.curse.addTags1.OPPOSED_TO_LIFE ~= 0 then return true end
		return self:casteFlagSet(ffi.C.CasteRawFlags_OPPOSED_TO_LIFE)
	end

	-- then a lot more here ...
	
	function mt:casteFlagSet(flagIndex, race, caste)
		assert(flagIndex ~= nil)
		race = race or self.race
		caste = caste or self.caste
--print('CreatureRaw:casteFlagSet', flagIndex, race, caste)

		local creature = df.CreatureRaw.find(race)
		-- 'creature' is df.world[0].raws.creatures.all[] vector entry, which is a CreatureRaw*
		-- need explicit nil test to detect null pointer cdata
--print('creature', creature)
		if creature == nil then return false end
--print('creature[0]', creature[0])

--print('creature caste', creature.caste)
		-- this is crashing ...
		local craw = creature.caste:at(caste)
--print'craw'
--print('craw', craw)
		if craw == nil then return false end

--print('craw flags', craw[0].flags)
		return craw.flags:isSet(flagIndex)
	end

	-- and a lot more yet ...

	df.Unit = ffi.metatype('Unit', mt)
end

-- get metatypes here or just from the ffi.typeof(name)
return df
