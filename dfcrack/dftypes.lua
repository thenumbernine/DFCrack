local ffi = require 'ffi'
local template = require 'template'

local vec2s = require 'vec-ffi.vec2s'
local vec3s = require 'vec-ffi.vec3s'
local vec3i = require 'vec-ffi.vec3i'
-- not sure if i like glsl or hlsl naming convention more...
ffi.cdef[[
typedef vec2s_t short2_t;
typedef vec3s_t short3_t;
typedef vec3i_t int3_t;
]]

-- dfhack naming
ffi.cdef[[
typedef short3_t Coord;
typedef short2_t Coord2D;
]]

ffi.cdef[[
typedef struct {
	int3_t start, end;
} Rect3D;
]]

ffi.cdef[[
typedef struct {
	Coord2D v1, v2;
	int16_t z;
} Rect2pt5D;
]]

ffi.cdef[[
typedef struct {
	char * data;
	size_t len;
	/* maybe more, meh */
} std_string_pointer;
typedef struct {
	std_string_pointer * _M_p;
} std_string;
]]
assert(ffi.sizeof'std_string' == 8)

local function makeStdVector(T, name)
	name = name or 'vector_'..T
	-- stl vector in my gcc / linux / df is 24 bytes
	-- template type of our vector ... 8 bytes mind you
	-- TODO rewrite my ffi.cpp.vector file to be a C struct this
	local code = template([[
typedef struct {
	<?=T?> * start;
	<?=T?> * finish;
	<?=T?> * endOfStorage;
} <?=name?>;
]], {
		T = T,			-- vector type / template arg
		name = name,	-- vector name
	})
	--print(require 'template.showcode'(code))
	ffi.cdef(code)
	assert(ffi.sizeof(name) == 24)
	assert(ffi.sizeof(T..'*') == 8)
end

makeStdVector('void*', 'vector_ptr')
makeStdVector'short'
makeStdVector'int'

-- 'T' is the ptr base type
local function makeVectorPtr(T, name)
	name = name or 'vector_'..T..'_ptr'
	-- for now just use void*, later I'll add types
	ffi.cdef('typedef vector_ptr vector_'..T..'_ptr;')
end

-- dfarray.h

local function makeDfArray(T, name)
	name = name or 'dfarray_'..T
	ffi.cdef(template([[
typedef struct {
	<?=T?> * data;
	uint16_t size;
} <?=name?>;
]], {
		T = T,
		name = name,
	}))
end
makeDfArray('uint8_t', 'dfarray_byte')
makeDfArray'short'

ffi.cdef[[
typedef struct {
	vector_short x;
	vector_short y;
} Path2D;
]]

-- more like a vector-of-coords in SOA format
-- used for generic vector-of-coords, not necessarily as a path
ffi.cdef[[
typedef struct {
	vector_short x;
	vector_short y;
	vector_short z;
} CoordPath;
]]

-- why not uint32_t[8] ?
ffi.cdef[[
typedef struct {
	uint16_t bits[16];
} TileBitmask;
]]

-- TODO is this the std::list layout?  should I be making that dynamically like I will be std::vector ?
-- it is super'd DFLinkedList<BlockBurrowLink, BlockBurrow>, but I think only for methods? 
ffi.cdef[[
struct BlockBurrow;
typedef struct BlockBurrowLink {
	struct BlockBurrow * item;
	struct BlockBurrowLink * prev, * next;
} BlockBurrowLink;
]]

ffi.cdef[[
struct BlockBurrow {
	int32_t id;
	TileBitmask tile_bitmask;
	BlockBurrowLink * link;
};
typedef struct BlockBurrow BlockBurrow;
]]

-- general_ref.h

ffi.cdef[[
typedef struct {
	void * vtable;	/* todo */
} GeneralRef;
]]
makeVectorPtr'GeneralRef'

-- specific_ref_type.h

-- maybe luajit can handle enum typedefs, but there's still no namespaces for the constants, so why bother
ffi.cdef[[
typedef int32_t SpecificRefType;
enum {
	SpecificRefType_NONE = -1, // -1, 0xFFFFFFFFFFFFFFFF
	SpecificRefType_anon_1, // 0, 0x0
	SpecificRefType_UNIT, // 1, 0x1
	SpecificRefType_JOB, // 2, 0x2
	SpecificRefType_BUILDING_PARTY, // 3, 0x3
	SpecificRefType_ACTIVITY, // 4, 0x4
	SpecificRefType_ITEM_GENERAL, // 5, 0x5
	SpecificRefType_EFFECT, // 6, 0x6
	/**
	* unused
	*/
	SpecificRefType_PETINFO_PET, // 7, 0x7
	/**
	* unused
	*/
	SpecificRefType_PETINFO_OWNER, // 8, 0x8
	SpecificRefType_VERMIN_EVENT, // 9, 0x9
	SpecificRefType_VERMIN_ESCAPED_PET, // 10, 0xA
	SpecificRefType_ENTITY, // 11, 0xB
	SpecificRefType_PLOT_INFO, // 12, 0xC
	SpecificRefType_VIEWSCREEN, // 13, 0xD
	SpecificRefType_UNIT_ITEM_WRESTLE, // 14, 0xE
	SpecificRefType_NULL_REF, // 15, 0xF
	SpecificRefType_HIST_FIG, // 16, 0x10
	SpecificRefType_SITE, // 17, 0x11
	SpecificRefType_ARTIFACT, // 18, 0x12
	SpecificRefType_ITEM_IMPROVEMENT, // 19, 0x13
	SpecificRefType_COIN_FRONT, // 20, 0x14
	SpecificRefType_COIN_BACK, // 21, 0x15
	SpecificRefType_DETAIL_EVENT, // 22, 0x16
	SpecificRefType_SUBREGION, // 23, 0x17
	SpecificRefType_FEATURE_LAYER, // 24, 0x18
	SpecificRefType_ART_IMAGE, // 25, 0x19
	SpecificRefType_CREATURE_DEF, // 26, 0x1A
	SpecificRefType_ENTITY_ART_IMAGE, // 27, 0x1B
	SpecificRefType_anon_2, // 28, 0x1C
	SpecificRefType_ENTITY_POPULATION, // 29, 0x1D
	SpecificRefType_BREED, // 30, 0x1E
};
]]

-- specific_ref.h

ffi.cdef[[
struct Unit;
struct ActivityInfo;
struct Viewscreen;
struct EffectInfo;
struct Vermin;
struct Job;
struct HistoricalFigure;
struct HistoricalEntity;
struct UnitItemWrestle;
typedef struct {
	SpecificRefType type;	/* SpecificRefType_* */
	union {
		struct Unit * unit;
		struct ActivityInfo * activity;
		struct Viewscreen * screen;
		struct EffectInfo * effect;
		struct Vermin * vermin;
		struct Job * job;
		struct HistoricalFigure * histfig;
		struct HistoricalEntity * entity;
		struct {
			void * wrestle_unk_1;
			struct UnitItemWrestle * wrestleItem;
		} wrestle;
	};
} SpecificRef;
]]
makeVectorPtr'SpecificRef'

-- layer_type.h

ffi.cdef[[
typedef int16_t LayerType;
enum {
	LayerType_Surface = -1, // -1, 0xFFFFFFFFFFFFFFFF
	LayerType_Cavern1, // 0, 0x0
	LayerType_Cavern2, // 1, 0x1
	LayerType_Cavern3, // 2, 0x2
	LayerType_MagmaSea, // 3, 0x3
	LayerType_Underworld, // 4, 0x4
};
]]

-- world_population_ref.h

ffi.cdef[[
typedef struct {
	int16_t region_x;
	int16_t region_y;
	int16_t feature_idx;
	int32_t cave_id;
	int32_t unk_28;
	int32_t population_idx;
	LayerType depth;
} WorldPopulationRef;
]]

-- profession.h

