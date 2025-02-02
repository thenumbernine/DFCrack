--[[
half hearted manually procured file of the globals.
get rid of this in favor of xml-generated dfcrack/df/*.lua

TODO autogen some C++ code for vanilla dfhack to write out all library/include/df/*.h struct sizeof()'s and offsetof()'s
then insert it into somewhere like library/LuaApi.cpp,
run it, get back the C++ offsets and sizeofs as Lua code
insert it into dfcrack as an initializatin test
you can even generate and store this per-version per-os
--]]
local ffi = require 'ffi'
local template = require 'template'
local struct = require 'struct'

local assert = require 'ext.assert'
local assertsizeof = require 'assertsizeof'

local vec2s = require 'vec-ffi.vec2s'
local vec3s = require 'vec-ffi.vec3s'
local vec3i = require 'vec-ffi.vec3i'
-- not sure if i like glsl or hlsl naming convention more...
ffi.cdef[[
typedef vec2s_t short2_t;
typedef vec3s_t short3_t;
typedef vec3i_t int3_t;
]]

require 'std.string'
require 'std.fstream'
local makeStdVector = require 'std.vector'
local makeList = require 'list'
local makeDfArray = require 'dfarray'

makeStdVector('char', 'vector_char')
makeStdVector('int8_t', 'vector_int8')
makeStdVector('uint8_t', 'vector_uint8')
makeStdVector('short', 'vector_int16')
makeStdVector('unsigned short', 'vector_uint16')
makeStdVector('int', 'vector_int32')
makeStdVector('unsigned int', 'vector_uint32')
makeStdVector('std_string', 'vector_string')

makeStdVector('void*', 'vector_ptr')
makeStdVector('char*', 'vector_char_ptr')

-- TODO WTF WHO USES BOOL VECTOR?!?!?!??!
-- this is guaranteed to be broken.  at best, array size is >>3 the vector size
-- at worse, it's a fully dif struct underneath
ffi.cdef[[
typedef struct vector_bool {
	uint8_t * v;
	uint8_t * idk[4];
} vector_bool;
]]
assertsizeof('vector_bool', 40)

-- 'T' is the ptr base type
local function makeStdVectorPtr(T, name)
	-- TODO '_ptr' suffix vs 'p' prefix?
	name = name or 'vector_'..T..'_ptr'
	return makeStdVector(T..' *', name)
end

makeStdVectorPtr'int'
makeStdVectorPtr('std_string', 'vector_string_ptr')

makeDfArray('uint8_t', 'dfarray_uint8')
makeDfArray('int16_t', 'dfarray_int16')
ffi.cdef'typedef dfarray_uint8 dfarray_byte;'	-- right?
makeDfArray'short'

-- except that its indexes and size are >>3
-- BitArray
local DFBitArray = require 'dfbitarray'

-- fwd decls:

ffi.cdef'typedef struct Building Building;'
makeStdVectorPtr'Building'

-- coord.h, coord2d.h

-- dfhack naming
ffi.cdef[[
typedef short3_t Coord;
typedef short2_t Coord2D;
]]

-- used in a few places:
ffi.cdef[[
typedef struct Rect3D {
	int3_t start, end;
} Rect3D;
]]

-- coord_rect.h aka

ffi.cdef[[
typedef struct Rect2pt5D {
	Coord2D v1, v2;
	int16_t z;
} Rect2pt5D;
typedef Rect2pt5D CoordRect;
]]
makeStdVectorPtr'CoordRect'

-- coord2d_path.h

ffi.cdef[[
typedef struct Coord2DPath {
	vector_int16 x;
	vector_int16 y;
} Coord2DPath;
]]

-- coord_path.h

-- more like a vector-of-coords in SOA format
-- used for generic vector-of-coords, not necessarily as a path
ffi.cdef[[
typedef struct CoordPath {
	vector_int16 x;
	vector_int16 y;
	vector_int16 z;
} CoordPath;
]]


-- tile_bitmask.h

-- why not uint32_t[8] ?
ffi.cdef[[
typedef struct TileBitmask {
	uint16_t bits[16];
} TileBitmask;
]]

-- block_burrow_link.h

ffi.cdef[[
struct BlockBurrow;
typedef struct BlockBurrow BlockBurrow;
]]
makeList'BlockBurrow'

-- block_burrow.h

ffi.cdef[[
struct BlockBurrow {
	int32_t id;
	TileBitmask tile_bitmask;
	list_BlockBurrow * link;
};
]]

-- burrow.h

ffi.cdef'typedef struct Burrow Burrow;'
makeStdVectorPtr'Burrow'

-- general_ref.h

ffi.cdef[[
typedef struct GeneralRef {
	void * vtable;	/* todo */
} GeneralRef;
]]
makeStdVectorPtr'GeneralRef'

-- specific_ref_type.h

-- maybe luajit can handle enum typedefs, but there's still no namespaces for the constants, so why bother
ffi.cdef[[
typedef int32_t SpecificRefType;
enum {
	SpecificRefType_NONE = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	SpecificRefType_anon_1, /* 0, 0x0*/
	SpecificRefType_UNIT, /* 1, 0x1*/
	SpecificRefType_JOB, /* 2, 0x2*/
	SpecificRefType_BUILDING_PARTY, /* 3, 0x3*/
	SpecificRefType_ACTIVITY, /* 4, 0x4*/
	SpecificRefType_ITEM_GENERAL, /* 5, 0x5*/
	SpecificRefType_EFFECT, /* 6, 0x6*/
	SpecificRefType_PETINFO_PET, /* 7, 0x7*/
	SpecificRefType_PETINFO_OWNER, /* 8, 0x8*/
	SpecificRefType_VERMIN_EVENT, /* 9, 0x9*/
	SpecificRefType_VERMIN_ESCAPED_PET, /* 10, 0xA*/
	SpecificRefType_ENTITY, /* 11, 0xB*/
	SpecificRefType_PLOT_INFO, /* 12, 0xC*/
	SpecificRefType_VIEWSCREEN, /* 13, 0xD*/
	SpecificRefType_UNIT_ITEM_WRESTLE, /* 14, 0xE*/
	SpecificRefType_NULL_REF, /* 15, 0xF*/
	SpecificRefType_HIST_FIG, /* 16, 0x10*/
	SpecificRefType_SITE, /* 17, 0x11*/
	SpecificRefType_ARTIFACT, /* 18, 0x12*/
	SpecificRefType_ITEM_IMPROVEMENT, /* 19, 0x13*/
	SpecificRefType_COIN_FRONT, /* 20, 0x14*/
	SpecificRefType_COIN_BACK, /* 21, 0x15*/
	SpecificRefType_DETAIL_EVENT, /* 22, 0x16*/
	SpecificRefType_SUBREGION, /* 23, 0x17*/
	SpecificRefType_FEATURE_LAYER, /* 24, 0x18*/
	SpecificRefType_ART_IMAGE, /* 25, 0x19*/
	SpecificRefType_CREATURE_DEF, /* 26, 0x1A*/
	SpecificRefType_ENTITY_ART_IMAGE, /* 27, 0x1B*/
	SpecificRefType_anon_2, /* 28, 0x1C*/
	SpecificRefType_ENTITY_POPULATION, /* 29, 0x1D*/
	SpecificRefType_BREED, /* 30, 0x1E*/
};
]]

-- specific_ref.h

ffi.cdef[[
typedef struct Unit Unit;
typedef struct ActivityInfo ActivityInfo;
typedef struct Viewscreen Viewscreen;
typedef struct EffectInfo EffectInfo;
typedef struct Vermin Vermin;
typedef struct Job Job;
typedef struct HistoricalFigure HistoricalFigure;
typedef struct HistoricalEntity HistoricalEntity;
typedef struct UnitItemWrestle UnitItemWrestle;
typedef struct SpecificRef {
	SpecificRefType type;	/* SpecificRefType_* */
	union {
		Unit * unit;
		ActivityInfo * activity;
		Viewscreen * screen;
		EffectInfo * effect;
		Vermin * vermin;
		Job * job;
		HistoricalFigure * histfig;
		HistoricalEntity * entity;
		struct Wrestle {
			void * wrestleUnknown1;
			UnitItemWrestle * wrestleItem;
		} wrestle;
	};
} SpecificRef;
]]
makeStdVectorPtr'SpecificRef'

-- historical_entity.h

-- TODO

-- layer_type.h

ffi.cdef[[
typedef int16_t LayerType;
enum {
	LayerType_Surface = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	LayerType_Cavern1, /* 0, 0x0*/
	LayerType_Cavern2, /* 1, 0x1*/
	LayerType_Cavern3, /* 2, 0x2*/
	LayerType_MagmaSea, /* 3, 0x3*/
	LayerType_Underworld, /* 4, 0x4*/
};
]]

-- world_population_ref.h

ffi.cdef[[
typedef struct WorldPopulationRef {
	int16_t region_x;
	int16_t region_y;
	int16_t feature_idx;
	int32_t caveID;
	int32_t unk_28;
	int32_t population_idx;
	LayerType depth;
} WorldPopulationRef;
]]

-- job_skill.h

ffi.cdef[[
typedef int16_t JobSkill;
enum {
	JobSkill_NONE = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	JobSkill_MINING, /* 0, 0x0*/
	JobSkill_WOODCUTTING, /* 1, 0x1*/
	JobSkill_CARPENTRY, /* 2, 0x2*/
	JobSkill_DETAILSTONE, /* 3, 0x3*/
	JobSkill_MASONRY, /* 4, 0x4*/
	JobSkill_ANIMALTRAIN, /* 5, 0x5*/
	JobSkill_ANIMALCARE, /* 6, 0x6*/
	JobSkill_DISSECT_FISH, /* 7, 0x7*/
	JobSkill_DISSECT_VERMIN, /* 8, 0x8*/
	JobSkill_PROCESSFISH, /* 9, 0x9*/
	JobSkill_BUTCHER, /* 10, 0xA*/
	JobSkill_TRAPPING, /* 11, 0xB*/
	JobSkill_TANNER, /* 12, 0xC*/
	JobSkill_WEAVING, /* 13, 0xD*/
	JobSkill_BREWING, /* 14, 0xE*/
	JobSkill_ALCHEMY, /* 15, 0xF*/
	JobSkill_CLOTHESMAKING, /* 16, 0x10*/
	JobSkill_MILLING, /* 17, 0x11*/
	JobSkill_PROCESSPLANTS, /* 18, 0x12*/
	JobSkill_CHEESEMAKING, /* 19, 0x13*/
	JobSkill_MILK, /* 20, 0x14*/
	JobSkill_COOK, /* 21, 0x15*/
	JobSkill_PLANT, /* 22, 0x16*/
	JobSkill_HERBALISM, /* 23, 0x17*/
	JobSkill_FISH, /* 24, 0x18*/
	JobSkill_SMELT, /* 25, 0x19*/
	JobSkill_EXTRACT_STRAND, /* 26, 0x1A*/
	JobSkill_FORGE_WEAPON, /* 27, 0x1B*/
	JobSkill_FORGE_ARMOR, /* 28, 0x1C*/
	JobSkill_FORGE_FURNITURE, /* 29, 0x1D*/
	JobSkill_CUTGEM, /* 30, 0x1E*/
	JobSkill_ENCRUSTGEM, /* 31, 0x1F*/
	JobSkill_WOODCRAFT, /* 32, 0x20*/
	JobSkill_STONECRAFT, /* 33, 0x21*/
	JobSkill_METALCRAFT, /* 34, 0x22*/
	JobSkill_GLASSMAKER, /* 35, 0x23*/
	JobSkill_LEATHERWORK, /* 36, 0x24*/
	JobSkill_BONECARVE, /* 37, 0x25*/
	JobSkill_AXE, /* 38, 0x26*/
	JobSkill_SWORD, /* 39, 0x27*/
	JobSkill_DAGGER, /* 40, 0x28*/
	JobSkill_MACE, /* 41, 0x29*/
	JobSkill_HAMMER, /* 42, 0x2A*/
	JobSkill_SPEAR, /* 43, 0x2B*/
	JobSkill_CROSSBOW, /* 44, 0x2C*/
	JobSkill_SHIELD, /* 45, 0x2D*/
	JobSkill_ARMOR, /* 46, 0x2E*/
	JobSkill_SIEGECRAFT, /* 47, 0x2F*/
	JobSkill_SIEGEOPERATE, /* 48, 0x30*/
	JobSkill_BOWYER, /* 49, 0x31*/
	JobSkill_PIKE, /* 50, 0x32*/
	JobSkill_WHIP, /* 51, 0x33*/
	JobSkill_BOW, /* 52, 0x34*/
	JobSkill_BLOWGUN, /* 53, 0x35*/
	JobSkill_THROW, /* 54, 0x36*/
	JobSkill_MECHANICS, /* 55, 0x37*/
	JobSkill_MAGIC_NATURE, /* 56, 0x38*/
	JobSkill_SNEAK, /* 57, 0x39*/
	JobSkill_DESIGNBUILDING, /* 58, 0x3A*/
	JobSkill_DRESS_WOUNDS, /* 59, 0x3B*/
	JobSkill_DIAGNOSE, /* 60, 0x3C*/
	JobSkill_SURGERY, /* 61, 0x3D*/
	JobSkill_SET_BONE, /* 62, 0x3E*/
	JobSkill_SUTURE, /* 63, 0x3F*/
	JobSkill_CRUTCH_WALK, /* 64, 0x40*/
	JobSkill_WOOD_BURNING, /* 65, 0x41*/
	JobSkill_LYE_MAKING, /* 66, 0x42*/
	JobSkill_SOAP_MAKING, /* 67, 0x43*/
	JobSkill_POTASH_MAKING, /* 68, 0x44*/
	JobSkill_DYER, /* 69, 0x45*/
	JobSkill_OPERATE_PUMP, /* 70, 0x46*/
	JobSkill_SWIMMING, /* 71, 0x47*/
	JobSkill_PERSUASION, /* 72, 0x48*/
	JobSkill_NEGOTIATION, /* 73, 0x49*/
	JobSkill_JUDGING_INTENT, /* 74, 0x4A*/
	JobSkill_APPRAISAL, /* 75, 0x4B*/
	JobSkill_ORGANIZATION, /* 76, 0x4C*/
	JobSkill_RECORD_KEEPING, /* 77, 0x4D*/
	JobSkill_LYING, /* 78, 0x4E*/
	JobSkill_INTIMIDATION, /* 79, 0x4F*/
	JobSkill_CONVERSATION, /* 80, 0x50*/
	JobSkill_COMEDY, /* 81, 0x51*/
	JobSkill_FLATTERY, /* 82, 0x52*/
	JobSkill_CONSOLE, /* 83, 0x53*/
	JobSkill_PACIFY, /* 84, 0x54*/
	JobSkill_TRACKING, /* 85, 0x55*/
	JobSkill_KNOWLEDGE_ACQUISITION, /* 86, 0x56*/
	JobSkill_CONCENTRATION, /* 87, 0x57*/
	JobSkill_DISCIPLINE, /* 88, 0x58*/
	JobSkill_SITUATIONAL_AWARENESS, /* 89, 0x59*/
	JobSkill_WRITING, /* 90, 0x5A*/
	JobSkill_PROSE, /* 91, 0x5B*/
	JobSkill_POETRY, /* 92, 0x5C*/
	JobSkill_READING, /* 93, 0x5D*/
	JobSkill_SPEAKING, /* 94, 0x5E*/
	JobSkill_COORDINATION, /* 95, 0x5F*/
	JobSkill_BALANCE, /* 96, 0x60*/
	JobSkill_LEADERSHIP, /* 97, 0x61*/
	JobSkill_TEACHING, /* 98, 0x62*/
	JobSkill_MELEE_COMBAT, /* 99, 0x63*/
	JobSkill_RANGED_COMBAT, /* 100, 0x64*/
	JobSkill_WRESTLING, /* 101, 0x65*/
	JobSkill_BITE, /* 102, 0x66*/
	JobSkill_GRASP_STRIKE, /* 103, 0x67*/
	JobSkill_STANCE_STRIKE, /* 104, 0x68*/
	JobSkill_DODGING, /* 105, 0x69*/
	JobSkill_MISC_WEAPON, /* 106, 0x6A*/
	JobSkill_KNAPPING, /* 107, 0x6B*/
	JobSkill_MILITARY_TACTICS, /* 108, 0x6C*/
	JobSkill_SHEARING, /* 109, 0x6D*/
	JobSkill_SPINNING, /* 110, 0x6E*/
	JobSkill_POTTERY, /* 111, 0x6F*/
	JobSkill_GLAZING, /* 112, 0x70*/
	JobSkill_PRESSING, /* 113, 0x71*/
	JobSkill_BEEKEEPING, /* 114, 0x72*/
	JobSkill_WAX_WORKING, /* 115, 0x73*/
	JobSkill_CLIMBING, /* 116, 0x74*/
	JobSkill_GELD, /* 117, 0x75*/
	JobSkill_DANCE, /* 118, 0x76*/
	JobSkill_MAKE_MUSIC, /* 119, 0x77*/
	JobSkill_SING_MUSIC, /* 120, 0x78*/
	JobSkill_PLAY_KEYBOARD_INSTRUMENT, /* 121, 0x79*/
	JobSkill_PLAY_STRINGED_INSTRUMENT, /* 122, 0x7A*/
	JobSkill_PLAY_WIND_INSTRUMENT, /* 123, 0x7B*/
	JobSkill_PLAY_PERCUSSION_INSTRUMENT, /* 124, 0x7C*/
	JobSkill_CRITICAL_THINKING, /* 125, 0x7D*/
	JobSkill_LOGIC, /* 126, 0x7E*/
	JobSkill_MATHEMATICS, /* 127, 0x7F*/
	JobSkill_ASTRONOMY, /* 128, 0x80*/
	JobSkill_CHEMISTRY, /* 129, 0x81*/
	JobSkill_GEOGRAPHY, /* 130, 0x82*/
	JobSkill_OPTICS_ENGINEER, /* 131, 0x83*/
	JobSkill_FLUID_ENGINEER, /* 132, 0x84*/
	JobSkill_PAPERMAKING, /* 133, 0x85*/
	JobSkill_BOOKBINDING, /* 134, 0x86*/
	JobSkill_INTRIGUE, /* 135, 0x87*/
	JobSkill_RIDING, /* 136, 0x88*/
};
]]
ffi.cdef'typedef vector_int16 vector_JobSkill;'

-- skill_rating.h

ffi.cdef[[
typedef int32_t SkillRating;
enum {
	SkillRating_Dabbling, // 0, 0x0
	SkillRating_Novice, // 1, 0x1
	SkillRating_Adequate, // 2, 0x2
	SkillRating_Competent, // 3, 0x3
	SkillRating_Skilled, // 4, 0x4
	SkillRating_Proficient, // 5, 0x5
	SkillRating_Talented, // 6, 0x6
	SkillRating_Adept, // 7, 0x7
	SkillRating_Expert, // 8, 0x8
	SkillRating_Professional, // 9, 0x9
	SkillRating_Accomplished, // 10, 0xA
	SkillRating_Great, // 11, 0xB
	SkillRating_Master, // 12, 0xC
	SkillRating_HighMaster, // 13, 0xD
	SkillRating_GrandMaster, // 14, 0xE
	SkillRating_Legendary, // 15, 0xF
	SkillRating_Legendary1, // 16, 0x10
	SkillRating_Legendary2, // 17, 0x11
	SkillRating_Legendary3, // 18, 0x12
	SkillRating_Legendary4, // 19, 0x13
	SkillRating_Legendary5, // 20, 0x14
};
]]
ffi.cdef'typedef vector_int32 vector_SkillRating;'

-- profession.h

ffi.cdef[[
typedef int16_t Profession;
enum {
	Profession_NONE = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	Profession_MINER, /* 0, 0x0*/
	Profession_WOODWORKER, /* 1, 0x1*/
	Profession_CARPENTER, /* 2, 0x2*/
	Profession_BOWYER, /* 3, 0x3*/
	Profession_WOODCUTTER, /* 4, 0x4*/
	Profession_STONEWORKER, /* 5, 0x5*/
	Profession_ENGRAVER, /* 6, 0x6*/
	Profession_MASON, /* 7, 0x7*/
	Profession_RANGER, /* 8, 0x8*/
	Profession_ANIMAL_CARETAKER, /* 9, 0x9*/
	Profession_ANIMAL_TRAINER, /* 10, 0xA*/
	Profession_HUNTER, /* 11, 0xB*/
	Profession_TRAPPER, /* 12, 0xC*/
	Profession_ANIMAL_DISSECTOR, /* 13, 0xD*/
	Profession_METALSMITH, /* 14, 0xE*/
	Profession_FURNACE_OPERATOR, /* 15, 0xF*/
	Profession_WEAPONSMITH, /* 16, 0x10*/
	Profession_ARMORER, /* 17, 0x11*/
	Profession_BLACKSMITH, /* 18, 0x12*/
	Profession_METALCRAFTER, /* 19, 0x13*/
	Profession_JEWELER, /* 20, 0x14*/
	Profession_GEM_CUTTER, /* 21, 0x15*/
	Profession_GEM_SETTER, /* 22, 0x16*/
	Profession_CRAFTSMAN, /* 23, 0x17*/
	Profession_WOODCRAFTER, /* 24, 0x18*/
	Profession_STONECRAFTER, /* 25, 0x19*/
	Profession_LEATHERWORKER, /* 26, 0x1A*/
	Profession_BONE_CARVER, /* 27, 0x1B*/
	Profession_WEAVER, /* 28, 0x1C*/
	Profession_CLOTHIER, /* 29, 0x1D*/
	Profession_GLASSMAKER, /* 30, 0x1E*/
	Profession_POTTER, /* 31, 0x1F*/
	Profession_GLAZER, /* 32, 0x20*/
	Profession_WAX_WORKER, /* 33, 0x21*/
	Profession_STRAND_EXTRACTOR, /* 34, 0x22*/
	Profession_FISHERY_WORKER, /* 35, 0x23*/
	Profession_FISHERMAN, /* 36, 0x24*/
	Profession_FISH_DISSECTOR, /* 37, 0x25*/
	Profession_FISH_CLEANER, /* 38, 0x26*/
	Profession_FARMER, /* 39, 0x27*/
	Profession_CHEESE_MAKER, /* 40, 0x28*/
	Profession_MILKER, /* 41, 0x29*/
	Profession_COOK, /* 42, 0x2A*/
	Profession_THRESHER, /* 43, 0x2B*/
	Profession_MILLER, /* 44, 0x2C*/
	Profession_BUTCHER, /* 45, 0x2D*/
	Profession_TANNER, /* 46, 0x2E*/
	Profession_DYER, /* 47, 0x2F*/
	Profession_PLANTER, /* 48, 0x30*/
	Profession_HERBALIST, /* 49, 0x31*/
	Profession_BREWER, /* 50, 0x32*/
	Profession_SOAP_MAKER, /* 51, 0x33*/
	Profession_POTASH_MAKER, /* 52, 0x34*/
	Profession_LYE_MAKER, /* 53, 0x35*/
	Profession_WOOD_BURNER, /* 54, 0x36*/
	Profession_SHEARER, /* 55, 0x37*/
	Profession_SPINNER, /* 56, 0x38*/
	Profession_PRESSER, /* 57, 0x39*/
	Profession_BEEKEEPER, /* 58, 0x3A*/
	Profession_ENGINEER, /* 59, 0x3B*/
	Profession_MECHANIC, /* 60, 0x3C*/
	Profession_SIEGE_ENGINEER, /* 61, 0x3D*/
	Profession_SIEGE_OPERATOR, /* 62, 0x3E*/
	Profession_PUMP_OPERATOR, /* 63, 0x3F*/
	Profession_CLERK, /* 64, 0x40*/
	Profession_ADMINISTRATOR, /* 65, 0x41*/
	Profession_TRADER, /* 66, 0x42*/
	Profession_ARCHITECT, /* 67, 0x43*/
	Profession_ALCHEMIST, /* 68, 0x44*/
	Profession_DOCTOR, /* 69, 0x45*/
	Profession_DIAGNOSER, /* 70, 0x46*/
	Profession_BONE_SETTER, /* 71, 0x47*/
	Profession_SUTURER, /* 72, 0x48*/
	Profession_SURGEON, /* 73, 0x49*/
	Profession_MERCHANT, /* 74, 0x4A*/
	Profession_HAMMERMAN, /* 75, 0x4B*/
	Profession_MASTER_HAMMERMAN, /* 76, 0x4C*/
	Profession_SPEARMAN, /* 77, 0x4D*/
	Profession_MASTER_SPEARMAN, /* 78, 0x4E*/
	Profession_CROSSBOWMAN, /* 79, 0x4F*/
	Profession_MASTER_CROSSBOWMAN, /* 80, 0x50*/
	Profession_WRESTLER, /* 81, 0x51*/
	Profession_MASTER_WRESTLER, /* 82, 0x52*/
	Profession_AXEMAN, /* 83, 0x53*/
	Profession_MASTER_AXEMAN, /* 84, 0x54*/
	Profession_SWORDSMAN, /* 85, 0x55*/
	Profession_MASTER_SWORDSMAN, /* 86, 0x56*/
	Profession_MACEMAN, /* 87, 0x57*/
	Profession_MASTER_MACEMAN, /* 88, 0x58*/
	Profession_PIKEMAN, /* 89, 0x59*/
	Profession_MASTER_PIKEMAN, /* 90, 0x5A*/
	Profession_BOWMAN, /* 91, 0x5B*/
	Profession_MASTER_BOWMAN, /* 92, 0x5C*/
	Profession_BLOWGUNMAN, /* 93, 0x5D*/
	Profession_MASTER_BLOWGUNMAN, /* 94, 0x5E*/
	Profession_LASHER, /* 95, 0x5F*/
	Profession_MASTER_LASHER, /* 96, 0x60*/
	Profession_RECRUIT, /* 97, 0x61*/
	Profession_TRAINED_HUNTER, /* 98, 0x62*/
	Profession_TRAINED_WAR, /* 99, 0x63*/
	Profession_MASTER_THIEF, /* 100, 0x64*/
	Profession_THIEF, /* 101, 0x65*/
	Profession_STANDARD, /* 102, 0x66*/
	Profession_CHILD, /* 103, 0x67*/
	Profession_BABY, /* 104, 0x68*/
	Profession_DRUNK, /* 105, 0x69*/
	Profession_MONSTER_SLAYER, /* 106, 0x6A*/
	Profession_SCOUT, /* 107, 0x6B*/
	Profession_BEAST_HUNTER, /* 108, 0x6C*/
	Profession_SNATCHER, /* 109, 0x6D*/
	Profession_MERCENARY, /* 110, 0x6E*/
	Profession_GELDER, /* 111, 0x6F*/
	Profession_PERFORMER, /* 112, 0x70*/
	Profession_POET, /* 113, 0x71*/
	Profession_BARD, /* 114, 0x72*/
	Profession_DANCER, /* 115, 0x73*/
	Profession_SAGE, /* 116, 0x74*/
	Profession_SCHOLAR, /* 117, 0x75*/
	Profession_PHILOSOPHER, /* 118, 0x76*/
	Profession_MATHEMATICIAN, /* 119, 0x77*/
	Profession_HISTORIAN, /* 120, 0x78*/
	Profession_ASTRONOMER, /* 121, 0x79*/
	Profession_NATURALIST, /* 122, 0x7A*/
	Profession_CHEMIST, /* 123, 0x7B*/
	Profession_GEOGRAPHER, /* 124, 0x7C*/
	Profession_SCRIBE, /* 125, 0x7D*/
	Profession_PAPERMAKER, /* 126, 0x7E*/
	Profession_BOOKBINDER, /* 127, 0x7F*/
	Profession_TAVERN_KEEPER, /* 128, 0x80*/
	Profession_CRIMINAL, /* 129, 0x81*/
	Profession_PEDDLER, /* 130, 0x82*/
	Profession_PROPHET, /* 131, 0x83*/
	Profession_PILGRIM, /* 132, 0x84*/
	Profession_MONK, /* 133, 0x85*/
	Profession_MESSENGER, /* 134, 0x86*/
	Num_Profession,
};
]]

-- part_of_speech.h

-- int16_t
ffi.cdef[[
typedef int16_t PartOfSpeech;
enum {
	PartOfSpeech_Noun, /* 0, 0x0*/
	PartOfSpeech_NounPlural, /* 1, 0x1*/
	PartOfSpeech_Adjective, /* 2, 0x2*/
	PartOfSpeech_Prefix, /* 3, 0x3*/
	PartOfSpeech_Verb, /* 4, 0x4*/
	PartOfSpeech_Verb3rdPerson, /* 5, 0x5*/
	PartOfSpeech_VerbPast, /* 6, 0x6*/
	PartOfSpeech_VerbPassive, /* 7, 0x7*/
	PartOfSpeech_VerbGerund, /* 8, 0x8*/
};
]]

-- language_name_type.h

ffi.cdef[[
typedef int16_t LanguageNameType;
enum {
	LanguageNameType_NONE = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	LanguageNameType_Figure, /* 0, 0x0*/
	LanguageNameType_Artifact, /* 1, 0x1*/
	LanguageNameType_Civilization, /* 2, 0x2*/
	LanguageNameType_Squad, /* 3, 0x3*/
	LanguageNameType_Site, /* 4, 0x4*/
	LanguageNameType_World, /* 5, 0x5*/
	LanguageNameType_Region, /* 6, 0x6*/
	LanguageNameType_Dungeon, /* 7, 0x7*/
	LanguageNameType_LegendaryFigure, /* 8, 0x8*/
	LanguageNameType_FigureNoFirst, /* 9, 0x9*/
	LanguageNameType_FigureFirstOnly, /* 10, 0xA*/
	LanguageNameType_ArtImage, /* 11, 0xB*/
	LanguageNameType_AdventuringGroup, /* 12, 0xC*/
	LanguageNameType_ElfTree, /* 13, 0xD*/
	LanguageNameType_SiteGovernment, /* 14, 0xE*/
	LanguageNameType_NomadicGroup, /* 15, 0xF*/
	LanguageNameType_Vessel, /* 16, 0x10*/
	LanguageNameType_MilitaryUnit, /* 17, 0x11*/
	LanguageNameType_Religion, /* 18, 0x12*/
	LanguageNameType_MountainPeak, /* 19, 0x13*/
	LanguageNameType_River, /* 20, 0x14*/
	LanguageNameType_Temple, /* 21, 0x15*/
	LanguageNameType_Keep, /* 22, 0x16*/
	LanguageNameType_MeadHall, /* 23, 0x17*/
	LanguageNameType_SymbolArtifice, /* 24, 0x18*/
	LanguageNameType_SymbolViolent, /* 25, 0x19*/
	LanguageNameType_SymbolProtect, /* 26, 0x1A*/
	LanguageNameType_SymbolDomestic, /* 27, 0x1B*/
	LanguageNameType_SymbolFood, /* 28, 0x1C*/
	LanguageNameType_War, /* 29, 0x1D*/
	LanguageNameType_Battle, /* 30, 0x1E*/
	LanguageNameType_Siege, /* 31, 0x1F*/
	LanguageNameType_Road, /* 32, 0x20*/
	LanguageNameType_Wall, /* 33, 0x21*/
	LanguageNameType_Bridge, /* 34, 0x22*/
	LanguageNameType_Tunnel, /* 35, 0x23*/
	LanguageNameType_PretentiousEntityPosition, /* 36, 0x24*/
	LanguageNameType_Monument, /* 37, 0x25*/
	LanguageNameType_Tomb, /* 38, 0x26*/
	LanguageNameType_OutcastGroup, /* 39, 0x27*/
	LanguageNameType_Unk40, /* 40, 0x28*/
	LanguageNameType_SymbolProtect2, /* 41, 0x29*/
	LanguageNameType_Unk42, /* 42, 0x2A*/
	LanguageNameType_Library, /* 43, 0x2B*/
	LanguageNameType_PoeticForm, /* 44, 0x2C*/
	LanguageNameType_MusicalForm, /* 45, 0x2D*/
	LanguageNameType_DanceForm, /* 46, 0x2E*/
	LanguageNameType_Festival, /* 47, 0x2F*/
	LanguageNameType_FalseIdentity, /* 48, 0x30*/
	LanguageNameType_MerchantCompany, /* 49, 0x31*/
	LanguageNameType_CountingHouse, /* 50, 0x32*/
	LanguageNameType_CraftGuild, /* 51, 0x33*/
	LanguageNameType_Guildhall, /* 52, 0x34*/
	LanguageNameType_NecromancerTower, /* 53, 0x35*/
};
]]

-- language_name.h

-- [=[
ffi.cdef[[
typedef struct LanguageName {
	std_string firstName;
	std_string nickname;
	int32_t words[7];
	PartOfSpeech partsOfSpeech[7]; /* PartOfSpeech_* */
	int32_t language;
	LanguageNameType type;	/* LanguageNameType_* */
	bool hasName;
} LanguageName;
]]
--]=]
--[=[ gives me __tostring support but I need to provide all metatable functionality up front
-- hmm eventually I'm switching over to this so ... I better think of a way to make it extensible
struct{
	name = 'LanguageName',
	fields = {
		{type='std_string', name='firstName'},
		{type='std_string', name='nickname'},
		{type='int32_t[7]', name='words'},
		{type='PartOfSpeech[7]', name='partsOfSpeech'},
		{type='int32_t', name='language'},
		{type='LanguageNameType', name='type'},
		{name='hasName', type='bool'},
	},
}
--]=]

assertsizeof('LanguageName', 72)

-- language_word_flags.h

ffi.cdef[[
typedef union LanguageWordFlags {
	uint32_t flags;
	struct {
		uint32_t frontCompoundNounSing : 1;
		uint32_t frontCompoundNounPlur : 1;
		uint32_t frontCompoundAdj : 1;
		uint32_t frontCompoundPrefix : 1;
		uint32_t rearCompoundNounSing : 1;
		uint32_t rearCompoundNounPlur : 1;
		uint32_t rearCompoundAdj : 1;
		uint32_t theNounSing : 1;
		uint32_t theNounPlur : 1;
		uint32_t theCompoundNounSing : 1;
		uint32_t theCompoundNounPlur : 1;
		uint32_t theCompoundAdj : 1;
		uint32_t theCompoundPrefix : 1;
		uint32_t ofNounSing : 1;
		uint32_t ofNounPlur : 1;
		uint32_t standard_verb : 1;
	};
} LanguageWordFlags;
]]

-- language_word.h

ffi.cdef[[
typedef struct LanguageWord {
	std_string word;
	std_string forms[9];
	uint8_t adj_dist;
	char pad_1[7]; /*!< looks like garbage */
	LanguageWordFlags flags;
	vector_string_ptr str; /*!< since v0.40.01 */
} LanguageWord;
]]
assertsizeof('LanguageWord', 120)
makeStdVectorPtr'LanguageWord'

-- language_symbol.h

-- TODO
ffi.cdef'typedef struct LanguageSymbol LanguageSymbol;'
makeStdVectorPtr'LanguageSymbol'

-- language_translation.h

