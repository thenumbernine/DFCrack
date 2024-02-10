-- ... still needs UnitAction stuff for it to work
local function fastdwarf(args)
	local df = assert(args.df)
	local enableFastDwarf = not not args.fast
	local enableTeleDwarf = not not args.tele
	
	for _,u in ipairs(df.world.units.active) do
		-- citizens only
		if u:isCitizen() then
			if enableTeleDwarf then
				-- skip dwarves that are dragging creatures or being dragged
				if u.relationshipIDs[UnitRelationshipType_Draggee] ~= -1
				or u.relationshipIDs[UnitRelationshipType_Dragger] ~= -1
				then
					break
				end

				-- skip dwarves that are following other units
				if u.following ~= 0 then
					break
				end

				-- skip unconscious units
				if u.counters.unconscious > 0 then
					break
				end

				-- don't do anything if the dwarf isn't going anywhere
				if not u.pos:isValid()
				or not u.path.dest:isValid()
				or u.pos == u.path.dest
				then
					break
				end

				if not u:teleport(u.path.dest) then
					break
				end

				-- TODO ...
				u.path.path:clear()
			end

			if enableFastDwarf then
				df.Units.setGroupActionTimers(u, 1, ffi.C.UnitActionTypeGroup_All)
			end
		end
	end
end

return fastdwarf