ffi.cdef[[
typedef int16_t Profession;
enum {
	Profession_NONE = -1, // -1, 0xFFFFFFFFFFFFFFFF
	Profession_MINER, // 0, 0x0
	Profession_WOODWORKER, // 1, 0x1
	Profession_CARPENTER, // 2, 0x2
	Profession_BOWYER, // 3, 0x3
	Profession_WOODCUTTER, // 4, 0x4
	Profession_STONEWORKER, // 5, 0x5
	Profession_ENGRAVER, // 6, 0x6
	Profession_MASON, // 7, 0x7
	Profession_RANGER, // 8, 0x8
	Profession_ANIMAL_CARETAKER, // 9, 0x9
	Profession_ANIMAL_TRAINER, // 10, 0xA
	Profession_HUNTER, // 11, 0xB
	Profession_TRAPPER, // 12, 0xC
	Profession_ANIMAL_DISSECTOR, // 13, 0xD
	Profession_METALSMITH, // 14, 0xE
	Profession_FURNACE_OPERATOR, // 15, 0xF
	Profession_WEAPONSMITH, // 16, 0x10
	Profession_ARMORER, // 17, 0x11
	Profession_BLACKSMITH, // 18, 0x12
	Profession_METALCRAFTER, // 19, 0x13
	Profession_JEWELER, // 20, 0x14
	Profession_GEM_CUTTER, // 21, 0x15
	Profession_GEM_SETTER, // 22, 0x16
	Profession_CRAFTSMAN, // 23, 0x17
	Profession_WOODCRAFTER, // 24, 0x18
	Profession_STONECRAFTER, // 25, 0x19
	Profession_LEATHERWORKER, // 26, 0x1A
	Profession_BONE_CARVER, // 27, 0x1B
	Profession_WEAVER, // 28, 0x1C
	Profession_CLOTHIER, // 29, 0x1D
	Profession_GLASSMAKER, // 30, 0x1E
	Profession_POTTER, // 31, 0x1F
	Profession_GLAZER, // 32, 0x20
	Profession_WAX_WORKER, // 33, 0x21
	Profession_STRAND_EXTRACTOR, // 34, 0x22
	Profession_FISHERY_WORKER, // 35, 0x23
	Profession_FISHERMAN, // 36, 0x24
	Profession_FISH_DISSECTOR, // 37, 0x25
	Profession_FISH_CLEANER, // 38, 0x26
	Profession_FARMER, // 39, 0x27
	Profession_CHEESE_MAKER, // 40, 0x28
	Profession_MILKER, // 41, 0x29
	Profession_COOK, // 42, 0x2A
	Profession_THRESHER, // 43, 0x2B
	Profession_MILLER, // 44, 0x2C
	Profession_BUTCHER, // 45, 0x2D
	Profession_TANNER, // 46, 0x2E
	Profession_DYER, // 47, 0x2F
	Profession_PLANTER, // 48, 0x30
	Profession_HERBALIST, // 49, 0x31
	Profession_BREWER, // 50, 0x32
	Profession_SOAP_MAKER, // 51, 0x33
	Profession_POTASH_MAKER, // 52, 0x34
	Profession_LYE_MAKER, // 53, 0x35
	Profession_WOOD_BURNER, // 54, 0x36
	Profession_SHEARER, // 55, 0x37
	Profession_SPINNER, // 56, 0x38
	Profession_PRESSER, // 57, 0x39
	Profession_BEEKEEPER, // 58, 0x3A
	Profession_ENGINEER, // 59, 0x3B
	Profession_MECHANIC, // 60, 0x3C
	Profession_SIEGE_ENGINEER, // 61, 0x3D
	Profession_SIEGE_OPERATOR, // 62, 0x3E
	Profession_PUMP_OPERATOR, // 63, 0x3F
	Profession_CLERK, // 64, 0x40
	Profession_ADMINISTRATOR, // 65, 0x41
	Profession_TRADER, // 66, 0x42
	Profession_ARCHITECT, // 67, 0x43
	Profession_ALCHEMIST, // 68, 0x44
	Profession_DOCTOR, // 69, 0x45
	Profession_DIAGNOSER, // 70, 0x46
	Profession_BONE_SETTER, // 71, 0x47
	Profession_SUTURER, // 72, 0x48
	Profession_SURGEON, // 73, 0x49
	Profession_MERCHANT, // 74, 0x4A
	Profession_HAMMERMAN, // 75, 0x4B
	Profession_MASTER_HAMMERMAN, // 76, 0x4C
	Profession_SPEARMAN, // 77, 0x4D
	Profession_MASTER_SPEARMAN, // 78, 0x4E
	Profession_CROSSBOWMAN, // 79, 0x4F
	Profession_MASTER_CROSSBOWMAN, // 80, 0x50
	Profession_WRESTLER, // 81, 0x51
	Profession_MASTER_WRESTLER, // 82, 0x52
	Profession_AXEMAN, // 83, 0x53
	Profession_MASTER_AXEMAN, // 84, 0x54
	Profession_SWORDSMAN, // 85, 0x55
	Profession_MASTER_SWORDSMAN, // 86, 0x56
	Profession_MACEMAN, // 87, 0x57
	Profession_MASTER_MACEMAN, // 88, 0x58
	Profession_PIKEMAN, // 89, 0x59
	Profession_MASTER_PIKEMAN, // 90, 0x5A
	Profession_BOWMAN, // 91, 0x5B
	Profession_MASTER_BOWMAN, // 92, 0x5C
	Profession_BLOWGUNMAN, // 93, 0x5D
	Profession_MASTER_BLOWGUNMAN, // 94, 0x5E
	Profession_LASHER, // 95, 0x5F
	Profession_MASTER_LASHER, // 96, 0x60
	Profession_RECRUIT, // 97, 0x61
	Profession_TRAINED_HUNTER, // 98, 0x62
	Profession_TRAINED_WAR, // 99, 0x63
	Profession_MASTER_THIEF, // 100, 0x64
	Profession_THIEF, // 101, 0x65
	Profession_STANDARD, // 102, 0x66
	Profession_CHILD, // 103, 0x67
	Profession_BABY, // 104, 0x68
	Profession_DRUNK, // 105, 0x69
	Profession_MONSTER_SLAYER, // 106, 0x6A
	Profession_SCOUT, // 107, 0x6B
	Profession_BEAST_HUNTER, // 108, 0x6C
	Profession_SNATCHER, // 109, 0x6D
	Profession_MERCENARY, // 110, 0x6E
	Profession_GELDER, // 111, 0x6F
	Profession_PERFORMER, // 112, 0x70
	Profession_POET, // 113, 0x71
	Profession_BARD, // 114, 0x72
	Profession_DANCER, // 115, 0x73
	Profession_SAGE, // 116, 0x74
	Profession_SCHOLAR, // 117, 0x75
	Profession_PHILOSOPHER, // 118, 0x76
	Profession_MATHEMATICIAN, // 119, 0x77
	Profession_HISTORIAN, // 120, 0x78
	Profession_ASTRONOMER, // 121, 0x79
	Profession_NATURALIST, // 122, 0x7A
	Profession_CHEMIST, // 123, 0x7B
	Profession_GEOGRAPHER, // 124, 0x7C
	Profession_SCRIBE, // 125, 0x7D
	Profession_PAPERMAKER, // 126, 0x7E
	Profession_BOOKBINDER, // 127, 0x7F
	Profession_TAVERN_KEEPER, // 128, 0x80
	Profession_CRIMINAL, // 129, 0x81
	Profession_PEDDLER, // 130, 0x82
	Profession_PROPHET, // 131, 0x83
	Profession_PILGRIM, // 132, 0x84
	Profession_MONK, // 133, 0x85
	Profession_MESSENGER, // 134, 0x86
};
]]

-- part_of_speech.h

-- int16_t
ffi.cdef[[
typedef int16_t PartOfSpeech;
enum {
	PartOfSpeech_Noun, // 0, 0x0
	PartOfSpeech_NounPlural, // 1, 0x1
	PartOfSpeech_Adjective, // 2, 0x2
	PartOfSpeech_Prefix, // 3, 0x3
	PartOfSpeech_Verb, // 4, 0x4
	PartOfSpeech_Verb3rdPerson, // 5, 0x5
	PartOfSpeech_VerbPast, // 6, 0x6
	PartOfSpeech_VerbPassive, // 7, 0x7
	PartOfSpeech_VerbGerund, // 8, 0x8
};
]]

-- language_name_type.h

ffi.cdef[[
typedef int16_t LanguageNameType;
enum {
	LanguageNameType_NONE = -1, // -1, 0xFFFFFFFFFFFFFFFF
	LanguageNameType_Figure, // 0, 0x0
	LanguageNameType_Artifact, // 1, 0x1
	LanguageNameType_Civilization, // 2, 0x2
	LanguageNameType_Squad, // 3, 0x3
	LanguageNameType_Site, // 4, 0x4
	LanguageNameType_World, // 5, 0x5
	LanguageNameType_Region, // 6, 0x6
	LanguageNameType_Dungeon, // 7, 0x7
	LanguageNameType_LegendaryFigure, // 8, 0x8
	LanguageNameType_FigureNoFirst, // 9, 0x9
	LanguageNameType_FigureFirstOnly, // 10, 0xA
	LanguageNameType_ArtImage, // 11, 0xB
	LanguageNameType_AdventuringGroup, // 12, 0xC
	LanguageNameType_ElfTree, // 13, 0xD
	LanguageNameType_SiteGovernment, // 14, 0xE
	LanguageNameType_NomadicGroup, // 15, 0xF
	LanguageNameType_Vessel, // 16, 0x10
	LanguageNameType_MilitaryUnit, // 17, 0x11
	LanguageNameType_Religion, // 18, 0x12
	LanguageNameType_MountainPeak, // 19, 0x13
	LanguageNameType_River, // 20, 0x14
	LanguageNameType_Temple, // 21, 0x15
	LanguageNameType_Keep, // 22, 0x16
	LanguageNameType_MeadHall, // 23, 0x17
	LanguageNameType_SymbolArtifice, // 24, 0x18
	LanguageNameType_SymbolViolent, // 25, 0x19
	LanguageNameType_SymbolProtect, // 26, 0x1A
	/**
	* Market
	*/
	LanguageNameType_SymbolDomestic, // 27, 0x1B
	/**
	* Tavern
	*/
	LanguageNameType_SymbolFood, // 28, 0x1C
	LanguageNameType_War, // 29, 0x1D
	LanguageNameType_Battle, // 30, 0x1E
	LanguageNameType_Siege, // 31, 0x1F
	LanguageNameType_Road, // 32, 0x20
	LanguageNameType_Wall, // 33, 0x21
	LanguageNameType_Bridge, // 34, 0x22
	LanguageNameType_Tunnel, // 35, 0x23
	LanguageNameType_PretentiousEntityPosition, // 36, 0x24
	LanguageNameType_Monument, // 37, 0x25
	LanguageNameType_Tomb, // 38, 0x26
	LanguageNameType_OutcastGroup, // 39, 0x27
	LanguageNameType_Unk40, // 40, 0x28
	LanguageNameType_SymbolProtect2, // 41, 0x29
	LanguageNameType_Unk42, // 42, 0x2A
	LanguageNameType_Library, // 43, 0x2B
	LanguageNameType_PoeticForm, // 44, 0x2C
	LanguageNameType_MusicalForm, // 45, 0x2D
	LanguageNameType_DanceForm, // 46, 0x2E
	LanguageNameType_Festival, // 47, 0x2F
	LanguageNameType_FalseIdentity, // 48, 0x30
	LanguageNameType_MerchantCompany, // 49, 0x31
	LanguageNameType_CountingHouse, // 50, 0x32
	LanguageNameType_CraftGuild, // 51, 0x33
	LanguageNameType_Guildhall, // 52, 0x34
	LanguageNameType_NecromancerTower, // 53, 0x35
};
]]