ffi.cdef[[
typedef struct LanguageTranslation {
	std_string name;
	vector_string_ptr unknown1; /*!< looks like english words */
	vector_string_ptr unknown2; /*!< looks like translated words */
	vector_string_ptr words;
	int32_t flags; /*!< since v0.40.01; 1 = generated */
	vector_string_ptr str; /*!< since v0.40.01 */
} LanguageTranslation;
]]
assertsizeof('LanguageTranslation', 112)
makeStdVectorPtr'LanguageTranslation'

-- language_word_table.h

ffi.cdef[[
typedef struct LanguageWordTable {
	vector_int32 words[6];
	vector_int32 parts[6]; /* PartOfSpeech_* */
} LanguageWordTable;
]]
assertsizeof('LanguageWordTable', 288)

-- item_type.h

ffi.cdef[[
typedef int16_t ItemType;
enum {
	ItemType_NONE = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	ItemType_BAR, /* 0, 0x0*/
	ItemType_SMALLGEM, /* 1, 0x1*/
	ItemType_BLOCKS, /* 2, 0x2*/
	ItemType_ROUGH, /* 3, 0x3*/
	ItemType_BOULDER, /* 4, 0x4*/
	ItemType_WOOD, /* 5, 0x5*/
	ItemType_DOOR, /* 6, 0x6*/
	ItemType_FLOODGATE, /* 7, 0x7*/
	ItemType_BED, /* 8, 0x8*/
	ItemType_CHAIR, /* 9, 0x9*/
	ItemType_CHAIN, /* 10, 0xA*/
	ItemType_FLASK, /* 11, 0xB*/
	ItemType_GOBLET, /* 12, 0xC*/
	ItemType_INSTRUMENT, /* 13, 0xD*/
	ItemType_TOY, /* 14, 0xE*/
	ItemType_WINDOW, /* 15, 0xF*/
	ItemType_CAGE, /* 16, 0x10*/
	ItemType_BARREL, /* 17, 0x11*/
	ItemType_BUCKET, /* 18, 0x12*/
	ItemType_ANIMALTRAP, /* 19, 0x13*/
	ItemType_TABLE, /* 20, 0x14*/
	ItemType_COFFIN, /* 21, 0x15*/
	ItemType_STATUE, /* 22, 0x16*/
	ItemType_CORPSE, /* 23, 0x17*/
	ItemType_WEAPON, /* 24, 0x18*/
	ItemType_ARMOR, /* 25, 0x19*/
	ItemType_SHOES, /* 26, 0x1A*/
	ItemType_SHIELD, /* 27, 0x1B*/
	ItemType_HELM, /* 28, 0x1C*/
	ItemType_GLOVES, /* 29, 0x1D*/
	ItemType_BOX, /* 30, 0x1E*/
	ItemType_BIN, /* 31, 0x1F*/
	ItemType_ARMORSTAND, /* 32, 0x20*/
	ItemType_WEAPONRACK, /* 33, 0x21*/
	ItemType_CABINET, /* 34, 0x22*/
	ItemType_FIGURINE, /* 35, 0x23*/
	ItemType_AMULET, /* 36, 0x24*/
	ItemType_SCEPTER, /* 37, 0x25*/
	ItemType_AMMO, /* 38, 0x26*/
	ItemType_CROWN, /* 39, 0x27*/
	ItemType_RING, /* 40, 0x28*/
	ItemType_EARRING, /* 41, 0x29*/
	ItemType_BRACELET, /* 42, 0x2A*/
	ItemType_GEM, /* 43, 0x2B*/
	ItemType_ANVIL, /* 44, 0x2C*/
	ItemType_CORPSEPIECE, /* 45, 0x2D*/
	ItemType_REMAINS, /* 46, 0x2E*/
	ItemType_MEAT, /* 47, 0x2F*/
	ItemType_FISH, /* 48, 0x30*/
	ItemType_FISH_RAW, /* 49, 0x31*/
	ItemType_VERMIN, /* 50, 0x32*/
	ItemType_PET, /* 51, 0x33*/
	ItemType_SEEDS, /* 52, 0x34*/
	ItemType_PLANT, /* 53, 0x35*/
	ItemType_SKIN_TANNED, /* 54, 0x36*/
	ItemType_PLANT_GROWTH, /* 55, 0x37*/
	ItemType_THREAD, /* 56, 0x38*/
	ItemType_CLOTH, /* 57, 0x39*/
	ItemType_TOTEM, /* 58, 0x3A*/
	ItemType_PANTS, /* 59, 0x3B*/
	ItemType_BACKPACK, /* 60, 0x3C*/
	ItemType_QUIVER, /* 61, 0x3D*/
	ItemType_CATAPULTPARTS, /* 62, 0x3E*/
	ItemType_BALLISTAPARTS, /* 63, 0x3F*/
	ItemType_SIEGEAMMO, /* 64, 0x40*/
	ItemType_BALLISTAARROWHEAD, /* 65, 0x41*/
	ItemType_TRAPPARTS, /* 66, 0x42*/
	ItemType_TRAPCOMP, /* 67, 0x43*/
	ItemType_DRINK, /* 68, 0x44*/
	ItemType_POWDER_MISC, /* 69, 0x45*/
	ItemType_CHEESE, /* 70, 0x46*/
	ItemType_FOOD, /* 71, 0x47*/
	ItemType_LIQUID_MISC, /* 72, 0x48*/
	ItemType_COIN, /* 73, 0x49*/
	ItemType_GLOB, /* 74, 0x4A*/
	ItemType_ROCK, /* 75, 0x4B*/
	ItemType_PIPE_SECTION, /* 76, 0x4C*/
	ItemType_HATCH_COVER, /* 77, 0x4D*/
	ItemType_GRATE, /* 78, 0x4E*/
	ItemType_QUERN, /* 79, 0x4F*/
	ItemType_MILLSTONE, /* 80, 0x50*/
	ItemType_SPLINT, /* 81, 0x51*/
	ItemType_CRUTCH, /* 82, 0x52*/
	ItemType_TRACTION_BENCH, /* 83, 0x53*/
	ItemType_ORTHOPEDIC_CAST, /* 84, 0x54*/
	ItemType_TOOL, /* 85, 0x55*/
	ItemType_SLAB, /* 86, 0x56*/
	ItemType_EGG, /* 87, 0x57*/
	ItemType_BOOK, /* 88, 0x58*/
	ItemType_SHEET, /* 89, 0x59*/
	ItemType_BRANCH, /* 90, 0x5A*/
};
]]
ffi.cdef'typedef vector_int16 vector_ItemType;'

-- history_hit_item.h

