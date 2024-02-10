-- formerly a plugin
-- this is just the map prospector, not the embark one
local function prospector(args)
	local df = assert(args.df)
	if not df.Maps.isValid() then
        return false, "Map is not available!"
	end

    local sizex, sizey, sizez= df.Maps.getSize()
    --MapExtras::MapCache map

    local mats = df.Materials	-- dfhack.Materials?

	local blockFeatureGlobal = DFHack_t_feature()
	local blockFeatureLocal = DFHack_t_feature()

    local hasDemonTemple = false
    local hasLair = false
    --MatMap baseMats;
    --MatMap layerMats;
    --MatMap veinMats;
    --MatMap plantMats;
    --MatMap treeMats;

    --matdata liquidWater;
    --matdata liquidMagma;
    --matdata aquiferTiles;
    --matdata tubeTiles;

	local blockCoord = Coord2D()
	local coord = Coord2D()
    for z=0,sizez-1 do
        for by=0,sizey-1 do
			blockCoord.y = by
            for bx=0,sizex-1 do
                blockCoord.x = bx
                -- Get the map block
                local b = map.BlockAt(bx, by, z)
                
				if not b or not b:isValid() then
                    --continue
                else
					-- Find features
					b.GetGlobalFeature(blockFeatureGlobal)
					b.GetLocalFeature(blockFeatureLocal)

					local globalZ = df.world.map.regionZ + z

					-- Iterate over all the tiles in the block
					for y=0,15 do
						coord.y = y
						for x=0,15 do
							coord.x = x
							local des = b.DesignationAt(coord)
							local occ = b.OccupancyAt(coord)

							-- Skip hidden tiles
							if not options.hidden ~= 0
							and des.hidden ~= 0
							then
								--continue
							else
								-- Check for aquifer
								if des.waterTable ~= 0 then
									aquiferTiles.add(globalZ)
								end

								// Check for lairs
								if (occ.bits.monster_lair)
								{
									hasLair = true;
								}

								// Check for liquid
								if (des.bits.flow_size)
								{
									if (des.bits.liquid_type == tile_liquid::Magma)
										liquidMagma.add(globalZ);
									else
										liquidWater.add(globalZ);
								}

								df::tiletype type = b->tiletypeAt(coord);
								df::tiletype_shape tileshape = tileShape(type);
								df::tiletype_material tilemat = tileMaterial(type);

								// We only care about these types
								switch (tileshape)
								{
								case tiletype_shape::WALL:
								case tiletype_shape::FORTIFICATION:
									break;
								case tiletype_shape::EMPTY:
									/* A heuristic: tubes inside adamantine have EMPTY:AIR tiles which
									   still have feature_local set. Also check the unrevealed status,
									   so as to exclude any holes mined by the player. */
									if (tilemat == tiletype_material::AIR &&
										des.bits.feature_local && des.bits.hidden &&
										blockFeatureLocal.type == feature_type::deep_special_tube)
									{
										tubeTiles.add(globalZ);
									}
								default:
									continue;
								}

								// Count the material type
								baseMats[tilemat].add(globalZ);

								// Find the type of the tile
								switch (tilemat)
								{
								case tiletype_material::SOIL:
								case tiletype_material::STONE:
									layerMats[b->layerMaterialAt(coord)].add(globalZ);
									break;
								case tiletype_material::MINERAL:
									veinMats[b->veinMaterialAt(coord)].add(globalZ);
									break;
								case tiletype_material::FEATURE:
									if (blockFeatureLocal.type != -1 && des.bits.feature_local)
									{
										if (blockFeatureLocal.type == feature_type::deep_special_tube
												&& blockFeatureLocal.main_material == 0) // stone
										{
											veinMats[blockFeatureLocal.sub_material].add(globalZ);
										}
										else if (blockFeatureLocal.type == feature_type::deep_surface_portal)
										{
											hasDemonTemple = true;
										}
									}

									if (blockFeatureGlobal.type != -1 && des.bits.feature_global
											&& blockFeatureGlobal.type == feature_type::underworld_from_layer
											&& blockFeatureGlobal.main_material == 0) // stone
									{
										layerMats[blockFeatureGlobal.sub_material].add(globalZ);
									}
									break;
								case tiletype_material::LAVA_STONE:
									// TODO ?
									break;
								default:
									break;
								}
							end
						end
					end

					// Check plants this way, as the other way wasn't getting them all
					// and we can check visibility more easily here
					if (options.shrubs)
					{
						auto block = Maps::getBlockColumn(b_x,b_y);
						vector<df::plant *> *plants = block ? &block->plants : NULL;
						if(plants)
						{
							for (PlantList::const_iterator it = plants->begin(); it != plants->end(); it++)
							{
								const df::plant & plant = *(*it);
								if (uint32_t(plant.pos.z) != z)
									continue;
								df::coord2d loc(plant.pos.x, plant.pos.y);
								loc = loc % 16;
								if (options.hidden || !b->DesignationAt(loc).bits.hidden)
								{
									if(plant.flags.bits.is_shrub)
										plantMats[plant.material].add(globalZ);
									else
										treeMats[plant.material].add(globalZ);
								}
							}
						}
					}
					// Block end
				} // block x
			end

            // Clean uneeded memory
            map.trash();
        } // block y
    } // z

    MatMap::const_iterator it;

    if (options.summary) {
        con << "Base materials:" << std::endl;
        for (it = baseMats.begin(); it != baseMats.end(); ++it)
        {
            con << std::setw(25) << ENUM_KEY_STR(tiletype_material,(df::tiletype_material)it->first) << " : " << it->second.count << std::endl;
        }
        con << std::endl;
    }

    if (options.liquids && (liquidWater.count || liquidMagma.count))
    {
        con << "Liquids:" << std::endl;
        if (liquidWater.count)
        {
            con << std::setw(25) << "WATER" << " : ";
            printMatdata(con, liquidWater);
        }
        if (liquidWater.count)
        {
            con << std::setw(25) << "MAGMA" << " : ";
            printMatdata(con, liquidMagma);
        }
        con << std::endl;
    }

    if (options.layers) {
        con << "Layer materials:" << std::endl;
        printMats<df::inorganic_raw, shallower>(con, layerMats, world->raws.inorganics, options);
    }

    if (options.features) {
        con << "Features:" << std::endl;

        bool hasFeature = false;
        if (aquiferTiles.count)
        {
            con << std::setw(25) << "Has aquifer" << " : ";
            if (options.value)
                con << "      ";
            printMatdata(con, aquiferTiles);
            hasFeature = true;
        }

        if (options.tube && tubeTiles.count)
        {
            con << std::setw(25) << "Has HFS tubes" << " :          ";
            if (options.value)
                con << "      ";
            printMatdata(con, tubeTiles, true);
            hasFeature = true;
        }

        if (hasDemonTemple)
        {
            con << std::setw(25) << "Has demon temple" << std::endl;
            hasFeature = true;
        }

        if (hasLair)
        {
            con << std::setw(25) << "Has lair" << std::endl;
            hasFeature = true;
        }

        if (!hasFeature)
            con << std::setw(25) << "None" << std::endl;

        con << std::endl;
    }

    printVeins(con, veinMats, options);

    if (options.shrubs) {
        con << "Shrubs:" << std::endl;
        printMats<df::plant_raw, std::greater>(con, plantMats, world->raws.plants.all, options);
    }

    if (options.trees) {
        con << "Wood in trees:" << std::endl;
        printMats<df::plant_raw, std::greater>(con, treeMats, world->raws.plants.all, options);
    }

    // Cleanup
    mats->Finish();

    return true
end