-- language_name.h

ffi.cdef[[
typedef struct {
	std_string first_name;
	std_string nickname;
	int32_t words[7];
	PartOfSpeech parts_of_speech[7]; /* PartOfSpeech_* */
	int32_t language;
	LanguageNameType type;	/* LanguageNameType_* */
	bool hasName;
} LanguageName;
]]

-- item_type.h

ffi.cdef[[
typedef int16_t ItemType;
enum {
	ItemType_NONE = -1, // -1, 0xFFFFFFFFFFFFFFFF
	ItemType_BAR, // 0, 0x0
	ItemType_SMALLGEM, // 1, 0x1
	ItemType_BLOCKS, // 2, 0x2
	ItemType_ROUGH, // 3, 0x3
	ItemType_BOULDER, // 4, 0x4
	ItemType_WOOD, // 5, 0x5
	ItemType_DOOR, // 6, 0x6
	ItemType_FLOODGATE, // 7, 0x7
	ItemType_BED, // 8, 0x8
	ItemType_CHAIR, // 9, 0x9
	ItemType_CHAIN, // 10, 0xA
	ItemType_FLASK, // 11, 0xB
	ItemType_GOBLET, // 12, 0xC
	ItemType_INSTRUMENT, // 13, 0xD
	ItemType_TOY, // 14, 0xE
	ItemType_WINDOW, // 15, 0xF
	ItemType_CAGE, // 16, 0x10
	ItemType_BARREL, // 17, 0x11
	ItemType_BUCKET, // 18, 0x12
	ItemType_ANIMALTRAP, // 19, 0x13
	ItemType_TABLE, // 20, 0x14
	ItemType_COFFIN, // 21, 0x15
	ItemType_STATUE, // 22, 0x16
	ItemType_CORPSE, // 23, 0x17
	ItemType_WEAPON, // 24, 0x18
	ItemType_ARMOR, // 25, 0x19
	ItemType_SHOES, // 26, 0x1A
	ItemType_SHIELD, // 27, 0x1B
	ItemType_HELM, // 28, 0x1C
	ItemType_GLOVES, // 29, 0x1D
	ItemType_BOX, // 30, 0x1E
	ItemType_BIN, // 31, 0x1F
	ItemType_ARMORSTAND, // 32, 0x20
	ItemType_WEAPONRACK, // 33, 0x21
	ItemType_CABINET, // 34, 0x22
	ItemType_FIGURINE, // 35, 0x23
	ItemType_AMULET, // 36, 0x24
	ItemType_SCEPTER, // 37, 0x25
	ItemType_AMMO, // 38, 0x26
	ItemType_CROWN, // 39, 0x27
	ItemType_RING, // 40, 0x28
	ItemType_EARRING, // 41, 0x29
	ItemType_BRACELET, // 42, 0x2A
	ItemType_GEM, // 43, 0x2B
	ItemType_ANVIL, // 44, 0x2C
	ItemType_CORPSEPIECE, // 45, 0x2D
	ItemType_REMAINS, // 46, 0x2E
	ItemType_MEAT, // 47, 0x2F
	ItemType_FISH, // 48, 0x30
	ItemType_FISH_RAW, // 49, 0x31
	ItemType_VERMIN, // 50, 0x32
	ItemType_PET, // 51, 0x33
	ItemType_SEEDS, // 52, 0x34
	ItemType_PLANT, // 53, 0x35
	ItemType_SKIN_TANNED, // 54, 0x36
	ItemType_PLANT_GROWTH, // 55, 0x37
	ItemType_THREAD, // 56, 0x38
	ItemType_CLOTH, // 57, 0x39
	ItemType_TOTEM, // 58, 0x3A
	ItemType_PANTS, // 59, 0x3B
	ItemType_BACKPACK, // 60, 0x3C
	ItemType_QUIVER, // 61, 0x3D
	ItemType_CATAPULTPARTS, // 62, 0x3E
	ItemType_BALLISTAPARTS, // 63, 0x3F
	ItemType_SIEGEAMMO, // 64, 0x40
	ItemType_BALLISTAARROWHEAD, // 65, 0x41
	ItemType_TRAPPARTS, // 66, 0x42
	ItemType_TRAPCOMP, // 67, 0x43
	ItemType_DRINK, // 68, 0x44
	ItemType_POWDER_MISC, // 69, 0x45
	ItemType_CHEESE, // 70, 0x46
	ItemType_FOOD, // 71, 0x47
	ItemType_LIQUID_MISC, // 72, 0x48
	ItemType_COIN, // 73, 0x49
	ItemType_GLOB, // 74, 0x4A
	ItemType_ROCK, // 75, 0x4B
	ItemType_PIPE_SECTION, // 76, 0x4C
	ItemType_HATCH_COVER, // 77, 0x4D
	ItemType_GRATE, // 78, 0x4E
	ItemType_QUERN, // 79, 0x4F
	ItemType_MILLSTONE, // 80, 0x50
	ItemType_SPLINT, // 81, 0x51
	ItemType_CRUTCH, // 82, 0x52
	ItemType_TRACTION_BENCH, // 83, 0x53
	ItemType_ORTHOPEDIC_CAST, // 84, 0x54
	ItemType_TOOL, // 85, 0x55
	ItemType_SLAB, // 86, 0x56
	ItemType_EGG, // 87, 0x57
	ItemType_BOOK, // 88, 0x58
	ItemType_SHEET, // 89, 0x59
	ItemType_BRANCH, // 90, 0x5A
};
]]

-- history_hit_item.h

ffi.cdef[[
typedef struct {
	
	int32_t item;
	ItemType itemType;
	int16_t itemSubType;
	int16_t matType;
	int32_t matIndex;
	
	int32_t shooterItem;
	ItemType shooterItemType;
	int16_t shooterItemSubType;
	int16_t shooterMatType;
	int32_t shooterMatIndex;
} HistoryHitItem;
]]


-- unit_station_type.h

ffi.cdef[[
typedef int16_t UnitStationType;
enum {
	UnitStationType_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	UnitStationType_Nonsense, // 0, 0x0
	UnitStationType_DungeonCommander, // 1, 0x1
	UnitStationType_InsaneMood, // 2, 0x2
	UnitStationType_UndeadHunt, // 3, 0x3
	UnitStationType_SiegerPatrol, // 4, 0x4
	UnitStationType_MaraudeTarget, // 5, 0x5
	UnitStationType_SiegerBasepoint, // 6, 0x6
	UnitStationType_SiegerMill, // 7, 0x7
	UnitStationType_AmbushPatrol, // 8, 0x8
	UnitStationType_MarauderMill, // 9, 0x9
	UnitStationType_WildernessCuriousWander, // 10, 0xA
	UnitStationType_WildernessCuriousStealTarget, // 11, 0xB
	UnitStationType_WildernessRoamer, // 12, 0xC
	UnitStationType_PatternPatrol, // 13, 0xD
	UnitStationType_InactiveMarauder, // 14, 0xE
	UnitStationType_Owner, // 15, 0xF
	UnitStationType_Commander, // 16, 0x10
	UnitStationType_ChainedAnimal, // 17, 0x11
	UnitStationType_MeetingLocation, // 18, 0x12
	UnitStationType_MeetingLocationBuilding, // 19, 0x13
	UnitStationType_Depot, // 20, 0x14
	UnitStationType_VerminHunting, // 21, 0x15
	UnitStationType_SeekCommander, // 22, 0x16
	UnitStationType_ReturnToBase, // 23, 0x17
	UnitStationType_MillAnywhere, // 24, 0x18
	UnitStationType_Wagon, // 25, 0x19
	UnitStationType_MillBuilding, // 26, 0x1A
	UnitStationType_HeadForEdge, // 27, 0x1B
	UnitStationType_MillingFlood, // 28, 0x1C
	UnitStationType_MillingBurrow, // 29, 0x1D
	UnitStationType_SquadMove, // 30, 0x1E
	UnitStationType_SquadKillList, // 31, 0x1F
	UnitStationType_SquadPatrol, // 32, 0x20
	UnitStationType_SquadDefendBurrow, // 33, 0x21
	UnitStationType_SquadDefendBurrowFromTarget, // 34, 0x22
	UnitStationType_LairHunter, // 35, 0x23
	UnitStationType_Graze, // 36, 0x24
	UnitStationType_Guard, // 37, 0x25
	UnitStationType_Alarm, // 38, 0x26
	UnitStationType_MoveToSite, // 39, 0x27
	UnitStationType_ClaimSite, // 40, 0x28
	UnitStationType_WaitOrder, // 41, 0x29
};
]]

-- unit_path_goal.h

