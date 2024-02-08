--[[
half hearted manually procured file of the globals.
get rid of this in favor of generated dfcrack/df/globals.lua
--]]
require 'dftypes'
require 'df_mts'
local ffi = require 'ffi'

local df = {}
df.cursor = ffi.cast('int3_t*', 0x19bfe60)
df.selectionRect = ffi.cast('SelectionRect*', 0x19bfe40)
df.gamemode = ffi.cast('int32_t*', 0x19bfe30)
df.gametype = ffi.cast('int32_t*', 0x19bfe20)
-- df.uiMenuWidth = ffi.cast('static-array*', 0x19bfd61)
df.title = ffi.cast('char*', 0x1a9f3c0)
df.titleSpaced = ffi.cast('char*', 0x1a9f2c0)
-- df.createdItemType = ffi.cast('vector<TODO>*', 0x1d32c60)
-- df.createdItemSubType = ffi.cast('vector<TODO>*', 0x1d32c40)
-- df.createdItemMatType = ffi.cast('vector<TODO>*', 0x1d32c20)
-- df.createdItemMatIndex = ffi.cast('vector<TODO>*', 0x1d32c00)
-- df.createdItemCount = ffi.cast('vector<TODO>*', 0x1d32be0)
--df.mapRenderer = ffi.cast('MapRenderer*', 0x1aa1d60)
--df.dInit = ffi.cast('dInit*', 0x1a9f4c0)
-- df.flows = ffi.cast('vector<TODO>*', 0x232a5f0)
--df.enabler = ffi.cast('Enabler*', 0x19c0a80)
--df.gps = ffi.cast('Graphic*', 0x19bff60)
--df.gview = ffi.cast('Interfacest*', 0x232a660)
--df.init = ffi.cast('Init*', 0x1a9fc20)
--df.texture = ffi.cast('TextureHandler*', 0x1aa1d00)
-- df.timedEvents = ffi.cast('vector<TODO>*', 0x232a5d0)
--df.ui = ffi.cast('UI*', 0x1d2a040)
--df.uiAdvMode = ffi.cast('UIAdvMode*', 0x1d20680)
--df.uiBuildSelector = ffi.cast('uiBuildSelector*', 0x23289a0)
-- df.uiBuildingAssignType = ffi.cast('vector<TODO>*', 0x1d32db0)
-- df.uiBuildingAssignIsMarked = ffi.cast('vector<TODO>*', 0x1d32d90)
-- df.uiBuildingAssignUnits = ffi.cast('vector<TODO>*', 0x1d32d70)
-- df.uiBuildingAssignItems = ffi.cast('vector<TODO>*', 0x1d32d50)
--df.uiLookList = ffi.cast('uiLookList*', 0x1a1f2a0)
--df.uiSidebarMenus = ffi.cast('uiSidebarMenus*', 0x1ab3f20)
df.world = ffi.cast('World*', 0x1ab5b40)
df.version = ffi.cast('int32_t*', 0x232a630)
df.minLoadVersion = ffi.cast('int32_t*', 0x232a620)
df.movieVersion = ffi.cast('int32_t*', 0x232a610)
df.basicSeed = ffi.cast('int32_t*', 0x232a640)
df.activityNextID = ffi.cast('int32_t*', 0x1a1f040)
df.agreementNextID = ffi.cast('int32_t*', 0x1a1ef90)
df.armyControllerNextID = ffi.cast('int32_t*', 0x1a1efc0)
df.armyNextID = ffi.cast('int32_t*', 0x1a1efd0)
df.armyTrackingInfoNextID = ffi.cast('int32_t*', 0x1a1efb0)
df.artImageChunkNextID = ffi.cast('int32_t*', 0x1a1f080)
df.artifactNextID = ffi.cast('int32_t*', 0x1a1f130)
df.beliefSystemNextID = ffi.cast('int32_t*', 0x1a1ef20)
df.buildingNextID = ffi.cast('int32_t*', 0x1a1f0f0)
df.crimeNextID = ffi.cast('int32_t*', 0x1a1eff0)
df.culturalIdentityNextID = ffi.cast('int32_t*', 0x1a1efa0)
df.danceFormNextID = ffi.cast('int32_t*', 0x1a1ef60)
df.divinationSetNextID = ffi.cast('int32_t*', 0x1a1ef00)
df.entityNextID = ffi.cast('int32_t*', 0x1a1f150)
df.flowGuideNextID = ffi.cast('int32_t*', 0x1a1f0d0)
df.formationNextID = ffi.cast('int32_t*', 0x1a1f050)
df.histEventCollectionNextID = ffi.cast('int32_t*', 0x1a1f0a0)
df.histEventNextID = ffi.cast('int32_t*', 0x1a1f0b0)
df.histFigureNextID = ffi.cast('int32_t*', 0x1a1f0c0)
df.identityNextID = ffi.cast('int32_t*', 0x1a1f010)
df.imageSetNextID = ffi.cast('int32_t*', 0x1a1ef10)
df.incidentNextID = ffi.cast('int32_t*', 0x1a1f000)
df.interactionInstanceNextID = ffi.cast('int32_t*', 0x1a1f030)
df.itemNextID = ffi.cast('int32_t*', 0x1a1f180)
df.jobNextID = ffi.cast('int32_t*', 0x1a1f120)
df.machineNextID = ffi.cast('int32_t*', 0x1a1f0e0)
df.musicalFormNextID = ffi.cast('int32_t*', 0x1a1ef70)
df.nemesisNextID = ffi.cast('int32_t*', 0x1a1f140)
df.occupationNextID = ffi.cast('int32_t*', 0x1a1ef30)
df.poeticFormNextID = ffi.cast('int32_t*', 0x1a1ef80)
df.projNextID = ffi.cast('int32_t*', 0x1a1f100)
df.rhythmNextID = ffi.cast('int32_t*', 0x1a1ef40)
df.scaleNextID = ffi.cast('int32_t*', 0x1a1ef50)
df.scheduleNextID = ffi.cast('int32_t*', 0x1a1f110)
df.soulNextID = ffi.cast('int32_t*', 0x1a1f160)
df.squadNextID = ffi.cast('int32_t*', 0x1a1f060)
df.taskNextID = ffi.cast('int32_t*', 0x1a1f070)
df.unitChunkNextID = ffi.cast('int32_t*', 0x1a1f090)
df.unitNextID = ffi.cast('int32_t*', 0x1a1f170)
df.vehicleNextID = ffi.cast('int32_t*', 0x1a1efe0)
df.writtenContentNextID = ffi.cast('int32_t*', 0x1a1f020)
df.cur_year = ffi.cast('int32_t*', 0x1d32e30)
df.cur_year_tick = ffi.cast('int32_t*', 0x1d32e10)
df.cur_year_tickAdvmode = ffi.cast('int32_t*', 0x1d32e00)
df.curSeason = ffi.cast('int8_t*', 0x1d35270)
df.curSeason_tick = ffi.cast('int32_t*', 0x1d35260)
-- df.currentWeather = ffi.cast('static-array*', 0x1d32e40)
df.pauseState = ffi.cast('bool*', 0x1d32cb0)
df.processDig = ffi.cast('bool*', 0x1d32e21)
df.processJobs = ffi.cast('bool*', 0x1d32e20)
df.uiBuildingInAssign = ffi.cast('bool*', 0x1d32dd0)
df.uiBuildingInResize = ffi.cast('bool*', 0x1d32dd1)
--df.uiBuildingResizeRadius = ffi.cast('int16_t*', 0x1d32dd2)
df.uiBuildingItemCursor = ffi.cast('int32_t*', 0x1d32ddc)
df.uiLookCursor = ffi.cast('int32_t*', 0x1d32cc0)
df.uiSelectedUnit = ffi.cast('int32_t*', 0x1d32cd0)
--df.uiUnitViewMode = ffi.cast('uiUnitViewMode*', 0x1d32cc4)
df.uiWorkshopInAdd = ffi.cast('bool*', 0x1d32dd5)
df.uiWorkshopJobCursor = ffi.cast('int32_t*', 0x1d32de0)
df.uiLever_target_type = ffi.cast('int8_t*', 0x1d32dd4)
df.windowX = ffi.cast('int32_t*', 0x2328998)
df.windowY = ffi.cast('int32_t*', 0x2328994)
df.windowZ = ffi.cast('int32_t*', 0x2328990)
df.debugNopause = ffi.cast('bool*', 0x19c70b1)
df.debugNomoods = ffi.cast('bool*', 0x19c70b0)
df.debugCombat = ffi.cast('bool*', 0x19c70a1)
df.debugWildlife = ffi.cast('bool*', 0x19c70a0)
df.debugNodrink = ffi.cast('bool*', 0x19c7090)
df.debugNoeat = ffi.cast('bool*', 0x19c708f)
df.debugNosleep = ffi.cast('bool*', 0x19c708e)
df.debugShowambush = ffi.cast('bool*', 0x19c708d)
df.debugFastmining = ffi.cast('bool*', 0x19c708c)
df.debugNoberserk = ffi.cast('bool*', 0x19c708a)
df.debug_turbospeed = ffi.cast('bool*', 0x19c7088)
df.saveOnExit = ffi.cast('bool*', 0x1d32df0)
--df.standingOrdersGatherMinerals = ffi.cast('uint8_t*', 0x19bfd93)
--df.standingOrdersGatherWood = ffi.cast('uint8_t*', 0x19bfd92)
--df.standingOrdersGatherFood = ffi.cast('uint8_t*', 0x19bfd91)
--df.standingOrdersGatherBodies = ffi.cast('uint8_t*', 0x19bfd90)
--df.standingOrdersGatherAnimals = ffi.cast('uint8_t*', 0x19bfd8e)
--df.standingOrdersGatherFurniture = ffi.cast('uint8_t*', 0x19bfd8d)
--df.standingOrdersFarmerHarvest = ffi.cast('uint8_t*', 0x19bfd8c)
--df.standingOrdersJobCancelAnnounce = ffi.cast('uint8_t*', 0x19bfd50)
--df.standingOrdersMixFood = ffi.cast('uint8_t*', 0x19bfd40)
--df.standingOrdersGatherRefuse = ffi.cast('uint8_t*', 0x19bfd8f)
--df.standingOrdersGatherRefuseOutside = ffi.cast('uint8_t*', 0x1d32ca9)
--df.standingOrdersGatherVerminRemains = ffi.cast('uint8_t*', 0x1d32ca8)
--df.standingOrdersDumpCorpses = ffi.cast('uint8_t*', 0x1d32ca7)
--df.standingOrdersDumpSkulls = ffi.cast('uint8_t*', 0x1d32ca6)
--df.standingOrdersDumpSkins = ffi.cast('uint8_t*', 0x1d32ca5)
--df.standingOrdersDumpBones = ffi.cast('uint8_t*', 0x1d32ca4)
--df.standingOrdersDumpHair = ffi.cast('uint8_t*', 0x1d32ca3)
--df.standingOrdersDumpShells = ffi.cast('uint8_t*', 0x1d32ca2)
--df.standingOrdersDumpOther = ffi.cast('uint8_t*', 0x1d32ca1)
--df.standingOrdersForbidUsedAmmo = ffi.cast('uint8_t*', 0x19bfd81)
--df.standingOrdersForbidOtherDeadItems = ffi.cast('uint8_t*', 0x19bfd80)
--df.standingOrdersForbidOwnDead = ffi.cast('uint8_t*', 0x1d32ca0)
--df.standingOrdersForbidOtherNohunt = ffi.cast('uint8_t*', 0x1d32c90)
--df.standingOrdersForbidOwnDeadItems = ffi.cast('uint8_t*', 0x1d32c80)
--df.standingOrdersAutoLoom = ffi.cast('uint8_t*', 0x19bfd8b)
--df.standingOrdersAutoCollectWebs = ffi.cast('uint8_t*', 0x19bfd8a)
--df.standingOrdersAutoSlaughter = ffi.cast('uint8_t*', 0x19bfd89)
--df.standingOrdersAutoButcher = ffi.cast('uint8_t*', 0x19bfd88)
--df.standingOrdersAuto_tan = ffi.cast('uint8_t*', 0x19bfd87)
--df.standingOrdersAutoFishery = ffi.cast('uint8_t*', 0x19bfd86)
--df.standingOrdersAutoKitchen = ffi.cast('uint8_t*', 0x19bfd85)
--df.standingOrdersAutoKiln = ffi.cast('uint8_t*', 0x19bfd84)
--df.standingOrdersAutoSmelter = ffi.cast('uint8_t*', 0x19bfd83)
--df.standingOrdersAutoOther = ffi.cast('uint8_t*', 0x19bfd82)
--df.standingOrdersUseDyedCloth = ffi.cast('uint8_t*', 0x1d32caa)
--df.standingOrdersZOneOnlyDrink = ffi.cast('uint8_t*', 0x1d32cac)
--df.standingOrdersZOneOnlyFish = ffi.cast('uint8_t*', 0x1d32cab)
--df.curSnowCounter = ffi.cast('int16_t*', 0x1d32e5a)
--df.curRainCounter = ffi.cast('int16_t*', 0x1d32e5c)
--df.weathertimer = ffi.cast('int16_t*', 0x1d32e34)
-- df.curSnow = ffi.cast('static-array*', 0x1d32e60)
-- df.curRain = ffi.cast('static-array*', 0x1d33460)
-- df.jobvalue = ffi.cast('static-array*', 0x232a1c0)
-- df.jobvalueSetter = ffi.cast('static-array*', 0x23299a0)
df.handleannounce = ffi.cast('bool*', 0x1a1f192)
df.preserveannounce = ffi.cast('bool*', 0x1a1f191)
df.updatelightstate = ffi.cast('bool*', 0x1a1f190)

return df