ffi.cdef[[
typedef struct HistoryHitItem {

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

-- unit_action_type_group.h

ffi.cdef[[
typedef int32_t UnitActionTypeGroup;
enum {
	UnitActionTypeGroup_All, // 0, 0x0
	UnitActionTypeGroup_Movement, // 1, 0x1
	UnitActionTypeGroup_MovementFeet, // 2, 0x2
	UnitActionTypeGroup_Combat, // 3, 0x3
	UnitActionTypeGroup_Work, // 4, 0x4
};
]]

-- unit_action_type.h

ffi.cdef[[
typedef int32_t UnitActionType;
enum {
	UnitActionType_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	UnitActionType_Move, // 0, 0x0
	UnitActionType_Attack, // 1, 0x1
	UnitActionType_Jump, // 2, 0x2
	UnitActionType_HoldTerrain, // 3, 0x3
	UnitActionType_ReleaseTerrain, // 4, 0x4
	UnitActionType_Climb, // 5, 0x5
	UnitActionType_Job, // 6, 0x6
	UnitActionType_Talk, // 7, 0x7
	UnitActionType_Unsteady, // 8, 0x8
	UnitActionType_Parry, // 9, 0x9
	UnitActionType_Block, // 10, 0xA
	UnitActionType_Dodge, // 11, 0xB
	UnitActionType_Recover, // 12, 0xC
	UnitActionType_StandUp, // 13, 0xD
	UnitActionType_LieDown, // 14, 0xE
	UnitActionType_Job2, // 15, 0xF
	UnitActionType_PushObject, // 16, 0x10
	UnitActionType_SuckBlood, // 17, 0x11
	UnitActionType_HoldItem, // 18, 0x12
	UnitActionType_ReleaseItem, // 19, 0x13
	UnitActionType_Unk20, // 20, 0x14
	UnitActionType_Unk21, // 21, 0x15
	UnitActionType_Unk22, // 22, 0x16
	UnitActionType_Unk23, // 23, 0x17
};
]]

-- unit_action.h

--[=[ TODO ...
ffi.cdef[[
typedef struct UnitAction {
	UnitActionType type;
	int32_t id;
	union {
		int32_t rawData[24];
		UnitActionDataMove move;
		UnitActionDataAttack attack;
		UnitActionDataJump jump;
		UnitActionDataHoldTerrain holdterrain;
		UnitActionDataReleaseTerrain releaseterrain;
		UnitActionDataClimb climb;
		UnitActionDataJob job;
		UnitActionDataTalk talk;
		UnitActionDataUnsteady unsteady;
		UnitActionDataParry parry;
		UnitActionDataBlock block;
		UnitActionDataDodge dodge;
		UnitActionDataRecover recover;
		UnitActionDataStandUp standup;
		UnitActionDataLieDown liedown;
		UnitActionDataJob2 job2;
		UnitActionDataPushObject pushobject;
		UnitActionDataSuckBlood suckblood;
		UnitActionDataHoldItem holditem;
		UnitActionDataReleaseItem releaseitem;
		UnitActionDataUnkSub20 unk20;
		UnitActionDataUnkSub21 unk21;
		UnitActionDataUnkSub22 unk22;
		UnitActionDataUnkSub23 unk23;
	} data;
} UnitAction;
]]
--]=]
-- [=[ until then
ffi.cdef'typedef struct UnitAction UnitAction;'
--]=]
makeStdVectorPtr'UnitAction'

-- unit_station_type.h

ffi.cdef[[
typedef int16_t UnitStationType;
enum {
	UnitStationType_None = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	UnitStationType_Nonsense, /* 0, 0x0*/
	UnitStationType_DungeonCommander, /* 1, 0x1*/
	UnitStationType_InsaneMood, /* 2, 0x2*/
	UnitStationType_UndeadHunt, /* 3, 0x3*/
	UnitStationType_SiegerPatrol, /* 4, 0x4*/
	UnitStationType_MaraudeTarget, /* 5, 0x5*/
	UnitStationType_SiegerBasepoint, /* 6, 0x6*/
	UnitStationType_SiegerMill, /* 7, 0x7*/
	UnitStationType_AmbushPatrol, /* 8, 0x8*/
	UnitStationType_MarauderMill, /* 9, 0x9*/
	UnitStationType_WildernessCuriousWander, /* 10, 0xA*/
	UnitStationType_WildernessCuriousStealTarget, /* 11, 0xB*/
	UnitStationType_WildernessRoamer, /* 12, 0xC*/
	UnitStationType_PatternPatrol, /* 13, 0xD*/
	UnitStationType_InactiveMarauder, /* 14, 0xE*/
	UnitStationType_Owner, /* 15, 0xF*/
	UnitStationType_Commander, /* 16, 0x10*/
	UnitStationType_ChainedAnimal, /* 17, 0x11*/
	UnitStationType_MeetingLocation, /* 18, 0x12*/
	UnitStationType_MeetingLocationBuilding, /* 19, 0x13*/
	UnitStationType_Depot, /* 20, 0x14*/
	UnitStationType_VerminHunting, /* 21, 0x15*/
	UnitStationType_SeekCommander, /* 22, 0x16*/
	UnitStationType_ReturnToBase, /* 23, 0x17*/
	UnitStationType_MillAnywhere, /* 24, 0x18*/
	UnitStationType_Wagon, /* 25, 0x19*/
	UnitStationType_MillBuilding, /* 26, 0x1A*/
	UnitStationType_HeadForEdge, /* 27, 0x1B*/
	UnitStationType_MillingFlood, /* 28, 0x1C*/
	UnitStationType_MillingBurrow, /* 29, 0x1D*/
	UnitStationType_SquadMove, /* 30, 0x1E*/
	UnitStationType_SquadKillList, /* 31, 0x1F*/
	UnitStationType_SquadPatrol, /* 32, 0x20*/
	UnitStationType_SquadDefendBurrow, /* 33, 0x21*/
	UnitStationType_SquadDefendBurrowFromTarget, /* 34, 0x22*/
	UnitStationType_LairHunter, /* 35, 0x23*/
	UnitStationType_Graze, /* 36, 0x24*/
	UnitStationType_Guard, /* 37, 0x25*/
	UnitStationType_Alarm, /* 38, 0x26*/
	UnitStationType_MoveToSite, /* 39, 0x27*/
	UnitStationType_ClaimSite, /* 40, 0x28*/
	UnitStationType_WaitOrder, /* 41, 0x29*/
};
]]

-- unit_path_goal.h

ffi.cdef[[
typedef int16_t UnitPathGoal;
enum {
	UnitPathGoal_None = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	UnitPathGoal_ComeToJobBuilding, /* 0, 0x0*/
	UnitPathGoal_ValidPondDumpUnit, /* 1, 0x1*/
	UnitPathGoal_ValidPondDump, /* 2, 0x2*/
	UnitPathGoal_ConflictDefense, /* 3, 0x3*/
	UnitPathGoal_AdventureMove, /* 4, 0x4*/
	UnitPathGoal_MarauderMill, /* 5, 0x5*/
	UnitPathGoal_WildernessCuriousStealTarget, /* 6, 0x6*/
	UnitPathGoal_WildernessRoamer, /* 7, 0x7*/
	UnitPathGoal_ThiefTarget, /* 8, 0x8*/
	UnitPathGoal_Owner, /* 9, 0x9*/
	UnitPathGoal_CheckChest, /* 10, 0xA*/
	UnitPathGoal_SleepBed, /* 11, 0xB*/
	UnitPathGoal_SleepBarracks, /* 12, 0xC*/
	UnitPathGoal_SleepGround, /* 13, 0xD*/
	UnitPathGoal_LeaveWall, /* 14, 0xE*/
	UnitPathGoal_FleeTerrain, /* 15, 0xF*/
	UnitPathGoal_TaxRoom, /* 16, 0x10*/
	UnitPathGoal_GuardTaxes, /* 17, 0x11*/
	UnitPathGoal_RansackTaxes, /* 18, 0x12*/
	UnitPathGoal_GetEmptySandBag, /* 19, 0x13*/
	UnitPathGoal_SandZone, /* 20, 0x14*/
	UnitPathGoal_GrabCage, /* 21, 0x15*/
	UnitPathGoal_UncageAnimal, /* 22, 0x16*/
	UnitPathGoal_CaptureSmallPet, /* 23, 0x17*/
	UnitPathGoal_GrabCageUnit, /* 24, 0x18*/
	UnitPathGoal_GoToCage, /* 25, 0x19*/
	UnitPathGoal_GrabAnimalTrap, /* 26, 0x1A*/
	UnitPathGoal_CageVermin, /* 27, 0x1B*/
	UnitPathGoal_GrabUnfillBucket, /* 28, 0x1C*/
	UnitPathGoal_SeekFillBucket, /* 29, 0x1D*/
	UnitPathGoal_SeekPatientForCarry, /* 30, 0x1E*/
	UnitPathGoal_SeekPatientForDiagnosis, /* 31, 0x1F*/
	UnitPathGoal_SeekPatientForImmobilizeBreak, /* 32, 0x20*/
	UnitPathGoal_SeekPatientForCrutch, /* 33, 0x21*/
	UnitPathGoal_SeekPatientForSuturing, /* 34, 0x22*/
	UnitPathGoal_SeekSurgerySite, /* 35, 0x23*/
	UnitPathGoal_CarryPatientToBed, /* 36, 0x24*/
	UnitPathGoal_SeekGiveWaterBucket, /* 37, 0x25*/
	UnitPathGoal_SeekJobItem, /* 38, 0x26*/
	UnitPathGoal_SeekUnitForItemDrop, /* 39, 0x27*/
	UnitPathGoal_SeekUnitForJob, /* 40, 0x28*/
	UnitPathGoal_SeekSplint, /* 41, 0x29*/
	UnitPathGoal_SeekCrutch, /* 42, 0x2A*/
	UnitPathGoal_SeekSutureThread, /* 43, 0x2B*/
	UnitPathGoal_SeekDressingCloth, /* 44, 0x2C*/
	UnitPathGoal_GoToGiveWaterTarget, /* 45, 0x2D*/
	UnitPathGoal_SeekFoodForTarget, /* 46, 0x2E*/
	UnitPathGoal_SeekTargetForFood, /* 47, 0x2F*/
	UnitPathGoal_SeekAnimalForSlaughter, /* 48, 0x30*/
	UnitPathGoal_SeekSlaughterBuilding, /* 49, 0x31*/
	UnitPathGoal_SeekAnimalForChain, /* 50, 0x32*/
	UnitPathGoal_SeekChainForAnimal, /* 51, 0x33*/
	UnitPathGoal_SeekCageForUnchain, /* 52, 0x34*/
	UnitPathGoal_SeekAnimalForUnchain, /* 53, 0x35*/
	UnitPathGoal_GrabFoodForTaming, /* 54, 0x36*/
	UnitPathGoal_SeekAnimalForTaming, /* 55, 0x37*/
	UnitPathGoal_SeekDrinkItem, /* 56, 0x38*/
	UnitPathGoal_SeekFoodItem, /* 57, 0x39*/
	UnitPathGoal_SeekEatingChair, /* 58, 0x3A*/
	UnitPathGoal_SeekEatingChair2, /* 59, 0x3B*/
	UnitPathGoal_SeekBadMoodBuilding, /* 60, 0x3C*/
	UnitPathGoal_SetGlassMoodBuilding, /* 61, 0x3D*/
	UnitPathGoal_SetMoodBuilding, /* 62, 0x3E*/
	UnitPathGoal_SeekFellVictim, /* 63, 0x3F*/
	UnitPathGoal_CleanBuildingSite, /* 64, 0x40*/
	UnitPathGoal_ResetPriorityGoal, /* 65, 0x41*/
	UnitPathGoal_MainJobBuilding, /* 66, 0x42*/
	UnitPathGoal_DropOffJobItems, /* 67, 0x43*/
	UnitPathGoal_GrabJobResources, /* 68, 0x44*/
	UnitPathGoal_WorkAtBuilding, /* 69, 0x45*/
	UnitPathGoal_GrabUniform, /* 70, 0x46*/
	UnitPathGoal_GrabClothing, /* 71, 0x47*/
	UnitPathGoal_GrabWeapon, /* 72, 0x48*/
	UnitPathGoal_GrabAmmunition, /* 73, 0x49*/
	UnitPathGoal_GrabShield, /* 74, 0x4A*/
	UnitPathGoal_GrabArmor, /* 75, 0x4B*/
	UnitPathGoal_GrabHelm, /* 76, 0x4C*/
	UnitPathGoal_GrabBoots, /* 77, 0x4D*/
	UnitPathGoal_GrabGloves, /* 78, 0x4E*/
	UnitPathGoal_GrabPants, /* 79, 0x4F*/
	UnitPathGoal_GrabQuiver, /* 80, 0x50*/
	UnitPathGoal_GrabBackpack, /* 81, 0x51*/
	UnitPathGoal_GrabWaterskin, /* 82, 0x52*/
	UnitPathGoal_StartHunt, /* 83, 0x53*/
	UnitPathGoal_StartFish, /* 84, 0x54*/
	UnitPathGoal_Clean, /* 85, 0x55*/
	UnitPathGoal_HuntVermin, /* 86, 0x56*/
	UnitPathGoal_Patrol, /* 87, 0x57*/
	UnitPathGoal_SquadStation, /* 88, 0x58*/
	UnitPathGoal_SeekInfant, /* 89, 0x59*/
	UnitPathGoal_ShopSpecific, /* 90, 0x5A*/
	UnitPathGoal_MillInShop, /* 91, 0x5B*/
	UnitPathGoal_GoToShop, /* 92, 0x5C*/
	UnitPathGoal_SeekTrainingAmmunition, /* 93, 0x5D*/
	UnitPathGoal_ArcheryTrainingSite, /* 94, 0x5E*/
	UnitPathGoal_SparringPartner, /* 95, 0x5F*/
	UnitPathGoal_SparringSite, /* 96, 0x60*/
	UnitPathGoal_AttendParty, /* 97, 0x61*/
	UnitPathGoal_SeekArtifact, /* 98, 0x62*/
	UnitPathGoal_GrabAmmunitionForBuilding, /* 99, 0x63*/
	UnitPathGoal_SeekBuildingForAmmunition, /* 100, 0x64*/
	UnitPathGoal_SeekItemForStorage, /* 101, 0x65*/
	UnitPathGoal_StoreItem, /* 102, 0x66*/
	UnitPathGoal_GrabKill, /* 103, 0x67*/
	UnitPathGoal_DropKillAtButcher, /* 104, 0x68*/
	UnitPathGoal_DropKillOutFront, /* 105, 0x69*/
	UnitPathGoal_GoToBeatingTarget, /* 106, 0x6A*/
	UnitPathGoal_SeekKidnapVictim, /* 107, 0x6B*/
	UnitPathGoal_SeekHuntingTarget, /* 108, 0x6C*/
	UnitPathGoal_SeekTargetMechanism, /* 109, 0x6D*/
	UnitPathGoal_SeekTargetForMechanism, /* 110, 0x6E*/
	UnitPathGoal_SeekMechanismForTrigger, /* 111, 0x6F*/
	UnitPathGoal_SeekTriggerForMechanism, /* 112, 0x70*/
	UnitPathGoal_SeekTrapForVerminCatch, /* 113, 0x71*/
	UnitPathGoal_SeekVerminForCatching, /* 114, 0x72*/
	UnitPathGoal_SeekVerminCatchLocation, /* 115, 0x73*/
	UnitPathGoal_WanderVerminCatchLocation, /* 116, 0x74*/
	UnitPathGoal_SeekVerminForHunting, /* 117, 0x75*/
	UnitPathGoal_SeekVerminHuntingSpot, /* 118, 0x76*/
	UnitPathGoal_WanderVerminHuntingSpot, /* 119, 0x77*/
	UnitPathGoal_SeekFishTrap, /* 120, 0x78*/
	UnitPathGoal_SeekFishCatchLocation, /* 121, 0x79*/
	UnitPathGoal_SeekWellForWater, /* 122, 0x7A*/
	UnitPathGoal_SeekDrinkAreaForWater, /* 123, 0x7B*/
	UnitPathGoal_UpgradeSquadEquipment, /* 124, 0x7C*/
	UnitPathGoal_PrepareEquipmentManifests, /* 125, 0x7D*/
	UnitPathGoal_WanderDepot, /* 126, 0x7E*/
	UnitPathGoal_SeekUpdateOffice, /* 127, 0x7F*/
	UnitPathGoal_SeekManageOffice, /* 128, 0x80*/
	UnitPathGoal_AssignedBuildingJob, /* 129, 0x81*/
	UnitPathGoal_ChaseOpponent, /* 130, 0x82*/
	UnitPathGoal_FleeFromOpponent, /* 131, 0x83*/
	UnitPathGoal_AttackBuilding, /* 132, 0x84*/
	UnitPathGoal_StartBedCarry, /* 133, 0x85*/
	UnitPathGoal_StartGiveFoodWater, /* 134, 0x86*/
	UnitPathGoal_StartMedicalAid, /* 135, 0x87*/
	UnitPathGoal_SeekStationFlood, /* 136, 0x88*/
	UnitPathGoal_SeekStation, /* 137, 0x89*/
	UnitPathGoal_StartWaterJobWell, /* 138, 0x8A*/
	UnitPathGoal_StartWaterJobDrinkArea, /* 139, 0x8B*/
	UnitPathGoal_StartEatJob, /* 140, 0x8C*/
	UnitPathGoal_ScheduledMeal, /* 141, 0x8D*/
	UnitPathGoal_ScheduledSleepBed, /* 142, 0x8E*/
	UnitPathGoal_ScheduledSleepGround, /* 143, 0x8F*/
	UnitPathGoal_Rest, /* 144, 0x90*/
	UnitPathGoal_RemoveConstruction, /* 145, 0x91*/
	UnitPathGoal_Chop, /* 146, 0x92*/
	UnitPathGoal_Detail, /* 147, 0x93*/
	UnitPathGoal_GatherPlant, /* 148, 0x94*/
	UnitPathGoal_Dig, /* 149, 0x95*/
	UnitPathGoal_Mischief, /* 150, 0x96*/
	UnitPathGoal_ChaseOpponentSameSquare, /* 151, 0x97*/
	UnitPathGoal_RestRecovered, /* 152, 0x98*/
	UnitPathGoal_RestReset, /* 153, 0x99*/
	UnitPathGoal_CombatTraining, /* 154, 0x9A*/
	UnitPathGoal_SkillDemonstration, /* 155, 0x9B*/
	UnitPathGoal_IndividualSkillDrill, /* 156, 0x9C*/
	UnitPathGoal_SeekBuildingForItemDrop, /* 157, 0x9D*/
	UnitPathGoal_SeekBuildingForJob, /* 158, 0x9E*/
	UnitPathGoal_GrabMilkUnit, /* 159, 0x9F*/
	UnitPathGoal_GoToMilkStation, /* 160, 0xA0*/
	UnitPathGoal_SeekPatientForDressWound, /* 161, 0xA1*/
	UnitPathGoal_UndeadHunt, /* 162, 0xA2*/
	UnitPathGoal_GrabShearUnit, /* 163, 0xA3*/
	UnitPathGoal_GoToShearStation, /* 164, 0xA4*/
	UnitPathGoal_LayEggNestBox, /* 165, 0xA5*/
	UnitPathGoal_ClayZone, /* 166, 0xA6*/
	UnitPathGoal_ColonyToInstall, /* 167, 0xA7*/
	UnitPathGoal_ReturnColonyToInstall, /* 168, 0xA8*/
	UnitPathGoal_Nonsense, /* 169, 0xA9*/
	UnitPathGoal_SeekBloodSuckVictim, /* 170, 0xAA*/
	UnitPathGoal_SeekSheriff, /* 171, 0xAB*/
	UnitPathGoal_GrabExecutionWeapon, /* 172, 0xAC*/
	UnitPathGoal_TrainAnimal, /* 173, 0xAD*/
	UnitPathGoal_GuardPath, /* 174, 0xAE*/
	UnitPathGoal_Harass, /* 175, 0xAF*/
	UnitPathGoal_SiteWalk, /* 176, 0xB0*/
	UnitPathGoal_SiteWalkToBuilding, /* 177, 0xB1*/
	UnitPathGoal_Reunion, /* 178, 0xB2*/
	UnitPathGoal_ArmyWalk, /* 179, 0xB3*/
	UnitPathGoal_ChaseOpponentFlood, /* 180, 0xB4*/
	UnitPathGoal_ChargeAttack, /* 181, 0xB5*/
	UnitPathGoal_FleeFromOpponentClimb, /* 182, 0xB6*/
	UnitPathGoal_SeekLadderToClimb, /* 183, 0xB7*/
	UnitPathGoal_SeekLadderToMove, /* 184, 0xB8*/
	UnitPathGoal_PlaceLadder, /* 185, 0xB9*/
	UnitPathGoal_SeekAnimalForGelding, /* 186, 0xBA*/
	UnitPathGoal_SeekGeldingBuilding, /* 187, 0xBB*/
	UnitPathGoal_Prayer, /* 188, 0xBC*/
	UnitPathGoal_Socialize, /* 189, 0xBD*/
	UnitPathGoal_Performance, /* 190, 0xBE*/
	UnitPathGoal_Research, /* 191, 0xBF*/
	UnitPathGoal_PonderTopic, /* 192, 0xC0*/
	UnitPathGoal_FillServiceOrder, /* 193, 0xC1*/
	UnitPathGoal_GetWrittenContent, /* 194, 0xC2*/
	UnitPathGoal_GoToReadingPlace, /* 195, 0xC3*/
	UnitPathGoal_GetWritingMaterials, /* 196, 0xC4*/
	UnitPathGoal_GoToWritingPlace, /* 197, 0xC5*/
	UnitPathGoal_Worship, /* 198, 0xC6*/
	UnitPathGoal_GrabInstrument, /* 199, 0xC7*/
	UnitPathGoal_Play, /* 200, 0xC8*/
	UnitPathGoal_MakeBelieve, /* 201, 0xC9*/
	UnitPathGoal_PlayWithToy, /* 202, 0xCA*/
	UnitPathGoal_GrabToy, /* 203, 0xCB*/
};
]]

-- entity_position_responsibility.h

ffi.cdef[[
typedef int16_t EntityPositionResponsibility;
enum {
	EntityPositionResponsibility_NONE = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	EntityPositionResponsibility_LAW_MAKING, /* 0, 0x0*/
	EntityPositionResponsibility_LAW_ENFORCEMENT, /* 1, 0x1*/
	EntityPositionResponsibility_RECEIVE_DIPLOMATS, /* 2, 0x2*/
	EntityPositionResponsibility_MEET_WORKERS, /* 3, 0x3*/
	EntityPositionResponsibility_MANAGE_PRODUCTION, /* 4, 0x4*/
	EntityPositionResponsibility_TRADE, /* 5, 0x5*/
	EntityPositionResponsibility_ACCOUNTING, /* 6, 0x6*/
	EntityPositionResponsibility_ESTABLISH_COLONY_TRADE_AGREEMENTS, /* 7, 0x7*/
	EntityPositionResponsibility_MAKE_INTRODUCTIONS, /* 8, 0x8*/
	EntityPositionResponsibility_MAKE_PEACE_AGREEMENTS, /* 9, 0x9*/
	EntityPositionResponsibility_MAKE_TOPIC_AGREEMENTS, /* 10, 0xA*/
	EntityPositionResponsibility_COLLECT_TAXES, /* 11, 0xB*/
	EntityPositionResponsibility_ESCORT_TAX_COLLECTOR, /* 12, 0xC*/
	EntityPositionResponsibility_EXECUTIONS, /* 13, 0xD*/
	EntityPositionResponsibility_TAME_EXOTICS, /* 14, 0xE*/
	EntityPositionResponsibility_RELIGION, /* 15, 0xF*/
	EntityPositionResponsibility_ATTACK_ENEMIES, /* 16, 0x10*/
	EntityPositionResponsibility_PATROL_TERRITORY, /* 17, 0x11*/
	EntityPositionResponsibility_MILITARY_GOALS, /* 18, 0x12*/
	EntityPositionResponsibility_MILITARY_STRATEGY, /* 19, 0x13*/
	EntityPositionResponsibility_UPGRADE_SQUAD_EQUIPMENT, /* 20, 0x14*/
	EntityPositionResponsibility_EQUIPMENT_MANIFESTS, /* 21, 0x15*/
	EntityPositionResponsibility_SORT_AMMUNITION, /* 22, 0x16*/
	EntityPositionResponsibility_BUILD_MORALE, /* 23, 0x17*/
	EntityPositionResponsibility_HEALTH_MANAGEMENT, /* 24, 0x18*/
	EntityPositionResponsibility_ESPIONAGE, /* 25, 0x19*/
	EntityPositionResponsibility_ADVISE_LEADERS, /* 26, 0x1A*/
	EntityPositionResponsibility_OVERSEE_LEADER_HOUSEHOLD, /* 27, 0x1B*/
	EntityPositionResponsibility_MANAGE_ANIMALS, /* 28, 0x1C*/
	EntityPositionResponsibility_MANAGE_LEADER_HOUSEHOLD_FOOD, /* 29, 0x1D*/
	EntityPositionResponsibility_MANAGE_LEADER_HOUSEHOLD_DRINKS, /* 30, 0x1E*/
	EntityPositionResponsibility_PREPARE_LEADER_MEALS, /* 31, 0x1F*/
	EntityPositionResponsibility_MANAGE_LEADER_HOUSEHOLD_CLEANLINESS, /* 32, 0x20*/
	EntityPositionResponsibility_MAINTAIN_SEWERS, /* 33, 0x21*/
	EntityPositionResponsibility_FOOD_SUPPLY, /* 34, 0x22*/
	EntityPositionResponsibility_FIRE_SAFETY, /* 35, 0x23*/
	EntityPositionResponsibility_JUDGE, /* 36, 0x24*/
	EntityPositionResponsibility_BUILDING_SAFETY, /* 37, 0x25*/
	EntityPositionResponsibility_CONSTRUCTION_PERMITS, /* 38, 0x26*/
	EntityPositionResponsibility_MAINTAIN_ROADS, /* 39, 0x27*/
	EntityPositionResponsibility_MAINTAIN_BRIDGES, /* 40, 0x28*/
	EntityPositionResponsibility_MAINTAIN_TUNNELS, /* 41, 0x29*/
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
	AnimalTrainingLevel_SemiWild, /* 0, 0x0*/
	AnimalTrainingLevel_Trained, /* 1, 0x1*/
	AnimalTrainingLevel_WellTrained, /* 2, 0x2*/
	AnimalTrainingLevel_SkilfullyTrained, /* 3, 0x3*/
	AnimalTrainingLevel_ExpertlyTrained, /* 4, 0x4*/
	AnimalTrainingLevel_ExceptionallyTrained, /* 5, 0x5*/
	AnimalTrainingLevel_MasterfullyTrained, /* 6, 0x6*/
	AnimalTrainingLevel_Domesticated, /* 7, 0x7*/
	AnimalTrainingLevel_Unk8, /* 8, 0x8*/
	AnimalTrainingLevel_WildUntamed, /* 9, 0x9*/
};
]]

-- mood_type.h

ffi.cdef[[
typedef int16_t MoodType;
enum {
	MoodType_None = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	MoodType_Fey, /* 0, 0x0*/
	MoodType_Secretive, /* 1, 0x1*/
	MoodType_Possessed, /* 2, 0x2*/
	MoodType_Macabre, /* 3, 0x3*/
	MoodType_Fell, /* 4, 0x4*/
	MoodType_Melancholy, /* 5, 0x5*/
	MoodType_Raving, /* 6, 0x6*/
	MoodType_Berserk, /* 7, 0x7*/
	MoodType_Baby, /* 8, 0x8*/
	MoodType_Traumatized, /* 9, 0x9*/
};
]]

-- unit_genes.h

ffi.cdef[[
typedef struct UnitGenes {
	dfarray_byte appearance;
	dfarray_short colors;
} UnitGenes;
]]

-- cie_add_tag_mask1.h

ffi.cdef[[
typedef union CIEAddTagMask1 {
	uint32_t flags;
	struct CIEAddTagMask1_Bits {
		uint32_t EXTRAVISION : 1;
		uint32_t OPPOSED_TO_LIFE : 1;
		uint32_t NOT_LIVING : 1;
		uint32_t NOEXERT : 1;
		uint32_t NOPAIN : 1;
		uint32_t NOBREATHE : 1;
		uint32_t HAS_BLOOD : 1;
		uint32_t NOSTUN : 1;
		uint32_t NONAUSEA : 1;
		uint32_t NO_DIZZINESS : 1;
		uint32_t NO_FEVERS : 1;
		uint32_t TRANCES : 1;
		uint32_t NOEMOTION : 1;
		uint32_t LIKES_FIGHTING : 1;
		uint32_t PARALYZEIMMUNE : 1;
		uint32_t NOFEAR : 1;
		uint32_t NO_EAT : 1;
		uint32_t NO_DRINK : 1;
		uint32_t NO_SLEEP : 1;
		uint32_t MISCHIEVOUS : 1;
		uint32_t NO_PHYS_ATT_GAIN : 1;
		uint32_t NO_PHYS_ATT_RUST : 1;
		uint32_t NOTHOUGHT : 1;
		uint32_t NO_THOUGHT_CENTER_FOR_MOVEMENT : 1;
		uint32_t CAN_SPEAK : 1;
		uint32_t CAN_LEARN : 1;
		uint32_t UTTERANCES : 1;
		uint32_t CRAZED : 1;
		uint32_t BLOODSUCKER : 1;
		uint32_t NO_CONNECTIONS_FOR_MOVEMENT : 1;
		uint32_t SUPERNATURAL : 1;
		uint32_t anon_1 : 1;
	};
} CIEAddTagMask1;
]]

-- cie_add_tag_mask2.h

ffi.cdef[[
typedef union {
	uint32_t flags;
	struct CIEAddTagMask2_Bits {
		uint32_t NO_AGING : 1;
		uint32_t MORTAL : 1;
		uint32_t STERILE : 1;
		uint32_t FIT_FOR_ANIMATION : 1;
		uint32_t FIT_FOR_RESURRECTION : 1;
	};
} CIEAddTagMask2;
]]

-- material_vec_ref.h

ffi.cdef[[
typedef struct {
	vector_int16 matType;
	vector_int32 matIndex;
} MaterialVecRef;
]]

-- body_part_status.h

ffi.cdef[[
typedef union {
	uint32_t flags;
	struct {
		uint32_t onFire : 1;
		uint32_t missing : 1;
		uint32_t organLoss : 1; /*!< cyan */
		uint32_t organDamage : 1; /*!< yellow */
		uint32_t muscleLoss : 1; /*!< red */
		uint32_t muscleDamage : 1; /*!< yellow */
		uint32_t boneLoss : 1; /*!< red */
		uint32_t boneDamage : 1; /*!< yellow */
		uint32_t skinDamage : 1; /*!< brown */
		uint32_t motorNerveSevered : 1;
		uint32_t sensoryNerveSevered : 1;
		uint32_t spilledGuts : 1;
		uint32_t hasSplint : 1;
		uint32_t hasBandage : 1;
		uint32_t hasPlasterCast : 1;
		uint32_t grime : 3;
		uint32_t severedOrJammed : 1; /*!< seen e.g. on ribs smashed by blunt attack, but quickly disappeared */
		uint32_t underShell : 1;
		uint32_t isShell : 1;
		uint32_t mangled : 1; /*!< a wounded body part is described as being mangled beyond recognition when this flag is set */
		uint32_t unk20 : 1; /*!< on zombified head */
		uint32_t gelded : 1; /*!< set on GELDABLE body parts after a unit has been gelded */
	};
} BodyPartStatus;
]]
makeStdVector'BodyPartStatus'

-- body_layer_status.h

ffi.cdef[[
typedef union {
	uint32_t flags;
	struct {
		uint32_t gone : 1;
		uint32_t leaking : 1;
	};
} BodyLayerStatus;
]]
makeStdVector'BodyLayerStatus'

-- body_component_info.h

ffi.cdef[[
typedef struct {
	vector_BodyPartStatus bodyPartStatus;
	vector_uint32 numberedMasks; /*!< 1 bit per instance of a numbered body part */
	vector_uint32 nonSolidRemaining; /*!< 0-100% */
	vector_BodyLayerStatus layerStatus;
	vector_uint32 layerWoundArea;
	vector_uint32 layerCutFraction; /*!< 0-10000 */
	vector_uint32 layerDentFraction; /*!< 0-10000 */
	vector_uint32 layerEffectFraction; /*!< 0-1000000000 */
} BodyComponentInfo;
]]

-- unit_wound.h

-- TODO
ffi.cdef'typedef struct UnitWound UnitWound;'
makeStdVectorPtr'UnitWound'

-- gait_info.h

ffi.cdef[[typedef struct GaitInfo GaitInfo;]]
makeStdVectorPtr'GaitInfo'

-- creature_interaction_effect.h

-- TODO
ffi.cdef'typedef struct CreatureInteractionEffect CreatureInteractionEffect;'
makeStdVectorPtr'CreatureInteractionEffect'

-- breath_attack_type.h

ffi.cdef[[
typedef int16_t BreathAttackType;
enum {
	BreathAttackType_TRAILING_DUST_FLOW, // 0, 0x0
	BreathAttackType_TRAILING_VAPOR_FLOW, // 1, 0x1
	BreathAttackType_TRAILING_GAS_FLOW, // 2, 0x2
	BreathAttackType_SOLID_GLOB, // 3, 0x3
	BreathAttackType_LIQUID_GLOB, // 4, 0x4
	BreathAttackType_UNDIRECTED_GAS, // 5, 0x5
	BreathAttackType_UNDIRECTED_VAPOR, // 6, 0x6
	BreathAttackType_UNDIRECTED_DUST, // 7, 0x7
	BreathAttackType_WEB_SPRAY, // 8, 0x8
	BreathAttackType_DRAGONFIRE, // 9, 0x9
	BreathAttackType_FIREJET, // 10, 0xA
	BreathAttackType_FIREBALL, // 11, 0xB
	BreathAttackType_WEATHER_CREEPING_GAS, // 12, 0xC
	BreathAttackType_WEATHER_CREEPING_VAPOR, // 13, 0xD
	BreathAttackType_WEATHER_CREEPING_DUST, // 14, 0xE
	BreathAttackType_WEATHER_FALLING_MATERIAL, // 15, 0xF
	BreathAttackType_SPATTER_POWDER, // 16, 0x10
	BreathAttackType_SPATTER_LIQUID, // 17, 0x11
	BreathAttackType_UNDIRECTED_ITEM_CLOUD, // 18, 0x12
	BreathAttackType_TRAILING_ITEM_FLOW, // 19, 0x13
	BreathAttackType_SHARP_ROCK, // 20, 0x14
	BreathAttackType_OTHER, // 21, 0x15
};
]]

-- interaction_source_usage_hint.h

ffi.cdef[[
typedef int32_t InteractionSourceUsageHint;
typedef vector_int32 vector_InteractionSourceUsageHint;
enum {
	InteractionSourceUsageHint_MAJOR_CURSE, // 0, 0x0
	InteractionSourceUsageHint_GREETING, // 1, 0x1
	InteractionSourceUsageHint_CLEAN_SELF, // 2, 0x2
	InteractionSourceUsageHint_CLEAN_FRIEND, // 3, 0x3
	InteractionSourceUsageHint_ATTACK, // 4, 0x4
	InteractionSourceUsageHint_FLEEING, // 5, 0x5
	InteractionSourceUsageHint_NEGATIVE_SOCIAL_RESPONSE, // 6, 0x6
	InteractionSourceUsageHint_TORMENT, // 7, 0x7
	InteractionSourceUsageHint_DEFEND, // 8, 0x8
	InteractionSourceUsageHint_MEDIUM_CURSE, // 9, 0x9
	InteractionSourceUsageHint_MINOR_CURSE, // 10, 0xA
	InteractionSourceUsageHint_MEDIUM_BLESSING, // 11, 0xB
	InteractionSourceUsageHint_MINOR_BLESSING, // 12, 0xC
};
]]

-- interaction_effect_location_hint.h

ffi.cdef[[
typedef int32_t InteractionEffectLocationHint;
typedef vector_int32 vector_InteractionEffectLocationHint;
enum {
	InteractionEffectLocationHint_IN_WATER, // 0, 0x0
	InteractionEffectLocationHint_IN_MAGMA, // 1, 0x1
	InteractionEffectLocationHint_NO_WATER, // 2, 0x2
	InteractionEffectLocationHint_NO_MAGMA, // 3, 0x3
	InteractionEffectLocationHint_NO_THICK_FOG, // 4, 0x4
	InteractionEffectLocationHint_OUTSIDE, // 5, 0x5
};
]]

-- creature_interaction_target_flags.h

ffi.cdef[[
typedef union CreatureInteractionTargetFlags {
	uint32_t flags;
	struct {
		uint32_t LINE_OF_SIGHT : 1;
		uint32_t TOUCHABLE : 1;
		uint32_t DISTURBER_ONLY : 1;
		uint32_t SELF_ALLOWED : 1;
		uint32_t SELF_ONLY : 1;
	};
} CreatureInteractionTargetFlags;
]]
makeStdVector'CreatureInteractionTargetFlags'

-- creature_interaction.h

ffi.cdef[[
typedef struct CreatureInteraction {
	vector_string_ptr bp_required_type;
	vector_string_ptr bp_required_name;
	std_string unk_1;
	std_string unk_2;
	std_string material_str0;
	std_string material_str1;
	std_string material_str2;
	BreathAttackType materialBreath;
	std_string verb_2nd;
	std_string verb_3rd;
	std_string verb_mutual;
	std_string verb_reverse_2nd; /*!< for RETRACT_INTO_BP, e.g. "unroll" */
	std_string verb_reverse_3rd;
	std_string target_verb_2nd;
	std_string target_verb_3rd;
	std_string interaction_type;
	int32_t typeID;
	vector_InteractionSourceUsageHint usageHint;
	vector_InteractionEffectLocationHint locationHint;
	union {
		int32_t flags;
		struct {
			int32_t CAN_BE_MUTUAL : 1;
			int32_t VERBAL : 1;
			int32_t FREE_ACTION : 1;
		};
	};
	vector_string_ptr unk_3;
	vector_CreatureInteractionTargetFlags targetFlags;
	vector_int32 target_ranges;
	vector_string_ptr unk_4;
	vector_int32 max_target_numbers;
	vector_int32 verbal_speeches;
	vector_ptr unk_5;
	std_string adv_name;
	int32_t wait_period;
} CreatureInteraction;
]]
assertsizeof('CreatureInteraction', 408)

-- body_part_raw.h

-- TODO
ffi.cdef'typedef struct BodyPartRaw BodyPartRaw;'
makeStdVectorPtr'BodyPartRaw'

-- caste_attack.h

-- TODO
ffi.cdef'typedef struct CasteAttack CasteAttack;'
makeStdVectorPtr'CasteAttack'

-- caste_body_info.h

ffi.cdef[[
typedef int32_t CasteBodyInfo_Interactions_Type;
enum {
	CasteBodyInfo_Interactions_Type_RETRACT_INTO_BP, // 0, 0x0
	CasteBodyInfo_Interactions_Type_CAN_DO_INTERACTION, // 1, 0x1
	CasteBodyInfo_Interactions_Type_ROOT_AROUND, // 2, 0x2
};
typedef struct CasteBodyInfo_Interactions {
	CasteBodyInfo_Interactions_Type type;
	CreatureInteraction interaction;
} CasteBodyInfo_Interactions;
]]
makeStdVectorPtr'CasteBodyInfo_Interactions'

ffi.cdef[[
typedef struct CasteBodyInfo_ExtraButcherObjects {
	int16_t unk_1;
	std_string unk_2;
	int32_t unk_3;
	std_string unk_4;
	std_string unk_5;
	std_string unk_6;
	std_string unk_7;
	std_string unk_8;
	int16_t unk_9;
	int16_t unk_10;
	int16_t unk_11;
	int32_t unk_12;
	int32_t unk_13;
} CasteBodyInfo_ExtraButcherObjects;
]]
makeStdVectorPtr'CasteBodyInfo_ExtraButcherObjects'

ffi.cdef[[
typedef struct CasteBodyInfo {
	vector_BodyPartRaw_ptr bodyParts;
	vector_CasteAttack_ptr attacks;
	vector_CasteBodyInfo_Interactions_ptr interactions;
	vector_CasteBodyInfo_ExtraButcherObjects_ptr extra_butcher_objects;
	int32_t total_relsize; /*!< unless INTERNAL or EMBEDDED */
	vector_int16 layer_part;
	vector_int16 layer_idx;
	vector_uint32 numbered_masks; /*!< 1 bit per instance of a numbered body part */
	vector_int32 layer_nonsolid;
	vector_int32 nonsolidLayers;
	/**
	 * Since v0.34.01
	 */
	union {
		uint32_t flags;
		struct {
			uint32_t unk0 : 1;
		};
	}; /*!< since v0.34.01 */
	vector_GaitInfo_ptr gait_info[5];
	MaterialVecRef materials;
	int32_t fraction_total;
	int32_t fraction_base;
	int32_t fractionFat;
	int32_t fraction_muscle;
	int32_t unk_v40_2[11]; /*!< since v0.40.01 */
} CasteBodyInfo;
]]
assertsizeof('CasteBodyInfo', 464)

-- unit_attribute.h

ffi.cdef[[
typedef struct {
	int32_t value; /*!< effective = value - softDemotion */
	int32_t maxValue;
	int32_t improveCounter; /*!< counts to PHYS_ATT_RATES improve cost; then value++ */
	int32_t unusedCounter; /*!< counts to PHYS_ATT_RATES unused rate; then rustCounter++ */
	int32_t softDemotion; /*!< 0-100; when not 0 blocks improveCounter */
	int32_t rustCounter; /*!< counts to PHYS_ATT_RATES rust; then demotionCounter++ */
	int32_t demotionCounter; /*!< counts to PHYS_ATT_RATES demotion; then value--; soft_demotion++ */
} UnitAttribute;
]]

-- body_size_info.h

ffi.cdef[[
typedef struct {
	int32_t sizeCur;
	int32_t sizeBase;
	int32_t areaCur; /*!< size_cur^0.666 */
	int32_t areaBase; /*!< size_base^0.666 */
	int32_t lengthCur; /*!< (size_cur*10000)^0.333 */
	int32_t lengthBase; /*!< (size_base*10000)^0.333 */
} BodySizeInfo;
]]

-- spatter.h

-- TODO
ffi.cdef[[typedef struct Spatter Spatter;]]
makeStdVectorPtr'Spatter'

-- death_type.h

ffi.cdef[[
typedef int16_t DeathType;
enum {
	DeathType_NONE = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	DeathType_OLD_AGE, /* 0, 0x0*/
	DeathType_HUNGER, /* 1, 0x1*/
	DeathType_THIRST, /* 2, 0x2*/
	DeathType_SHOT, /* 3, 0x3*/
	DeathType_BLEED, /* 4, 0x4*/
	DeathType_DROWN, /* 5, 0x5*/
	DeathType_SUFFOCATE, /* 6, 0x6*/
	DeathType_STRUCK_DOWN, /* 7, 0x7*/
	DeathType_SCUTTLE, /* 8, 0x8*/
	DeathType_COLLISION, /* 9, 0x9*/
	DeathType_MAGMA, /* 10, 0xA*/
	DeathType_MAGMA_MIST, /* 11, 0xB*/
	DeathType_DRAGONFIRE, /* 12, 0xC*/
	DeathType_FIRE, /* 13, 0xD*/
	DeathType_SCALD, /* 14, 0xE*/
	DeathType_CAVEIN, /* 15, 0xF*/
	DeathType_DRAWBRIDGE, /* 16, 0x10*/
	DeathType_FALLING_ROCKS, /* 17, 0x11*/
	DeathType_CHASM, /* 18, 0x12*/
	DeathType_CAGE, /* 19, 0x13*/
	DeathType_MURDER, /* 20, 0x14*/
	DeathType_TRAP, /* 21, 0x15*/
	DeathType_VANISH, /* 22, 0x16*/
	DeathType_QUIT, /* 23, 0x17*/
	DeathType_ABANDON, /* 24, 0x18*/
	DeathType_HEAT, /* 25, 0x19*/
	DeathType_COLD, /* 26, 0x1A*/
	DeathType_SPIKE, /* 27, 0x1B*/
	DeathType_ENCASE_LAVA, /* 28, 0x1C*/
	DeathType_ENCASE_MAGMA, /* 29, 0x1D*/
	DeathType_ENCASE_ICE, /* 30, 0x1E*/
	DeathType_BEHEAD, /* 31, 0x1F*/
	DeathType_CRUCIFY, /* 32, 0x20*/
	DeathType_BURY_ALIVE, /* 33, 0x21*/
	DeathType_DROWN_ALT, /* 34, 0x22*/
	DeathType_BURN_ALIVE, /* 35, 0x23*/
	DeathType_FEED_TO_BEASTS, /* 36, 0x24*/
	DeathType_HACK_TO_PIECES, /* 37, 0x25*/
	DeathType_LEAVE_OUT_IN_AIR, /* 38, 0x26*/
	DeathType_BOIL, /* 39, 0x27*/
	DeathType_MELT, /* 40, 0x28*/
	DeathType_CONDENSE, /* 41, 0x29*/
	DeathType_SOLIDIFY, /* 42, 0x2A*/
	DeathType_INFECTION, /* 43, 0x2B*/
	DeathType_MEMORIALIZE, /* 44, 0x2C*/
	DeathType_SCARE, /* 45, 0x2D*/
	DeathType_DARKNESS, /* 46, 0x2E*/
	DeathType_COLLAPSE, /* 47, 0x2F*/
	DeathType_DRAIN_BLOOD, /* 48, 0x30*/
	DeathType_SLAUGHTER, /* 49, 0x31*/
	DeathType_VEHICLE, /* 50, 0x32*/
	DeathType_FALLING_OBJECT, /* 51, 0x33*/
	DeathType_LEAPT_FROM_HEIGHT, /* 52, 0x34*/
	DeathType_DROWN_ALT2, /* 53, 0x35*/
	DeathType_EXECUTION_GENERIC, /* 54, 0x36*/
};
]]

-- curse_attr_change.h

ffi.cdef[[
typedef struct {
	int32_t physAttPerc[6];
	int32_t physAttAdd[6];
	int32_t mentAttPerc[13];
	int32_t mentAttAdd[13];
} CurseAttrChange;
]]

-- unit_misc_traits.h

-- TODO
ffi.cdef'typedef struct UnitMiscTrait UnitMiscTrait;'
makeStdVectorPtr'UnitMiscTrait'

-- unit_soul.h

-- TODO
ffi.cdef'typedef struct UnitSoul UnitSoul;'
makeStdVectorPtr'UnitSoul'

-- unit_demand.h

-- TODO
ffi.cdef'typedef struct UnitDemand UnitDemand;'
makeStdVectorPtr'UnitDemand'

-- unit_item_wrestle.h

-- TODO
ffi.cdef'typedef struct UnitItemWrestle UnitItemWrestle;'
makeStdVectorPtr'UnitItemWrestle'

-- unit_complaint.h

-- TODO
ffi.cdef'typedef struct UnitComplaint UnitComplaint;'
makeStdVectorPtr'UnitComplaint'

-- unit_unk_138.h

-- TODO
ffi.cdef'typedef struct UnitUnknown138 UnitUnknown138;'
makeStdVectorPtr'UnitUnknown138'

-- unit_request.h

-- TODO
ffi.cdef'typedef struct UnitRequest UnitRequest;'
makeStdVectorPtr'UnitRequest'

-- unit_coin_debt.h

-- TODO
ffi.cdef'typedef struct UnitCoinDebt UnitCoinDebt;'
makeStdVectorPtr'UnitCoinDebt'

-- temperaturest.h

-- TODO
ffi.cdef'typedef struct Temperaturest Temperaturest;'
makeStdVectorPtr'Temperaturest'

-- tile_designation.h

-- TODO
ffi.cdef[[
typedef union {
	uint32_t flags;
	struct {
		uint32_t flow_size : 3; /*!< liquid amount */
		uint32_t pile : 1; /*!< stockpile; Adventure: lit */
		uint32_t/*TileDigDesignation*/ dig : 3; /*!< Adventure: line_of_sight, furniture_memory, item_memory */
		uint32_t smooth : 2; /*!< Adventure: creature_memory, original_cave */
		uint32_t hidden : 1;
		uint32_t geolayer_index : 4;
		uint32_t light : 1;
		uint32_t subterranean : 1;
		uint32_t outside : 1;
		uint32_t biome : 4;
		uint32_t/*TileLiquid*/ liquid_type : 1;
		uint32_t water_table : 1; /*!< aquifer */
		uint32_t rained : 1;
		uint32_t/*TileTraffic*/ traffic : 2;
		uint32_t flowForbid : 1;
		uint32_t liquid_static : 1;
		uint32_t featureLocal : 1;
		uint32_t feature_global : 1;
		uint32_t water_stagnant : 1;
		uint32_t water_salt : 1;
	};
} TileDesignation;
]]

-- unit_syndrome.h

-- TODO
ffi.cdef'typedef struct UnitSyndrome UnitSyndrome;'
makeStdVectorPtr'UnitSyndrome'

-- unit_health_info.h

-- TODO
ffi.cdef'typedef struct UnitHealthInfo UnitHealthInfo;'

-- unit_item_use.h

-- TODO
ffi.cdef'typedef struct UnitItemUse UnitItemUse;'
makeStdVectorPtr'UnitItemUse'

-- unit_appearance.h

-- TODO
ffi.cdef'typedef struct UnitAppearance UnitAppearance;'
makeStdVectorPtr'UnitAppearance'

-- witness_report.h

-- TODO
ffi.cdef'typedef struct WitnessReport WitnessReport;'
makeStdVectorPtr'WitnessReport'

-- entity_event.h

-- TODO
ffi.cdef'typedef struct EntityEvent EntityEvent;'
makeStdVectorPtr'EntityEvent'

-- army_controller.h

ffi.cdef'typedef struct ArmyController ArmyController;'
makeStdVectorPtr'ArmyController'

-- occupation.h

ffi.cdef'typedef struct Occupation Occupation;'
makeStdVectorPtr'Occupation'

-- unit_inventory_item.h

-- TODO
ffi.cdef'typedef struct UnitInventoryItem UnitInventoryItem;'
makeStdVectorPtr'UnitInventoryItem'

-- unit_ghost_info.h

-- TODO
ffi.cdef'typedef struct UnitGhostInfo UnitGhostInfo;'

-- unit.h

ffi.cdef[[
typedef int16_t SoldierMood;
enum {
	SoldierMood_None = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	SoldierMood_MartialTrance, /* 0, 0x0*/
	SoldierMood_Enraged, /* 1, 0x1*/
	SoldierMood_Tantrum, /* 2, 0x2*/
	SoldierMood_Depressed, /* 3, 0x3*/
	SoldierMood_Oblivious, /* 4, 0x4*/
};
]]

ffi.cdef[[
typedef uint8_t UnitMeetingState;
enum {
	UnitMeetingState_SelectNoble = 0,
	UnitMeetingState_FollowNoble = 1,
	UnitMeetingState_DoMeeting = 2,
	UnitMeetingState_LeaveMap = 3,
};
]]

ffi.cdef[[
typedef struct {
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
	int16_t unk_5;
	int16_t unk_6;
	int16_t unk_7;
} UnitStatusUnknown1;
]]
makeStdVectorPtr'UnitStatusUnknown1'

ffi.cdef[[
typedef struct {
	int32_t unk_sub1_1; /*!< checked if 0 while praying */
	int32_t unk_sub1_2;
	int32_t unk_sub1_3;
	int32_t remaining; /*!< set when praying; counts down to 0 */
	int32_t year;
	int32_t year_tick;
	union {
		uint32_t flags;
		struct {
			uint32_t anon_1 : 1;
		};
	};
	int32_t unk_sub1_8;
	int32_t unk_sub1_9;
} UnitEnemyUnknownv40Sub3_Unknown7_UnknownSub1;
]]
makeStdVectorPtr'UnitEnemyUnknownv40Sub3_Unknown7_UnknownSub1'

ffi.cdef[[
typedef int8_t UnitVisionCone[21][21];
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

	union {
		uint32_t flags1;
		struct {
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
		};
	};

	union {
		uint32_t flags2;
		struct {
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
		};
	};

	union {
		uint32_t flags3;
		struct {
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
		};
	};

	union {
		uint32_t flags4;
		struct {
			uint32_t unk_4_0 : 1;
			uint32_t unk_4_1 : 1;
			uint32_t unk_4_2 : 1;
			uint32_t unk_4_3 : 1;
		};
	};

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
		vector_int32 unk_items; /*!< since v0.34.06 */
		vector_int32 uniforms[4];
		union {
			uint32_t flags;	/* not needed? */
			uint32_t update : 1;
		} pickupFlags;	/* aslo not needed?  just pickupUpdate intead? */
		vector_int32 uniformPickup;
		vector_int32 uniformDrop;
		vector_int32 individualDrills;
	} military;

	vector_int32 socialActivities;
	vector_int32 conversations; /*!< since v0.40.01 */
	vector_int32 activities;
	vector_int32 unk_1e8; /*!< since v0.40.01 */
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
	vector_int32 ownedItems;
	vector_int32 tradedItems; /*!< items brought to trade depot */
	vector_Building_ptr ownedBuildings;
	vector_int32 corpseParts; /*!< entries remain even when items are destroyed */

	struct {
		int32_t account;
		int32_t satisfaction; /*!< amount earned recently for jobs */
		Unit * huntTarget;
		int32_t unk_v4305_1;
		Building * destroyTarget;
		int32_t unk_v40_1; /*!< since v0.40.01 */
		int32_t unk_v40_2; /*!< since v0.40.01 */
		int32_t unk_v40_3; /*!< since v0.40.01 */
		int32_t unk_v40_4; /*!< since v0.40.01 */
		int8_t unk_v40_5; /*!< since v0.40.01 */
		int32_t gaitBuildUp;
		Coord climbHold;
		int32_t unk_v4014_1; /*!< since v0.40.14 */
		Job * currentJob; /*!< df_job */
		JobSkill moodSkill; /*!< can be uninitialized for children and animals */
		int32_t moodTimeout; /*!< counts down from 50000, insanity upon reaching zero */
		int32_t unk_39c;
	} job;

	struct {
		BodyComponentInfo components;
		vector_UnitWound_ptr wounds;
		int32_t woundNextID;
		int32_t unk_39c[10];
		CasteBodyInfo * bodyPlan;
		int16_t weaponBodyPart;
		UnitAttribute physicalAttrs[6];
		BodySizeInfo sizeInfo;
		uint32_t bloodMax;
		uint32_t bloodCount;
		int32_t infectionLevel; /*!< GETS_INFECTIONS_FROM_ROT sets; DISEASE_RESISTANCE reduces; >=300 causes bleeding */
		vector_Spatter_ptr spatters;
	} body;

	struct {
		vector_int32 body_modifiers;
		vector_int32 bp_modifiers;
		int32_t size_modifier; /*!< product of all H/B/LENGTH body modifiers, in % */
		vector_int16 tissue_style;
		vector_int32 tissue_style_civID;
		vector_int32 tissue_styleID;
		vector_int32 tissue_style_type;
		vector_int32 tissueLength; /*!< description uses bp_modifiers[styleList_idx[index] ] */
		UnitGenes genes;
		vector_int32 colors;
	} appearance;

	vector_UnitAction_ptr actions;
	int32_t nextActionID;

	struct Unit_Counters {
		int32_t thinkCounter;
		int32_t jobCounter;
		int32_t swapCounter; /*!< dec per job_counter reroll, can_swap if 0 */
		DeathType deathCause;
		int32_t deathID;
		int16_t winded;
		int16_t stunned;
		int16_t unconscious;
		int16_t suffocation; /*!< counts up while winded, results in death */
		int16_t webbed;
		Coord gutsTrail1;
		Coord gutsTrail2;
		int16_t soldierMoodCountdown; /*!< plus a random amount */
		SoldierMood soldierMood;
		uint32_t pain;
		uint32_t nausea;
		uint32_t dizziness;
	} counters;

	struct Unit_Curse {
		int32_t unk_0; /*!< moved from end of counters in 0.43.05 */
		CIEAddTagMask1 addTags1;
		CIEAddTagMask1 removeTags1;
		CIEAddTagMask2 addTags2;
		CIEAddTagMask2 removeTags2;
		bool nameVisible; /*!< since v0.34.01 */
		std_string name; /*!< since v0.34.01 */
		std_string namePlural; /*!< since v0.34.01 */
		std_string nameAdjective; /*!< since v0.34.01 */
		uint32_t symAndColor1; /*!< since v0.34.01 */
		uint32_t symAndColor2; /*!< since v0.34.01 */
		uint32_t flashPeriod; /*!< since v0.34.01 */
		uint32_t flashTime2; /*!< since v0.34.01 */
		vector_int32 bodyAppearance;
		vector_int32 bodyPartAppearance; /*!< since v0.34.01; guess! */
		uint32_t speed_add; /*!< since v0.34.01 */
		uint32_t speed_mul_percent; /*!< since v0.34.01 */
		CurseAttrChange * attr_change; /*!< since v0.34.01 */
		uint32_t luck_mul_percent; /*!< since v0.34.01 */
		int32_t unk_98; /*!< since v0.42.01 */
		vector_int32 interactionID; /*!< since v0.34.01 */
		vector_int32 interaction_time; /*!< since v0.34.01 */
		vector_int32 interaction_delay; /*!< since v0.34.01 */
		int32_t time_on_site; /*!< since v0.34.01 */
		vector_int32 own_interaction; /*!< since v0.34.01 */
		vector_int32 own_interaction_delay; /*!< since v0.34.01 */
	} curse;

	struct {
		uint32_t paralysis;
		uint32_t numbness;
		uint32_t fever;
		uint32_t exhaustion;
		uint32_t hungerTimer;
		uint32_t thirstTimer;
		uint32_t sleepinessTimer;
		uint32_t stomachContent;
		uint32_t stomachFood;
		uint32_t vomitTimeout; /*!< blocks nausea causing vomit */
		uint32_t storedFat; /*!< hunger leads to death only when 0 */
	} counters2;

	struct {
		vector_UnitMiscTrait_ptr miscTraits;
		struct {
			struct {
				vector_ItemType item_type;
				vector_int16 item_subtype;
				MaterialVecRef material;
				vector_int32 year;
				vector_int32 yearTime;
			} food;
			struct {
				vector_ItemType item_type;
				vector_int16 itemSubType;
				MaterialVecRef material;
				vector_int32 year;
				vector_int32 yearTime;
			} drink;
		} * eat_history;
		int32_t demandTimeout;
		int32_t mandateTimeout;
		vector_int32 attackerIDs;
		vector_int16 attackerCountdown;
		uint8_t faceDirection; /*!< for wagons */
		LanguageName artifact_name;
		vector_UnitSoul_ptr souls;
		UnitSoul * current_soul;
		vector_UnitDemand_ptr demands;
		bool labors[94];
		vector_UnitItemWrestle_ptr wrestle_items;
		vector_int32 observedTraps;
		vector_UnitComplaint_ptr complaints;
		vector_UnitUnknown138_ptr unk_138; /*!< since v0.44.01 */
		vector_UnitRequest_ptr requests;
		vector_UnitCoinDebt_ptr coinDebts;
		vector_UnitStatusUnknown1_ptr unk_1; /*!< since v0.47.01 */
		int32_t unk_2; /*!< since v0.47.01 */
		int32_t unk_3; /*!< since v0.47.01 */
		int32_t unk_4[5]; /*!< since v0.47.01; initialized together with enemy.gait_index */
		int32_t unk_5; /*!< since v0.47.01 */
		int16_t adv_sleep_timer;
		Coord recent_job_area;
		CoordPath recent_jobs;
	} status;

	int32_t histFigureID;
	int32_t histFigureID2; /*!< used for ghost in AttackedByDead thought */
	struct {
		int16_t limbsStandMax;
		int16_t limbsStandCount;
		int16_t limbsGraspMax;
		int16_t limbsGraspCount;
		int16_t limbsFlyMax;
		int16_t limbsFlyCount;
		vector_Temperaturest_ptr bodyPartTemperature;
		uint32_t addPathFlags; /*!< pathing flags to OR, set to 0 after move */
		TileDesignation liquidType;
		uint8_t liquidDepth;
		int32_t histEventColID; /*!< linked to an active invasion or kidnapping */
	} status2;

	struct {
		vector_int32 unk_7c4;
		vector_int32 unk_c; /*!< since v0.34.01 */
	} unknown7;

	struct {
		vector_UnitSyndrome_ptr active;
		vector_int32 reinfectionType;
		vector_int16 reinfectionCount;
	} syndromes;

	struct {
		vector_int32 log[3];
		int32_t last_year[3];
		int32_t last_year_tick[3];
	} reports;

	UnitHealthInfo * health;
	vector_UnitItemUse_ptr usedItems; /*!< Contains worn clothes, armor, weapons, arrows fired by archers */

	struct {
		vector_int32 sound_cooldown; /*!< since v0.34.01 */
		struct {
			int32_t unk_1;
			int32_t unk_2;
			int32_t unk_3;
			int32_t unk_4;
			int32_t unk_5;
			int32_t unk_6; /*!< since v0.47.01 */
			int16_t rootBodyPartID; /*!< ID of the root body part in the corpse or corpse piece from which the reanimated unit was produced */
			std_string undeadName; /*!< display name of reanimated creatures */
			int32_t unk_v43_1; /*!< since v0.43.01 */
			int32_t unk_v43_2; /*!< since v0.43.01 */
		} * undead; /*!< since v0.34.01 */

		int32_t wereRace;
		int32_t wereCaste;
		int32_t normalRace;
		int32_t normalCaste;
		int32_t interaction; /*!< since v0.34.01; is set when a RETRACT_INTO_BP interaction is active */
		vector_UnitAppearance_ptr appearances;
		vector_WitnessReport_ptr witnessReports;
		vector_EntityEvent_ptr unk_a5c;
		int32_t gaitIndex[5];
		int32_t unk_unit_id_1[10]; /*!< since v0.40.01; number of non -1 entries control linked contents in following 4 vectors, rotating */
		int32_t unk_v40_1b[10]; /*!< since v0.40.01 */
		int32_t unk_v40_1c[10]; /*!< since v0.40.01; unused elements probably uninitialized */
		int32_t unk_v40_1d[10]; /*!< since v0.40.01; unused elements probably uninitialized */
		int32_t unk_v40_1e[10]; /*!< since v0.40.01; unused elements probably uninitialized */
		int32_t unk_unit_id_2[200]; /*!< since v0.40.01; Seen own side, enemy side, not involved (witnesses?). Unused fields not cleared */
		int32_t unk_unit_id_2_count; /*!< since v0.40.01 */

		struct {
			int32_t unk_1;
			int32_t unk_2;
			int32_t unk_3;
			struct {
				int32_t unk_1;
				int32_t unk_2;
				int32_t unk_3;
				int32_t unk_4;
				int32_t unk_5;
				int32_t unk_6;
				int32_t unk_7;
				int32_t unk_8;
				int32_t unk_9;
				int32_t unk_10; /*!< not saved */
			} unk;
		} * unk_448; /*!< since v0.40.01 */

		struct {
			int32_t unk_1;
			int32_t unk_2;
			int16_t unk_3;
			int32_t unk_4;
			int32_t unk_5;
			int32_t unk_6;
			int32_t unk_7[20];
			int32_t unk_8[20];
			int16_t unk_9;
			int16_t unk_10;
			int32_t unk_11;
			int32_t unk_12;
		} * unk_44c; /*!< since v0.40.01 */

		int32_t unk_450; /*!< since v0.40.01 */
		int32_t unk_454; /*!< since v0.40.01 */
		int32_t army_controllerID; /*!< since v0.40.01 */

		/**
		 * Since v0.40.01
		 */
		struct {
			ArmyController * controller; /*!< since v0.40.01 */
			struct {
				vector_int32 unk_1;
				vector_int32 unk_2;
				vector_int32 unk_3;
				vector_int32 unk_4;
			} * unk_2; /*!< since v0.40.01 */
			vector_int32 unk_3; /*!< since v0.40.01 */
			vector_int32 unk_4; /*!< since v0.40.01 */
			vector_int32 unk_5; /*!< since v0.40.01 */
			struct {
				vector_int32 unk_0;
				vector_int32 unk_10;
			} * unk_6;
			struct {
				vector_UnitEnemyUnknownv40Sub3_Unknown7_UnknownSub1_ptr unk_sub1;
				union {
					uint32_t flags;
					struct {
						uint32_t anon_1 : 1;
						uint32_t anon_2 : 1;
					};
				} unk_1;
				int32_t year;
				int32_t year_tick;
				int32_t unk_4;
				int32_t unk_5;
				int32_t unk_6;
				int32_t unk_7;
			} * unk_7; /*!< since v0.42.01 */
		} unk_v40_sub3; /*!< since v0.40.01 */
		int32_t combat_sideID;
		DFBitArray/*CasteRawFlags*/ casteFlags; /*!< since v0.44.06 */
		int32_t enemyStatusSlot;
		int32_t unk_874_cntr;
		vector_uint8 body_part_878;
		vector_uint8 body_part_888;
		vector_int32 body_part_relsize; /*!< with modifiers */
		vector_uint8 body_part_8a8;
		vector_uint16 body_part_base_ins;
		vector_uint16 body_part_clothing_ins;
		vector_uint16 body_part_8d8;
		vector_int32 unk_8e8;
		vector_uint16 unk_8f8;
	} enemy;

	vector_int32 healing_rate;
	int32_t effective_rate;
	int32_t tendons_heal;
	int32_t ligaments_heal;
	int32_t weight;
	int32_t weightFraction; /*!< 1e-6 */
	vector_int32 burrows;
	UnitVisionCone* vision_cone;
	vector_Occupation_ptr occupations; /*!< since v0.42.01 */
	std_string adjective; /*!< from physical descriptions for use in adv */

};
typedef struct Unit Unit;
]]

-- item.h

ffi.cdef[[
typedef struct {
	void * vtable; /* TODO */

	Coord pos;

	union {
		uint32_t flags;
		struct {
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
		};
	};

	union {
		uint32_t flags2;
		struct {
			uint32_t hasRider : 1; /*!< vehicle with a rider */
			uint32_t unk_2_1 : 1;
			uint32_t grown : 1;
			uint32_t unkBook : 1; /*!< possibly book/written-content-related */
			uint32_t anon_1 : 1;
		};
	};

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
	VerminCategory_None = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	VerminCategory_Eater, /* 0, 0x0*/
	VerminCategory_Grounder, /* 1, 0x1*/
	VerminCategory_Rotter, /* 2, 0x2*/
	VerminCategory_Swamper, /* 3, 0x3*/
	VerminCategory_Searched, /* 4, 0x4*/
	VerminCategory_Disturbed, /* 5, 0x5*/
	VerminCategory_Dropped, /* 6, 0x6*/
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

	/* verminFlags */
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
	vector_int32 buildings;
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

makeStdVectorPtr'Rect3D'

ffi.cdef[[
typedef struct {
	int8_t triggered;	/* vs bool?*/
	vector_int32 coffinSkeletons;
	int32_t disturbance;
	vector_int32 treasures;
	int32_t unk_1;
	int32_t unk_2;
	vector_Rect3D_ptr triggerRegions;
	Coord coffinPos;
} CursedTomb;
]]

-- conflict_level.h

ffi.cdef[[
typedef int32_t ConflictLevel;
enum {
	ConflictLevel_None = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	ConflictLevel_Encounter, /* 0, 0x0*/
	ConflictLevel_Horseplay, /* 1, 0x1*/
	ConflictLevel_Training, /* 2, 0x2*/
	ConflictLevel_Brawl, /* 3, 0x3*/
	ConflictLevel_Nonlethal, /* 4, 0x4*/
	ConflictLevel_Lethal, /* 5, 0x5*/
	ConflictLevel_NoQuarter, /* 6, 0x6*/
};
]]

-- job.h

-- TODO
ffi.cdef[[
typedef struct Job Job;
]]
makeStdVectorPtr'Job'

-- job_list_link.h

makeList'Job'

-- job_handler.h

ffi.cdef[[
typedef struct {
	int32_t index;
	Job * job;
	int32_t dead : 1;
	int32_t unk_1;
} JobHandlerPosting;
]]
makeStdVectorPtr'JobHandlerPosting'

ffi.cdef[[
typedef struct {
	void * vtable; /* TODO */
	list_Job list;
	vector_JobHandlerPosting_ptr postings;
	struct {
		Unit * unk1;
		int32_t unk2;
		int32_t unk3;
	} unk_1[2000];
	int32_t unk2;
} JobHandler;
]]


-- building_extents_type.h

ffi.cdef[[
typedef uint8_t BuildingExtentsType;
enum {
	BuildingExtentsType_None = 0, /* 0, 0x0*/
	BuildingExtentsType_Stockpile, /* 1, 0x1*/
	BuildingExtentsType_Wall, /* 2, 0x2*/
	BuildingExtentsType_Interior, /* 3, 0x3*/
	BuildingExtentsType_DistanceBoundary, /* 4, 0x4*/
};
]]

-- building_extents.h

ffi.cdef[[
typedef struct {
	BuildingExtentsType * extents;
	int32_t x;
	int32_t y;
	int32_t width;
	int32_t height;
} BuildingExtents;
]]

-- building.h

ffi.cdef[[
typedef struct {
	Unit * unit;
	int32_t timer;
} BuildingJobClaimSuppress;
]]
makeStdVectorPtr'BuildingJobClaimSuppress'

ffi.cdef[[
typedef struct {
	int32_t activityID;
	int32_t eventid;
} BuildingActivity;
]]
makeStdVectorPtr'BuildingActivity'

ffi.cdef[[
typedef struct {
	void * vtable;
	int32_t x1; /*!< top left */
	int32_t y1;
	int32_t centerx; /*!< work location */
	int32_t x2; /*!< bottom right */
	int32_t y2;
	int32_t centery;
	int32_t z;

	union {
		uint32_t flags;
		struct {
			uint32_t exists : 1; /*!< actually built, not just ordered */
			uint32_t siteBlocked : 1; /*!< items on ground on site */
			uint32_t roomCollision : 1; /*!< major intersection with another room? */
			uint32_t anon1 : 1;
			uint32_t justice : 1;
			uint32_t almostDeleted : 1; /*!< when requesting delete while in_update */
			uint32_t inUpdate : 1;
			uint32_t fromWorldGen : 1;
		};
	};

	int16_t matType;
	int32_t matIndex;
	BuildingExtents room;
	int32_t age;
	int16_t race;
	int32_t id;
	vector_Job_ptr jobs;
	vector_SpecificRef_ptr specificRefs;
	vector_GeneralRef_ptr generalRefs;
	bool isSoom;
	vector_Building_ptr children; /*!< other buildings within this room */
	vector_Building_ptr parents; /*!< rooms this building belongs to */
	int32_t ownerID; /*!< since v0.40.01 */
	Unit * owner;

	vector_BuildingJobClaimSuppress_ptr jobClaimSuppress; /*!< after Remv Cre, prevents unit from taking jobs at building */
	std_string name;

	vector_BuildingActivity_ptr activities;
	int32_t worldDataID; /*!< since v0.34.01 */
	int32_t worldDataSubID; /*!< since v0.34.01 */
	int32_t unk_v40_2; /*!< since v0.40.01 */
	int32_t siteID; /*!< since v0.42.01 */
	int32_t locationID; /*!< since v0.42.01 */
	int32_t unk_v40_3; /*!< since v0.40.01 */
} Building;
]]

-- projectile.h

-- TOOD
ffi.cdef'typedef struct Projectile Projectile;'

-- proj_list_link.h

makeList'Projectile'

-- machine.h

-- TODO
ffi.cdef'typedef struct Machine Machine;'
makeStdVectorPtr'Machine'

-- flow_guide.h

-- TODO
ffi.cdef'typedef struct FlowGuide FlowGuide;'
makeStdVectorPtr'FlowGuide'

-- plant.h

-- TODO
ffi.cdef'typedef struct Plant Plant;'
makeStdVectorPtr'Plant'

-- schedule_info.h

-- TODO
ffi.cdef'typedef struct ScheduleInfo ScheduleInfo;'
makeStdVectorPtr'ScheduleInfo'

-- squad.h

-- TODO
ffi.cdef'typedef struct Squad Squad;'
makeStdVectorPtr'Squad'

-- activity_entry.h

ffi.cdef'typedef struct ActivityEntry ActivityEntry;'
makeStdVectorPtr'ActivityEntry'

-- report.h

ffi.cdef'typedef struct Report Report;'
makeStdVectorPtr'Report'

-- popup_mesage.h

ffi.cdef'typedef struct PopupMessage PopupMessage;'
makeStdVectorPtr'PopupMessage'

-- mission_report.h

ffi.cdef'typedef struct MissionReport MissionReport;'
makeStdVectorPtr'MissionReport'

-- spoils_report.h

ffi.cdef'typedef struct SpoilsReport SpoilsReport;'
makeStdVectorPtr'SpoilsReport'

-- interrogation_report.h

ffi.cdef'typedef struct InterrogationReport InterrogationReport;'
makeStdVectorPtr'InterrogationReport'

-- combat_report_event_type.h

ffi.cdef[[
typedef int16_t CombatReportEventType;
enum {
	CombatReportEventType_anon_1, /* 0, 0x0*/
	CombatReportEventType_Deflected, /* 1, 0x1*/
	CombatReportEventType_anon_2, /* 2, 0x2*/
	CombatReportEventType_anon_3, /* 3, 0x3*/
	CombatReportEventType_anon_4, /* 4, 0x4*/
	CombatReportEventType_anon_5, /* 5, 0x5*/
	CombatReportEventType_Unconscious, /* 6, 0x6*/
	CombatReportEventType_Stunned, /* 7, 0x7*/
	CombatReportEventType_MoreStunned, /* 8, 0x8*/
	CombatReportEventType_Winded, /* 9, 0x9*/
	CombatReportEventType_MoreWinded, /* 10, 0xA*/
	CombatReportEventType_Nausea, /* 11, 0xB*/
	CombatReportEventType_MoreNausea, /* 12, 0xC*/
	CombatReportEventType_anon_6, /* 13, 0xD*/
	CombatReportEventType_anon_7, /* 14, 0xE*/
	CombatReportEventType_ExtractInjected, /* 15, 0xF*/
	CombatReportEventType_ExtractSprayed, /* 16, 0x10*/
	CombatReportEventType_BloodSucked, /* 17, 0x11*/
	CombatReportEventType_SeveredPart, /* 18, 0x12*/
	CombatReportEventType_anon_8, /* 19, 0x13*/
	CombatReportEventType_KnockedBack, /* 20, 0x14*/
	CombatReportEventType_StuckIn, /* 21, 0x15*/
	CombatReportEventType_LatchOnPart, /* 22, 0x16*/
	CombatReportEventType_LatchOn, /* 23, 0x17*/
	CombatReportEventType_Enraged, /* 24, 0x18*/
	CombatReportEventType_PassThrough, /* 25, 0x19*/
	CombatReportEventType_GlancesAway, /* 26, 0x1A*/
	CombatReportEventType_anon_9, /* 27, 0x1B*/
	CombatReportEventType_anon_10, /* 28, 0x1C*/
	CombatReportEventType_MajorArtery, /* 29, 0x1D*/
	CombatReportEventType_Artery, /* 30, 0x1E*/
	CombatReportEventType_MotorNerve, /* 31, 0x1F*/
	CombatReportEventType_SensoryNerve, /* 32, 0x20*/
	CombatReportEventType_NoForce, /* 33, 0x21*/
	CombatReportEventType_Interrupted, /* 34, 0x22*/
};
]]

-- interaction_instance.h

ffi.cdef'typedef struct InteractionInstance InteractionInstance;'
makeStdVectorPtr'InteractionInstance'

-- written_content.h

ffi.cdef'typedef struct WrittenContent WrittenContent;'
makeStdVectorPtr'WrittenContent'

-- identity.h

ffi.cdef'typedef struct Identity Identity;'
makeStdVectorPtr'Identity'

-- incident.h

ffi.cdef'typedef struct Incident Incident;'
makeStdVectorPtr'Incident'

-- crime.h

ffi.cdef'typedef struct Crime Crime;'
makeStdVectorPtr'Crime'

-- vehicle.h

ffi.cdef'typedef struct Vehicle Vehicle;'
makeStdVectorPtr'Vehicle'

-- army.h

ffi.cdef'typedef struct Army Army;'
makeStdVectorPtr'Army'

-- cultural_identity.h

ffi.cdef'typedef struct CulturalIdentity CulturalIdentity;'
makeStdVectorPtr'CulturalIdentity'

-- agreement.h

ffi.cdef'typedef struct Agreement Agreement;'
makeStdVectorPtr'Agreement'

-- poetic_form.h

ffi.cdef'typedef struct PoeticForm PoeticForm;'
makeStdVectorPtr'PoeticForm'

-- musical_form.h

ffi.cdef'typedef struct MusicalForm MusicalForm;'
makeStdVectorPtr'MusicalForm'

-- dance_form.h

ffi.cdef'typedef struct DanceForm DanceForm;'
makeStdVectorPtr'DanceForm'

-- scale.h

ffi.cdef'typedef struct Scale Scale;'
makeStdVectorPtr'Scale'

-- rhythm.h

ffi.cdef'typedef struct Rhythm Rhythm;'
makeStdVectorPtr'Rhythm'

-- belief_system.h

ffi.cdef'typedef struct BeliefSystem BeliefSystem;'
makeStdVectorPtr'BeliefSystem'

-- image_set.h

ffi.cdef'typedef struct ImageSet ImageSet;'
makeStdVectorPtr'ImageSet'

-- divination_set.h

ffi.cdef'typedef struct DivinationSet DivinationSet;'
makeStdVectorPtr'DivinationSet'

-- stockpile_category.h

ffi.cdef[[
typedef int16_t StockpileCategory;
enum {
	StockpileCategory_Remove = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	StockpileCategory_Animals, /* 0, 0x0*/
	StockpileCategory_Food, /* 1, 0x1*/
	StockpileCategory_Furniture, /* 2, 0x2*/
	StockpileCategory_Corpses, /* 3, 0x3*/
	StockpileCategory_Refuse, /* 4, 0x4*/
	StockpileCategory_Stone, /* 5, 0x5*/
	StockpileCategory_Ore, /* 6, 0x6*/
	StockpileCategory_Ammo, /* 7, 0x7*/
	StockpileCategory_Coins, /* 8, 0x8*/
	StockpileCategory_Bars, /* 9, 0x9*/
	StockpileCategory_Gems, /* 10, 0xA*/
	StockpileCategory_Goods, /* 11, 0xB*/
	StockpileCategory_Leather, /* 12, 0xC*/
	StockpileCategory_Cloth, /* 13, 0xD*/
	StockpileCategory_Wood, /* 14, 0xE*/
	StockpileCategory_Weapons, /* 15, 0xF*/
	StockpileCategory_Armor, /* 16, 0x10*/
	StockpileCategory_Sheets, /* 17, 0x11*/
	StockpileCategory_Custom, /* 18, 0x12*/
};
]]

-- screw_pump_direction.h

ffi.cdef[[
typedef int8_t ScrewPumpDirection;
enum {
	ScrewPumpDirection_FromNorth, /* 0, 0x0*/
	ScrewPumpDirection_FromEast, /* 1, 0x1*/
	ScrewPumpDirection_FromSouth, /* 2, 0x2*/
	ScrewPumpDirection_FromWest, /* 3, 0x3*/
};
]]

-- map_block.h

-- TODO
ffi.cdef'typedef struct MapBlock MapBlock;'
makeStdVectorPtr'MapBlock'

-- map_block_column.h

-- TODO
ffi.cdef'typedef struct MapBlockColumn MapBlockColumn;'
makeStdVectorPtr'MapBlockColumn'

-- z_level_flags.h

ffi.cdef[[
typedef union {
	uint32_t flags;
	struct {
		uint32_t update : 1;
		uint32_t can_stop : 1;
		uint32_t update_twice : 1;
	};
} ZLevelFlags;
]]

-- block_square_event_spoorst.h

--- TODO
ffi.cdef'typedef struct BlockSquareEventSpoorst BlockSquareEventSpoorst;'
makeStdVectorPtr'BlockSquareEventSpoorst'

-- orientation_flags.h

ffi.cdef[[
typedef union OrientationFlags {
	uint32_t flags;
	struct {
		uint32_t indeterminate : 1; /*!< only seen on adventurers */
		uint32_t romanceMale : 1;
		uint32_t marryMale : 1;
		uint32_t romanceFemale : 1;
		uint32_t marryFemale : 1;
	};
} OrientationFlags;
]]

-- histfig_entity_link_type.h

ffi.cdef[[
typedef int32_t HistfigEntityLinkType;
enum {
	HistfigEntityLinkType_MEMBER, // 0, 0x0
	HistfigEntityLinkType_FORMER_MEMBER, // 1, 0x1
	HistfigEntityLinkType_MERCENARY, // 2, 0x2
	HistfigEntityLinkType_FORMER_MERCENARY, // 3, 0x3
	HistfigEntityLinkType_SLAVE, // 4, 0x4
	HistfigEntityLinkType_FORMER_SLAVE, // 5, 0x5
	HistfigEntityLinkType_PRISONER, // 6, 0x6
	HistfigEntityLinkType_FORMER_PRISONER, // 7, 0x7
	HistfigEntityLinkType_ENEMY, // 8, 0x8
	HistfigEntityLinkType_CRIMINAL, // 9, 0x9
	HistfigEntityLinkType_POSITION, // 10, 0xA
	HistfigEntityLinkType_FORMER_POSITION, // 11, 0xB
	HistfigEntityLinkType_POSITION_CLAIM, // 12, 0xC
	HistfigEntityLinkType_SQUAD, // 13, 0xD
	HistfigEntityLinkType_FORMER_SQUAD, // 14, 0xE
	HistfigEntityLinkType_OCCUPATION, // 15, 0xF
	HistfigEntityLinkType_FORMER_OCCUPATION, // 16, 0x10
};
]]

-- file_compressorst.h

ffi.cdef[[
typedef struct FileCompressorst {
	bool compressed;					/* offset: 0x0 */
	std_fstream f;						/* offset: 0x8 */
	uint8_t * inBuffer;					/* offset: 0x218 */
	long inBufferSize;					/* offset: 0x220 */
	long inBufferAmountLoaded;			/* offset: 0x228 */
	long inBufferPosition;				/* offset: 0x230 */
	uint8_t * outBuffer;				/* offset: 0x238 */
	long outBufferSize;					/* offset: 0x240 */
	int32_t outBufferAmountWritten;		/* offset: 0x248 */
} FileCompressorst;						/* sizeof: 0x250 */
]]
assertsizeof('FileCompressorst', 0x250)

-- save_version.h

ffi.cdef[[
typedef int32_t SaveVersion;
enum {
	SaveVersion_v0_21_93_19a = 1107, /* 1107, 0x453*/
	SaveVersion_v0_21_93_19c = 1108, /* 1108, 0x454*/
	SaveVersion_v0_21_95_19a = 1108, /* 1108, 0x454*/
	SaveVersion_v0_21_95_19b = 1108, /* 1108, 0x454*/
	SaveVersion_v0_21_95_19c = 1110, /* 1110, 0x456*/
	SaveVersion_v0_21_104_19d = 1121, /* 1121, 0x461*/
	SaveVersion_v0_21_104_21a = 1123, /* 1123, 0x463*/
	SaveVersion_v0_21_104_21b = 1125, /* 1125, 0x465*/
	SaveVersion_v0_21_105_21a = 1128, /* 1128, 0x468*/
	SaveVersion_v0_22_107_21a = 1128, /* 1128, 0x468*/
	SaveVersion_v0_22_110_22e = 1134, /* 1134, 0x46E*/
	SaveVersion_v0_22_110_22f = 1137, /* 1137, 0x471*/
	SaveVersion_v0_22_110_23a = 1148, /* 1148, 0x47C*/
	SaveVersion_v0_22_120_23a = 1151, /* 1151, 0x47F*/
	SaveVersion_v0_22_121_23b = 1161, /* 1161, 0x489*/
	SaveVersion_v0_22_123_23a = 1165, /* 1165, 0x48D*/
	SaveVersion_v0_23_130_23a = 1169, /* 1169, 0x491*/
	SaveVersion_v0_27_169_32a = 1205, /* 1205, 0x4B5*/
	SaveVersion_v0_27_169_33a = 1206, /* 1206, 0x4B6*/
	SaveVersion_v0_27_169_33b = 1209, /* 1209, 0x4B9*/
	SaveVersion_v0_27_169_33c = 1211, /* 1211, 0x4BB*/
	SaveVersion_v0_27_169_33d = 1212, /* 1212, 0x4BC*/
	SaveVersion_v0_28_181_39b = 1255, /* 1255, 0x4E7*/
	SaveVersion_v0_28_181_39c = 1256, /* 1256, 0x4E8*/
	SaveVersion_v0_28_181_39d = 1259, /* 1259, 0x4EB*/
	SaveVersion_v0_28_181_39e = 1260, /* 1260, 0x4EC*/
	SaveVersion_v0_28_181_39f = 1261, /* 1261, 0x4ED*/
	SaveVersion_v0_28_181_40a = 1265, /* 1265, 0x4F1*/
	SaveVersion_v0_28_181_40b = 1266, /* 1266, 0x4F2*/
	SaveVersion_v0_28_181_40c = 1267, /* 1267, 0x4F3*/
	SaveVersion_v0_28_181_40d = 1268, /* 1268, 0x4F4*/
	SaveVersion_v0_31_01 = 1287, /* 1287, 0x507*/
	SaveVersion_v0_31_02 = 1288, /* 1288, 0x508*/
	SaveVersion_v0_31_03 = 1289, /* 1289, 0x509*/
	SaveVersion_v0_31_04 = 1292, /* 1292, 0x50C*/
	SaveVersion_v0_31_05 = 1295, /* 1295, 0x50F*/
	SaveVersion_v0_31_06 = 1297, /* 1297, 0x511*/
	SaveVersion_v0_31_08 = 1300, /* 1300, 0x514*/
	SaveVersion_v0_31_09 = 1304, /* 1304, 0x518*/
	SaveVersion_v0_31_10 = 1305, /* 1305, 0x519*/
	SaveVersion_v0_31_11 = 1310, /* 1310, 0x51E*/
	SaveVersion_v0_31_12 = 1311, /* 1311, 0x51F*/
	SaveVersion_v0_31_13 = 1323, /* 1323, 0x52B*/
	SaveVersion_v0_31_14 = 1325, /* 1325, 0x52D*/
	SaveVersion_v0_31_15 = 1326, /* 1326, 0x52E*/
	SaveVersion_v0_31_16 = 1327, /* 1327, 0x52F*/
	SaveVersion_v0_31_17 = 1340, /* 1340, 0x53C*/
	SaveVersion_v0_31_18 = 1341, /* 1341, 0x53D*/
	SaveVersion_v0_31_19 = 1351, /* 1351, 0x547*/
	SaveVersion_v0_31_20 = 1353, /* 1353, 0x549*/
	SaveVersion_v0_31_21 = 1354, /* 1354, 0x54A*/
	SaveVersion_v0_31_22 = 1359, /* 1359, 0x54F*/
	SaveVersion_v0_31_23 = 1360, /* 1360, 0x550*/
	SaveVersion_v0_31_24 = 1361, /* 1361, 0x551*/
	SaveVersion_v0_31_25 = 1362, /* 1362, 0x552*/
	SaveVersion_v0_34_01 = 1372, /* 1372, 0x55C*/
	SaveVersion_v0_34_02 = 1374, /* 1374, 0x55E*/
	SaveVersion_v0_34_03 = 1376, /* 1376, 0x560*/
	SaveVersion_v0_34_04 = 1377, /* 1377, 0x561*/
	SaveVersion_v0_34_05 = 1378, /* 1378, 0x562*/
	SaveVersion_v0_34_06 = 1382, /* 1382, 0x566*/
	SaveVersion_v0_34_07 = 1383, /* 1383, 0x567*/
	SaveVersion_v0_34_08 = 1400, /* 1400, 0x578*/
	SaveVersion_v0_34_09 = 1402, /* 1402, 0x57A*/
	SaveVersion_v0_34_10 = 1403, /* 1403, 0x57B*/
	SaveVersion_v0_34_11 = 1404, /* 1404, 0x57C*/
	SaveVersion_v0_40_01 = 1441, /* 1441, 0x5A1*/
	SaveVersion_v0_40_02 = 1442, /* 1442, 0x5A2*/
	SaveVersion_v0_40_03 = 1443, /* 1443, 0x5A3*/
	SaveVersion_v0_40_04 = 1444, /* 1444, 0x5A4*/
	SaveVersion_v0_40_05 = 1445, /* 1445, 0x5A5*/
	SaveVersion_v0_40_06 = 1446, /* 1446, 0x5A6*/
	SaveVersion_v0_40_07 = 1448, /* 1448, 0x5A8*/
	SaveVersion_v0_40_08 = 1449, /* 1449, 0x5A9*/
	SaveVersion_v0_40_09 = 1451, /* 1451, 0x5AB*/
	SaveVersion_v0_40_10 = 1452, /* 1452, 0x5AC*/
	SaveVersion_v0_40_11 = 1456, /* 1456, 0x5B0*/
	SaveVersion_v0_40_12 = 1459, /* 1459, 0x5B3*/
	SaveVersion_v0_40_13 = 1462, /* 1462, 0x5B6*/
	SaveVersion_v0_40_14 = 1469, /* 1469, 0x5BD*/
	SaveVersion_v0_40_15 = 1470, /* 1470, 0x5BE*/
	SaveVersion_v0_40_16 = 1471, /* 1471, 0x5BF*/
	SaveVersion_v0_40_17 = 1472, /* 1472, 0x5C0*/
	SaveVersion_v0_40_18 = 1473, /* 1473, 0x5C1*/
	SaveVersion_v0_40_19 = 1474, /* 1474, 0x5C2*/
	SaveVersion_v0_40_20 = 1477, /* 1477, 0x5C5*/
	SaveVersion_v0_40_21 = 1478, /* 1478, 0x5C6*/
	SaveVersion_v0_40_22 = 1479, /* 1479, 0x5C7*/
	SaveVersion_v0_40_23 = 1480, /* 1480, 0x5C8*/
	SaveVersion_v0_40_24 = 1481, /* 1481, 0x5C9*/
	SaveVersion_v0_42_01 = 1531, /* 1531, 0x5FB*/
	SaveVersion_v0_42_02 = 1532, /* 1532, 0x5FC*/
	SaveVersion_v0_42_03 = 1533, /* 1533, 0x5FD*/
	SaveVersion_v0_42_04 = 1534, /* 1534, 0x5FE*/
	SaveVersion_v0_42_05 = 1537, /* 1537, 0x601*/
	SaveVersion_v0_42_06 = 1542, /* 1542, 0x606*/
	SaveVersion_v0_43_01 = 1551, /* 1551, 0x60F*/
	SaveVersion_v0_43_02 = 1552, /* 1552, 0x610*/
	SaveVersion_v0_43_03 = 1553, /* 1553, 0x611*/
	SaveVersion_v0_43_04 = 1555, /* 1555, 0x613*/
	SaveVersion_v0_43_05 = 1556, /* 1556, 0x614*/
	SaveVersion_v0_44_01 = 1596, /* 1596, 0x63C*/
	SaveVersion_v0_44_02 = 1597, /* 1597, 0x63D*/
	SaveVersion_v0_44_03 = 1600, /* 1600, 0x640*/
	SaveVersion_v0_44_04 = 1603, /* 1603, 0x643*/
	SaveVersion_v0_44_05 = 1604, /* 1604, 0x644*/
	SaveVersion_v0_44_06 = 1611, /* 1611, 0x64B*/
	SaveVersion_v0_44_07 = 1612, /* 1612, 0x64C*/
	SaveVersion_v0_44_08 = 1613, /* 1613, 0x64D*/
	SaveVersion_v0_44_09 = 1614, /* 1614, 0x64E*/
	SaveVersion_v0_44_10 = 1620, /* 1620, 0x654*/
	SaveVersion_v0_44_11 = 1623, /* 1623, 0x657*/
	SaveVersion_v0_44_12 = 1625, /* 1625, 0x659*/
	SaveVersion_v0_47_01 = 1710, /* 1710, 0x6AE*/
	SaveVersion_v0_47_02 = 1711, /* 1711, 0x6AF*/
	SaveVersion_v0_47_03 = 1713, /* 1713, 0x6B1*/
	SaveVersion_v0_47_04 = 1715, /* 1715, 0x6B3*/
	SaveVersion_v0_47_05 = 1716, /* 1716, 0x6B4*/
};
]]

-- histfig_entity_link.h

-- why is this called link again?
ffi.cdef[[
typedef struct HistfigEntityLink HistfigEntityLink;

typedef struct HistfigEntityLink_vtable {
	HistfigEntityLinkType (*getType)(HistfigEntityLink *);
	void (*dtor)(HistfigEntityLink *);
	void (*writeFile)(HistfigEntityLink *, FileCompressorst *);
	void (*readFile)(HistfigEntityLink *, FileCompressorst *, SaveVersion);
	void (*anon_4)(HistfigEntityLink *);
	void (*anon_5)(HistfigEntityLink *);
	int32_t (*getPosition)(HistfigEntityLink *);
	int32_t (*getOccupation)(HistfigEntityLink *);
	int32_t (*getPositionStartYear)(HistfigEntityLink *);
	int32_t (*getPositionEndYear)(HistfigEntityLink *);
	void (*generateXML)(HistfigEntityLink *, std_fstream *, int32_t);
} HistfigEntityLink_vtable;

struct HistfigEntityLink {
	HistfigEntityLink_vtable * vtable;
    int32_t entityID;
    int16_t linkStrength;
};
]]
assertsizeof('HistfigEntityLink', 16)
makeStdVectorPtr'HistfigEntityLink'

-- histfig_site_link.h

ffi.cdef[[
typedef struct HistfigSiteLink {
    void * vtable;
	int32_t site;
    int32_t subID; /*!< from XML */
    int32_t entity;
} HistfigSiteLink;
]]
makeStdVectorPtr'HistfigSiteLink'

-- histfig_hf_link.h

ffi.cdef[[
typedef struct HistfigHFLink {
    int32_t targetHF;
    int16_t linkStrength;
} HistfigHFLink;
]]
makeStdVectorPtr'HistfigHFLink'

-- historical_figure_info.h

-- TODO
ffi.cdef'typedef struct HistoricalFigureInfo HistoricalFigureInfo;'

-- vague_relationship_type.h

ffi.cdef[[
typedef int16_t VagueRelationshipType;
enum {
	VagueRelationshipType_none = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	VagueRelationshipType_childhoodFriend, /* 0, 0x0*/
	VagueRelationshipType_war_buddy, /* 1, 0x1*/
	VagueRelationshipType_jealous_obsession, /* 2, 0x2*/
	VagueRelationshipType_jealous_relationship_grudge, /* 3, 0x3*/
	VagueRelationshipType_lover, /* 4, 0x4*/
	/**
	* broke up
	*/
	VagueRelationshipType_former_lover, /* 5, 0x5*/
	VagueRelationshipType_scholar_buddy, /* 6, 0x6*/
	VagueRelationshipType_artistic_buddy, /* 7, 0x7*/
	VagueRelationshipType_athlete_buddy, /* 8, 0x8*/
	VagueRelationshipType_atheletic_rival, /* 9, 0x9*/
	VagueRelationshipType_business_rival, /* 10, 0xA*/
	VagueRelationshipType_religious_persecution_grudge, /* 11, 0xB*/
	VagueRelationshipType_grudge, /* 12, 0xC*/
	VagueRelationshipType_persecution_grudge, /* 13, 0xD*/
	VagueRelationshipType_supernatural_grudge, /* 14, 0xE*/
	VagueRelationshipType_lieutenant, /* 15, 0xF*/
	VagueRelationshipType_worshipped_deity, /* 16, 0x10*/
	VagueRelationshipType_spouse, /* 17, 0x11*/
	VagueRelationshipType_mother, /* 18, 0x12*/
	VagueRelationshipType_father, /* 19, 0x13*/
	VagueRelationshipType_master, /* 20, 0x14*/
	VagueRelationshipType_apprentice, /* 21, 0x15*/
	VagueRelationshipType_companion, /* 22, 0x16*/
	VagueRelationshipType_ex_spouse, /* 23, 0x17*/
	VagueRelationshipType_neighbor, /* 24, 0x18*/
	/**
	* Religion/PerformanceTroupe/MerchantCompany/Guild
	*/
	VagueRelationshipType_shared_entity, /* 25, 0x19*/
};
]]

-- world_site.h

--- TODO
ffi.cdef'typedef struct WorldSite WorldSite;'
makeStdVectorPtr'WorldSite'

-- world_region.h

--- TODO
ffi.cdef'typedef struct WorldRegion WorldRegion;'
makeStdVectorPtr'WorldRegion'

-- world_underground_region.h

--- TODO
ffi.cdef'typedef struct WorldUndergroundRegion WorldUndergroundRegion;'
makeStdVectorPtr'WorldUndergroundRegion'

-- historical_figure.h

-- TODO
ffi.cdef[[
struct HistoricalFigure {
	Profession profession;
	int16_t race;
	int16_t caste;
	Gender sex;
	OrientationFlags orientationFlags;
	int32_t appearedYear;
	int32_t bornYear;
	int32_t bornSeconds;
	int32_t curseYear; /*!< since v0.34.01 */
	int32_t curseSeconds; /*!< since v0.34.01 */
	int32_t birthYearBias; /*!< since v0.34.01 */
	int32_t birthTimeBias; /*!< since v0.34.01 */
	int32_t oldYear;
	int32_t oldSeconds;
	int32_t diedYear;
	int32_t diedSeconds;
	LanguageName name;
	int32_t civID;
	int32_t populationID;
	int32_t breedID; /*!< from legends export */
	int32_t culturalIdentity; /*!< since v0.40.01 */
	int32_t familyHeadID; /*!< since v0.44.01; When a unit is asked about their family in adventure mode, the historical figure corresponding to this ID is called the head of the family or ancestor. */
	DFBitArray/*HistfigFlags*/ flags;
	int32_t unitID;
	int32_t nemesisID; /*!< since v0.40.01; sometimes garbage */
	int32_t id;
	int32_t unk4;
	vector_HistfigEntityLink_ptr entityLinks;
	vector_HistfigSiteLink_ptr siteLinks;
	vector_HistfigHFLink_ptr histfigLinks;
	HistoricalFigureInfo * info;
	struct {
		int32_t hfid[6];
		VagueRelationshipType relationship[6]; /*!< unused elements are uninitialized */
		int32_t count; /*!< number of hf/relationship pairs above */
	} * vagueRelationships; /*!< Do not have to be available mutually, i.e. DF can display Legends relations forming for the other party that does not have an entry (plus time and other conditions not located) */
	WorldSite * unk_f0;
	WorldRegion * unk_f4;
	WorldUndergroundRegion * unk_f8;
	struct {
		dfarray_uint8 unk_0;
		dfarray_int16 unk_8;
	} * unk_fc;
	struct {
		HistoricalFigure * unk_1;
		HistoricalFigure * unk_2;
		HistoricalFigure * unk_3;
		HistoricalFigure * unk_4;
		HistoricalFigure * unk_5;
		HistoricalFigure * unk_6;
		int16_t unk_7;
		int16_t unk_8;
		int16_t unk_9;
		int16_t unk_10;
		int16_t unk_11;
		int16_t unk_12;
		int32_t unk_13;
		HistoricalFigure * unk_14;
		HistoricalFigure * unk_15;
		HistoricalFigure * unk_16;
	} * unk_v47_2;
	int32_t unk_v47_3;
	int32_t unk_v47_4;
	int32_t unk_v4019_1; /*!< since v0.40.17-19 */
	int32_t unk_5;
} HistoricalFigure;
]]

assert.eq(ffi.offsetof('HistoricalFigure', 'profession'), 0)
assert.eq(ffi.offsetof('HistoricalFigure', 'race'), 2)
assert.eq(ffi.offsetof('HistoricalFigure', 'caste'), 4)
assert.eq(ffi.offsetof('HistoricalFigure', 'sex'), 6)
assert.eq(ffi.offsetof('HistoricalFigure', 'orientationFlags'), 8)
assert.eq(ffi.offsetof('HistoricalFigure', 'appearedYear'), 0xc)
assert.eq(ffi.offsetof('HistoricalFigure', 'name'), 0x38)
assert.eq(ffi.offsetof('HistoricalFigure', 'unk_fc'), 0x128)
assertsizeof('HistoricalFigure', 328)
makeStdVectorPtr'HistoricalFigure'

-- world_region_details.h

--- TODO
ffi.cdef'typedef struct WorldRegionDetails WorldRegionDetails;'
makeStdVectorPtr'WorldRegionDetails'

-- world_construction_square.h

--- TODO
ffi.cdef'typedef struct WorldConstructionSquare WorldConstructionSquare;'
makeStdVectorPtr'WorldConstructionSquare'

-- world_construction.h

--- TODO
ffi.cdef'typedef struct WorldConstruction WorldConstruction;'
makeStdVectorPtr'WorldConstruction'

-- entity_claim_mask.h

ffi.cdef[[
typedef uint8_t EntityClaimMaskMapRegionMask[16][16];
]]
makeStdVectorPtr'EntityClaimMaskMapRegionMask'

ffi.cdef[[
typedef struct {
	struct {
		vector_int32 entities;
		vector_EntityClaimMaskMapRegionMask_ptr regionMasks;
	} ** map;
	int16_t width;
	int16_t height;
} EntityClaimMask;
]]

-- world_site_unk130.h

--- TODO
ffi.cdef'typedef struct WorldSiteUnknown130 WorldSiteUnknown130;'
makeStdVectorPtr'WorldSiteUnknown130'

-- resource_allotment_data.h

--- TODO
ffi.cdef'typedef struct ResourceAllotmentData ResourceAllotmentData;'
makeStdVectorPtr'ResourceAllotmentData'

-- breed.h

--- TODO
ffi.cdef'typedef struct Breed Breed;'
makeStdVectorPtr'Breed'

-- battlefield.h

--- TODO
ffi.cdef'typedef struct Battlefield Battlefield;'
makeStdVectorPtr'Battlefield'

-- region_weather.h

--- TODO
ffi.cdef'typedef struct RegionWeather RegionWeather;'
makeStdVectorPtr'RegionWeather'

-- world_object_data.h

--- TODO
ffi.cdef'typedef struct WorldObjectData WorldObjectData;'
makeStdVectorPtr'WorldObjectData'

-- world_landmass.h

--- TODO
ffi.cdef'typedef struct WorldLandMass WorldLandMass;'
makeStdVectorPtr'WorldLandMass'

-- world_geo_biome.h

--- TODO
ffi.cdef'typedef struct WorldGeoBiome WorldGeoBiome;'
makeStdVectorPtr'WorldGeoBiome'

-- world_mountain_peak.h

--- TODO
ffi.cdef'typedef struct WorldMountainPeak WorldMountainPeak;'
makeStdVectorPtr'WorldMountainPeak'

-- world_river.h

--- TODO
ffi.cdef'typedef struct WorldRiver WorldRiver;'
makeStdVectorPtr'WorldRiver'

-- region_map_entry.h

--- TODO
ffi.cdef'typedef struct RegionMapEntry RegionMapEntry;'
makeStdVectorPtr'RegionMapEntry'

-- embark_note.h

--- TODO
ffi.cdef'typedef struct EmbarkNote EmbarkNote;'
makeStdVectorPtr'EmbarkNote'

-- feature_init.h

--- TODO
ffi.cdef'typedef struct FeatureInit FeatureInit;'
makeStdVectorPtr'FeatureInit'

-- world_geo_layer.h

--- TODO
ffi.cdef'typedef struct WorldGeoLayer WorldGeoLayer;'

-- entity_raw.h

--- TODO
ffi.cdef'typedef struct EntityRaw EntityRaw;'
makeStdVectorPtr'EntityRaw'

-- abstract_building.h

--- TODO
ffi.cdef'typedef struct AbstractBuilding AbstractBuilding;'
makeStdVectorPtr'AbstractBuilding'

-- flow_reuse_pool.h

ffi.cdef[[
typedef struct {
	int32_t reuseIndex;
	uint32_t active;
} FlowReusePool;
]]

-- material_template.h

--- TODO
ffi.cdef'typedef struct MaterialTemplate MaterialTemplate;'
makeStdVectorPtr'MaterialTemplate'

-- inorganic_raw.h

--- TODO
ffi.cdef'typedef struct InorganicRaw InorganicRaw;'
makeStdVectorPtr'InorganicRaw'

-- plant_raw.h

--- TODO
ffi.cdef'typedef struct PlantRaw PlantRaw;'
makeStdVectorPtr'PlantRaw'

-- tissue_template.h

--- TODO
ffi.cdef'typedef struct TissueTemplate TissueTemplate;'
makeStdVectorPtr'TissueTemplate'

-- body_detail_plan.h

--- TODO
ffi.cdef'typedef struct BodyDetailPlan BodyDetailPlan;'
makeStdVectorPtr'BodyDetailPlan'

-- body_template.h

--- TODO
ffi.cdef'typedef struct BodyTemplate BodyTemplate;'
makeStdVectorPtr'BodyTemplate'

-- creature_variation.h

--- TODO
ffi.cdef'typedef struct CreatureVariation CreatureVariation;'
makeStdVectorPtr'CreatureVariation'

-- creature_graphics_appointment.h

--- TODO
ffi.cdef'typedef struct CreatureGraphicsAppointment CreatureGraphicsAppointment;'
makeStdVectorPtr'CreatureGraphicsAppointment'

-- caste_raw_flags.h

ffi.cdef[[
typedef int32_t CasteRawFlags;
enum {
	CasteRawFlags_CAN_BREATHE_WATER, // 0, 0x0
	CasteRawFlags_CANNOT_BREATHE_AIR, // 1, 0x1
	CasteRawFlags_LOCKPICKER, // 2, 0x2
	/**
	* the flag used internally is actually MISCHIEVIOUS
	*/
	CasteRawFlags_MISCHIEVOUS, // 3, 0x3
	CasteRawFlags_PATTERNFLIER, // 4, 0x4
	CasteRawFlags_CURIOUS_BEAST, // 5, 0x5
	CasteRawFlags_CURIOUS_BEAST_ITEM, // 6, 0x6
	CasteRawFlags_CURIOUS_BEAST_GUZZLER, // 7, 0x7
	CasteRawFlags_FLEEQUICK, // 8, 0x8
	CasteRawFlags_AT_PEACE_WITH_WILDLIFE, // 9, 0x9
	CasteRawFlags_CAN_SWIM, // 10, 0xA
	CasteRawFlags_OPPOSED_TO_LIFE, // 11, 0xB
	CasteRawFlags_CURIOUS_BEAST_EATER, // 12, 0xC
	CasteRawFlags_NO_EAT, // 13, 0xD
	CasteRawFlags_NO_DRINK, // 14, 0xE
	CasteRawFlags_NO_SLEEP, // 15, 0xF
	CasteRawFlags_COMMON_DOMESTIC, // 16, 0x10
	CasteRawFlags_WAGON_PULLER, // 17, 0x11
	CasteRawFlags_PACK_ANIMAL, // 18, 0x12
	CasteRawFlags_FLIER, // 19, 0x13
	CasteRawFlags_LARGE_PREDATOR, // 20, 0x14
	CasteRawFlags_MAGMA_VISION, // 21, 0x15
	CasteRawFlags_FIREIMMUNE, // 22, 0x16
	CasteRawFlags_FIREIMMUNE_SUPER, // 23, 0x17
	CasteRawFlags_WEBBER, // 24, 0x18
	CasteRawFlags_WEBIMMUNE, // 25, 0x19
	CasteRawFlags_FISHITEM, // 26, 0x1A
	CasteRawFlags_IMMOBILE_LAND, // 27, 0x1B
	CasteRawFlags_IMMOLATE, // 28, 0x1C
	CasteRawFlags_MILKABLE, // 29, 0x1D
	CasteRawFlags_NO_SPRING, // 30, 0x1E
	CasteRawFlags_NO_SUMMER, // 31, 0x1F
	CasteRawFlags_NO_AUTUMN, // 32, 0x20
	CasteRawFlags_NO_WINTER, // 33, 0x21
	CasteRawFlags_BENIGN, // 34, 0x22
	CasteRawFlags_VERMIN_NOROAM, // 35, 0x23
	CasteRawFlags_VERMIN_NOTRAP, // 36, 0x24
	CasteRawFlags_VERMIN_NOFISH, // 37, 0x25
	CasteRawFlags_HAS_NERVES, // 38, 0x26
	CasteRawFlags_NO_DIZZINESS, // 39, 0x27
	CasteRawFlags_NO_FEVERS, // 40, 0x28
	CasteRawFlags_NO_UNIT_TYPE_COLOR, // 41, 0x29
	CasteRawFlags_NO_CONNECTIONS_FOR_MOVEMENT, // 42, 0x2A
	CasteRawFlags_SUPERNATURAL, // 43, 0x2B
	CasteRawFlags_AMBUSHPREDATOR, // 44, 0x2C
	CasteRawFlags_GNAWER, // 45, 0x2D
	CasteRawFlags_NOT_BUTCHERABLE, // 46, 0x2E
	CasteRawFlags_COOKABLE_LIVE, // 47, 0x2F
	CasteRawFlags_HAS_SECRETION, // 48, 0x30
	CasteRawFlags_IMMOBILE, // 49, 0x31
	CasteRawFlags_MULTIPART_FULL_VISION, // 50, 0x32
	CasteRawFlags_MEANDERER, // 51, 0x33
	CasteRawFlags_THICKWEB, // 52, 0x34
	CasteRawFlags_TRAINABLE_HUNTING, // 53, 0x35
	CasteRawFlags_PET, // 54, 0x36
	CasteRawFlags_PET_EXOTIC, // 55, 0x37
	CasteRawFlags_HAS_ROTTABLE, // 56, 0x38
	/**
	* aka INTELLIGENT_SPEAKS
	*/
	CasteRawFlags_CAN_SPEAK, // 57, 0x39
	/**
	* aka INTELLIGENT_LEARNS
	*/
	CasteRawFlags_CAN_LEARN, // 58, 0x3A
	CasteRawFlags_UTTERANCES, // 59, 0x3B
	CasteRawFlags_BONECARN, // 60, 0x3C
	CasteRawFlags_CARNIVORE, // 61, 0x3D
	CasteRawFlags_AQUATIC_UNDERSWIM, // 62, 0x3E
	CasteRawFlags_NOEXERT, // 63, 0x3F
	CasteRawFlags_NOPAIN, // 64, 0x40
	CasteRawFlags_EXTRAVISION, // 65, 0x41
	CasteRawFlags_NOBREATHE, // 66, 0x42
	CasteRawFlags_NOSTUN, // 67, 0x43
	CasteRawFlags_NONAUSEA, // 68, 0x44
	CasteRawFlags_HAS_BLOOD, // 69, 0x45
	CasteRawFlags_TRANCES, // 70, 0x46
	CasteRawFlags_NOEMOTION, // 71, 0x47
	CasteRawFlags_SLOW_LEARNER, // 72, 0x48
	CasteRawFlags_NOSTUCKINS, // 73, 0x49
	CasteRawFlags_HAS_PUS, // 74, 0x4A
	CasteRawFlags_NOSKULL, // 75, 0x4B
	CasteRawFlags_NOSKIN, // 76, 0x4C
	CasteRawFlags_NOBONES, // 77, 0x4D
	CasteRawFlags_NOMEAT, // 78, 0x4E
	CasteRawFlags_PARALYZEIMMUNE, // 79, 0x4F
	CasteRawFlags_NOFEAR, // 80, 0x50
	CasteRawFlags_CANOPENDOORS, // 81, 0x51
	/**
	* set if the tag is present; corpse parts go to map_renderer.cursor_other
	*/
	CasteRawFlags_ITEMCORPSE, // 82, 0x52
	CasteRawFlags_GETS_WOUND_INFECTIONS, // 83, 0x53
	CasteRawFlags_NOSMELLYROT, // 84, 0x54
	CasteRawFlags_REMAINS_UNDETERMINED, // 85, 0x55
	CasteRawFlags_HASSHELL, // 86, 0x56
	CasteRawFlags_PEARL, // 87, 0x57
	CasteRawFlags_TRAINABLE_WAR, // 88, 0x58
	CasteRawFlags_NO_THOUGHT_CENTER_FOR_MOVEMENT, // 89, 0x59
	CasteRawFlags_ARENA_RESTRICTED, // 90, 0x5A
	CasteRawFlags_LAIR_HUNTER, // 91, 0x5B
	/**
	* previously LIKES_FIGHTING
	*/
	CasteRawFlags_GELDABLE, // 92, 0x5C
	CasteRawFlags_VERMIN_HATEABLE, // 93, 0x5D
	CasteRawFlags_VEGETATION, // 94, 0x5E
	CasteRawFlags_MAGICAL, // 95, 0x5F
	CasteRawFlags_NATURAL_ANIMAL, // 96, 0x60
	CasteRawFlags_HAS_BABYSTATE, // 97, 0x61
	CasteRawFlags_HAS_CHILDSTATE, // 98, 0x62
	CasteRawFlags_MULTIPLE_LITTER_RARE, // 99, 0x63
	CasteRawFlags_MOUNT, // 100, 0x64
	CasteRawFlags_MOUNT_EXOTIC, // 101, 0x65
	CasteRawFlags_FEATURE_ATTACK_GROUP, // 102, 0x66
	CasteRawFlags_VERMIN_MICRO, // 103, 0x67
	CasteRawFlags_EQUIPS, // 104, 0x68
	CasteRawFlags_LAYS_EGGS, // 105, 0x69
	CasteRawFlags_GRAZER, // 106, 0x6A
	CasteRawFlags_NOTHOUGHT, // 107, 0x6B
	CasteRawFlags_TRAPAVOID, // 108, 0x6C
	CasteRawFlags_CAVE_ADAPT, // 109, 0x6D
	CasteRawFlags_MEGABEAST, // 110, 0x6E
	CasteRawFlags_SEMIMEGABEAST, // 111, 0x6F
	CasteRawFlags_ALL_ACTIVE, // 112, 0x70
	CasteRawFlags_DIURNAL, // 113, 0x71
	CasteRawFlags_NOCTURNAL, // 114, 0x72
	CasteRawFlags_CREPUSCULAR, // 115, 0x73
	CasteRawFlags_MATUTINAL, // 116, 0x74
	CasteRawFlags_VESPERTINE, // 117, 0x75
	CasteRawFlags_LIGHT_GEN, // 118, 0x76
	CasteRawFlags_LISP, // 119, 0x77
	CasteRawFlags_GETS_INFECTIONS_FROM_ROT, // 120, 0x78
	CasteRawFlags_HAS_SOLDIER_TILE, // 121, 0x79
	CasteRawFlags_ALCOHOL_DEPENDENT, // 122, 0x7A
	CasteRawFlags_CAN_SWIM_INNATE, // 123, 0x7B
	CasteRawFlags_POWER, // 124, 0x7C
	CasteRawFlags_TENDONS, // 125, 0x7D
	CasteRawFlags_LIGAMENTS, // 126, 0x7E
	CasteRawFlags_HAS_TILE, // 127, 0x7F
	CasteRawFlags_HAS_COLOR, // 128, 0x80
	CasteRawFlags_HAS_GLOW_TILE, // 129, 0x81
	CasteRawFlags_HAS_GLOW_COLOR, // 130, 0x82
	CasteRawFlags_FEATURE_BEAST, // 131, 0x83
	CasteRawFlags_TITAN, // 132, 0x84
	CasteRawFlags_UNIQUE_DEMON, // 133, 0x85
	CasteRawFlags_DEMON, // 134, 0x86
	CasteRawFlags_MANNERISM_LAUGH, // 135, 0x87
	CasteRawFlags_MANNERISM_SMILE, // 136, 0x88
	CasteRawFlags_MANNERISM_WALK, // 137, 0x89
	CasteRawFlags_MANNERISM_SIT, // 138, 0x8A
	CasteRawFlags_MANNERISM_BREATH, // 139, 0x8B
	CasteRawFlags_MANNERISM_POSTURE, // 140, 0x8C
	CasteRawFlags_MANNERISM_STRETCH, // 141, 0x8D
	CasteRawFlags_MANNERISM_EYELIDS, // 142, 0x8E
	CasteRawFlags_NIGHT_CREATURE, // 143, 0x8F
	CasteRawFlags_NIGHT_CREATURE_HUNTER, // 144, 0x90
	CasteRawFlags_NIGHT_CREATURE_BOGEYMAN, // 145, 0x91
	CasteRawFlags_CONVERTED_SPOUSE, // 146, 0x92
	CasteRawFlags_SPOUSE_CONVERTER, // 147, 0x93
	CasteRawFlags_SPOUSE_CONVERSION_TARGET, // 148, 0x94
	CasteRawFlags_DIE_WHEN_VERMIN_BITE, // 149, 0x95
	CasteRawFlags_REMAINS_ON_VERMIN_BITE_DEATH, // 150, 0x96
	CasteRawFlags_COLONY_EXTERNAL, // 151, 0x97
	CasteRawFlags_LAYS_UNUSUAL_EGGS, // 152, 0x98
	CasteRawFlags_RETURNS_VERMIN_KILLS_TO_OWNER, // 153, 0x99
	CasteRawFlags_HUNTS_VERMIN, // 154, 0x9A
	CasteRawFlags_ADOPTS_OWNER, // 155, 0x9B
	CasteRawFlags_HAS_SOUND_ALERT, // 156, 0x9C
	CasteRawFlags_HAS_SOUND_PEACEFUL_INTERMITTENT, // 157, 0x9D
	CasteRawFlags_NOT_LIVING, // 158, 0x9E
	CasteRawFlags_NO_PHYS_ATT_GAIN, // 159, 0x9F
	CasteRawFlags_NO_PHYS_ATT_RUST, // 160, 0xA0
	CasteRawFlags_CRAZED, // 161, 0xA1
	CasteRawFlags_BLOODSUCKER, // 162, 0xA2
	CasteRawFlags_NO_VEGETATION_PERTURB, // 163, 0xA3
	CasteRawFlags_DIVE_HUNTS_VERMIN, // 164, 0xA4
	CasteRawFlags_VERMIN_GOBBLER, // 165, 0xA5
	CasteRawFlags_CANNOT_JUMP, // 166, 0xA6
	CasteRawFlags_STANCE_CLIMBER, // 167, 0xA7
	CasteRawFlags_CANNOT_CLIMB, // 168, 0xA8
	CasteRawFlags_LOCAL_POPS_CONTROLLABLE, // 169, 0xA9
	CasteRawFlags_OUTSIDER_CONTROLLABLE, // 170, 0xAA
	CasteRawFlags_LOCAL_POPS_PRODUCE_HEROES, // 171, 0xAB
	CasteRawFlags_STRANGE_MOODS, // 172, 0xAC
	CasteRawFlags_HAS_GRASP, // 173, 0xAD
	CasteRawFlags_HAS_FLY_RACE_GAIT, // 174, 0xAE
	CasteRawFlags_HAS_RACE_GAIT, // 175, 0xAF
	CasteRawFlags_NIGHT_CREATURE_NIGHTMARE, // 176, 0xB0
	CasteRawFlags_NIGHT_CREATURE_EXPERIMENTER, // 177, 0xB1
	CasteRawFlags_SPREAD_EVIL_SPHERES_IF_RULER, // 178, 0xB2
};
]]

-- body_appearance_modifier.h

ffi.cdef'typedef struct BodyAppearanceModifier BodyAppearanceModifier;'
makeStdVectorPtr'BodyAppearanceModifier'

-- bp_appearance_modifier.h

ffi.cdef'typedef struct BPAppearanceModifier BPAppearanceModifier;'
makeStdVectorPtr'BPAppearanceModifier'

-- color_modifier_raw.h

ffi.cdef'typedef struct ColorModifierRaw ColorModifierRaw;'
makeStdVectorPtr'ColorModifierRaw'

-- tissue_style_raw.h

ffi.cdef'typedef struct TissueStyleRaw TissueStyleRaw;'
makeStdVectorPtr'TissueStyleRaw'

-- matter_state.h

ffi.cdef[[
typedef int16_t MatterState;
enum {
	MatterState_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	MatterState_Solid, // 0, 0x0
	MatterState_Liquid, // 1, 0x1
	MatterState_Gas, // 2, 0x2
	MatterState_Powder, // 3, 0x3
	MatterState_Paste, // 4, 0x4
	MatterState_Pressed, // 5, 0x5
};
]]

-- caste_raw.h

ffi.cdef[[
typedef struct CasteRaw_ShearableTissueLayer {
	int8_t unk_0;
	int8_t unk_1;
	int32_t length;
	vector_int16 partIndex;
	vector_int16 layerIndex;
	vector_int32 bpModifiersIndex;
} CasteRaw_ShearableTissueLayer;
]]
makeStdVectorPtr'CasteRaw_ShearableTissueLayer'

ffi.cdef[[
typedef struct CasteRaw_Secretion {
	int16_t matType;
	int32_t matIndex;
	MatterState matState;
	std_string matTypeStr;
	std_string matIndexStr;
	std_string unk_44;
	vector_int16 body_partID;
	vector_int16 layerID;
	int32_t cause; /*!< since v0.40.01; 2 EXERTION, 1 EXTREME_EMOTION, 0 always? */
} CasteRaw_Secretion;
]]
makeStdVectorPtr'CasteRaw_Secretion'

ffi.cdef[[
typedef struct CasteRaw_Sound {
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
	std_string caption[3];
} CasteRaw_Sound;
]]
makeStdVectorPtr'CasteRaw_Sound'

ffi.cdef[[
typedef struct {
	std_string unk_1;
	std_string unk_2;
	std_string unk_3;
	int16_t unk_4;
	int32_t unk_5;
	int32_t unk_6;
	int32_t unk_7;
} CasteRaw_Unknown1;
]]
makeStdVectorPtr'CasteRaw_Unknown1'

ffi.cdef[[
typedef struct CasteRaw {
	std_string casteID;
	std_string caste_name[3];
	std_string vermin_bite_txt;
	std_string gnawer_txt;
	std_string baby_name[2];
	std_string child_name[2];
	std_string itemcorpse_str[5];
	std_string remains[2];
	std_string description;
	/**
	 * fingers[2], nose, ear, head, eyes, mouth, hair, knuckles, lips, cheek, nails, f eet, arms, hands, tongue, leg
	 */
	std_string mannerisms[17];
	uint8_t caste_tile;
	uint8_t caste_soldier_tile;
	uint8_t caste_alttile;
	uint8_t caste_soldier_alttile;
	uint8_t caste_glowtile;
	uint16_t homeotherm;
	uint16_t min_temp;
	uint16_t max_temp;
	uint16_t fixed_temp;
	int16_t caste_color[3];
	struct {
		int16_t litter_size_min;
		int16_t litter_size_max;
		int16_t penetratepower;
		int16_t vermin_bite_chance;
		int16_t grasstrample;
		int16_t buildingdestroyer;
		ItemType itemcorpse_itemtype; /*!< no longer used? Changes when the same save is reloaded */
		int16_t itemcorpse_itemsubtype;
		int16_t itemcorpse_materialtype; /*!< no longer used? Changes when the same save is reloaded */
		int16_t itemcorpse_materialindex;
		int16_t itemcorpse_quality;
		int16_t remains_color[3];
		int16_t difficulty;
		int16_t caste_glowcolor[3]; /*!< different from same save with 0.44.12 */
		int16_t beach_frequency;
		int16_t clutch_size_min;
		int16_t clutch_size_max;
		int16_t vision_arc_min;
		int16_t vision_arc_max;
		int32_t speed; /*!< no longer used */
		int32_t modvalue;
		int32_t petvalue;
		int32_t milkable;
		int32_t viewrange;
		int32_t maxage_min;
		int32_t maxage_max;
		int32_t baby_age; /*!< no longer used? Silly large value 7628903 */
		int32_t child_age; /*!< no longer used? Changes when the same save is reloaded */
		int32_t swim_speed; /*!< no longer used */
		int32_t trade_capacity;
		int32_t unk4;
		int32_t pop_ratio;
		int32_t adult_size;
		int32_t bone_mat;
		int32_t bone_matidx;
		int32_t fish_mat_index;
		int32_t egg_mat_index;
		int32_t attack_trigger[3];
		int32_t egg_size;
		int32_t grazer;
		int32_t petvalue_divisor;
		int32_t prone_to_rage;
		int32_t unk6[29]; /*!< different from same save with 0.44.12 */
	} misc;
	struct {
		int16_t a[50];
		int16_t b[50];
		int16_t c[50];
	} personality;
	DFBitArray/*CasteRawFlags*/ flags;
	int32_t index; /*!< global across creatures */
	CasteBodyInfo bodyInfo;
	vector_ptr caste_speech_1;
	vector_ptr caste_speech_2;
	int32_t skill_rates[4][147];
	struct {
		int32_t phys_att_range[6][7];
		int32_t ment_att_range[13][7];
		int32_t phys_att_rates[6][4];
		int32_t ment_att_rates[13][4];
		int32_t phys_att_cap_perc[6];
		int32_t ment_att_cap_perc[13];
	} attributes;
	Gender sex;
	int32_t orientationMale[3]; /*!< since v0.40.01 */
	int32_t orientation_female[3]; /*!< since v0.40.01 */
	vector_int32 body_size_1; /*!< age in ticks */
	vector_int32 body_size_2; /*!< size at the age at the same index in body_size_1 */
	vector_BodyAppearanceModifier_ptr bodyAppearanceModifiers;
	struct {
		vector_BPAppearanceModifier_ptr modifiers;
		vector_int32 modifierIndex;
		vector_int16 partIndex;
		vector_int16 layerIndex;
		vector_int16 style_partIndex;
		vector_int16 style_layerIndex;
		vector_int32 style_listIndex;
	} bp_appearance;
	vector_ColorModifierRaw_ptr colorModifiers;
	vector_TissueStyleRaw_ptr tissueStyles;
	vector_CasteRaw_ShearableTissueLayer_ptr shearableTissueLayer;
	vector_ptr unk16a[4];
	vector_int32 unk16b[4];
	int32_t appearance_gene_count;
	int32_t color_gene_count;
	vector_JobSkill natural_skillID;
	vector_int32 natural_skill_exp;
	vector_SkillRating natural_skill_lvl;
	struct {
		std_string singular[Num_Profession];
		std_string plural[Num_Profession];
	} casteProfessionName;
	struct {
		vector_int16 extractMat;
		vector_int32 extractMatIndex;
		vector_string_ptr extract_str[3];
		int16_t milkable_mat;
		int32_t milkable_matidx;
		std_string milkable_str[3];
		int16_t webber_mat;
		int32_t webber_matidx;
		std_string webber_str[3];
		int16_t vermin_bite_mat;
		int32_t vermin_bite_matidx;
		int16_t vermin_bite_chance;
		std_string vermin_bite_str[3];
		int16_t tendons_mat;
		int32_t tendons_matidx;
		std_string tendons_str[3];
		int32_t tendons_heal;
		int16_t ligaments_mat;
		int32_t ligaments_matidx;
		std_string ligaments_str[3];
		int32_t ligaments_heal;
		int16_t blood_state;
		int16_t blood_mat;
		int32_t blood_matidx;
		std_string blood_str[3];
		int16_t pus_state;
		int16_t pus_mat;
		int32_t pus_matidx;
		std_string pus_str[3];
		vector_int16 egg_material_mattype;
		vector_int32 egg_material_matindex;
		vector_string_ptr egg_material_str[3];
		vector_ItemType lays_unusual_eggs_itemtype;
		vector_int16 lays_unusual_eggs_itemsubtype;
		vector_int16 lays_unusual_eggs_mattype;
		vector_int32 lays_unusual_eggs_matindex;
		vector_string_ptr lays_unusual_eggs_str[5];
	} extracts;
	vector_CasteRaw_Secretion_ptr secretion;
	vector_string_ptr creatureClass;
	struct {
		vector_string_ptr syndrome_dilution_identifier; /*!< since v0.42.01; SYNDROME_DILUTION_FACTOR */
		vector_int32 syndrome_dilution_factor; /*!< since v0.42.01; SYNDROME_DILUTION_FACTOR */
		vector_string_ptr gobble_vermin_class;
		vector_string_ptr gobble_vermin_creature_1;
		vector_string_ptr gobble_vermin_creature_2;
		vector_int32 infect_all; /*!< since v0.34.01; for spatter applied to all bp */
		vector_int32 infect_local; /*!< since v0.34.01; for spatter applied to one bp */
		vector_int32 unk23f; /*!< since v0.34.01 */
		vector_int32 unk23g; /*!< since v0.34.01 */
		DFBitArray/*int*/ unk24_flags;
		DFBitArray/*int*/ unk25_flags;
		int32_t armor_sizes[4][4]; /*!< index by UBSTEP */
		int32_t pants_sizes[4]; /*!< index by LBSTEP */
		int32_t helm_size;
		int32_t shield_sizes[4]; /*!< index by UPSTEP */
		int32_t shoes_sizes[4]; /*!< index by UPSTEP */
		int32_t gloves_sizes[4]; /*!< index by UPSTEP */
		MaterialVecRef materials;
		vector_int16 unk_2f20;
		vector_int8 unk_2f30;
		vector_int32 unk_2f40;
		vector_int16 unk_2f50; /*!< since v0.34.01 */
		int16_t mat_type;
		int32_t mat_index;
	} unknown2;
	int32_t habit_num[2];
	vector_int16 habit_1;
	vector_int32 habit_2;
	vector_int16 lair_1;
	vector_int32 lair_2;
	vector_int16 lair_characteristic_1;
	vector_int32 lair_characteristic_2;
	struct {
		vector_int32 unk_1;
		vector_ptr unk_2;
	} lair_hunter_speech;
	struct {
		vector_ptr unk_1;
		vector_int32 unk_2;
	} unk29;
	vector_ptr specific_food[2];
	vector_CasteRaw_Sound_ptr sound;
	vector_int32 soundAlert;
	vector_int32 soundPeacefulIntermittent;
	vector_CasteRaw_Unknown1_ptr unk_1; /*!< since v0.34.01 */
	int32_t smell_trigger;
	int32_t odor_level;
	std_string odor_string;
	int32_t low_light_vision;
	vector_string_ptr sense_creature_class_1;
	vector_int8 sense_creature_class_2;
	vector_int16 sense_creature_class_3;
	vector_int16 sense_creature_class_4;
	vector_int16 sense_creature_class_5;
} CasteRaw;
]]
assertsizeof('CasteRaw', 9264)
makeStdVectorPtr'CasteRaw'

-- material.h

-- TODO
ffi.cdef'typedef struct Material Material;'
makeStdVectorPtr'Material'

-- tissue.h

-- TODO
ffi.cdef'typedef struct Tissue Tissue;'
makeStdVectorPtr'Tissue'

-- creature_raw.h

--- TODO
ffi.cdef[[
typedef struct CreatureRaw {
	std_string creatureID;
	std_string name[3];
	std_string general_baby_name[2];
	std_string general_child_name[2];
	std_string unk_v43_1; /*!< since v0.43.01 */
	uint8_t creature_tile;
	uint8_t creature_soldier_tile;
	uint8_t alttile;
	uint8_t soldier_alttile;
	uint8_t glowtile;
	uint16_t temperature1;
	uint16_t temperature2;
	int16_t frequency;
	int16_t population_number[2];
	int16_t cluster_number[2];
	int16_t triggerable_group[2];
	int16_t color[3];
	int16_t glowcolor[3];
	int32_t adultsize;
	vector_string_ptr prefstring;
	vector_int16 sphere;
	vector_CasteRaw_ptr caste;
	vector_int32 pop_ratio;
	DFBitArray/*CreatureRawFlags*/ flags;
	struct {
		int32_t texpos[6];
		int32_t texposGs[6];
		int32_t entityLinkTexpos[6][18];
		int32_t entityLinkTexposGs[6][18];
		int32_t siteLinkTexpos[6][10];
		int32_t siteLinkTexposGs[6][10];
		int32_t professionTexpos[6][Num_Profession];
		int32_t professionTexposGs[6][Num_Profession];
		bool add_color[6];
		bool entityLink_add_color[6][18];
		bool siteLink_add_color[6][10];
		bool profession_add_color[6][Num_Profession];
		vector_CreatureGraphicsAppointment_ptr appointments;
	} graphics;
	vector_int8 speech1;
	vector_int32 speech2;
	vector_ptr speech3;
	vector_Material_ptr material;
	vector_Tissue_ptr tissue;
	struct {
		std_string singular[Num_Profession];
		std_string plural[Num_Profession];
	} professionName;
	int32_t undergroundLayer_min;
	int32_t undergroundLayer_max;
	vector_int32 modifier_class;
	vector_int32 modifier_num_patterns; /*!< for color modifiers, == number of items in their pattern_* vectors */
	struct {
		vector_int32 number;
		vector_int32 time;
		vector_ItemType item_type;
		vector_int16 item_subtype;
		MaterialVecRef material;
		vector_string_ptr tmpstr[5];
	} hive_product;
	int32_t source_hfid;
	int32_t unk_v4201_1; /*!< since v0.42.01 */
	int32_t next_modifierID;
	vector_string_ptr raws;
} CreatureRaw;
]]
assertsizeof('CreatureRaw', 11744)
makeStdVectorPtr'CreatureRaw'

-- creature_handler.h

ffi.cdef[[
typedef struct CreatureHandler {
	void * table /* TODO */;
	vector_CreatureRaw_ptr alphabetic;
	vector_CreatureRaw_ptr all;
	int32_t numCaste; /*!< seems equal to length of vectors below */
	vector_int32 listCreature; /*!< Together with list_caste, a list of all caste indexes in order. */
	vector_int32 listCaste;
	vector_string actionStrings; /*!< since v0.40.01 */
} CreatureHandler;
]]

-- itemdef.h

--- TODO
for T in ([[
ItemDef
ItemDef_weaponst
ItemDef_trapcompst
ItemDef_toyst
ItemDef_toolst
ItemDef_instrumentst
ItemDef_armorst
ItemDef_ammost
ItemDef_siegeammost
ItemDef_glovesst
ItemDef_shoesst
ItemDef_shieldst
ItemDef_helmst
ItemDef_pantsst
ItemDef_foodst
]]):gmatch'[%w_]+' do
	ffi.cdef('typedef struct '..T..' '..T..';')
	makeStdVectorPtr(T)
end

-- descriptor_color.h

-- TODO
ffi.cdef'typedef struct DescriptorColor DescriptorColor;'
makeStdVectorPtr'DescriptorColor'

-- descriptor_shape.h

-- TODO
ffi.cdef'typedef struct DescriptorShape DescriptorShape;'
makeStdVectorPtr'DescriptorShape'

-- descriptor_pattern.h

-- TODO
ffi.cdef'typedef struct DescriptorPattern DescriptorPattern;'
makeStdVectorPtr'DescriptorPattern'

-- reaction.h

-- TODO
ffi.cdef'typedef struct Reaction Reaction;'
makeStdVectorPtr'Reaction'

-- reaction_category.h

-- TODO
ffi.cdef'typedef struct ReactionCategory ReactionCategory;'
makeStdVectorPtr'ReactionCategory'

-- building_def.h

-- TODO
ffi.cdef'typedef struct BuildingDef BuildingDef;'
makeStdVectorPtr'BuildingDef'

-- building_def_workshopst.h

-- TODO
ffi.cdef'typedef struct BuildingDefWorkshopst BuildingDefWorkshopst;'
makeStdVectorPtr'BuildingDefWorkshopst'

-- building_def_furnacest.h

-- TODO
ffi.cdef'typedef struct BuildingDefFurnacest BuildingDefFurnacest;'
makeStdVectorPtr'BuildingDefFurnacest'

-- interaction.h

-- TODO
ffi.cdef'typedef struct Interaction Interaction;'
makeStdVectorPtr'Interaction'

-- syndrome.h

-- TODO
ffi.cdef'typedef struct Syndrome Syndrome;'
makeStdVectorPtr'Syndrome'

-- world_raws.h

ffi.cdef[[
typedef struct {
	std_string id;
	std_string old_singular;
	std_string new_singular;
	std_string old_plural;
	std_string new_plural;
} WorldRawsBodyGlosses;
]]
makeStdVectorPtr'WorldRawsBodyGlosses'

ffi.cdef[[
typedef struct WorldRaws {
	vector_MaterialTemplate_ptr materialTemplates;
	vector_InorganicRaw_ptr inorganics;
	vector_InorganicRaw_ptr inorganicsSubset; /*!< all inorganics with value less than 4 */
	struct {
		vector_PlantRaw_ptr all;
		vector_PlantRaw_ptr bushes;
		vector_int32 bushesIndex;
		vector_PlantRaw_ptr trees;
		vector_int32 treesIndex;
		vector_PlantRaw_ptr grasses;
		vector_int32 grassesIndex;
	} plants;
	vector_TissueTemplate_ptr tissueTemplates;
	vector_BodyDetailPlan_ptr bodyDetailPlans;
	vector_BodyTemplate_ptr body_templates;
	vector_WorldRawsBodyGlosses_ptr bodyglosses;
	vector_CreatureVariation_ptr creatureVariations;
	CreatureHandler creatures;
	struct {
		vector_ItemDef_ptr all;
		vector_ItemDef_weaponst_ptr weapons;
		vector_ItemDef_trapcompst_ptr trapcomps;
		vector_ItemDef_toyst_ptr toys;
		vector_ItemDef_toolst_ptr tools;
		vector_ItemDef_toolst_ptr toolsbyType[26];
		vector_ItemDef_instrumentst_ptr instruments;
		vector_ItemDef_armorst_ptr armor;
		vector_ItemDef_ammost_ptr ammo;
		vector_ItemDef_siegeammost_ptr siegeAmmo;
		vector_ItemDef_glovesst_ptr gloves;
		vector_ItemDef_shoesst_ptr shoes;
		vector_ItemDef_shieldst_ptr shields;
		vector_ItemDef_helmst_ptr helms;
		vector_ItemDef_pantsst_ptr pants;
		vector_ItemDef_foodst_ptr food;
	} itemdefs;

	vector_EntityRaw_ptr entities;

	struct {
		vector_LanguageWord_ptr words;
		vector_LanguageSymbol_ptr symbols;
		vector_LanguageTranslation_ptr translations;
		LanguageWordTable wordTable[2][67];
	} language;

	struct {
		vector_DescriptorColor_ptr colors;
		vector_DescriptorShape_ptr shapes;
		vector_DescriptorPattern_ptr patterns;
		vector_int32 unk_1; /*!< since v0.47.01 */
		vector_int32 unk_2; /*!< since v0.47.01 */
		vector_int32 unk_3; /*!< since v0.47.01 */
	} descriptors;

	struct {
		vector_Reaction_ptr reactions;
		vector_ReactionCategory_ptr reactionCategories;
	} reactions;

	struct {
		vector_BuildingDef_ptr all;
		vector_BuildingDefWorkshopst_ptr workshops;
		vector_BuildingDefFurnacest_ptr furnaces;
		int32_t nextID;
	} buildings;

	vector_Interaction_ptr interactions; /*!< since v0.34.01 */

	struct {
		vector_int16 organicTypes[39];
		vector_int32 organicIndexes[39];
		vector_int32 organicUnknown[39]; /*!< everything 0 */
		Material * builtin[659];
	} matTable;

	struct {
		/* first two fields match MaterialVecRef*/
		vector_int16 matTypes;
		vector_int32 matIndexes;
		vector_int32 interactions;
		vector_Syndrome_ptr all; /*!< since v0.34.01 */
	} syndromes;

	struct {
		/* first two fields match MaterialVecRef*/
		/* first three fields matches syndromes*/
		vector_int16 matTypes;
		vector_int32 matIndexes;
		vector_int32 interactions;
		vector_CreatureInteractionEffect_ptr all; /*!< since v0.34.01 */
	} effects;

/*!< since v0.34.01: */
	struct {
		int32_t bookInstruction;
		int32_t bookArt;
		int32_t secretDeath;
	} textObjectCounts;
} WorldRaws;
]]
assertsizeof('WorldRaws', 48752)

-- world_data.h

ffi.cdef[[
typedef int16_t FlipLatitude;
enum {
	FlipLatitude_None = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	FlipLatitude_North, /* 0, 0x0*/
	FlipLatitude_South, /* 1, 0x1*/
	FlipLatitude_Both, /* 2, 0x2*/
};
]]

ffi.cdef[[
typedef struct {
	int32_t unk_0;
	int32_t race;
	int32_t unk_8;
} WorldDataUnknown274Unknown10;
]]
makeStdVectorPtr'WorldDataUnknown274Unknown10'

ffi.cdef[[
typedef struct {
	vector_HistoricalFigure_ptr members;
	vector_WorldDataUnknown274Unknown10_ptr unk_10;
	HistoricalEntity * entity;
	int32_t unk_24;
	LanguageName * unknownRegionName;
	int32_t unk_2c;
	int32_t unk_30;
} WorldDataUnknown274;
]]
makeStdVectorPtr'WorldDataUnknown274'

ffi.cdef[[
typedef struct {
	LanguageName name; /*!< name of the world */
	int8_t unk1[15];
	int32_t next_siteID;
	int32_t next_site_unk130ID;
	int32_t next_resource_allotmentID;
	int32_t next_breedID;
	int32_t next_battlefieldID; /*!< since v0.34.01 */
	int32_t unk_v34_1; /*!< since v0.34.01 */
	int32_t world_width;
	int32_t world_height;
	int32_t unk_78;
	int32_t moon_phase;
	FlipLatitude flipLatitude;
	int16_t flipLongitude;
	int16_t unk_84;
	int16_t unk_86;
	int16_t unk_88;
	int16_t unk_8a;
	int16_t unk_v34_2; /*!< since v0.34.01 */
	int16_t unk_v34_3; /*!< since v0.34.01 */
	struct {
		int32_t world_width2;
		int32_t world_height2;
		uint32_t * unk_1; /*!< align(width,4)*height */
		uint32_t * unk_2; /*!< align(width,4)*height */
		uint32_t * unk_3; /*!< width*height */
		uint8_t * unk_4; /*!< align(width,4)*height */
	} unk_b4;
	vector_WorldRegionDetails_ptr regionDetails;
	int32_t advRegionX;
	int32_t advRegionY;
	int32_t advEmbX;
	int32_t advEmbY;
	int16_t unk_x1;
	int16_t unk_y1;
	int16_t unk_x2;
	int16_t unk_y2;
	struct {
		int16_t width;
		int16_t height;
		vector_WorldConstructionSquare_ptr ** map;
		vector_WorldConstruction_ptr list;
		int32_t nextID;
	} constructions;
	EntityClaimMask entityClaims1;
	EntityClaimMask entityClaims2;
	vector_WorldSite_ptr sites;
	vector_WorldSiteUnknown130_ptr siteUnk130;
	vector_ResourceAllotmentData_ptr resourceAllotments;
	vector_Breed_ptr breeds;
	vector_Battlefield_ptr battlefields; /*!< since v0.34.01 */
	vector_RegionWeather_ptr region_weather; /*!< since v0.34.01 */
	vector_WorldObjectData_ptr object_data; /*!< since v0.34.01 */
	vector_WorldLandMass_ptr landmasses;
	vector_WorldRegion_ptr regions;
	vector_WorldUndergroundRegion_ptr underground_regions;
	vector_WorldGeoBiome_ptr geo_biomes;
	vector_WorldMountainPeak_ptr mountain_peaks;
	vector_WorldRiver_ptr rivers;
	RegionMapEntry** region_map;
	int8_t* unk_1c4;
	char unk_1c8[4];
	vector_EmbarkNote_ptr embark_notes;
	vector_Army_ptr** unk_1dc;
	vector_ptr ** unk_1e0;
	vector_ptr ** unk_1e4;
	vector_ptr ** unk_1e8;
	vector_ptr ** unk_1ec;
	vector_ptr ** unk_1f0;
	int32_t unk_1; /*!< since v0.40.01 */
	void* unk_2; /*!< since v0.40.01 */
	void* unk_3; /*!< since v0.40.01 */
	void* unk_4; /*!< since v0.40.01 */
	void* unk_5; /*!< since v0.40.01 */
	void* unk_6; /*!< since v0.40.01 */
	void* unk_7; /*!< since v0.40.01 */
	void* unk_8; /*!< since v0.40.01 */
	void* unk_9; /*!< since v0.40.01 */
	void* unk_10; /*!< since v0.40.01 */
	void* unk_11; /*!< since v0.40.01 */
	void* unk_12; /*!< since v0.40.01 */
	void* unk_13; /*!< since v0.40.01 */
	void* unk_14; /*!< since v0.40.01 */
	void* unk_15; /*!< since v0.40.01 */
	void* unk_16; /*!< since v0.40.01 */
	char pad_1[294920];
	int8_t unk_17; /*!< since v0.40.01 */
	int8_t unk_18; /*!< since v0.40.01 */
	vector_WorldSite_ptr active_site;
	struct {
		int16_t x;
		int16_t y;
		struct {
			vector_FeatureInit_ptr featureInit[16][16];
			int32_t unk[16][16][30];
		} * features;
		int16_t* unk_8;
		int32_t* unk_c;
	} ** featureMap;
	vector_int32 old_sites;
	vector_int32 old_site_x;
	vector_int32 old_site_y;
	Coord2DPath land_rgns;
	int32_t unk_260;
	int8_t unk_264;
	int32_t unk_268;
	int8_t unk_26c;
	int32_t unk_270;
	vector_WorldDataUnknown274_ptr unk_274;
/*!< since v0.40.01 */
	struct {
		int32_t unk_1[320000];
		int32_t unk_2;
		int32_t unk_3;
		int32_t unk_4;
		int32_t unk_5;
		int32_t unk_6;
		int32_t unk_7;
		int32_t unk_8;
	} unk_482f8;
} WorldData;
]]

-- history_event.h

-- TODO
ffi.cdef'typedef struct HistoryEvent HistoryEvent;'
makeStdVectorPtr'HistoryEvent'

-- relationship_event.h

-- TODO
ffi.cdef'typedef struct RelationshipEvent RelationshipEvent;'
makeStdVectorPtr'RelationshipEvent'

-- relationship_event_supplement.h

-- TODO
ffi.cdef'typedef struct RelationshipEventSupplement RelationshipEventSupplement;'
makeStdVectorPtr'RelationshipEventSupplement'

-- history_event_collection.h

-- TODO
ffi.cdef'typedef struct HistoryEventCollection HistoryEventCollection;'
makeStdVectorPtr'HistoryEventCollection'

-- history_era.h

-- TODO
ffi.cdef'typedef struct HistoryEra HistoryEra;'
makeStdVectorPtr'HistoryEra'

-- intrigue.h

-- TODO
ffi.cdef'typedef struct Intrigue Intrigue;'
makeStdVectorPtr'Intrigue'

-- entity_population.h

-- TODO
ffi.cdef'typedef struct EntityPopulation EntityPopulation;'
makeStdVectorPtr'EntityPopulation'

-- flow_info.h

-- TODO
ffi.cdef'typedef struct FlowInfo FlowInfo;'
makeStdVectorPtr'FlowInfo'

-- interaction_effect.h

-- TODO
ffi.cdef'typedef struct InteractionEffect InteractionEffect;'
makeStdVectorPtr'InteractionEffect'


-- world_history.h

ffi.cdef[[
typedef struct {
	vector_HistoryEvent_ptr events;
	vector_HistoryEvent_ptr deathEvents;
	vector_RelationshipEvent_ptr relationshipEvents; /*!< since v0.47.01 */
	vector_RelationshipEventSupplement_ptr relationshipEventSupplements; /*!< since v0.47.01; supplemental info for artistic/scholar buddies */
	vector_HistoricalFigure_ptr figures;
	struct {
		vector_HistoryEventCollection_ptr all;
		vector_HistoryEventCollection_ptr other[18];
	} event_collections;
	vector_HistoryEra_ptr eras;
	vector_int32 discoveredArtImageID;
	vector_int16 discoveredArtImageSubID;
	int32_t totalUnknown;
	int32_t totalPowers; /*!< also includes megabeasts */
	int32_t totalMegaBeasts;
	int32_t totalSemiMegaBeasts;
	vector_ptr unk_14;
	int16_t unk_v42_1[28]; /*!< since v0.42.01 */
	vector_Intrigue_ptr intrigues; /*!< since v0.47.01 */
	vector_HistoricalFigure_ptr live_megabeasts;
	vector_HistoricalFigure_ptr live_semimegabeasts;
	vector_HistoricalFigure_ptr unk_histfig_3;
	vector_HistoricalFigure_ptr unk_histfig_4;
	vector_HistoricalFigure_ptr unk_histfig_5;
	vector_HistoricalFigure_ptr unk_1; /*!< since v0.47.01 */
	vector_HistoricalFigure_ptr unk_v40_1[15]; /*!< since v0.40.01 */
	vector_HistoricalFigure_ptr unk_histfig_6; /*!< since v0.42.01 */
	vector_HistoricalFigure_ptr unk_histfig_7; /*!< since v0.42.01 */
	vector_HistoricalFigure_ptr unk_histfig_8; /*!< since v0.42.01 */
	vector_HistoricalFigure_ptr unk_histfig_9; /*!< since v0.42.01 */
	vector_HistoricalFigure_ptr unk_histfig_10; /*!< since v0.42.01 */
	vector_HistoricalFigure_ptr unk_histfig_11; /*!< since v0.40.01 */
	vector_HistoricalFigure_ptr unk_histfig_12; /*!< since v0.44.01 */
	vector_HistoricalFigure_ptr unk_histfig_13; /*!< since v0.44.01 */
	vector_HistoricalFigure_ptr unk_3; /*!< since v0.44.01 */
	vector_ptr unk_4; /*!< since v0.47.01 */
	vector_HistoricalFigure_ptr unk_5; /*!< since v0.47.01 */
	vector_ptr unk_6; /*!< since v0.47.01 */
	vector_ptr unk_7; /*!< since v0.47.01 */
	int8_t unk_8;
	vector_HistoryEventCollection_ptr active_event_collections;
	int8_t unk_10;
	int32_t unk_11;
	int32_t unk_12;
	MissionReport * active_mission;
} WorldHistory;
]]

-- worldgen_parms_ps.h

ffi.cdef[[
typedef struct {
	int32_t width;
	int32_t height;
	int16_t ** data[24];
} WorldGenParamsPS;
]]

-- worldgen_parms.h

ffi.cdef[[
typedef struct WorldGenParams {
	std_string title;
	std_string seed; /*!< since v0.34.01 */
	std_string historySeed; /*!< since v0.34.01 */
	std_string nameSeed; /*!< since v0.34.01 */
	std_string creatureSeed; /*!< since v0.34.01 */
	int32_t dimX;
	int32_t dimY;
	std_string customName;
	bool hasSeed;
	bool hasHistorySeed;
	bool hasNameSeed;
	bool hasCreatureSeed;
	int32_t embarkPoints;
	int32_t peakNumberMin;
	int32_t partialOceanEdgeMin;
	int32_t completeOceanEdgeMin;
	int32_t volcanoMin;
	int32_t regionCounts[3][10];
	int32_t riverMins[2];
	int32_t subregionMax;
	int32_t cavernLayerCount;
	int32_t cavernLayerOpennessMin;
	int32_t cavernLayerOpennessMax;
	int32_t cavernLayerPassageDensityMin;
	int32_t cavernLayerPassageDensityMax;
	int32_t cavernLayerWaterMin;
	int32_t cavernLayerWaterMax;
	bool have_bottomLayer_1;
	bool have_bottomLayer_2;
	int32_t levels_above_ground;
	int32_t levels_aboveLayer_1;
	int32_t levels_aboveLayer_2;
	int32_t levels_aboveLayer_3;
	int32_t levels_aboveLayer_4;
	int32_t levels_aboveLayer_5;
	int32_t levels_at_bottom;
	int32_t cave_min_size;
	int32_t cave_max_size;
	int32_t mountain_cave_min;
	int32_t non_mountain_cave_min;
	int32_t total_civ_number;
	int32_t rain_ranges_1;
	int32_t rain_ranges_0;
	int32_t rain_ranges_2;
	int32_t drainage_ranges_1;
	int32_t drainage_ranges_0;
	int32_t drainage_ranges_2;
	int32_t savagery_ranges_1;
	int32_t savagery_ranges_0;
	int32_t savagery_ranges_2;
	int32_t volcanism_ranges_1;
	int32_t volcanism_ranges_0;
	int32_t volcanism_ranges_2;
	int32_t ranges[4][24];
	int32_t beast_end_year;
	int32_t end_year;
	int32_t beast_end_year_percent;
	int32_t total_civ_population;
	int32_t site_cap;
	int32_t elevation_ranges_1;
	int32_t elevation_ranges_0;
	int32_t elevation_ranges_2;
	int32_t mineral_scarcity;
	int32_t megabeast_cap;
	int32_t semimegabeast_cap;
	int32_t titan_number;
	int32_t titan_attack_trigger[3];
	int32_t demon_number;
	int32_t night_troll_number;
	int32_t bogeyman_number;
	int32_t nightmare_number; /*!< since v0.47.01 */
	int32_t vampire_number;
	int32_t werebeast_number;
	int32_t werebeast_attack_trigger[3]; /*!< since v0.47.01 */
	int32_t secret_number;
	int32_t regional_interaction_number;
	int32_t disturbance_interaction_number;
	int32_t evil_cloud_number;
	int32_t evil_rain_number;
	int8_t generate_divine_materials; /*!< since v0.40.01 */
	int8_t allow_divination; /*!< since v0.47.01 */
	int8_t allow_demonic_experiments; /*!< since v0.47.01 */
	int8_t allow_necromancer_experiments; /*!< since v0.47.01 */
	int8_t allow_necromancerLieutenants; /*!< since v0.47.01 */
	int8_t allow_necromancer_ghouls; /*!< since v0.47.01 */
	int8_t allow_necromancer_summons; /*!< since v0.47.01 */
	int32_t good_sq_counts_0;
	int32_t evil_sq_counts_0;
	int32_t good_sq_counts_1;
	int32_t evil_sq_counts_1;
	int32_t good_sq_counts_2;
	int32_t evil_sq_counts_2;
	int32_t elevation_frequency[6];
	int32_t rain_frequency[6];
	int32_t drainage_frequency[6];
	int32_t savagery_frequency[6];
	int32_t temperature_frequency[6];
	int32_t volcanism_frequency[6];
	WorldGenParamsPS * ps;
	int32_t revealAllHistory;
	int32_t cullHistoricalFigures;
	int32_t erosionCycleCount;
	int32_t periodicallyErodeExtremes;
	int32_t orographicPrecipitation;
	int32_t playable_civilization_required;
	int32_t all_caves_visible;
	int32_t show_embark_tunnel;
	int32_t pole;
	bool unk_1;
} WorldGenParams;
]]

-- engraving.h

ffi.cdef'typedef struct Engraving Engraving;'
makeStdVectorPtr'Engraving'

-- campfire.h

ffi.cdef'typedef struct Campfire Campfire;'
makeStdVectorPtr'Campfire'

-- web_cluster.h

ffi.cdef'typedef struct WebCluster WebCluster;'
makeStdVectorPtr'WebCluster'

-- fire.h

ffi.cdef'typedef struct Fire Fire;'
makeStdVectorPtr'Fire'

-- machine_handler.h

ffi.cdef[[
typedef struct MachineHandler {
	void * vtable;
	vector_Machine_ptr all;
	vector_Machine_ptr bad;
} MachineHandler;
]]

-- building_handler.h

for T in ([[
Building_stockpilest
Building_civzonest
Building_actual
Building_boxst
Building_cabinetst
Building_trapst
Building_doorst
Building_floodgatest
Building_hatchst
Building_grate_wallst
Building_grate_floorst
Building_bars_verticalst
Building_bars_floorst
Building_wellst
Building_tablest
Building_bridgest
Building_chairst
Building_tradedepotst
Building_nestst
Building_nest_boxst
Building_bookcasest
Building_display_furniturest
Building_hivest
Building_wagonst
Building_shopst
Building_bedst
Building_traction_benchst
Building_farmplotst
Building_gear_assemblyst
Building_rollersst
Building_axle_horizontalst
Building_axle_verticalst
Building_supportst
Building_archerytargetst
Building_screw_pumpst
Building_water_wheelst
Building_windmillst
Building_chainst
Building_cagest
Building_statuest
Building_slabst
Building_coffinst
Building_weaponrackst
Building_armorstandst
Building_furnacest
Building_workshopst
Building_weaponst
Building_instrumentst
Building_offering_placest
]]):gmatch'[%w_]+' do
	ffi.cdef('typedef struct '..T..' '..T..';')
	makeStdVectorPtr(T)
end

ffi.cdef[[
typedef struct BuildingHandler {
	void * vtable;	/* TODO */
	vector_Building_ptr all;

	struct {
		vector_Building_ptr IN_PLAY;
		vector_Building_ptr LOCATION_ASSIGNED;
		vector_Building_stockpilest_ptr STOCKPILE;
		vector_Building_civzonest_ptr ANY_ZONE;
		vector_Building_civzonest_ptr ACTIVITY_ZONE;
		vector_Building_actual_ptr ANY_ACTUAL;
		vector_Building_ptr ANY_MACHINE;
		vector_Building_ptr ANY_HOSPITAL_STORAGE;
		vector_Building_ptr ANY_STORAGE;
		vector_Building_ptr ANY_BARRACKS;
		vector_Building_ptr ANY_NOBLE_ROOM;
		vector_Building_ptr ANY_HOSPITAL;
		vector_Building_boxst_ptr BOX;
		vector_Building_cabinetst_ptr CABINET;
		vector_Building_trapst_ptr TRAP;
		vector_Building_doorst_ptr DOOR;
		vector_Building_floodgatest_ptr FLOODGATE;
		vector_Building_hatchst_ptr HATCH;
		vector_Building_grate_wallst_ptr GRATE_WALL;
		vector_Building_grate_floorst_ptr GRATE_FLOOR;
		vector_Building_bars_verticalst_ptr BARS_VERTICAL;
		vector_Building_bars_floorst_ptr BARS_FLOOR;
		vector_Building_ptr WINDOW_ANY;
		vector_Building_wellst_ptr WELL;
		vector_Building_tablest_ptr TABLE;
		vector_Building_bridgest_ptr BRIDGE;
		vector_Building_chairst_ptr CHAIR;
		vector_Building_tradedepotst_ptr TRADE_DEPOT;
		vector_Building_nestst_ptr NEST;
		vector_Building_nest_boxst_ptr NEST_BOX;
		vector_Building_bookcasest_ptr BOOKCASE;
		vector_Building_display_furniturest_ptr DISPLAY_CASE; /*!< since v0.44.01 */
		vector_Building_hivest_ptr HIVE;
		vector_Building_wagonst_ptr WAGON;
		vector_Building_shopst_ptr SHOP;
		vector_Building_bedst_ptr BED;
		vector_Building_traction_benchst_ptr TRACTION_BENCH;
		vector_Building_ptr ANY_ROAD;
		vector_Building_farmplotst_ptr FARM_PLOT;
		vector_Building_gear_assemblyst_ptr GEAR_ASSEMBLY;
		vector_Building_rollersst_ptr ROLLERS;
		vector_Building_axle_horizontalst_ptr AXLE_HORIZONTAL;
		vector_Building_axle_verticalst_ptr AXLE_VERTICAL;
		vector_Building_supportst_ptr SUPPORT;
		vector_Building_archerytargetst_ptr ARCHERY_TARGET;
		vector_Building_screw_pumpst_ptr SCREW_PUMP;
		vector_Building_water_wheelst_ptr WATER_WHEEL;
		vector_Building_windmillst_ptr WINDMILL;
		vector_Building_chainst_ptr CHAIN;
		vector_Building_cagest_ptr CAGE;
		vector_Building_statuest_ptr STATUE;
		vector_Building_slabst_ptr SLAB;
		vector_Building_coffinst_ptr COFFIN;
		vector_Building_weaponrackst_ptr WEAPON_RACK;
		vector_Building_armorstandst_ptr ARMOR_STAND;
		vector_Building_furnacest_ptr FURNACE_ANY;
		vector_Building_furnacest_ptr FURNACE_WOOD;
		vector_Building_furnacest_ptr FURNACE_SMELTER_ANY;
		vector_Building_furnacest_ptr FURNACE_SMELTER_MAGMA;
		vector_Building_furnacest_ptr FURNACE_KILN_ANY;
		vector_Building_furnacest_ptr FURNACE_GLASS_ANY;
		vector_Building_furnacest_ptr FURNACE_CUSTOM;
		vector_Building_workshopst_ptr WORKSHOP_ANY;
		vector_Building_workshopst_ptr WORKSHOP_BUTCHER;
		vector_Building_workshopst_ptr WORKSHOP_MASON;
		vector_Building_workshopst_ptr WORKSHOP_KENNEL;
		vector_Building_workshopst_ptr WORKSHOP_FISHERY;
		vector_Building_workshopst_ptr WORKSHOP_JEWELER;
		vector_Building_workshopst_ptr WORKSHOP_LOOM;
		vector_Building_workshopst_ptr WORKSHOP_TANNER;
		vector_Building_workshopst_ptr WORKSHOP_DYER;
		vector_Building_workshopst_ptr WORKSHOP_MILL_ANY;
		vector_Building_workshopst_ptr WORKSHOP_QUERN;
		vector_Building_workshopst_ptr WORKSHOP_TOOL;
		vector_Building_workshopst_ptr WORKSHOP_MILLSTONE;
		vector_Building_workshopst_ptr WORKSHOP_KITCHEN;
		vector_Building_workshopst_ptr WORKSHOP_STILL;
		vector_Building_workshopst_ptr WORKSHOP_FARMER;
		vector_Building_workshopst_ptr WORKSHOP_ASHERY;
		vector_Building_workshopst_ptr WORKSHOP_CARPENTER;
		vector_Building_workshopst_ptr WORKSHOP_CRAFTSDWARF;
		vector_Building_workshopst_ptr WORKSHOP_MECHANIC;
		vector_Building_workshopst_ptr WORKSHOP_SIEGE;
		vector_Building_workshopst_ptr WORKSHOP_CLOTHIER;
		vector_Building_workshopst_ptr WORKSHOP_LEATHER;
		vector_Building_workshopst_ptr WORKSHOP_BOWYER;
		vector_Building_workshopst_ptr WORKSHOP_MAGMA_FORGE;
		vector_Building_workshopst_ptr WORKSHOP_FORGE_ANY;
		vector_Building_workshopst_ptr WORKSHOP_CUSTOM;
		vector_Building_weaponst_ptr WEAPON_UPRIGHT;
		vector_Building_instrumentst_ptr INSTRUMENT_STATIONARY;
		vector_Building_offering_placest_ptr OFFERING_PLACE;
	} other;

	vector_Building_ptr bad;
	bool checkBridgeCollapse;
	bool checkMachineCollapse;
} BuildingHandler;
]]

-- world.h

-- TODO codegen + methods with proper types
-- and not just typedef to void* vector
for T in ([[
GlowingBarrier
DeepVeinHollow
CursedTomb
Vermin
Coord
OceanWaveMaker
OceanWave
Construction
EmbarkFeature
EffectInfo
CoinBatch
LocalPopulation
ManagerOrder
Mandate
HistoricalEntity
Unit
UnitChunk
ArtImageChunk
NemesisRecord
Item
Item_weaponst
Item_armorst
Item_helmst
Item_shoesst
Item_shieldst
Item_glovesst
Item_pantsst
Item_quiverst
Item_splintst
Item_orthopedic_castst
Item_crutchst
Item_backpackst
Item_ammost
Item_woodst
Item_branchst
Item_boulderst
Item_rockst
Item_doorst
Item_floodgatest
Item_hatch_coverst
Item_gratest
Item_cagest
Item_flaskst
Item_windowst
Item_gobletst
Item_instrumentst
Item_toyst
Item_toolst
Item_bucketst
Item_barrelst
Item_chainst
Item_animaltrapst
Item_bedst
Item_traction_benchst
Item_chairst
Item_coffinst
Item_tablest
Item_statuest
Item_slabst
Item_quernst
Item_millstonest
Item_boxst
Item_binst
Item_armorstandst
Item_weaponrackst
Item_cabinetst
Item_anvilst
Item_catapultpartsst
Item_ballistapartsst
Item_siegeammost
Item_trappartsst
Item_threadst
Item_pipe_sectionst
Item_drinkst
ItemLiquid_miscst
Item_powder_miscst
Item_verminst
Item_petst
Item_coinst
Item_globst
Item_trapcompst
Item_barst
Item_smallgemst
Item_blocksst
Item_roughst
Item_body_component
Item_corpsest
Item_bookst
Item_figurinest
Item_amuletst
Item_scepterst
Item_crownst
Item_ringst
Item_earringst
Item_braceletst
Item_gemst
Item_corpsepiecest
Item_remainsst
Item_meatst
Item_fishst
Item_fish_rawst
Item_eggst
Item_seedsst
Item_plantst
Item_skin_tannedst
Item_plant_growthst
Item_clothst
Item_sheetst
Item_totemst
Item_cheesest
Item_foodst
Item_ballistaarrowheadst
ArtifactRecord
]]):gmatch'[%w_]+' do
	ffi.cdef('typedef struct '..T..' '..T..';')
	makeStdVectorPtr(T)
end

ffi.cdef[[
typedef int16_t WorldGenStatusState;
enum {
	WorldGenStatusState_None = -1, /* -1, 0xFFFFFFFFFFFFFFFF*/
	WorldGenStatusState_Initializing, /* 0, 0x0*/
	WorldGenStatusState_PreparingElevation, /* 1, 0x1*/
	WorldGenStatusState_SettingTemperature, /* 2, 0x2*/
	WorldGenStatusState_RunningRivers, /* 3, 0x3*/
	WorldGenStatusState_FormingLakesAndMinerals, /* 4, 0x4*/
	WorldGenStatusState_GrowingVegetation, /* 5, 0x5*/
	WorldGenStatusState_VerifyingTerrain, /* 6, 0x6*/
	WorldGenStatusState_ImportingWildlife, /* 7, 0x7*/
	WorldGenStatusState_RecountingLegends, /* 8, 0x8*/
	WorldGenStatusState_Finalizing, /* 9, 0x9*/
	WorldGenStatusState_Done, /* 10, 0xA*/
};
]]

ffi.cdef[[
typedef struct {
	WorldPopulationRef ref;
	vector_int32 grasses;
} WorldLayerGrasses;
]]
makeStdVectorPtr'WorldLayerGrasses'

ffi.cdef[[
typedef struct {
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
	int32_t unk_5;
	int32_t unk_6;
	int32_t unk_7;
	int32_t unk_8;
	int32_t unk_9;
	int32_t unk_10;
	int32_t unk_11;
	int32_t unk_12;
	int32_t unk_13;
	int32_t unk_14;
	int32_t unk_15;
	int32_t unk_16;
} WorldUnknown131ec0;
]]
makeStdVectorPtr'WorldUnknown131ec0'

ffi.cdef[[
typedef struct {
	std_string name;
	int32_t unknown1;
	int32_t unknown2;
} WorldLanguages;
]]
makeStdVectorPtr'WorldLanguages'

ffi.cdef[[
typedef struct {
	int32_t artifact;
	int32_t unk_1; /*!< only seen 1, and only family heirloom... */
	int32_t year; /*!< matches up with creation or a claim... */
	int32_t year_tick;
	int32_t unk_2; /*!< only seen -1 */
} World_Unknown131ef0_Claims;
]]
makeStdVectorPtr'World_Unknown131ef0_Claims'

ffi.cdef[[
typedef struct {
	int32_t hfid; /*!< confusing. usually the creator, but sometimes completely unrelated or culled */
	vector_World_Unknown131ef0_Claims_ptr claims;
	int32_t unk_hfid; /*!< hfid or completely unrelated hf seen? */
	int32_t unk_1; /*!< only seen 0 */
	int32_t unk_2; /*!< only seen 0 */
} WorldUnknown131ef0 ;
]]
makeStdVectorPtr'WorldUnknown131ef0'

ffi.cdef[[
typedef int32_t WorldLoadStage;
enum {
	WorldLoadStage_LoadingObjectFiles, /* 0, 0x0*/
	WorldLoadStage_SortingMaterialTemplates, /* 1, 0x1*/
	WorldLoadStage_SortingInorganics, /* 2, 0x2*/
	WorldLoadStage_SortingPlants, /* 3, 0x3*/
	WorldLoadStage_SortingTissueTemplates, /* 4, 0x4*/
	WorldLoadStage_SortingItems, /* 5, 0x5*/
	WorldLoadStage_SortingBuildings, /* 6, 0x6*/
	WorldLoadStage_SortingBodyDetailPlans, /* 7, 0x7*/
	WorldLoadStage_SortingCreatureBodies, /* 8, 0x8*/
	WorldLoadStage_SortingCreatureVariations, /* 9, 0x9*/
	WorldLoadStage_SortingCreatures, /* 10, 0xA*/
	WorldLoadStage_SortingEntities, /* 11, 0xB*/
	WorldLoadStage_SortingLanguages, /* 12, 0xC*/
	WorldLoadStage_SortingDescriptions, /* 13, 0xD*/
	WorldLoadStage_SortingReactions, /* 14, 0xE*/
	WorldLoadStage_SortingInteractions, /* 15, 0xF*/
	WorldLoadStage_FinalizingLanguages, /* 16, 0x10*/
	WorldLoadStage_FinalizingDescriptors, /* 17, 0x11*/
	WorldLoadStage_FinalizingMaterialTemplates, /* 18, 0x12*/
	WorldLoadStage_FinalizingInorganics, /* 19, 0x13*/
	WorldLoadStage_FinalizingPlants, /* 20, 0x14*/
	WorldLoadStage_FinalizingTissueTemplates, /* 21, 0x15*/
	WorldLoadStage_FinalizingItems, /* 22, 0x16*/
	WorldLoadStage_FinalizingBuildings, /* 23, 0x17*/
	WorldLoadStage_FinalizingBodyDetailPlans, /* 24, 0x18*/
	WorldLoadStage_FinalizingCreatureVariations, /* 25, 0x19*/
	WorldLoadStage_FinalizingCreatures, /* 26, 0x1A*/
	WorldLoadStage_FinalizingEntities, /* 27, 0x1B*/
	WorldLoadStage_FinalizingReactions, /* 28, 0x1C*/
	WorldLoadStage_FinalizingInteractions, /* 29, 0x1D*/
	WorldLoadStage_PreparingMaterialData, /* 30, 0x1E*/
	WorldLoadStage_GeneratingInorganics, /* 31, 0x1F*/
	WorldLoadStage_GeneratingPlants, /* 32, 0x20*/
	WorldLoadStage_GeneratingItems, /* 33, 0x21*/
	WorldLoadStage_GeneratingCreatures, /* 34, 0x22*/
	WorldLoadStage_GeneratingEntities, /* 35, 0x23*/
	WorldLoadStage_GeneratingReactions, /* 36, 0x24*/
	WorldLoadStage_GeneratingInteractions, /* 37, 0x25*/
	WorldLoadStage_FinalizingGeneratedObjects, /* 38, 0x26*/
	WorldLoadStage_PreparingTextObjects, /* 39, 0x27*/
	WorldLoadStage_PreparingGraphics, /* 40, 0x28*/
	WorldLoadStage_Finishing, /* 41, 0x29*/
};
]]

ffi.cdef[[
typedef int32_t WorldLoadingState;
enum {
	WorldLoadingState_Initializing, /* 0, 0x0*/
	WorldLoadingState_Languages, /* 1, 0x1*/
	WorldLoadingState_Shapes, /* 2, 0x2*/
	WorldLoadingState_Colors, /* 3, 0x3*/
	WorldLoadingState_Patterns, /* 4, 0x4*/
	WorldLoadingState_MaterialTemplates, /* 5, 0x5*/
	WorldLoadingState_Inorganics, /* 6, 0x6*/
	WorldLoadingState_Plants, /* 7, 0x7*/
	WorldLoadingState_TissueTemplates, /* 8, 0x8*/
	WorldLoadingState_Items, /* 9, 0x9*/
	WorldLoadingState_Buildings, /* 10, 0xA*/
	WorldLoadingState_BodyDetailPlans, /* 11, 0xB*/
	WorldLoadingState_CreatureBodies, /* 12, 0xC*/
	WorldLoadingState_CreatureVariations, /* 13, 0xD*/
	WorldLoadingState_Creatures, /* 14, 0xE*/
	WorldLoadingState_Entities, /* 15, 0xF*/
	WorldLoadingState_Reactions, /* 16, 0x10*/
	WorldLoadingState_Interactions, /* 17, 0x11*/
	WorldLoadingState_Finishing, /* 18, 0x12*/
};
]]

-- matches HistoryHitItem but with an extra bool
ffi.cdef[[
typedef struct WorldItemTypes {
	ItemType itemType;
	int16_t itemSubType;
	int16_t matType;
	int32_t matIndex;
	bool unk_1;
} WorldItemTypes;
]]
makeStdVectorPtr'WorldItemTypes'

ffi.cdef[[
typedef struct World_Unknown19325c_Unknown1 {
	void * unk_1;
	int32_t unk_2;
	int16_t unk_3;
	int32_t unk_4;
	int32_t unk_5;
	int32_t unk_6;
} World_Unknown19325c_Unknown1;
]]
makeStdVectorPtr'World_Unknown19325c_Unknown1'

ffi.cdef[[
typedef struct World_Unknown19325c_Unknown2 {
	Item * unk_1;
	int32_t unk_2;
	int32_t unk_3;
} World_Unknown19325c_Unknown2;
]]
makeStdVectorPtr'World_Unknown19325c_Unknown2'

ffi.cdef[[
typedef struct World_Unknown19325c_Unknown3 {
	int16_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
} World_Unknown19325c_Unknown3;
]]
makeStdVectorPtr'World_Unknown19325c_Unknown3'

ffi.cdef[[
typedef struct World {
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
	vector_CoordRect_ptr murkyPools;
	vector_EmbarkFeature_ptr embarkFeatures; /*!< populated at embark */

	struct {
		vector_GlowingBarrier_ptr glowingBarriers;
		vector_DeepVeinHollow_ptr deepVeinHollows;
		vector_CursedTomb_ptr cursedTombs;
		vector_Engraving_ptr engravings;

		vector_Construction_ptr constructions;
		vector_EmbarkFeature_ptr embarkFeatures;
		vector_OceanWaveMaker_ptr oceanWaveMakers;
		vector_CoordRect_ptr murkyPools;
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
		vector_Unit_ptr all;
		vector_Unit_ptr active;

		struct {
			vector_Unit_ptr ANY_RIDER;
			vector_Unit_ptr ANY_BABY2;
		} other;

		vector_Unit_ptr bad;
		vector_ptr unknown;
	} units;
	vector_UnitChunk_ptr unitChunks;
	vector_ArtImageChunk_ptr artImageChunks;

	struct {
		vector_NemesisRecord_ptr all;
		vector_NemesisRecord_ptr other[28];
		vector_NemesisRecord_ptr bad;
		bool unk4;
	} nemesis;

	struct {
		vector_Item_ptr all;

		vector_Item_ptr IN_PLAY;
		vector_Item_ptr ANY_ARTIFACT;
		vector_Item_weaponst_ptr WEAPON;
		vector_Item_ptr ANY_WEAPON;
		vector_Item_ptr ANY_SPIKE;
		vector_Item_armorst_ptr ANY_TRUE_ARMOR;
		vector_Item_helmst_ptr ANY_ARMOR_HELM;
		vector_Item_shoesst_ptr ANY_ARMOR_SHOES;
		vector_Item_shieldst_ptr SHIELD;
		vector_Item_glovesst_ptr ANY_ARMOR_GLOVES;
		vector_Item_pantsst_ptr ANY_ARMOR_PANTS;
		vector_Item_quiverst_ptr QUIVER;
		vector_Item_splintst_ptr SPLINT;
		vector_Item_orthopedic_castst_ptr ORTHOPEDIC_CAST;
		vector_Item_crutchst_ptr CRUTCH;
		vector_Item_backpackst_ptr BACKPACK;
		vector_Item_ammost_ptr AMMO;
		vector_Item_woodst_ptr WOOD;
		vector_Item_branchst_ptr BRANCH;
		vector_Item_boulderst_ptr BOULDER;
		vector_Item_rockst_ptr ROCK;
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
		vector_Item_doorst_ptr DOOR;
		vector_Item_floodgatest_ptr FLOODGATE;
		vector_Item_hatch_coverst_ptr HATCH_COVER;
		vector_Item_gratest_ptr GRATE;
		vector_Item_cagest_ptr CAGE;
		vector_Item_flaskst_ptr FLASK;
		vector_Item_windowst_ptr WINDOW;
		vector_Item_gobletst_ptr GOBLET;
		vector_Item_instrumentst_ptr INSTRUMENT;
		vector_Item_instrumentst_ptr INSTRUMENT_STATIONARY;
		vector_Item_toyst_ptr TOY;
		vector_Item_toolst_ptr TOOL;
		vector_Item_bucketst_ptr BUCKET;
		vector_Item_barrelst_ptr BARREL;
		vector_Item_chainst_ptr CHAIN;
		vector_Item_animaltrapst_ptr ANIMALTRAP;
		vector_Item_bedst_ptr BED;
		vector_Item_traction_benchst_ptr TRACTION_BENCH;
		vector_Item_chairst_ptr CHAIR;
		vector_Item_coffinst_ptr COFFIN;
		vector_Item_tablest_ptr TABLE;
		vector_Item_statuest_ptr STATUE;
		vector_Item_slabst_ptr SLAB;
		vector_Item_quernst_ptr QUERN;
		vector_Item_millstonest_ptr MILLSTONE;
		vector_Item_boxst_ptr BOX;
		vector_Item_binst_ptr BIN;
		vector_Item_armorstandst_ptr ARMORSTAND;
		vector_Item_weaponrackst_ptr WEAPONRACK;
		vector_Item_cabinetst_ptr CABINET;
		vector_Item_anvilst_ptr ANVIL;
		vector_Item_catapultpartsst_ptr CATAPULTPARTS;
		vector_Item_ballistapartsst_ptr BALLISTAPARTS;
		vector_Item_siegeammost_ptr SIEGEAMMO;
		vector_Item_trappartsst_ptr TRAPPARTS;
		vector_Item_threadst_ptr ANY_WEBS;
		vector_Item_pipe_sectionst_ptr PIPE_SECTION;
		vector_Item_ptr ANY_ENCASED;
		vector_Item_ptr ANY_IN_CONSTRUCTION;
		vector_Item_drinkst_ptr DRINK;
		vector_Item_drinkst_ptr ANY_DRINK;
		vector_ItemLiquid_miscst_ptr LIQUID_MISC;
		vector_Item_powder_miscst_ptr POWDER_MISC;
		vector_Item_ptr ANY_COOKABLE;
		vector_Item_ptr ANY_GENERIC84;
		vector_Item_verminst_ptr VERMIN;
		vector_Item_petst_ptr PET;
		vector_Item_ptr ANY_CRITTER;
		vector_Item_coinst_ptr COIN;
		vector_Item_globst_ptr GLOB;
		vector_Item_trapcompst_ptr TRAPCOMP;
		vector_Item_barst_ptr BAR;
		vector_Item_smallgemst_ptr SMALLGEM;
		vector_Item_blocksst_ptr BLOCKS;
		vector_Item_roughst_ptr ROUGH;
		vector_Item_body_component_ptr ANY_CORPSE;
		vector_Item_corpsest_ptr CORPSE;
		vector_Item_bookst_ptr BOOK;
		vector_Item_figurinest_ptr FIGURINE;
		vector_Item_amuletst_ptr AMULET;
		vector_Item_scepterst_ptr SCEPTER;
		vector_Item_crownst_ptr CROWN;
		vector_Item_ringst_ptr RING;
		vector_Item_earringst_ptr EARRING;
		vector_Item_braceletst_ptr BRACELET;
		vector_Item_gemst_ptr GEM;
		vector_Item_corpsepiecest_ptr CORPSEPIECE;
		vector_Item_remainsst_ptr REMAINS;
		vector_Item_meatst_ptr MEAT;
		vector_Item_fishst_ptr FISH;
		vector_Item_fish_rawst_ptr FISH_RAW;
		vector_Item_eggst_ptr EGG;
		vector_Item_seedsst_ptr SEEDS;
		vector_Item_plantst_ptr PLANT;
		vector_Item_skin_tannedst_ptr SKIN_TANNED;
		vector_Item_plant_growthst_ptr PLANT_GROWTH;
		vector_Item_threadst_ptr THREAD;
		vector_Item_clothst_ptr CLOTH;
		vector_Item_sheetst_ptr SHEET;
		vector_Item_totemst_ptr TOTEM;
		vector_Item_pantsst_ptr PANTS;
		vector_Item_cheesest_ptr CHEESE;
		vector_Item_foodst_ptr FOOD;
		vector_Item_ballistaarrowheadst_ptr BALLISTAARROWHEAD;
		vector_Item_armorst_ptr ARMOR;
		vector_Item_shoesst_ptr SHOES;
		vector_Item_helmst_ptr HELM;
		vector_Item_glovesst_ptr GLOVES;
		vector_Item_ptr ANY_GENERIC128;
		vector_Item_ptr FOOD_STORAGE;
		vector_Item_ptr ANY_RECENTLY_DROPPED;
		vector_Item_ptr ANY_MELT_DESIGNATED;

		vector_Item_ptr bad;
		vector_int32 badTag;
	} items;

	struct {
		vector_ArtifactRecord_ptr all, bad;
	} artifacts;

	JobHandler jobs;
	list_Projectile projectileList;
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
		vector_int8 seeds, plants, cheese, meat_fish, eggs, leaves, plant_powder;
		struct {
			int8_t seeds, plants, cheese, fish, meat, leaves, powder, eggs;
		} simple2;
		vector_int8 liquid_plant, liquid_animal, liquid_builtin;
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
		vector_int_ptr all;
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

		struct {
			CombatReportEventType type;
			int32_t item;
			int32_t unk1b;
			int32_t unk1c;
			int32_t unk1d;
			int16_t body_part;
			int16_t unk2b;
			int16_t unk2c;
			int16_t unk2d;
			std_string target_bp_name;
			std_string verb;
			std_string with_item_name;
			std_string unk3d;

			union {
				int32_t flags;
				struct {
					int32_t behind : 1;
					int32_t side : 1;
					int32_t by : 1;
					int32_t item : 1;
					int32_t tap : 1;
					int32_t sever : 1;
				};
			};
		} slots[100];

		int16_t slotIDUsed[38];
		int16_t slotIDIndex1[38];
		int16_t slotIDIndex2[38];
		int16_t slotsUsed;
	} status;

	struct {
		vector_InteractionInstance_ptr all, bad;
	} interctionInstances;

	struct {
		vector_WrittenContent_ptr all, bad;
	} writtenContents;

	struct {
		vector_Identity_ptr all, bad;
	} identities;

	struct {
		vector_Incident_ptr all, bad;
	} incidents;

	struct {
		vector_Crime_ptr all, bad;
	} crimes;

 /*!< since v0.34.08: */
	struct {
		vector_Vehicle_ptr all, active, bad;
	} vehicles;

/*!< since v0.40.01: */
	struct {
		vector_Army_ptr all, bad;
	} armies;

	struct {
		vector_ArmyController_ptr all, bad;
	} armyControllers;

	struct {
		vector_ptr all, bad;
	} armyTrackingInfo;

	struct {
		vector_CulturalIdentity_ptr all, bad;
	} culturalIdentities;

	struct {
		vector_Agreement_ptr all, bad;
	} agreements;

/*!< since v0.42.01: */
	struct {
		vector_PoeticForm_ptr all, bad;
	} poeticForms;

	struct {
		vector_MusicalForm_ptr all, bad;
	} musicalForms;

	struct {
		vector_DanceForm_ptr all, bad;
	} danceForms;

	struct {
		vector_Scale_ptr all, bad;
	} scales;

	struct {
		vector_Rhythm_ptr all, bad;
	} rhythms;

	struct {
		vector_Occupation_ptr all, bad;
	} occupations;

/*!< since v0.44.01: */
	struct {
		vector_BeliefSystem_ptr all, bad;
	} beliefSystems;

 /*!< since v0.47.01: */
	struct {
		vector_ImageSet_ptr all, bad;
	} imageSets;

	struct {
		vector_DivinationSet_ptr all, bad;
	} divinationSets;

/* all versions: */
    Building * selectedBuilding;
    StockpileCategory selectedStockpileType;
    bool updateSelectedBuilding;
    int16_t buildingWidth;
    int16_t buildingHeight;
    ScrewPumpDirection selectedDirection;

	struct {
		vector_MapBlock_ptr mapBlocks;
		MapBlock**** blockIndex;
		vector_MapBlockColumn_ptr mapBlockColumns;
		MapBlockColumn*** columnIndex;
		int32_t xCountBlock;
		int32_t yCountBlock;
		int32_t zCountBlock;
		int32_t xCount;
		int32_t yCount;
		int32_t zCount;
		int32_t regionX;
		int32_t regionY;
		int32_t regionZ;
		int16_t distanceLookup[53][53];
	} map;

/*!< since v0.40.01: */
	struct {
		vector_JobSkill primary[Num_Profession];
		vector_JobSkill secondary[Num_Profession];
	} professionSkills;

	struct {
		struct {
			int32_t cos, sin;
		} approx[40];
		double cos[181];
		double hypot[11][11];
	} math;

	struct {
/* all versions: */
		uint8_t rotation;
/*!< since v0.34.05 */
		ZLevelFlags * zLevelflags;
/*!< since v0.40.01 */
		vector_BlockSquareEventSpoorst_ptr unk_v40_3a;
		vector_int16 unk_v40_3b;
		vector_int16 unk_v40_3c;
		vector_int16 unk_v40_3d;
	} mapExtras;

	WorldData * worldData;

	struct {
		WorldGenStatusState state;
		int32_t numRejects;
		int32_t unk_1[53];
		int32_t unk_2[53];
		int16_t rejectionReason;
		int32_t lakesTotal;
		int32_t unk_3;
		int16_t unk_4;
		int32_t lakesCur;
		int32_t unk_5;
		int32_t unk_6;
		WorldGeoLayer * geoLayers[100];
		int8_t unk_7[100];
		int16_t unk_8[100];
		int32_t unk_9;
		int32_t finalizedCivMats;
		int32_t finalizedArt;
		int32_t finalizedUniforms;
		int32_t finalizedSites;
		int32_t unk_10;
		int32_t unk_11;
		int32_t unk_12;
		vector_HistoricalEntity_ptr entities;
		vector_WorldSite_ptr sites;
		int32_t cursorX;
		int32_t cursorY;
		vector_ptr unk_13;
		vector_ptr unk_14;
		int32_t riversTotal;
		int32_t riversCur;
		int8_t unk_15;
		std_string last_param_set;
		std_string last_seed;
		std_string last_name_seed;
		std_string last_history_seed;
		std_string last_creature_seed;
		bool placeCaves;
		bool placeGoodEvil;
		bool placeMegabeasts;
		bool placeOtherBeasts;
		bool makeCavePops;
		bool makeCaveCivs;
		bool place_civs;
		bool finishedPrehistory;
		vector_WorldSite_ptr sites2;
		vector_WorldSite_ptr sites3;
		int32_t unk_16;
		int8_t unk_17;
		int8_t unk_18;
		int8_t unk_19;
		int8_t unk_20;
		vector_EntityRaw_ptr entityRaws;
		vector_int16 unk_21;
		int32_t civCount;
		int32_t civsLeftToPlace;
		vector_WorldRegion_ptr regions1[10];
		vector_WorldRegion_ptr regions2[10];
		vector_WorldRegion_ptr regions3[10];
		vector_int32 unk_22;
		vector_int32 unk_23;
		vector_int32 unk_24;
		vector_int32 unk_25;
		vector_int32 unk_26;
		vector_int32 unk_27;
		int32_t unk_28;
		int32_t unk_29;
		vector_int16 unk_10d298; /*!< since v0.40.01 */
		vector_int16 unk_10d2a4; /*!< since v0.40.01 */
		vector_AbstractBuilding_ptr libraries; /*!< since v0.42.01 */
		int32_t unk_30; /*!< since v0.42.01 */
		vector_AbstractBuilding_ptr temples; /*!< since v0.44.01 */
		vector_ArtifactRecord_ptr some_artifacts; /*!< since v0.44.01 */
		vector_ptr unk_31; /*!< since v0.47.01 */
		vector_int32 unk_32; /*!< since v0.47.01 */
	} worldgenStatus;

    FlowReusePool orphanedFlowPool;
    WorldRaws raws;

	struct {
		Coord2DPath worldTiles;
		vector_WorldLayerGrasses_ptr layerGrasses;
	} areaGrasses;

	struct {
		int8_t rnd16;
		int16_t rnd256;
		int16_t rndPos;
		int16_t rndX[16];
		int16_t rndY[16];
		int32_t blockIndex;
		vector_int16 unk7a;
		vector_int16 unk7b;
		vector_int16 unk7c;
		vector_int16 unk7_cntdn;
	} flowEngine;

	vector_int32 busyBuildings;
	DFBitArray caveInFlags;

	SaveVersion originalSaveVersion;
	struct {
		std_string version;
		int32_t nextUnitChunkID;
		int16_t nextUnitChunkOffset;
		int32_t nextArtImageChunkID;
		int16_t nextArtImageChunkOffset;
		WorldGenParams worldGenParams;
	} worldGen;
	WorldHistory history;

	vector_EntityPopulation_ptr entityPopulations;

	struct {
		vector_int32 unk1[336]; /*!< since v0.40.01 */
		vector_int32 unk2[336]; /*!< since v0.40.01 */
		vector_int32 unk3[336]; /*!< since v0.40.01 */
		vector_int32 unk4[336]; /*!< since v0.40.01 */
		vector_int32 unk5[336]; /*!< since v0.40.01 */
		vector_int32 unk6[336]; /*!< since v0.40.01 */
	} unk_v40_6; /*!< every value matches a nemesis, but unk2/3 have too few values to draw conclusions. Note that nemesis matches may just be a conincidence of falling within the nemesis range */

	vector_WorldUnknown131ec0_ptr unk_131ec0; /*!< since v0.42.01 */

	vector_WorldLanguages_ptr languages;
	vector_WorldUnknown131ef0_ptr unk_131ef0;

	int32_t unknown_131f08; /*!< since v0.44.01 */
	bool reindexPathfinding; /*!< forces map_block.passable to be recomputed */
	int32_t frameCounter; /*!< increases by 1 every time . is pressed */
	vector_FlowInfo_ptr orphanedFlows; /*!< flows that are not tied to a map_block */

	struct {
		struct {
			int32_t totalCost;
			int32_t localCost;
			int16_t x;
			int16_t y;
			int32_t z;
		} boundary_heap[80000];
		int32_t heap_count;
		Coord pos1;
		Coord pos2;
		int32_t distX;
		int32_t distY;
		int32_t distZ;
		int32_t nextPathCost;
		bool wipePathCost;
		uint16_t nextPathTag;
		bool wipePathTag;
		int16_t nextWalkableID;
		int16_t plantUpdateStep;
		bool unk_1;
	} pathfinder;

	int32_t saveVersion;

	struct {
		std_string saveDir;
		int32_t unknown_v40_0s;
		WorldLoadStage loadStage; /*!< since v0.40.01 */
		int32_t unknown_v40_2s; /*!< since v0.40.01 */
	} curSavegame;

	struct {
		WorldLoadingState state;
		int32_t progress;
		vector_char_ptr objectFiles;
		int32_t objectFileIndex;
	} loading;

	void* unk_v40_7s; /*!< mutated from 0.40.01. Generates 4 bytes of padding before it on 64 bit systems followed by an 8 byte pointer, but only a 4 byte pointer on 32 bit systems */

	struct {
		vector_WorldSite_ptr unk_v47_1; /*!< since v0.47.01 */
		vector_FeatureInit_ptr mapFeatures;
		vector_int16 featureX;
		vector_int16 featureY;
		vector_int16 featureLocalIndex; /*!< same as map_block.local_feature */
		vector_int32 featureGlobalIndex;
		vector_FeatureInit_ptr unk_1; /*!< from unk_9C */
		vector_int16 unk_2; /*!< unk_9C.region.x */
		vector_int16 unk_3; /*!< unk_9C.region.y */
		vector_int16 unk_4; /*!< unk_9C.embark.x */
		vector_int16 unk_5; /*!< unk_9C.embark.y */
		vector_int16 unk_6; /*!< unk_9C.local_feature_idx */
		vector_int32 unk_7; /*!< unk_9C.global_feature_idx */
		vector_int32 unk_8; /*!< unk_9C.unk10 */
		vector_int16 unk_9; /*!< unk_9C.unk14 */
		vector_int16 unk_10; /*!< unk_9C.local.x */
		vector_int16 unk_11; /*!< unk_9C.local.y */
		vector_int16 unk_12; /*!< unk_9C.z_min */
		vector_int16 unk_13; /*!< unk_9C.z_min; yes, seemingly duplicate */
		vector_int16 unk_14; /*!< unk_9C.z_max */
		vector_bool unk_15; /*!< since v0.40.11 */
	} features;
	bool allowAnnouncements; /*!< announcements will not be processed at all if false */
	bool unknown_26a9a9;
	bool unknown_26a9aa; /*!< since v0.42.01 */

	struct {
		vector_int16 race;
		vector_int16 caste;
		int32_t type;
		std_string filter; /*!< since v0.34.08 */
		vector_WorldItemTypes_ptr itemTypes[107]; /*!< true array */
		vector_ptr unk_vec1;
		vector_ptr unk_vec2;
		vector_ptr unk_vec3;
		struct {
			vector_JobSkill skills;
			vector_int32 skillLevels;
			vector_ItemType itemTypes;
			vector_int16 itemSubTypes;
			MaterialVecRef itemMaterials;
			vector_int32 itemCounts;
		} equipment;
		int32_t side;
		int32_t interaction;
		int32_t tame; /*!< since v0.47.01; sets tame-mountable status when the creature creation menu is opened */
		vector_InteractionEffect_ptr interactions; /*!< since v0.34.01 */
		vector_int32 creature_cnt;
		int32_t unk_int1;
	} arenaSpawn;

	struct {
		ConflictLevel conflictLevel;
		bool morale_enable;
		int16_t unk1;
		uint16_t temperature;
		int16_t time;
		int32_t weather_column;
		int32_t weather_row;
		vector_PlantRaw_ptr tree_types;
		int32_t tree_cursor;
		int32_t tree_age;
		std_string tree_filter;
		std_string tree_age_str;
	} arenaSettings;

	int8_t unk_26b5b8;
	int8_t unk_26b5b9;

	struct {
		vector_ptr unk_1;
		vector_ptr unk_2;
		int32_t unk_3;
		struct /*world_unk26c678_unk38*/ {
			vector_ptr unk_1[107];
			vector_int32 unk_2;
			vector_int16 unk_3;
			vector_int16 unk_4;
		} unk_38;
		vector_ptr unk_4;
		vector_ptr unk_5;
		vector_ptr unk_6;
		vector_ptr unk_7;
		vector_ptr unk_8;
		vector_ptr unk_9;
		vector_ptr unk_10;
		vector_ptr unk_11;
	} unk_26c678; /*!< since v0.47.01 */

	struct {
		vector_World_Unknown19325c_Unknown1_ptr unk_1;
		vector_World_Unknown19325c_Unknown2_ptr unk_2;
		vector_World_Unknown19325c_Unknown3_ptr unk_3;
		int32_t unk_4;
		int32_t unk_5;
		int32_t unk_6;
	} unk_19325c;
	int32_t unk_26b618; /*!< since v0.40.01 */
} World;
]]
-- gdb: macro define offsetof(t, f) &((t *) 0)->f
assert.eq(ffi.offsetof('World', 'items'), 0x13ef8)	-- good
assert.eq(ffi.offsetof('World', 'buildings'), 0x1c928)	-- good
assert.eq(ffi.offsetof('World', 'machines'), 0x1d208)	-- good
assert.eq(ffi.offsetof('World', 'flowGuides'), 0x1d240)	-- good
assert.eq(ffi.offsetof('World', 'enemyStatusCache'), 0x1d460)	-- good
assert.eq(ffi.offsetof('World', 'status'), 0x111958)	-- good
assert.eq(ffi.offsetof('World', 'interctionInstances'), 0x113728)	-- good
assert.eq(ffi.offsetof('World', 'writtenContents'), 0x113758)	-- good
assert.eq(ffi.offsetof('World', 'identities'), 0x113788)	-- good
assert.eq(ffi.offsetof('World', 'crimes'), 0x1137e8)	-- good
assert.eq(ffi.offsetof('World', 'armyTrackingInfo'), 0x1138c0)	-- good
assert.eq(ffi.offsetof('World', 'worldgenStatus'), 0x1175e8)	-- good
assert.eq(ffi.offsetof('World', 'pathfinder'), 0x130928)	-- good
assert.eq(ffi.offsetof('World', 'features'), 0x2691a0)	-- good
assert.eq(ffi.cast('size_t', ffi.cast('void*', ffi.cast('World*', 0).features.unk_15)), 0x269380)
assert.eq(ffi.offsetof('World', 'allowAnnouncements'), 0x2693a8)
assert.eq(ffi.offsetof('World', 'unknown_26a9a9'), 0x2693a9)
assert.eq(ffi.offsetof('World', 'unknown_26a9aa'), 0x2693aa)
assert.eq(ffi.offsetof('World', 'arenaSpawn'), 0x2693b0)
assertsizeof('World', 2534184)

-- caravan_state.h

ffi.cdef'typedef struct CaravanState CaravanState;'
makeStdVectorPtr'CaravanState'

-- activity_info.h

makeStdVectorPtr'ActivityInfo'

-- entity_sell_requests.h

ffi.cdef'typedef struct EntitySellRequests EntitySellRequests;'

-- entity_buy_requests.h

ffi.cdef'typedef struct EntityBuyRequests EntityBuyRequests;'

-- dipscript_info.h

ffi.cdef'typedef struct DipScriptInfo DipScriptInfo;'
makeStdVectorPtr'DipScriptInfo'

-- dipscript_popup.h

ffi.cdef'typedef struct DipScriptPopup DipScriptPopup;'
makeStdVectorPtr'DipScriptPopup'

-- active_script_varst.h

ffi.cdef'typedef struct ActiveScriptVarst ActiveScriptVarst;'
makeStdVectorPtr'ActiveScriptVarst'

-- entity_activity_statistics.h

ffi.cdef[[
typedef struct EntityActivityStatistics {
	struct {
		int32_t total;
		int32_t meat;
		int32_t fish;
		int32_t other;
		int32_t seeds;
		int32_t plant;
		int32_t drink;
	} food;
	int16_t unit_counts[152];
	int16_t population;
	int16_t unk_1;
	int16_t unk_2; /*!< in 0.23, omnivores */
	int16_t unk_3; /*!< in 0.23, carnivores */
	int16_t trained_animals;
	int16_t other_animals;
	int16_t unk_4; /*!< in 0.23, potential soldiers */
	int32_t unk_5; /*!< in 0.23, combat aptitude */
	int32_t item_counts[112];
	vector_int32 created_weapons;
	struct {
		int32_t total;
		int32_t weapons;
		int32_t armor;
		int32_t furniture;
		int32_t other;
		int32_t architecture;
		int32_t displayed;
		int32_t held;
		int32_t imported;
		int32_t unk_1;
		int32_t exported;
	} wealth;
	int32_t recent_jobs[7][260];
	int32_t excavated_tiles; /*!< unhidden, subterranean, and excluding map features */
	int32_t death_history[5];
	int32_t insanity_history[5];
	int32_t execution_history[5];
	int32_t noble_death_history[5];
	int32_t total_deaths;
	int32_t total_insanities;
	int32_t total_executions;
	int32_t num_artifacts;
	int32_t unk_6; /*!< in 0.23, total siegers */
	vector_char discovered_creature_foods;
	vector_char discovered_creatures;
	vector_char discovered_plant_foods;
	vector_char discovered_plants; /*!< allows planting of seeds */
	int16_t discovered_water_features;
	int16_t discovered_subterranean_features;
	int16_t discovered_chasm_features; /*!< unused since 40d */
	int16_t discovered_magma_features;
	int16_t discovered_feature_layers; /*!< back in 40d, this counted HFS */
	int32_t migrant_wave_idx; /*!< when >= 2, no migrants */
	vector_int32 found_minerals; /*!< Added after 'you have struck' announcement */
	union {
		uint32_t flags;
		struct {
			uint32_t deep_special : 1;
		};
	} found_misc;
} EntityActivityStatistics;
]]
assertsizeof('EntityActivityStatistics', 8400)

-- meeting_event.h

ffi.cdef'typedef struct MeetingEvent MeetingEvent;'
makeStdVectorPtr'MeetingEvent'

-- meeting_topic.h

ffi.cdef[[
typedef int16_t MeetingTopic;
enum {
	MeetingTopic_DiscussCurrent, // 0, 0x0
	MeetingTopic_RequestPeace, // 1, 0x1
	MeetingTopic_TreeQuota, // 2, 0x2
	MeetingTopic_BecomeLandHolder, // 3, 0x3
	MeetingTopic_PromoteLandHolder, // 4, 0x4
	MeetingTopic_ExportAgreement, // 5, 0x5
	MeetingTopic_ImportAgreement, // 6, 0x6
	MeetingTopic_PleasantPlace, // 7, 0x7
	MeetingTopic_WorldStatus, // 8, 0x8
	MeetingTopic_TributeAgreement, // 9, 0x9
};
typedef vector_int16 vector_MeetingTopic;
]]

-- meeting_diplomat_info.h

ffi.cdef[[
typedef struct MeetingDiplomatInfo {
	int32_t civID;
	int16_t unk1; /*!< maybe is_first_contact */
	int32_t diplomatID;
	int32_t associateID;
	vector_int32/*<enum_field<df::meeting_topic,int32_t>*/ topic_list;
	vector_int32 topic_parms;
	EntitySellRequests * sell_requests;
	EntityBuyRequests* buy_requests;
	DipScriptInfo * dipscript;
	int32_t cur_step;
	vector_ActiveScriptVarst_ptr active_script_vars;
	std_string unk_50;
	std_string unk_6c;
	union {
		uint32_t flags ;
		struct {
			uint32_t dynamic_load : 1; /*!< destroy dipscript_info in destructor */
			uint32_t failure : 1;
			uint32_t success : 1;
		};
	} flags;
	vector_MeetingEvent_ptr events;
	vector_int32 agreement_entity;
	vector_MeetingTopic agreement_topic;
	vector_int32 agreement_year;
	vector_int32 agreement_tick;
	vector_int16 agreement_outcome;
	vector_int32 contact_entity;
	vector_int32 contact_year;
	vector_int32 contact_tick;
} MeetingDiplomatInfo;
]]
makeStdVectorPtr'MeetingDiplomatInfo'

-- invasion_info.h

ffi.cdef'typedef struct InvasionInfo InvasionInfo;'
makeStdVectorPtr'InvasionInfo'

-- punishment.h

ffi.cdef'typedef struct Punishment Punishment;'
makeStdVectorPtr'Punishment'

-- party_info.h

ffi.cdef'typedef struct PartyInfo PartyInfo;'
makeStdVectorPtr'PartyInfo'

-- room_rent_info.h

ffi.cdef'typedef struct RoomRentInfo RoomRentInfo;'
makeStdVectorPtr'RoomRentInfo'

-- kitchen_exc_type.h

ffi.cdef[[
typedef int8_t KitchenExcType;
typedef vector_int8 vector_KitchenExcType;
enum {
	KitchenExcType_Cook = 1, // 1, 0x1
	KitchenExcType_Brew, // 2, 0x2
};
]]

-- entity_material_category.h

ffi.cdef[[
typedef int16_t EntityMaterialCategory;
enum {
	EntityMaterialCategory_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	/**
	* cloth or leather
	*/
	EntityMaterialCategory_Clothing, // 0, 0x0
	/**
	* organic.leather
	*/
	EntityMaterialCategory_Leather, // 1, 0x1
	/**
	* any cloth
	*/
	EntityMaterialCategory_Cloth, // 2, 0x2
	/**
	* organic.wood, used for training weapons
	*/
	EntityMaterialCategory_Wood, // 3, 0x3
	/**
	* misc_mat.crafts
	*/
	EntityMaterialCategory_Crafts, // 4, 0x4
	/**
	* stones
	*/
	EntityMaterialCategory_Stone, // 5, 0x5
	/**
	* misc_mat.crafts
	*/
	EntityMaterialCategory_Improvement, // 6, 0x6
	/**
	* misc_mat.glass_unused, used for extract vials
	*/
	EntityMaterialCategory_Glass, // 7, 0x7
	/**
	* misc_mat.barrels, also used for buckets
	*/
	EntityMaterialCategory_Wood2, // 8, 0x8
	/**
	* cloth/leather
	*/
	EntityMaterialCategory_Bag, // 9, 0x9
	/**
	* misc_mat.cages
	*/
	EntityMaterialCategory_Cage, // 10, 0xA
	/**
	* metal.weapon
	*/
	EntityMaterialCategory_WeaponMelee, // 11, 0xB
	/**
	* metal.ranged
	*/
	EntityMaterialCategory_WeaponRanged, // 12, 0xC
	/**
	* metal.ammo
	*/
	EntityMaterialCategory_Ammo, // 13, 0xD
	/**
	* metal.ammo2
	*/
	EntityMaterialCategory_Ammo2, // 14, 0xE
	/**
	* metal.pick
	*/
	EntityMaterialCategory_Pick, // 15, 0xF
	/**
	* metal.armor, also used for shields, tools, instruments, and toys
	*/
	EntityMaterialCategory_Armor, // 16, 0x10
	/**
	* gems
	*/
	EntityMaterialCategory_Gem, // 17, 0x11
	/**
	* refuse.bone
	*/
	EntityMaterialCategory_Bone, // 18, 0x12
	/**
	* refuse.shell
	*/
	EntityMaterialCategory_Shell, // 19, 0x13
	/**
	* refuse.pearl
	*/
	EntityMaterialCategory_Pearl, // 20, 0x14
	/**
	* refuse.ivory
	*/
	EntityMaterialCategory_Ivory, // 21, 0x15
	/**
	* refuse.horn
	*/
	EntityMaterialCategory_Horn, // 22, 0x16
	/**
	* misc_mat.others
	*/
	EntityMaterialCategory_Other, // 23, 0x17
	/**
	* metal.anvil
	*/
	EntityMaterialCategory_Anvil, // 24, 0x18
	/**
	* misc_mat.booze
	*/
	EntityMaterialCategory_Booze, // 25, 0x19
	/**
	* metals with ITEMS_HARD, used for chains
	*/
	EntityMaterialCategory_Metal, // 26, 0x1A
	/**
	* organic.fiber
	*/
	EntityMaterialCategory_PlantFiber, // 27, 0x1B
	/**
	* organic.silk
	*/
	EntityMaterialCategory_Silk, // 28, 0x1C
	/**
	* organic.wool
	*/
	EntityMaterialCategory_Wool, // 29, 0x1D
	/**
	* misc_mat.rock_metal
	*/
	EntityMaterialCategory_Furniture, // 30, 0x1E
	/**
	* misc_mat.wood2
	*/
	EntityMaterialCategory_MiscWood2, // 31, 0x1F
};
]]

-- item_filter_spec.h

-- matches WorldItemTypes and HistoryHitItem
ffi.cdef[[
typedef struct ItemFilterSpec {
	ItemType itemType;
	int16_t itemSubType;
	EntityMaterialCategory materialClass;
	int16_t matType;
	int32_t matIndex;
} ItemFilterSpec;
]]

-- squad_ammo_spec.h

ffi.cdef[[
typedef struct SquadAmmoSpec {
	ItemFilterSpec item_filter;
	int32_t amount;
	union {
		uint32_t flags;
		struct {
			uint32_t use_combat : 1;
			uint32_t use_training : 1;
		};
	};
	vector_int32 assigned;
} SquadAmmoSpec;
]]
makeStdVectorPtr'SquadAmmoSpec'

-- season.h

ffi.cdef[[
typedef int8_t Season;
typedef vector_int8 vector_Season;
enum {
	Season_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	Season_Spring, // 0, 0x0
	Season_Summer, // 1, 0x1
	Season_Autumn, // 2, 0x2
	Season_Winter, // 3, 0x3
};
]]

-- ghost_type.h

ffi.cdef[[
typedef int16_t GhostType;
enum {
	GhostType_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	GhostType_MurderousGhost, // 0, 0x0
	GhostType_SadisticGhost, // 1, 0x1
	GhostType_SecretivePoltergeist, // 2, 0x2
	GhostType_EnergeticPoltergeist, // 3, 0x3
	GhostType_AngryGhost, // 4, 0x4
	GhostType_ViolentGhost, // 5, 0x5
	GhostType_MoaningSpirit, // 6, 0x6
	GhostType_HowlingSpirit, // 7, 0x7
	GhostType_TroublesomePoltergeist, // 8, 0x8
	GhostType_RestlessHaunt, // 9, 0x9
	GhostType_ForlornHaunt, // 10, 0xA
};
]]

-- stockpile_group_set.h

ffi.cdef[[
typedef struct StockpileGroupSet {
	uint32_t flags;
	struct {
		uint32_t animals : 1;
		uint32_t food : 1;
		uint32_t furniture : 1;
		uint32_t corpses : 1;
		uint32_t refuse : 1;
		uint32_t stone : 1;
		uint32_t ammo : 1;
		uint32_t coins : 1;
		uint32_t bars_blocks : 1;
		uint32_t gems : 1;
		uint32_t finished_goods : 1;
		uint32_t leather : 1;
		uint32_t cloth : 1;
		uint32_t wood : 1;
		uint32_t weapons : 1;
		uint32_t armor : 1;
		uint32_t sheet : 1;
	};
} StockpileGroupSet;
]]

-- stockpile_settings.h

ffi.cdef[[
typedef struct StockpileSettings {
	StockpileGroupSet flags;
	struct {
		bool empty_cages;
		bool empty_traps;
		vector_char enabled;
	} animals;
	struct {
		vector_char meat;
		vector_char fish;
		vector_char unprepared_fish;
		vector_char egg;
		vector_char plants;
		vector_char drink_plant;
		vector_char drink_animal;
		vector_char cheese_plant;
		vector_char cheese_animal;
		vector_char seeds;
		vector_char leaves;
		vector_char powder_plant;
		vector_char powder_creature;
		vector_char glob;
		vector_char glob_paste;
		vector_char glob_pressed;
		vector_char liquid_plant;
		vector_char liquid_animal;
		vector_char liquid_misc;
		bool prepared_meals;
	} food;
	struct {
		vector_char type;
		vector_char other_mats;
		vector_char mats;
		bool quality_core[7];
		bool quality_total[7];
	} furniture;
	int32_t unk1;
	struct {
		vector_char type;
		vector_char corpses;
		vector_char body_parts;
		vector_char skulls;
		vector_char bones;
		vector_char hair;
		vector_char shells;
		vector_char teeth;
		vector_char horns;
		bool fresh_raw_hide;
		bool rotten_raw_hide;
	} refuse;
	struct {
		vector_char mats;
	} stone;
	struct {
		vector_char mats; /*!< unused */
	} ore;
	struct {
		vector_char type;
		vector_char other_mats;
		vector_char mats;
		bool quality_core[7];
		bool quality_total[7];
	} ammo;
	struct {
		vector_char mats;
	} coins;
	struct {
		vector_char bars_other_mats;
		vector_char blocks_other_mats;
		vector_char bars_mats;
		vector_char blocks_mats;
	} bars_blocks;
	struct {
		vector_char rough_other_mats;
		vector_char cut_other_mats;
		vector_char rough_mats;
		vector_char cut_mats;
	} gems;
	struct {
		vector_char type;
		vector_char other_mats;
		vector_char mats;
		bool quality_core[7];
		bool quality_total[7];
	} finished_goods;
	struct {
		vector_char mats;
	} leather;
	struct {
		vector_char thread_silk;
		vector_char thread_plant;
		vector_char thread_yarn;
		vector_char thread_metal;
		vector_char cloth_silk;
		vector_char cloth_plant;
		vector_char cloth_yarn;
		vector_char cloth_metal;
	} cloth;
	struct {
		vector_char mats;
	} wood;
	struct {
		vector_char weapon_type;
		vector_char trapcomp_type;
		vector_char other_mats;
		vector_char mats;
		bool quality_core[7];
		bool quality_total[7];
		bool usable;
		bool unusable;
	} weapons;
	struct {
		vector_char body;
		vector_char head;
		vector_char feet;
		vector_char hands;
		vector_char legs;
		vector_char shield;
		vector_char other_mats;
		vector_char mats;
		bool quality_core[7];
		bool quality_total[7];
		bool usable;
		bool unusable;
	} armor;
	struct {
		vector_char paper;
		vector_char parchment;
	} sheet;
	bool allow_organic;
	bool allow_inorganic;
} StockpileSettings;
]]

-- training_assignment.h

ffi.cdef'typedef struct TrainingAssignment TrainingAssignment;'
makeStdVectorPtr'TrainingAssignment'

-- hauling_route.h

ffi.cdef'typedef struct HaulingRoute HaulingRoute;'
makeStdVectorPtr'HaulingRoute'

-- hauling_stop.h

ffi.cdef'typedef struct HaulingStop HaulingStop;'
makeStdVectorPtr'HaulingStop'

-- stop_depart_condition.h

ffi.cdef'typedef struct StopDepartCondition StopDepartCondition;'
makeStdVectorPtr'StopDepartCondition'

-- route_stockpile_link.h

ffi.cdef'typedef struct RouteStockpileLink RouteStockpileLink;'
makeStdVectorPtr'RouteStockpileLink'

-- ui_hotkey.h

ffi.cdef[[
typedef int16_t UIHotKey_Cmd;
enum {
	UIHotKey_Cmd_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	UIHotKey_Cmd_Zoom, // 0, 0x0
	UIHotKey_Cmd_FollowUnit, // 1, 0x1
	UIHotKey_Cmd_FollowItem, // 2, 0x2
};
]]

ffi.cdef[[
typedef struct UIHotKey {
	std_string name;
	UIHotKey_Cmd cmd;
	int32_t x;
	int32_t y;
	int32_t z;
	union {
		int32_t unitID; /*!< since v0.34.08 */
		int32_t itemID; /*!< since v0.34.08 */
	};
} UIHotKey;
]]

-- ui_sidebar_mode.h

ffi.cdef[[
typedef int16_t UISideBarMode;
enum {
	UISideBarMode_Default, // 0, 0x0
	UISideBarMode_Squads, // 1, 0x1
	UISideBarMode_DesignateMine, // 2, 0x2
	UISideBarMode_DesignateRemoveRamps, // 3, 0x3
	UISideBarMode_DesignateUpStair, // 4, 0x4
	UISideBarMode_DesignateDownStair, // 5, 0x5
	UISideBarMode_DesignateUpDownStair, // 6, 0x6
	UISideBarMode_DesignateUpRamp, // 7, 0x7
	UISideBarMode_DesignateChannel, // 8, 0x8
	UISideBarMode_DesignateGatherPlants, // 9, 0x9
	UISideBarMode_DesignateRemoveDesignation, // 10, 0xA
	UISideBarMode_DesignateSmooth, // 11, 0xB
	UISideBarMode_DesignateCarveTrack, // 12, 0xC
	UISideBarMode_DesignateEngrave, // 13, 0xD
	UISideBarMode_DesignateCarveFortification, // 14, 0xE
	UISideBarMode_Stockpiles, // 15, 0xF
	UISideBarMode_Build, // 16, 0x10
	UISideBarMode_QueryBuilding, // 17, 0x11
	UISideBarMode_Orders, // 18, 0x12
	UISideBarMode_OrdersForbid, // 19, 0x13
	UISideBarMode_OrdersRefuse, // 20, 0x14
	UISideBarMode_OrdersWorkshop, // 21, 0x15
	UISideBarMode_OrdersZone, // 22, 0x16
	UISideBarMode_BuildingItems, // 23, 0x17
	UISideBarMode_ViewUnits, // 24, 0x18
	UISideBarMode_LookAround, // 25, 0x19
	UISideBarMode_DesignateItemsClaim, // 26, 0x1A
	UISideBarMode_DesignateItemsForbid, // 27, 0x1B
	UISideBarMode_DesignateItemsMelt, // 28, 0x1C
	UISideBarMode_DesignateItemsUnmelt, // 29, 0x1D
	UISideBarMode_DesignateItemsDump, // 30, 0x1E
	UISideBarMode_DesignateItemsUndump, // 31, 0x1F
	UISideBarMode_DesignateItemsHide, // 32, 0x20
	UISideBarMode_DesignateItemsUnhide, // 33, 0x21
	UISideBarMode_DesignateChopTrees, // 34, 0x22
	UISideBarMode_DesignateToggleEngravings, // 35, 0x23
	UISideBarMode_DesignateToggleMarker, // 36, 0x24
	UISideBarMode_Hotkeys, // 37, 0x25
	UISideBarMode_DesignateTrafficHigh, // 38, 0x26
	UISideBarMode_DesignateTrafficNormal, // 39, 0x27
	UISideBarMode_DesignateTrafficLow, // 40, 0x28
	UISideBarMode_DesignateTrafficRestricted, // 41, 0x29
	UISideBarMode_Zones, // 42, 0x2A
	UISideBarMode_ZonesPenInfo, // 43, 0x2B
	UISideBarMode_ZonesPitInfo, // 44, 0x2C
	UISideBarMode_ZonesHospitalInfo, // 45, 0x2D
	UISideBarMode_ZonesGatherInfo, // 46, 0x2E
	UISideBarMode_DesignateRemoveConstruction, // 47, 0x2F
	UISideBarMode_DepotAccess, // 48, 0x30
	UISideBarMode_NotesPoints, // 49, 0x31
	UISideBarMode_NotesRoutes, // 50, 0x32
	UISideBarMode_Burrows, // 51, 0x33
	UISideBarMode_Hauling, // 52, 0x34
	UISideBarMode_ArenaWeather, // 53, 0x35
	UISideBarMode_ArenaTrees, // 54, 0x36
	UISideBarMode_BuildingLocationInfo, // 55, 0x37
	UISideBarMode_ZonesLocationInfo, // 56, 0x38
};
]]

-- nemesis_offload.h

ffi.cdef[[
typedef struct NemesisOffload {
	vector_int32 nemesis_save_fileID;
	vector_int16 nemesis_member_idx;
	vector_Unit_ptr units;
	UnitChunk * cur_unit_chunk;
	int32_t cur_unit_chunk_num;
	int32_t units_offloaded;
} NemesisOffload;
]]

-- ui.h
-- TODO is this ... on the UI thread?  because ...

ffi.cdef[[
typedef int16_t UI_Nobles_BookkeeperSettings;
enum {
	UI_Nobles_BookkeeperSettings_nearest_10, // 0, 0x0
	UI_Nobles_BookkeeperSettings_nearest_100, // 1, 0x1
	UI_Nobles_BookkeeperSettings_nearest_1000, // 2, 0x2
	UI_Nobles_BookkeeperSettings_nearest_10000, // 3, 0x3
	UI_Nobles_BookkeeperSettings_all_accurate, // 4, 0x4
};
]]

ffi.cdef[[
typedef struct UI_Waypoints_Points {
	int32_t id;
	uint8_t tile;
	int16_t fg_color;
	int16_t bg_color;
	std_string name;
	std_string comment;
	Coord pos;
} UI_Waypoints_Points;
]]
makeStdVectorPtr'UI_Waypoints_Points'

ffi.cdef[[
typedef struct UI_Waypoints_Routes {
	int32_t id;
	std_string name;
	vector_int32 points;
} UI_Waypoints_Routes;
]]
makeStdVectorPtr'UI_Waypoints_Routes'

ffi.cdef[[
typedef struct UI_Alerts_List {
	int32_t id;
	std_string name;
	vector_int32 burrows;
} UI_Alerts_List;
]]
makeStdVectorPtr'UI_Alerts_List'

ffi.cdef[[
typedef struct UI_Unknown8 {
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3; /*!< refers to historical_figure_info::T_relationships::T_intrigues::T_plots::id */
	int32_t unk_4;
	int32_t unk_5;
	int32_t unk_6;
	int32_t unk_7;
	int32_t unk_8;
	int32_t unk_9;
	Coord unk_10; /*!< guess; only x is initialized */
	int32_t unk_11[16];
	int32_t unk_12[16];
	int32_t unk_13[16];
	int32_t unk_14[16];
	int32_t unk_15[16];
	int32_t unk_16[16];
	int32_t unk_17[16];
	int32_t unk_18[16];
	int32_t unk_19;
	int32_t unk_20;
	int32_t unk_21;
	int32_t unk_22;
	int32_t unk_23;
} UI_Unknown8;
]]
makeStdVectorPtr'UI_Unknown8'

ffi.cdef[[
typedef struct UI_Main_DeadCitizens {
	int32_t unitID;
	int32_t histfigID;
	int32_t death_year;
	int32_t death_time;
	int32_t timer; /*!< +1 per 10 */
	GhostType ghost_type;
} UI_Main_DeadCitizens;
]]
makeStdVectorPtr'UI_Main_DeadCitizens'

ffi.cdef[[
typedef struct UI {
	int16_t game_state; /*!< 2 running, 1 lost to siege, 0 lost */
	int32_t lost_to_siege_civ;
	struct {
		int16_t state;
		int32_t check_timer;
		vector_int32 rooms;
		int32_t reach_room_timer;
		int32_t tc_protect_timer;
		int32_t guard1_reach_tc_timer;
		int32_t guard2_reach_tc_timer;
		int16_t collected;
		int16_t quota;
		Coord collector_pos;
		int16_t guard_pos_x[2];
		int16_t guard_pos_y[2];
		int16_t guard_pos_z[2];
		Unit* collector;
		Unit* guard1;
		Unit* guard2;
		int8_t guard_lack_complained;
	} tax_collection;
	struct {
		int32_t unk_1;
		int32_t manager_cooldown; /*!< 0-1008 */
		int32_t bookkeeper_cooldown; /*!< 0-1008 */
		int32_t bookkeeper_precision;
		UI_Nobles_BookkeeperSettings bookkeeper_settings;
	} nobles;
	vector_CaravanState_ptr caravans;
	int8_t unk_2;
	int16_t fortress_rank;
	int16_t progress_population; /*!< ? */
	int16_t progress_trade; /*!< ? */
	int16_t progress_production; /*!< ? */
	bool king_arrived;
	bool king_hasty;
	bool economy_active;
	bool ignore_labor_shortage;
	bool justice_active;
	uint16_t unk_3;
	uint16_t unk_4;
	int16_t manager_timer;
	struct {
		int32_t desired_architecture;
		int32_t desired_offerings;
	} becoming_capital;
	int16_t units_killed[152];
	vector_int32 currency_value;
	int32_t trees_removed;
	int32_t unk_5;
	int32_t fortress_age; /*!< ?; +1 per 10; used in first 2 migrant waves etc */
	EntityActivityStatistics tasks;
	vector_int32 meeting_requests; /*!< guild complaints and diplomats */
	vector_ActivityInfo_ptr activities;
	vector_MeetingDiplomatInfo_ptr dip_meeting_info;
	vector_int32 aid_requesters;
	bool gameOver;
	struct {
		vector_InvasionInfo_ptr list;
		int32_t nextID;
	} invasions;
	vector_Punishment_ptr punishments;
	vector_PartyInfo_ptr parties;
	vector_RoomRentInfo_ptr room_rent;
	vector_DipScriptInfo_ptr dipscripts;
	vector_DipScriptPopup_ptr dipscript_popups; /*!< cause viewscreen_meetingst to pop up */
	struct {
		vector_ItemType item_types;
		vector_int16 item_subtypes;
		vector_int16 mat_types;
		vector_int32 mat_indices;
		vector_KitchenExcType exc_types;
	} kitchen;
	vector_char economic_stone;
	union {
		uint32_t flags;
		struct {
			uint32_t first_year : 1;
			uint32_t recheck_aid_requests : 1;
			uint32_t force_elections : 1;
		};
	} unk23c8_flags;
	int16_t mood_cooldown;
	int32_t civID;
	int32_t siteID;
	int32_t groupID; /*!< i.e. specifically the fortress dwarves */
	int16_t raceID;
	vector_int32 unk_races; /*!< since v0.42.01 */
	vector_int16 farm_crops;
	vector_Season farm_seasons;
	struct {
		struct {
			vector_int32 general_items;
			vector_int32 weapons;
			vector_int32 armor;
			vector_int32 handwear;
			vector_int32 footwear;
			vector_int32 headwear;
			vector_int32 legwear;
			vector_int32 prepared_food;
			vector_int32 wood;
			vector_int32 thread_cloth;
			vector_int32 paper;
			vector_int32 parchment;
			vector_int32 bone;
			vector_int32 tooth;
			vector_int32 horn;
			vector_int32 pearl;
			vector_int32 shell;
			vector_int32 leather;
			vector_int32 silk;
			vector_int32 yarn;
			vector_int32 inorganic;
			vector_int32 meat;
			vector_int32 fish;
			vector_int32 plants;
			vector_int32 drinks;
			vector_int32 extract_animal;
			vector_int32 extract_plant;
			vector_int32 mill_animal;
			vector_int32 mill_plant;
			vector_int32 cheese_animal;
			vector_int32 cheese_plant;
			vector_int32 pets;
		} priceAdjustment;
		struct {
			vector_Unit_ptr general_items;
			vector_Unit_ptr weapons;
			vector_Unit_ptr armor;
			vector_Unit_ptr handwear;
			vector_Unit_ptr footwear;
			vector_Unit_ptr headwear;
			vector_Unit_ptr legwear;
			vector_Unit_ptr prepared_food;
			vector_Unit_ptr wood;
			vector_Unit_ptr thread_cloth;
			vector_Unit_ptr paper;
			vector_Unit_ptr parchment;
			vector_Unit_ptr bone;
			vector_Unit_ptr tooth;
			vector_Unit_ptr horn;
			vector_Unit_ptr pearl;
			vector_Unit_ptr shell;
			vector_Unit_ptr leather;
			vector_Unit_ptr silk;
			vector_Unit_ptr yarn;
			vector_Unit_ptr inorganic;
			vector_Unit_ptr meat;
			vector_Unit_ptr fish;
			vector_Unit_ptr plants;
			vector_Unit_ptr drinks;
			vector_Unit_ptr extract_animal;
			vector_Unit_ptr extract_plant;
			vector_Unit_ptr mill_animal;
			vector_Unit_ptr mill_plant;
			vector_Unit_ptr cheese_animal;
			vector_Unit_ptr cheese_plant;
			vector_Unit_ptr pets;
		} priceSetter;
	} economyPrices;
	struct {
		int32_t reserved_bins;
		int32_t reserved_barrels;
		StockpileSettings custom_settings;
	} stockpile;
	struct {
		int16_t unk1;
		int16_t unk2;
	} unk2a8c[4][768];
	vector_int16 unk_mapedge_x;
	vector_int16 unk_mapedge_y;
	vector_int16 unk_mapedge_z;
	struct {
		vector_int16 layer_x[5];
		vector_int16 surface_x;
		vector_int16 layer_y[5];
		vector_int16 surface_y;
		vector_int16 layer_z[5];
		vector_int16 surface_z;
	} map_edge;
	vector_int16 feature_x;
	vector_int16 feature_y;
	vector_int16 feature_id_local;
	vector_int32 feature_id_global;
	vector_int32 event_collections;
	vector_int16 stone_mat_types;
	vector_int16 stone_mat_indexes;
	struct {
		vector_UI_Waypoints_Points_ptr points;
		vector_UI_Waypoints_Routes_ptr routes;
		int16_t sym_selector;
		int16_t unk_1;
		int32_t cur_point_index;
		bool in_edit_name_mode;
		bool in_edit_text_mode;
		uint8_t sym_tile;
		int16_t sym_fg_color;
		int16_t sym_bg_color;
		vector_string_ptr unk5c04;
		int32_t next_pointID;
		int32_t next_routeID;
		int32_t sel_route_idx;
		int32_t sel_route_waypt_idx;
		bool in_edit_waypts_mode;
		vector_ptr unk_42_06; /*!< since v0.42.06 */
	} waypoints;
	struct {
		vector_Burrow_ptr list;
		int32_t nextID;
		int32_t sel_index;
		int32_t selID;
		bool in_confirm_delete;
		bool in_add_units_mode;
		vector_Unit_ptr list_units;
		vector_bool sel_units;
		int32_t unit_cursor_pos;
		bool in_define_mode;
		bool brush_erasing;
		Coord rect_start;
		int16_t brush_mode;
		bool in_edit_name_mode;
		int16_t sym_selector;
		int16_t sym_tile;
		int16_t sym_fg_color;
		int16_t sym_bg_color;
	} burrows;
	struct {
		vector_UI_Alerts_List_ptr list;
		int32_t nextID;
		int32_t civ_alert_idx;
	} alerts;
	struct {
		vector_Item_ptr items_unmanifested[112];
		vector_Item_ptr items_unassigned[112];
		vector_Item_ptr items_assigned[112];
		union {
			uint32_t flags;
			struct {
				uint32_t weapon : 1;
				uint32_t armor : 1;
				uint32_t shoes : 1;
				uint32_t shield : 1;
				uint32_t helm : 1;
				uint32_t gloves : 1;
				uint32_t ammo : 1;
				uint32_t pants : 1;
				uint32_t backpack : 1;
				uint32_t quiver : 1;
				uint32_t flask : 1;
				uint32_t anon_1 : 1;
				uint32_t buildings : 1;
			};
		} update;
		vector_int32 work_weapons; /*!< i.e. woodcutter axes, and miner picks */
		vector_int32 work_units;
		vector_SquadAmmoSpec_ptr hunter_ammunition;
		vector_int32 ammo_items;
		vector_int32 ammo_units;
		vector_TrainingAssignment_ptr training_assignments; /*!< since v0.34.06; sorted by animalID */
	} equipment;
	/**
	 * Since v0.34.08
	 */
	struct {
		vector_HaulingRoute_ptr routes;
		int32_t nextID;
		vector_HaulingRoute_ptr view_routes;
		vector_HaulingStop_ptr view_stops;
		vector_int32 view_bad;
		int32_t cursor_top;
		bool in_stop;
		int32_t cursor_stop;
		vector_StopDepartCondition_ptr stop_conditions;
		vector_RouteStockpileLink_ptr stop_links;
		bool in_advanced_cond;
		bool in_assign_vehicle;
		int32_t cursor_vehicle;
		vector_Vehicle_ptr vehicles;
		bool in_name;
		std_string old_name;
	} hauling; /*!< since v0.34.08 */
	vector_int32 petitions; /*!< related to agreements */
	vector_int32 unk_6; /*!< since v0.47.01; observed allocating 4 bytes */
	vector_ptr unk_7; /*!< since v0.44.01 */
	vector_UI_Unknown8_ptr unk_8; /*!< since v0.47.01; related to (job_type)0xf1 */
	vector_int32 infiltrator_histfigs; /*!< since v0.47.01 */
	vector_int32 infiltrator_years; /*!< since v0.47.01 */
	vector_int32 infiltrator_year_ticks; /*!< since v0.47.01 */
	struct {
		UIHotKey hotkeys[16];
		int32_t traffic_cost_high;
		int32_t traffic_cost_normal;
		int32_t traffic_cost_low;
		int32_t traffic_cost_restricted;
		vector_UI_Main_DeadCitizens_ptr dead_citizens; /*!< ? */
		HistoricalEntity* fortress_entity; /*!< entity pointed to by groupID */
		WorldSite* fortress_site;
		UISideBarMode mode;
		int16_t unk1;
		int16_t selected_traffic_cost; /*!< For changing the above costs. */
		bool autosave_request;
		bool autosave_unk; /*!< set to 0 when a_rq set to 1 */
		int32_t unk6df4;
		bool unk_44_12a;
		char pad_1[3]; /*!< workaround for strange IDA 7.0 bug */
		NemesisOffload unk_44_12b;
		bool unk_44_12c; /*!< since v0.44.12 */
		int32_t unk_44_12d; /*!< padding? */
		int16_t selected_hotkey;
		bool in_rename_hotkey;
	} main;
	struct {
		vector_Squad_ptr list; /*!< valid only when ui is displayed */
		vector_ptr unk6e08;
		vector_bool sel_squads;
		vector_int32 indiv_selected;
		bool in_select_indiv;
		int32_t sel_indiv_squad;
		int32_t unk_70;
		int32_t squad_list_scroll;
		int32_t squad_list_firstID;
		Squad* nearest_squad;
		bool in_move_order;
		int32_t point_list_scroll;
		bool in_kill_order;
		vector_Unit_ptr kill_rect_targets;
		int32_t kill_rect_targets_scroll; /*!< also used for the list of targets at cursor */
		bool in_kill_list;
		vector_Unit_ptr kill_targets;
		vector_bool sel_kill_targets;
		int32_t kill_list_scroll;
		bool in_kill_rect;
		Coord rect_start;
	} squads;
	int32_t follow_unit;
	int32_t follow_item;
	vector_int16 selected_farm_crops; /*!< valid for the currently queried farm plot */
	vector_bool available_seeds;
} UI;
]]
assertsizeof('UI', 35744)

-- d_init_nickname.h

ffi.cdef[[
typedef int32_t DInitNickname;
enum {
	DInitNickname_REPLACE_FIRST, // 0, 0x0
	DInitNickname_CENTRALIZE, // 1, 0x1
	DInitNickname_REPLACE_ALL, // 2, 0x2
};
]]

-- d_init_idlers.h

ffi.cdef[[
typedef int16_t DInitIdlers;
enum {
	DInitIdlers_OFF = -1, // -1, 0xFFFFFFFFFFFFFFFF
	DInitIdlers_TOP, // 0, 0x0
	DInitIdlers_BOTTOM, // 1, 0x1
};
]]

-- d_init_tunnel.h

ffi.cdef[[
typedef int16_t DInitTunnel;
enum {
	DInitTunnel_NO, // 0, 0x0
	DInitTunnel_FINDER, // 1, 0x1
	DInitTunnel_ALWAYS, // 2, 0x2
};
]]

-- d_init_z_view.h

ffi.cdef[[
typedef int32_t DInitZView;
enum {
	DInitZView_OFF, // 0, 0x0
	DInitZView_UNHIDDEN, // 1, 0x1
	DInitZView_CREATURE, // 2, 0x2
	DInitZView_ON, // 3, 0x3
};
]]

-- d_init_embark_confirm.h

ffi.cdef[[
typedef int32_t DInitEmbarkConfirm;
enum {
	DInitEmbarkConfirm_ALWAYS, // 0, 0x0
	DInitEmbarkConfirm_IF_POINTS_REMAIN, // 1, 0x1
	DInitEmbarkConfirm_NO, // 2, 0x2
};
]]

-- announcement_flags.h

ffi.cdef[[
typedef union AnnouncementFlags {
	uint32_t flags;
	struct {
		uint32_t DO_MEGA : 1; /*!< BOX */
		uint32_t PAUSE : 1; /*!< P */
		uint32_t RECENTER : 1; /*!< R */
		uint32_t A_DISPLAY : 1; /*!< A_D */
		uint32_t D_DISPLAY : 1; /*!< D_D */
		uint32_t UNIT_COMBAT_REPORT : 1; /*!< UCR */
		uint32_t UNIT_COMBAT_REPORT_ALL_ACTIVE : 1; /*!< UCR_A */
	};
} AnnouncementFlags;
]]

-- announcements.h

ffi.cdef[[
typedef struct Announcements {
	AnnouncementFlags flags[339];
	void * unused;
} Announcements;
]]
assertsizeof('Announcements', 1368)

-- d_init.h

ffi.cdef[[
typedef struct DInit {
	DFBitArray/*DInitFlags1*/ flags1;
	DInitNickname nickname[10];
	uint8_t sky_tile;
	int16_t sky_color[3];
	uint8_t chasm_tile;
	uint8_t pillar_tile;
	uint8_t track_tiles[15]; /*!< since v0.34.08 */
	uint8_t track_tile_invert[15]; /*!< since v0.34.08 */
	uint8_t track_ramp_tiles[15]; /*!< since v0.34.08 */
	uint8_t track_ramp_invert[15]; /*!< since v0.34.08 */
	uint8_t tree_tiles[104]; /*!< since v0.40.01 */
	int16_t chasm_color[3];
	struct {
		int16_t none[3];
		int16_t minor[3];
		int16_t inhibited[3];
		int16_t function_loss[3];
		int16_t broken[3];
		int16_t missing[3];
	} wound_color;
	DInitIdlers idlers;
	DInitTunnel show_embark_tunnel;
	DFBitArray/*DInitFlags2*/ flags2;
	int32_t display_length;
	DInitZView adventurer_z_view;
	int32_t adventurer_z_view_size;
	DFBitArray/*DInitFlags3*/ flags3;
	int32_t population_cap;
	int32_t strict_population_cap;
	int32_t baby_cap_absolute;
	int32_t baby_cap_percent;
	int32_t visitor_cap;
	int32_t specific_seed_cap;
	int32_t fortress_seed_cap;
	int32_t invasion_soldier_cap[3];
	int32_t invasion_monster_cap[3];
	int32_t path_cost[4];
	int16_t embark_rect[2];
	struct {
		int16_t item_decrease;
		int16_t seed_combine;
		int16_t bucket_combine;
		int16_t barrel_combine;
		int16_t bin_combine;
	} store_dist;
	int16_t set_labor_lists[2];
	int32_t graze_coefficient; /*!< since v0.40.13 */
	int32_t temple_value_levels[2]; /*!< since v0.47.01 */
	int32_t priesthood_unit_counts[2]; /*!< since v0.47.01 */
	int32_t guildhall_value_levels[2]; /*!< since v0.47.01 */
	int32_t guild_unit_counts[2]; /*!< since v0.47.01 */
	DFBitArray/*DInitFlags4*/ flags4;
	DInitEmbarkConfirm post_prepare_embark_confirmation;
	Announcements announcements;
} DInit;
]]
assertsizeof('DInit', 1848)

-- global_objects.h

ffi.cdef[[
typedef Rect3D SelectionRect;
]]