ffi.cdef[[
typedef int16_t UnitPathGoal;
enum {
	UnitPathGoal_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	UnitPathGoal_ComeToJobBuilding, // 0, 0x0
	UnitPathGoal_ValidPondDumpUnit, // 1, 0x1
	UnitPathGoal_ValidPondDump, // 2, 0x2
	UnitPathGoal_ConflictDefense, // 3, 0x3
	UnitPathGoal_AdventureMove, // 4, 0x4
	UnitPathGoal_MarauderMill, // 5, 0x5
	UnitPathGoal_WildernessCuriousStealTarget, // 6, 0x6
	UnitPathGoal_WildernessRoamer, // 7, 0x7
	UnitPathGoal_ThiefTarget, // 8, 0x8
	UnitPathGoal_Owner, // 9, 0x9
	UnitPathGoal_CheckChest, // 10, 0xA
	UnitPathGoal_SleepBed, // 11, 0xB
	UnitPathGoal_SleepBarracks, // 12, 0xC
	UnitPathGoal_SleepGround, // 13, 0xD
	UnitPathGoal_LeaveWall, // 14, 0xE
	UnitPathGoal_FleeTerrain, // 15, 0xF
	UnitPathGoal_TaxRoom, // 16, 0x10
	UnitPathGoal_GuardTaxes, // 17, 0x11
	UnitPathGoal_RansackTaxes, // 18, 0x12
	UnitPathGoal_GetEmptySandBag, // 19, 0x13
	UnitPathGoal_SandZone, // 20, 0x14
	UnitPathGoal_GrabCage, // 21, 0x15
	UnitPathGoal_UncageAnimal, // 22, 0x16
	UnitPathGoal_CaptureSmallPet, // 23, 0x17
	UnitPathGoal_GrabCageUnit, // 24, 0x18
	UnitPathGoal_GoToCage, // 25, 0x19
	UnitPathGoal_GrabAnimalTrap, // 26, 0x1A
	UnitPathGoal_CageVermin, // 27, 0x1B
	UnitPathGoal_GrabUnfillBucket, // 28, 0x1C
	UnitPathGoal_SeekFillBucket, // 29, 0x1D
	UnitPathGoal_SeekPatientForCarry, // 30, 0x1E
	UnitPathGoal_SeekPatientForDiagnosis, // 31, 0x1F
	UnitPathGoal_SeekPatientForImmobilizeBreak, // 32, 0x20
	UnitPathGoal_SeekPatientForCrutch, // 33, 0x21
	UnitPathGoal_SeekPatientForSuturing, // 34, 0x22
	UnitPathGoal_SeekSurgerySite, // 35, 0x23
	UnitPathGoal_CarryPatientToBed, // 36, 0x24
	UnitPathGoal_SeekGiveWaterBucket, // 37, 0x25
	UnitPathGoal_SeekJobItem, // 38, 0x26
	UnitPathGoal_SeekUnitForItemDrop, // 39, 0x27
	UnitPathGoal_SeekUnitForJob, // 40, 0x28
	UnitPathGoal_SeekSplint, // 41, 0x29
	UnitPathGoal_SeekCrutch, // 42, 0x2A
	UnitPathGoal_SeekSutureThread, // 43, 0x2B
	UnitPathGoal_SeekDressingCloth, // 44, 0x2C
	UnitPathGoal_GoToGiveWaterTarget, // 45, 0x2D
	UnitPathGoal_SeekFoodForTarget, // 46, 0x2E
	UnitPathGoal_SeekTargetForFood, // 47, 0x2F
	UnitPathGoal_SeekAnimalForSlaughter, // 48, 0x30
	UnitPathGoal_SeekSlaughterBuilding, // 49, 0x31
	UnitPathGoal_SeekAnimalForChain, // 50, 0x32
	UnitPathGoal_SeekChainForAnimal, // 51, 0x33
	UnitPathGoal_SeekCageForUnchain, // 52, 0x34
	UnitPathGoal_SeekAnimalForUnchain, // 53, 0x35
	UnitPathGoal_GrabFoodForTaming, // 54, 0x36
	UnitPathGoal_SeekAnimalForTaming, // 55, 0x37
	UnitPathGoal_SeekDrinkItem, // 56, 0x38
	UnitPathGoal_SeekFoodItem, // 57, 0x39
	UnitPathGoal_SeekEatingChair, // 58, 0x3A
	UnitPathGoal_SeekEatingChair2, // 59, 0x3B
	UnitPathGoal_SeekBadMoodBuilding, // 60, 0x3C
	UnitPathGoal_SetGlassMoodBuilding, // 61, 0x3D
	UnitPathGoal_SetMoodBuilding, // 62, 0x3E
	UnitPathGoal_SeekFellVictim, // 63, 0x3F
	UnitPathGoal_CleanBuildingSite, // 64, 0x40
	UnitPathGoal_ResetPriorityGoal, // 65, 0x41
	UnitPathGoal_MainJobBuilding, // 66, 0x42
	UnitPathGoal_DropOffJobItems, // 67, 0x43
	UnitPathGoal_GrabJobResources, // 68, 0x44
	UnitPathGoal_WorkAtBuilding, // 69, 0x45
	UnitPathGoal_GrabUniform, // 70, 0x46
	UnitPathGoal_GrabClothing, // 71, 0x47
	UnitPathGoal_GrabWeapon, // 72, 0x48
	UnitPathGoal_GrabAmmunition, // 73, 0x49
	UnitPathGoal_GrabShield, // 74, 0x4A
	UnitPathGoal_GrabArmor, // 75, 0x4B
	UnitPathGoal_GrabHelm, // 76, 0x4C
	UnitPathGoal_GrabBoots, // 77, 0x4D
	UnitPathGoal_GrabGloves, // 78, 0x4E
	UnitPathGoal_GrabPants, // 79, 0x4F
	UnitPathGoal_GrabQuiver, // 80, 0x50
	UnitPathGoal_GrabBackpack, // 81, 0x51
	UnitPathGoal_GrabWaterskin, // 82, 0x52
	UnitPathGoal_StartHunt, // 83, 0x53
	UnitPathGoal_StartFish, // 84, 0x54
	UnitPathGoal_Clean, // 85, 0x55
	UnitPathGoal_HuntVermin, // 86, 0x56
	UnitPathGoal_Patrol, // 87, 0x57
	UnitPathGoal_SquadStation, // 88, 0x58
	UnitPathGoal_SeekInfant, // 89, 0x59
	UnitPathGoal_ShopSpecific, // 90, 0x5A
	UnitPathGoal_MillInShop, // 91, 0x5B
	UnitPathGoal_GoToShop, // 92, 0x5C
	UnitPathGoal_SeekTrainingAmmunition, // 93, 0x5D
	UnitPathGoal_ArcheryTrainingSite, // 94, 0x5E
	UnitPathGoal_SparringPartner, // 95, 0x5F
	UnitPathGoal_SparringSite, // 96, 0x60
	UnitPathGoal_AttendParty, // 97, 0x61
	UnitPathGoal_SeekArtifact, // 98, 0x62
	UnitPathGoal_GrabAmmunitionForBuilding, // 99, 0x63
	UnitPathGoal_SeekBuildingForAmmunition, // 100, 0x64
	UnitPathGoal_SeekItemForStorage, // 101, 0x65
	UnitPathGoal_StoreItem, // 102, 0x66
	UnitPathGoal_GrabKill, // 103, 0x67
	UnitPathGoal_DropKillAtButcher, // 104, 0x68
	UnitPathGoal_DropKillOutFront, // 105, 0x69
	UnitPathGoal_GoToBeatingTarget, // 106, 0x6A
	UnitPathGoal_SeekKidnapVictim, // 107, 0x6B
	UnitPathGoal_SeekHuntingTarget, // 108, 0x6C
	UnitPathGoal_SeekTargetMechanism, // 109, 0x6D
	UnitPathGoal_SeekTargetForMechanism, // 110, 0x6E
	UnitPathGoal_SeekMechanismForTrigger, // 111, 0x6F
	UnitPathGoal_SeekTriggerForMechanism, // 112, 0x70
	UnitPathGoal_SeekTrapForVerminCatch, // 113, 0x71
	UnitPathGoal_SeekVerminForCatching, // 114, 0x72
	UnitPathGoal_SeekVerminCatchLocation, // 115, 0x73
	UnitPathGoal_WanderVerminCatchLocation, // 116, 0x74
	UnitPathGoal_SeekVerminForHunting, // 117, 0x75
	UnitPathGoal_SeekVerminHuntingSpot, // 118, 0x76
	UnitPathGoal_WanderVerminHuntingSpot, // 119, 0x77
	UnitPathGoal_SeekFishTrap, // 120, 0x78
	UnitPathGoal_SeekFishCatchLocation, // 121, 0x79
	UnitPathGoal_SeekWellForWater, // 122, 0x7A
	UnitPathGoal_SeekDrinkAreaForWater, // 123, 0x7B
	UnitPathGoal_UpgradeSquadEquipment, // 124, 0x7C
	UnitPathGoal_PrepareEquipmentManifests, // 125, 0x7D
	UnitPathGoal_WanderDepot, // 126, 0x7E
	UnitPathGoal_SeekUpdateOffice, // 127, 0x7F
	UnitPathGoal_SeekManageOffice, // 128, 0x80
	UnitPathGoal_AssignedBuildingJob, // 129, 0x81
	UnitPathGoal_ChaseOpponent, // 130, 0x82
	UnitPathGoal_FleeFromOpponent, // 131, 0x83
	UnitPathGoal_AttackBuilding, // 132, 0x84
	UnitPathGoal_StartBedCarry, // 133, 0x85
	UnitPathGoal_StartGiveFoodWater, // 134, 0x86
	UnitPathGoal_StartMedicalAid, // 135, 0x87
	UnitPathGoal_SeekStationFlood, // 136, 0x88
	UnitPathGoal_SeekStation, // 137, 0x89
	UnitPathGoal_StartWaterJobWell, // 138, 0x8A
	UnitPathGoal_StartWaterJobDrinkArea, // 139, 0x8B
	UnitPathGoal_StartEatJob, // 140, 0x8C
	UnitPathGoal_ScheduledMeal, // 141, 0x8D
	UnitPathGoal_ScheduledSleepBed, // 142, 0x8E
	UnitPathGoal_ScheduledSleepGround, // 143, 0x8F
	UnitPathGoal_Rest, // 144, 0x90
	UnitPathGoal_RemoveConstruction, // 145, 0x91
	UnitPathGoal_Chop, // 146, 0x92
	UnitPathGoal_Detail, // 147, 0x93
	UnitPathGoal_GatherPlant, // 148, 0x94
	UnitPathGoal_Dig, // 149, 0x95
	UnitPathGoal_Mischief, // 150, 0x96
	UnitPathGoal_ChaseOpponentSameSquare, // 151, 0x97
	UnitPathGoal_RestRecovered, // 152, 0x98
	UnitPathGoal_RestReset, // 153, 0x99
	UnitPathGoal_CombatTraining, // 154, 0x9A
	UnitPathGoal_SkillDemonstration, // 155, 0x9B
	UnitPathGoal_IndividualSkillDrill, // 156, 0x9C
	UnitPathGoal_SeekBuildingForItemDrop, // 157, 0x9D
	UnitPathGoal_SeekBuildingForJob, // 158, 0x9E
	UnitPathGoal_GrabMilkUnit, // 159, 0x9F
	UnitPathGoal_GoToMilkStation, // 160, 0xA0
	UnitPathGoal_SeekPatientForDressWound, // 161, 0xA1
	UnitPathGoal_UndeadHunt, // 162, 0xA2
	UnitPathGoal_GrabShearUnit, // 163, 0xA3
	UnitPathGoal_GoToShearStation, // 164, 0xA4
	UnitPathGoal_LayEggNestBox, // 165, 0xA5
	UnitPathGoal_ClayZone, // 166, 0xA6
	UnitPathGoal_ColonyToInstall, // 167, 0xA7
	UnitPathGoal_ReturnColonyToInstall, // 168, 0xA8
	UnitPathGoal_Nonsense, // 169, 0xA9
	UnitPathGoal_SeekBloodSuckVictim, // 170, 0xAA
	UnitPathGoal_SeekSheriff, // 171, 0xAB
	UnitPathGoal_GrabExecutionWeapon, // 172, 0xAC
	UnitPathGoal_TrainAnimal, // 173, 0xAD
	UnitPathGoal_GuardPath, // 174, 0xAE
	UnitPathGoal_Harass, // 175, 0xAF
	UnitPathGoal_SiteWalk, // 176, 0xB0
	UnitPathGoal_SiteWalkToBuilding, // 177, 0xB1
	UnitPathGoal_Reunion, // 178, 0xB2
	UnitPathGoal_ArmyWalk, // 179, 0xB3
	UnitPathGoal_ChaseOpponentFlood, // 180, 0xB4
	UnitPathGoal_ChargeAttack, // 181, 0xB5
	UnitPathGoal_FleeFromOpponentClimb, // 182, 0xB6
	UnitPathGoal_SeekLadderToClimb, // 183, 0xB7
	UnitPathGoal_SeekLadderToMove, // 184, 0xB8
	UnitPathGoal_PlaceLadder, // 185, 0xB9
	UnitPathGoal_SeekAnimalForGelding, // 186, 0xBA
	UnitPathGoal_SeekGeldingBuilding, // 187, 0xBB
	UnitPathGoal_Prayer, // 188, 0xBC
	UnitPathGoal_Socialize, // 189, 0xBD
	UnitPathGoal_Performance, // 190, 0xBE
	UnitPathGoal_Research, // 191, 0xBF
	UnitPathGoal_PonderTopic, // 192, 0xC0
	UnitPathGoal_FillServiceOrder, // 193, 0xC1
	UnitPathGoal_GetWrittenContent, // 194, 0xC2
	UnitPathGoal_GoToReadingPlace, // 195, 0xC3
	UnitPathGoal_GetWritingMaterials, // 196, 0xC4
	UnitPathGoal_GoToWritingPlace, // 197, 0xC5
	UnitPathGoal_Worship, // 198, 0xC6
	UnitPathGoal_GrabInstrument, // 199, 0xC7
	UnitPathGoal_Play, // 200, 0xC8
	UnitPathGoal_MakeBelieve, // 201, 0xC9
	UnitPathGoal_PlayWithToy, // 202, 0xCA
	UnitPathGoal_GrabToy, // 203, 0xCB
};
]]

-- entity_position_responsibility.h

ffi.cdef[[
typedef int16_t EntityPositionResponsibility;
enum { 
	EntityPositionResponsibility_NONE = -1, // -1, 0xFFFFFFFFFFFFFFFF
	EntityPositionResponsibility_LAW_MAKING, // 0, 0x0
	EntityPositionResponsibility_LAW_ENFORCEMENT, // 1, 0x1
	EntityPositionResponsibility_RECEIVE_DIPLOMATS, // 2, 0x2
	EntityPositionResponsibility_MEET_WORKERS, // 3, 0x3
	EntityPositionResponsibility_MANAGE_PRODUCTION, // 4, 0x4
	EntityPositionResponsibility_TRADE, // 5, 0x5
	EntityPositionResponsibility_ACCOUNTING, // 6, 0x6
	EntityPositionResponsibility_ESTABLISH_COLONY_TRADE_AGREEMENTS, // 7, 0x7
	EntityPositionResponsibility_MAKE_INTRODUCTIONS, // 8, 0x8
	EntityPositionResponsibility_MAKE_PEACE_AGREEMENTS, // 9, 0x9
	EntityPositionResponsibility_MAKE_TOPIC_AGREEMENTS, // 10, 0xA
	EntityPositionResponsibility_COLLECT_TAXES, // 11, 0xB
	EntityPositionResponsibility_ESCORT_TAX_COLLECTOR, // 12, 0xC
	EntityPositionResponsibility_EXECUTIONS, // 13, 0xD
	EntityPositionResponsibility_TAME_EXOTICS, // 14, 0xE
	EntityPositionResponsibility_RELIGION, // 15, 0xF
	EntityPositionResponsibility_ATTACK_ENEMIES, // 16, 0x10
	EntityPositionResponsibility_PATROL_TERRITORY, // 17, 0x11
	EntityPositionResponsibility_MILITARY_GOALS, // 18, 0x12
	EntityPositionResponsibility_MILITARY_STRATEGY, // 19, 0x13
	EntityPositionResponsibility_UPGRADE_SQUAD_EQUIPMENT, // 20, 0x14
	EntityPositionResponsibility_EQUIPMENT_MANIFESTS, // 21, 0x15
	EntityPositionResponsibility_SORT_AMMUNITION, // 22, 0x16
	EntityPositionResponsibility_BUILD_MORALE, // 23, 0x17
	EntityPositionResponsibility_HEALTH_MANAGEMENT, // 24, 0x18
	EntityPositionResponsibility_ESPIONAGE, // 25, 0x19
	EntityPositionResponsibility_ADVISE_LEADERS, // 26, 0x1A
	EntityPositionResponsibility_OVERSEE_LEADER_HOUSEHOLD, // 27, 0x1B
	EntityPositionResponsibility_MANAGE_ANIMALS, // 28, 0x1C
	EntityPositionResponsibility_MANAGE_LEADER_HOUSEHOLD_FOOD, // 29, 0x1D
	EntityPositionResponsibility_MANAGE_LEADER_HOUSEHOLD_DRINKS, // 30, 0x1E
	EntityPositionResponsibility_PREPARE_LEADER_MEALS, // 31, 0x1F
	EntityPositionResponsibility_MANAGE_LEADER_HOUSEHOLD_CLEANLINESS, // 32, 0x20
	EntityPositionResponsibility_MAINTAIN_SEWERS, // 33, 0x21
	EntityPositionResponsibility_FOOD_SUPPLY, // 34, 0x22
	EntityPositionResponsibility_FIRE_SAFETY, // 35, 0x23
	EntityPositionResponsibility_JUDGE, // 36, 0x24
	EntityPositionResponsibility_BUILDING_SAFETY, // 37, 0x25
	EntityPositionResponsibility_CONSTRUCTION_PERMITS, // 38, 0x26
	EntityPositionResponsibility_MAINTAIN_ROADS, // 39, 0x27
	EntityPositionResponsibility_MAINTAIN_BRIDGES, // 40, 0x28
	EntityPositionResponsibility_MAINTAIN_TUNNELS, // 41, 0x29
};
]]

-- pronoun_type.h

ffi.cdef[[
typedef int8_t Gender;
enum {
	Gender_UNKNOWN = -1,
	Gender_FEMALE = 0,
	Gender_MALE = 1,
};
]]

-- animal_training_level.h

ffi.cdef[[
typedef int32_t AnimalTrainingLevel;
enum {
	AnimalTrainingLevel_SemiWild, // 0, 0x0
	AnimalTrainingLevel_Trained, // 1, 0x1
	AnimalTrainingLevel_WellTrained, // 2, 0x2
	AnimalTrainingLevel_SkilfullyTrained, // 3, 0x3
	AnimalTrainingLevel_ExpertlyTrained, // 4, 0x4
	AnimalTrainingLevel_ExceptionallyTrained, // 5, 0x5
	AnimalTrainingLevel_MasterfullyTrained, // 6, 0x6
	AnimalTrainingLevel_Domesticated, // 7, 0x7
	AnimalTrainingLevel_Unk8, // 8, 0x8
	AnimalTrainingLevel_WildUntamed, // 9, 0x9
};
]]

-- mood_type.h

ffi.cdef[[
typedef int16_t MoodType;
enum {
	MoodType_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	MoodType_Fey, // 0, 0x0
	MoodType_Secretive, // 1, 0x1
	MoodType_Possessed, // 2, 0x2
	MoodType_Macabre, // 3, 0x3
	MoodType_Fell, // 4, 0x4
	MoodType_Melancholy, // 5, 0x5
	MoodType_Raving, // 6, 0x6
	MoodType_Berserk, // 7, 0x7
	MoodType_Baby, // 8, 0x8
	MoodType_Traumatized, // 9, 0x9
};
]]

-- unit_genes.h

ffi.cdef[[
typedef struct {
	dfarray_byte appearance;
	dfarray_short colors;
} UnitGenes;
]]

-- unit.h

-- TODO
ffi.cdef[[
typedef struct UnitGhostInfo UnitGhostInfo;
]]
makeVectorPtr'UnitInventoryItem'
makeVectorPtr'Building'

ffi.cdef[[
typedef uint8_t UnitMeetingState;
enum {
	UnitMeetingState_SelectNoble = 0,
	UnitMeetingState_FollowNoble = 1,
	UnitMeetingState_DoMeeting = 2,
	UnitMeetingState_LeaveMap = 3,
};
struct Unit {
	void * vtable;	/* TODO */
	LanguageName name;
	std_string customProfession;
	Profession profession;
	Profession profession2;
	int32_t race;
	Coord pos;
	Coord idleArea;
	int32_t idleAreaThreshold;
	UnitStationType idleAreaType;
	int32_t followDistance;
	struct {
		Coord dest;
		UnitPathGoal goal;
		CoordPath path;
	} path;

	/* unit_flags1 */
	uint32_t moveState : 1; /*!< Can the dwarf move or are they waiting for their movement timer */
	uint32_t inactive : 1; /*!< Set for dead units and incoming/leaving critters that are alive but off-map */
	uint32_t hasMood : 1; /*!< Currently in mood */
	uint32_t hadMood : 1; /*!< Had a mood already */
	uint32_t marauder : 1; /*!< wide class of invader/inside creature attackers */
	uint32_t drowning : 1; /*!< Is currently drowning */
	uint32_t merchant : 1; /*!< An active merchant */
	uint32_t forest : 1; /*!< used for units no longer linked to merchant/diplomacy, they just try to leave mostly */
	uint32_t left : 1; /*!< left the map */
	uint32_t rider : 1; /*!< Is riding an another creature */
	uint32_t incoming : 1;
	uint32_t diplomat : 1;
	uint32_t zombie : 1;
	uint32_t skeleton : 1;
	uint32_t canSwap : 1; /*!< Can swap tiles during movement (prevents multiple swaps) */
	uint32_t onGround : 1; /*!< The creature is laying on the floor, can be conscious */
	uint32_t projectile : 1; /*!< Launched into the air? Funny. */
	uint32_t activeInvader : 1; /*!< Active invader (for organized ones) */
	uint32_t hiddenInAmbush : 1;
	uint32_t invaderOrigin : 1; /*!< Invader origin (could be inactive and fleeing) */
	uint32_t coward : 1; /*!< Will flee if invasion turns around */
	uint32_t hiddenAmbusher : 1; /*!< Active marauder/invader moving inward? */
	uint32_t invades : 1; /*!< Marauder resident/invader moving in all the way */
	uint32_t checkFlows : 1; /*!< Check against flows next time you get a chance */
	uint32_t ridden : 1;
	uint32_t caged : 1;
	uint32_t tame : 1;
	uint32_t chained : 1;
	uint32_t royalGuard : 1;
	uint32_t fortressGuard : 1;
	uint32_t suppressWield : 1;
	uint32_t importantHistoricalFigure : 1; /*!< Is an important historical figure */

	/* unit_flags2 */
	uint32_t swimming : 1;
	uint32_t sparring : 1; /*!< works, but not set for sparring military dwarves(?) (since 0.40.01?) */
	uint32_t noNotify : 1; /*!< Do not notify about level gains (for embark etc) */
	uint32_t unused : 1;
	uint32_t calculatedNerves : 1;
	uint32_t calculatedBodyParts : 1;
	uint32_t importantHistoricalFigure : 1; /*!< Is important historical figure (slight variation) */
	uint32_t killed : 1; /*!< Has been killed by kill function (slightly different from dead, not necessarily violent death) */
	uint32_t cleanup1 : 1; /*!< Must be forgotten by forget function (just cleanup) */
	uint32_t cleanup2 : 1; /*!< Must be deleted (cleanup) */
	uint32_t cleanup3 : 1; /*!< Recently forgotten (cleanup) */
	uint32_t forTrade : 1; /*!< Offered for trade */
	uint32_t tradeResolved : 1;
	uint32_t hasBreaks : 1;
	uint32_t gutted : 1;
	uint32_t circulatorySpray : 1;
	uint32_t lockedInForTrading : 1; /*!< Locked in for trading (it's a projectile on the other set of flags, might be what the flying was) */
	uint32_t slaughter : 1; /*!< marked for slaughter */
	uint32_t underworld : 1; /*!< Underworld creature */
	uint32_t resident : 1; /*!< Current resident */
	uint32_t cleanup4 : 1; /*!< Marked for special cleanup as unused load from unit block on disk */
	uint32_t calculatedInsulation : 1; /*!< Insulation from clothing calculated */
	uint32_t visitorUninvited : 1; /*!< Uninvited guest */
	uint32_t visitor : 1;
	uint32_t calculatedInventory : 1; /*!< Inventory order calculated */
	uint32_t visionGood : 1; /*!< Vision -- have good part */
	uint32_t visionDamaged : 1; /*!< Vision -- have damaged part */
	uint32_t visionMissing : 1; /*!< Vision -- have missing part */
	uint32_t breathingGood : 1; /*!< Breathing -- have good part */
	uint32_t breathingProblem : 1; /*!< Breathing -- having a problem */
	uint32_t roamingWildernessPopulationSource : 1;
	uint32_t roamingWildernessPopulationSourceNotAMapFeature : 1;

	/* unit_flags3 */
	uint32_t bodyPartRelsizeComputed : 1;
	uint32_t sizeModifierComputed : 1;
	uint32_t stuckWeaponComputed : 1; /*!< cleared if removing StuckIn item to recompute wound flags. */
	uint32_t computeHealth : 1; /*!< causes the health structure to be created or updated */
	uint32_t announceTitan : 1; /*!< Announces creature like an FB or titan. */
	uint32_t unk_3_5 : 1;
	uint32_t onCrutch : 1;
	uint32_t weightComputed : 1;
	uint32_t bodyTempInRange : 1; /*!< Is set to 1 every tick for non-dead creatures. */
	uint32_t waitUntilReveal : 1; /*!< Blocks all kind of things until tile is revealed. */
	uint32_t scuttle : 1;
	uint32_t unk_3_11 : 1;
	uint32_t ghostly : 1;
	uint32_t unk_3_13 : 1;
	uint32_t unk_3_14 : 1;
	uint32_t unk_3_15 : 1; /*!< dropped when znew >= zold */
	uint32_t unk_3_16 : 1; /*!< something to do with werewolves? */
	uint32_t noMeandering : 1; /*!< for active_invaders */
	uint32_t floundering : 1;
	uint32_t exitVehicle1 : 1; /*!< trapavoid */
	uint32_t exitVehicle2 : 1; /*!< trapavoid */
	uint32_t dangerousTerrain : 1;
	uint32_t advYield : 1;
	uint32_t visionConeSet : 1;
	uint32_t unk_3_24 : 1;
	uint32_t emotionallyOverloaded : 1; /*!< since v0.40.01 */
	uint32_t unk_3_26 : 1;
	uint32_t availableForAdoption : 1;
	uint32_t gelded : 1;
	uint32_t markedForGelding : 1;
	uint32_t injuryThought : 1;
	uint32_t unk_3_31 : 1; /*!< causes No Activity to be displayed */

	/* unit_flags4 */
	uint32_t unk_4_0 : 1;
	uint32_t unk_4_1 : 1;
	uint32_t unk_4_2 : 1;
	uint32_t unk_4_3 : 1;

	struct {
		UnitMeetingState state;	/* UnitMeetingState_* */ 
		/* umm should this struct be packed? */
		uint32_t targetEntity;
		EntityPositionResponsibility targetRole;
		char pad_1[2];
	} meeting;

	int16_t caste;
	Gender sex;
	int32_t id;
	int16_t unk_100;
	AnimalTrainingLevel trainingLevel;
	int32_t scheduleID;
	int32_t civID;
	int32_t populationID;
	int32_t unk_c0; /*!< since v0.34.01 */
	int32_t culturalIdentity; /*!< since v0.40.01 */
	int32_t invasionID;
	CoordPath patrolRoute; /*!< used by necromancers for corpse locations, siegers etc */
	int32_t patrolIndex; /*!< from 23a */
	vector_SpecificRef_ptr specificRefs;
	vector_GeneralRef_ptr generalRefs;

	struct {
		int32_t squadID;
		int32_t squadPosition;
		int32_t patrolCoolDown;
		int32_t patrolTimer;
		int16_t curUniform;
		vector_int unk_items; /*!< since v0.34.06 */
		vector_int uniforms[4];
		union {
			uint32_t whole;	/* not needed? */
			uint32_t update : 1;
		} pickupFlags;	/* aslo not needed?  just pickupUpdate intead? */
		vector_int uniformPickup;
		vector_int uniformDrop;
		vector_int individualDrills;
	} military;

	vector_int socialActivities;
	vector_int conversations; /*!< since v0.40.01 */
	vector_int activities;
	vector_int unk_1e8; /*!< since v0.40.01 */
	struct {
		WorldPopulationRef population;
		int32_t leaveCountdown; /*!< once 0, it heads for the edge and leaves */
		int32_t vanishCountdown; /*!< once 0, it vanishes in a puff of smoke */
	} animal;
	struct {
		int32_t unitID; /*!< since v0.40.01 */
		Coord unitPos; /*!< since v0.40.01 */
		int32_t unk_c; /*!< since v0.40.01 */
	} opponent;

	MoodType mood;
	int16_t unk_18e;
	uint32_t pregnancyTimer;
	UnitGenes * pregnancyGenes; /*!< genes from mate */
	int16_t pregnancyCaste; /*!< caste of mate */
	int32_t pregnancySpouse;
	MoodType moodCopy; /*!< copied from mood type upon entering strange mood */
	UnitGhostInfo * ghostInfo;
	int32_t unk_9; /*!< since v0.34.01 */
	int32_t birthYear;
	int32_t birthTime;
	int32_t curseYear; /*!< since v0.34.01 */
	int32_t curseTime; /*!< since v0.34.01 */
	int32_t birthYearBias; /*!< since v0.34.01 */
	int32_t birthTimeBias; /*!< since v0.34.01 */
	int32_t oldYear; /*!< could there be a death of old age time?? */
	int32_t oldTime;

	struct Unit * following;
	uint16_t unk_238; /*!< invalid unless following */
	int32_t relationshipIDs[10];
	int16_t mountType; /*!< 0 = riding, 1 = being carried, 2/3 = wagon horses, 4 = wagon merchant */
	HistoryHitItem lastHit;
	int32_t ridingItemID; /*!< since v0.34.08 */
	vector_UnitInventoryItem_ptr inventory;
	vector_int ownedItems;
	vector_int tradedItems; /*!< items brought to trade depot */
	vector_Building_ptr ownedBuildings;
	vector_int corpseParts; /*!< entries remain even when items are destroyed */
};
typedef struct Unit Unit;
]]

-- item.h

ffi.cdef[[
typedef struct {
	void * vtable; /* TODO */
	
	Coord pos;

	/* item_flags */
	uint32_t onGround : 1; /*!< Item on ground */
	uint32_t inJob : 1; /*!< Item currently being used in a job */
	uint32_t hostile : 1; /*!< Item owned by hostile */
	uint32_t inInventory : 1; /*!< Item in a creature, workshop or container inventory */
	uint32_t removed : 1; /*!< completely invisible and with no position */
	uint32_t inBuilding : 1; /*!< Part of a building (including mechanisms, bodies in coffins) */
	uint32_t container : 1; /*!< Set on anything that contains or contained items? */
	uint32_t deadDwarf : 1; /*!< Dwarfs dead body or body part */
	uint32_t rotten : 1; /*!< Rotten food */
	uint32_t spiderWeb : 1; /*!< Thread in spider web */
	uint32_t construction : 1; /*!< Material used in construction */
	uint32_t encased : 1; /*!< Item encased in ice or obsidian */
	uint32_t unk_1_12 : 1; /*!< unknown, unseen */
	uint32_t murder : 1; /*!< Implies murder - used in fell moods */
	uint32_t foreign : 1; /*!< Item is imported */
	uint32_t trader : 1; /*!< Item ownwed by trader */
	uint32_t owned : 1; /*!< Item is owned by a dwarf */
	uint32_t garbage_collect : 1; /*!< Marked for deallocation by DF it seems */
	uint32_t artifact : 1; /*!< Artifact */
	uint32_t forbid : 1; /*!< Forbidden item */
	uint32_t alreadyUncategorized : 1; /*!< unknown, unseen */
	uint32_t dump : 1; /*!< Designated for dumping */
	uint32_t onFire : 1; /*!< Indicates if item is on fire, Will Set Item On Fire if Set! */
	uint32_t melt : 1; /*!< Designated for melting, if applicable */
	uint32_t hidden : 1; /*!< Hidden item */
	uint32_t inChest : 1; /*!< Stored in chest/part of well? */
	uint32_t useRecorded : 1; /*!< transient in unit.used_items update */
	uint32_t artifact_mood : 1; /*!< created by mood/named existing item */
	uint32_t tempsComputed : 1; /*!< melting/boiling/ignite/etc. points */
	uint32_t weightComputed : 1;
	uint32_t unk_1_30 : 1; /*!< unknown, unseen */
	uint32_t fromWorldgen : 1; /*!< created by underground critters? */

	/* item_flags2 */
	uint32_t hasRider : 1; /*!< vehicle with a rider */
	uint32_t unk_2_1 : 1;
	uint32_t grown : 1;
	uint32_t unkBook : 1; /*!< possibly book/written-content-related */
	uint32_t anon_1 : 1;
	
	uint32_t age;
	int32_t id;
	vector_SpecificRef_ptr specificRefs;
	vector_GeneralRef_ptr generalRefs;
	int32_t worldDataID; /*!< since v0.34.01 */
	int32_t worldDataSubID; /*!< since v0.34.01 */
	uint8_t stockpileCountdown; /*!< -1 per 50 frames; then check if needs moving */
	uint8_t stockpileDelay; /*!< used to reset countdown; randomly varies */
	int16_t unk2;
	int32_t baseUniformScore;
	int16_t walkableID; /*!< from map_block.walkable */
	uint16_t specHeat;
	uint16_t ignitePoint;
	uint16_t heatdamPoint;
	uint16_t colddamPoint;
	uint16_t boilingPoint;
	uint16_t meltingPoint;
	uint16_t fixedTemp;
	int32_t weight; /*!< if flags.weight_computed */
	int32_t weightFraction; /*!< 1e-6 */
} Item;
]]

-- vermin_category.h

ffi.cdef[[
typedef int16_t VerminCategory;
enum {		
	VerminCategory_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	VerminCategory_Eater, // 0, 0x0
	VerminCategory_Grounder, // 1, 0x1
	VerminCategory_Rotter, // 2, 0x2
	VerminCategory_Swamper, // 3, 0x3
	VerminCategory_Searched, // 4, 0x4
	VerminCategory_Disturbed, // 5, 0x5
	VerminCategory_Dropped, // 6, 0x6
};
]]

-- vermin.h

ffi.cdef[[
typedef struct {
	int16_t race;
	int16_t caste;
	Coord pos;
	bool visible;
	int16_t countdown;
	Item * item;
	
	/* vermin_flags */
	uint32_t anon_1 : 1;
	uint32_t is_colony : 1;
	uint32_t anon_2 : 1;
	uint32_t is_roaming_colony : 1;
	uint32_t anon_3 : 1;
	
	int32_t amount;
	WorldPopulationRef population;
	VerminCategory category;	/* VerminCategory_* */
	int32_t id;
} Vermin;
]]

-- glowing_barrier.h

ffi.cdef[[
typedef struct {
	bool triggered;
	int32_t unk_1;
	vector_int buildings;
	Coord pos;
} GlowingBarrier;
]]

-- deep_vein_hollow.h

ffi.cdef[[
typedef struct {
	bool triggered;
	int32_t unk_1;
	CoordPath tiles;
	Coord pos;
} DeepVeinHollow;
]]

-- cursed_tomb.h

makeVectorPtr'Rect3D'

ffi.cdef[[
typedef struct {
	int8_t triggered;	// vs bool?
	vector_int coffinSkeletons;
	int32_t disturbance;
	vector_int treasures;
	int32_t unk_1;
	int32_t unk_2;
	vector_Rect3D_ptr triggerRegions;
	Coord coffinPos;
} CursedTomb;
]]

-- world.h

-- TODO codegen + methods with proper types
-- and not just typedef to void* vector
for T in ([[
GlowingBarrier
DeepVeinHollow
CursedTomb
Engraving
Vermin
Coord
Campfire
WebCluster
Fire
OceanWaveMaker
OceanWave
Construction
Rect2pt5D
EmbarkFeature
EffectInfo
CoinBatch
LocalPopulation
ManagerOrder
Mandate
]]):gmatch'%w+' do
	makeVectorPtr(T)
end

ffi.cdef[[
typedef struct {
	vector_GlowingBarrier_ptr glowingBarriers;
	vector_DeepVeinHollow_ptr deepVeinHollows;
	vector_CursedTomb_ptr cursedTombs;
	vector_Engraving_ptr engravings;
	
	struct {
		vector_Vermin_ptr all, colonies;
	} vermin;
	
	vector_Coord_ptr dirtyWaters; /*!< for making blood flow downstream in rivers, but also includes mud in artificial water channels */
	vector_Campfire_ptr campfires;
	vector_WebCluster_ptr webClusters;
	vector_Fire_ptr fires;
	
	vector_OceanWaveMaker_ptr oceanWaveMakers;
	vector_OceanWave_ptr oceanWaves;
	vector_Construction_ptr constructions;
	vector_Rect2pt5D_ptr murkyPools;
	vector_EmbarkFeature_ptr embarkFeatures; /*!< populated at embark */

	struct {
		vector_GlowingBarrier_ptr glowingBarriers;
		vector_DeepVeinHollow_ptr deepVeinHollows;
		vector_CursedTomb_ptr cursedTombs;
		vector_Engraving_ptr engravings;
		
		vector_Construction_ptr constructions;
		vector_EmbarkFeature_ptr embarkFeatures;
		vector_OceanWaveMaker_ptr oceanWaveMakers;
		vector_Rect2pt5D_ptr murkyPools;
	} site;
	
	vector_EffectInfo_ptr effects;
	vector_CoinBatch_ptr coinBatches;
	vector_LocalPopulation_ptr populations;
	vector_ManagerOrder_ptr managerOrders;
	int32_t managerOrderNextID;
	vector_Mandate_ptr mandates;

	struct {
		vector_HistoricalEntity_ptr all, bad;
	} entities;

	struct {
		Coord2D slots[20000];
		int16_t nextSlot;
	} worldgenCoordBuf;

	struct {
		vector_Unit_ptr all, active;
		
		/* units_other */
		vector_Unit_ptr other_ANY_RIDER, other_ANY_BABY2;
		
		vector_Unit_ptr bad;
		vector_ptr unknown;
	} units;
	vector_UnitChunk_ptr unitChunks;
	vector_ArtImageChunk_ptr artImageChunks;
	
	struct {
		vector_NemesisRecord_ptr all, other[28], bad;
		bool unk4;
	} nemesis;

	struct {
		vector_Item_ptr all;
		
		vector_Item_ptr IN_PLAY;
		vector_Item_ptr ANY_ARTIFACT;
		vector_item_weaponst_ptr WEAPON;
		vector_Item_ptr ANY_WEAPON;
		vector_Item_ptr ANY_SPIKE;
		vector_item_armorst_ptr ANY_TRUE_ARMOR;
		vector_item_helmst_ptr ANY_ARMOR_HELM;
		vector_item_shoesst_ptr ANY_ARMOR_SHOES;
		vector_item_shieldst_ptr SHIELD;
		vector_item_glovesst_ptr ANY_ARMOR_GLOVES;
		vector_item_pantsst_ptr ANY_ARMOR_PANTS;
		vector_item_quiverst_ptr QUIVER;
		vector_item_splintst_ptr SPLINT;
		vector_item_orthopedic_castst_ptr ORTHOPEDIC_CAST;
		vector_item_crutchst_ptr CRUTCH;
		vector_item_backpackst_ptr BACKPACK;
		vector_item_ammost_ptr AMMO;
		vector_item_woodst_ptr WOOD;
		vector_item_branchst_ptr BRANCH;
		vector_item_boulderst_ptr BOULDER;
		vector_item_rockst_ptr ROCK;
		vector_Item_ptr ANY_REFUSE;
		vector_Item_ptr ANY_GOOD_FOOD;
		vector_Item_ptr ANY_AUTO_CLEAN;
		vector_Item_ptr ANY_GENERIC24;
		vector_Item_ptr ANY_BUTCHERABLE;
		vector_Item_ptr ANY_FURNITURE;
		vector_Item_ptr ANY_CAGE_OR_TRAP;
		vector_Item_ptr ANY_EDIBLE_RAW;
		vector_Item_ptr ANY_EDIBLE_CARNIVORE;
		vector_Item_ptr ANY_EDIBLE_BONECARN;
		vector_Item_ptr ANY_EDIBLE_VERMIN;
		vector_Item_ptr ANY_EDIBLE_VERMIN_BOX;
		vector_Item_ptr ANY_CAN_ROT;
		vector_Item_ptr ANY_MURDERED;
		vector_Item_ptr ANY_DEAD_DWARF;
		vector_Item_ptr ANY_GENERIC36;
		vector_Item_ptr ANY_GENERIC37;
		vector_Item_ptr ANY_GENERIC38;
		vector_Item_ptr ANY_GENERIC39;
		vector_item_doorst_ptr DOOR;
		vector_item_floodgatest_ptr FLOODGATE;
		vector_item_hatch_coverst_ptr HATCH_COVER;
		vector_item_gratest_ptr GRATE;
		vector_item_cagest_ptr CAGE;
		vector_item_flaskst_ptr FLASK;
		vector_item_windowst_ptr WINDOW;
		vector_item_gobletst_ptr GOBLET;
		vector_item_instrumentst_ptr INSTRUMENT;
		vector_item_instrumentst_ptr INSTRUMENT_STATIONARY;
		vector_item_toyst_ptr TOY;
		vector_item_toolst_ptr TOOL;
		vector_item_bucketst_ptr BUCKET;
		vector_item_barrelst_ptr BARREL;
		vector_item_chainst_ptr CHAIN;
		vector_item_animaltrapst_ptr ANIMALTRAP;
		vector_item_bedst_ptr BED;
		vector_item_traction_benchst_ptr TRACTION_BENCH;
		vector_item_chairst_ptr CHAIR;
		vector_item_coffinst_ptr COFFIN;
		vector_item_tablest_ptr TABLE;
		vector_item_statuest_ptr STATUE;
		vector_item_slabst_ptr SLAB;
		vector_item_quernst_ptr QUERN;
		vector_item_millstonest_ptr MILLSTONE;
		vector_item_boxst_ptr BOX;
		vector_item_binst_ptr BIN;
		vector_item_armorstandst_ptr ARMORSTAND;
		vector_item_weaponrackst_ptr WEAPONRACK;
		vector_item_cabinetst_ptr CABINET;
		vector_item_anvilst_ptr ANVIL;
		vector_item_catapultpartsst_ptr CATAPULTPARTS;
		vector_item_ballistapartsst_ptr BALLISTAPARTS;
		vector_item_siegeammost_ptr SIEGEAMMO;
		vector_item_trappartsst_ptr TRAPPARTS;
		vector_item_threadst_ptr ANY_WEBS;
		vector_item_pipe_sectionst_ptr PIPE_SECTION;
		vector_Item_ptr ANY_ENCASED;
		vector_Item_ptr ANY_IN_CONSTRUCTION;
		vector_item_drinkst_ptr DRINK;
		vector_item_drinkst_ptr ANY_DRINK;
		vector_item_liquid_miscst_ptr LIQUID_MISC;
		vector_item_powder_miscst_ptr POWDER_MISC;
		vector_Item_ptr ANY_COOKABLE;
		vector_Item_ptr ANY_GENERIC84;
		vector_item_verminst_ptr VERMIN;
		vector_item_petst_ptr PET;
		vector_Item_ptr ANY_CRITTER;
		vector_item_coinst_ptr COIN;
		vector_item_globst_ptr GLOB;
		vector_item_trapcompst_ptr TRAPCOMP;
		vector_item_barst_ptr BAR;
		vector_item_smallgemst_ptr SMALLGEM;
		vector_item_blocksst_ptr BLOCKS;
		vector_item_roughst_ptr ROUGH;
		vector_item_body_component_ptr ANY_CORPSE;
		vector_item_corpsest_ptr CORPSE;
		vector_item_bookst_ptr BOOK;
		vector_item_figurinest_ptr FIGURINE;
		vector_item_amuletst_ptr AMULET;
		vector_item_scepterst_ptr SCEPTER;
		vector_item_crownst_ptr CROWN;
		vector_item_ringst_ptr RING;
		vector_item_earringst_ptr EARRING;
		vector_item_braceletst_ptr BRACELET;
		vector_item_gemst_ptr GEM;
		vector_item_corpsepiecest_ptr CORPSEPIECE;
		vector_item_remainsst_ptr REMAINS;
		vector_item_meatst_ptr MEAT;
		vector_item_fishst_ptr FISH;
		vector_item_fish_rawst_ptr FISH_RAW;
		vector_item_eggst_ptr EGG;
		vector_item_seedsst_ptr SEEDS;
		vector_item_plantst_ptr PLANT;
		vector_item_skin_tannedst_ptr SKIN_TANNED;
		vector_item_plant_growthst_ptr PLANT_GROWTH;
		vector_item_threadst_ptr THREAD;
		vector_item_clothst_ptr CLOTH;
		vector_item_sheetst_ptr SHEET;
		vector_item_totemst_ptr TOTEM;
		vector_item_pantsst_ptr PANTS;
		vector_item_cheesest_ptr CHEESE;
		vector_item_foodst_ptr FOOD;
		vector_item_ballistaarrowheadst_ptr BALLISTAARROWHEAD;
		vector_item_armorst_ptr ARMOR;
		vector_item_shoesst_ptr SHOES;
		vector_item_helmst_ptr HELM;
		vector_item_glovesst_ptr GLOVES;
		vector_Item_ptr ANY_GENERIC128;
		vector_Item_ptr FOOD_STORAGE;
		vector_Item_ptr ANY_RECENTLY_DROPPED;
		vector_Item_ptr ANY_MELT_DESIGNATED;

		vector_Item_ptr bad;
		vector_int badTag;
	} items;

	struct {
		vector_ArtifactRecord_ptr all, bad;
	} artifacts;

	JobHandler jobs;
	ProjListLink projList;
	BuildingHandler buildings;
	MachineHandler machines;

	struct {
		vector_FlowGuide_ptr all, bad;
	} flowGuides;

	struct {
		int32_t numJobs[10];
		int32_t numHaulers[10];
		struct {
			int8_t unk_1, food, unk_2, unk_3;
		} simple1;
		vector_int8_t seeds, plants, cheese, meat_fish, eggs, leaves, plant_powder;
		struct {
			int8_t seeds, plants, cheese, fish, meat, leaves, powder, eggs;
		} simple2;
		vector_int8_t liquid_plant, liquid_animal, liquid_builtin;
		struct {
			int8_t globFat, globTallow, globPaste, globPressed, weapons, shield, ammo, coins, barBlocks, gems, finishedGoods, tannedSkins, threadCloth, unk1, unk2, unk3;
		} simple3;
	} stockpile;

	struct {
		vector_Plant_ptr all, shrubDry, shrubWet, treeDry, treeWet, empty;
	} plants;

	struct {
		bool slotsUsed[500];
		int32_t relMap[500][500];
		int32_t nextSlot;
	} enemyStatusCache;

	struct {
		vector_ScheduleInfo_ptr all, bad;
	} schedules;

	struct {
		vector_Squad_ptr all, bad;
	} squads;

	struct {
		vector_int_ptr all
		vector_ptr bad;
	} formations;

	struct {
		vector_ActivityEntry_ptr all, bad;
	} activities;

	struct {
		vector_Report_ptr reports, annuncements;
		vector_PopupMessage_ptr popups;
		int32_t nextReportID;
		union {
			struct {
				uint32_t combat : 1;
				uint32_t hunting : 1;
				uint32_t sparring : 1;
			};
			uint32_t flags;
		};
		int32_t unk_1[9];
		vector_MissionReport_ptr missionReports;
		vector_SpoilsReport_ptr spoilsReports;
		vector_InterrogationReport_ptr interrogationReports;
		int32_t displayTimer;

		// ... TODO
	} status;
	
	// ... TODO
} World;
]]
