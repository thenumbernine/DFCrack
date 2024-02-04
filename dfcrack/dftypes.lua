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
	union {
		<?=T?> * v;		/* shorthand index access: .v[] */
		<?=T?> * start;
	};
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

	local mt = {}
	mt.__index = mt
	function mt:size()
		return self.finish - self.start
	end
	function mt:capacity()
		return self.endOfStorage - self.start
	end

	-- slow impl
	function mt:__ipairs()
		return coroutine.wrap(function()
			-- TODO validate size every iteration?
			-- or just claim that modifying invalidates iteration...
			for i=0,self:size()-1 do
				coroutine.yield(i, self.v[i])
			end
		end)
	end



	ffi.metatype(name, mt)
end

makeStdVector('void*', 'vector_ptr')
makeStdVector('char*', 'vector_char_ptr')
makeStdVector('uint8_t', 'vector_byte')	-- ubyte?
makeStdVector('int8_t', 'vector_sbyte')
makeStdVector'short'
makeStdVector('unsigned short', 'vector_ushort')
makeStdVector'int'
makeStdVector('unsigned int', 'vector_uint')
makeStdVector('std_string', 'vector_string')

-- TODO WTF WHO USES BOOL VECTOR?!?!?!??!
-- this is guaranteed to be broken.  at best, array size is >>3 the vector size
-- at worse, it's a fully dif struct underneath
makeStdVector('bool', 'vector_bool')

-- 'T' is the ptr base type
local function makeVectorPtr(T, name)
	name = name or 'vector_'..T..'_ptr'
	-- for now just use void*, later I'll add types
	local code = 'typedef vector_ptr vector_'..T..'_ptr;'
	--print(code)
	ffi.cdef(code)
end

makeVectorPtr'int'

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

-- except that its indexes and size are >>3
ffi.cdef[[typedef dfarray_byte dfarray_bit;]]

-- TODO is this the std::list layout?
-- are the items always pointers?
local function makeList(T, name)
	name = name or 'list_'..T
	ffi.cdef(template([[
typedef struct <?=name?> {
	<?=T?> * item;
	struct <?=name?> * prev, * next;
} <?=name?>;
]], {
		T = T,
		name = name,
	}))
end

-- fwd decls:

ffi.cdef'typedef struct Building Building;'
makeVectorPtr'Building'

-- coord.h, coord2d.h

-- dfhack naming
ffi.cdef[[
typedef short3_t Coord;
typedef short2_t Coord2D;
]]

-- used in a few places:
ffi.cdef[[
typedef struct {
	int3_t start, end;
} Rect3D;
]]

-- coord_rect.h aka

ffi.cdef[[
typedef struct {
	Coord2D v1, v2;
	int16_t z;
} Rect2pt5D;
typedef Rect2pt5D CoordRect;
]]
makeVectorPtr'CoordRect'

-- coord2d_path.h

ffi.cdef[[
typedef struct {
	vector_short x;
	vector_short y;
} Coord2DPath;
]]

-- coord_path.h

-- more like a vector-of-coords in SOA format
-- used for generic vector-of-coords, not necessarily as a path
ffi.cdef[[
typedef struct {
	vector_short x;
	vector_short y;
	vector_short z;
} CoordPath;
]]


-- tile_bitmask.h

-- why not uint32_t[8] ?
ffi.cdef[[
typedef struct {
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
typedef struct {
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
		struct {
			void * wrestleUnknown1;
			UnitItemWrestle * wrestleItem;
		} wrestle;
	};
} SpecificRef;
]]
makeVectorPtr'SpecificRef'

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
ffi.cdef'typedef vector_short vector_JobSkill;'

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

-- language_word.h

-- TODO
ffi.cdef'typedef struct LanguageWord LanguageWord;'
makeVectorPtr'LanguageWord'

-- language_symbol.h

-- TODO
ffi.cdef'typedef struct LanguageSymbol LanguageSymbol;'
makeVectorPtr'LanguageSymbol'

-- language_translation.h

-- TODO
ffi.cdef'typedef struct LanguageTranslation LanguageTranslation;'
makeVectorPtr'LanguageTranslation'

-- language_word_table.h

ffi.cdef[[
typedef struct {
	vector_int words[6];
	vector_int parts[6]; /* PartOfSpeech_* */
} LanguageWordTable;
]]

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
ffi.cdef'typedef vector_short vector_ItemType;'

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
typedef struct {
	dfarray_byte appearance;
	dfarray_short colors;
} UnitGenes;
]]

-- cie_add_tag_mask1.h

ffi.cdef[[
typedef union {
	uint32_t flags;
	struct {
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
	struct {
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
	vector_short matType;
	vector_int matIndex;
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
	vector_uint numberedMasks; /*!< 1 bit per instance of a numbered body part */
	vector_uint nonSolidRemaining; /*!< 0-100% */
	vector_BodyLayerStatus layerStatus;
	vector_uint layerWoundArea;
	vector_uint layerCutFraction; /*!< 0-10000 */
	vector_uint layerDentFraction; /*!< 0-10000 */
	vector_uint layerEffectFraction; /*!< 0-1000000000 */
} BodyComponentInfo;
]]

-- unit_wound.h

-- TODO
ffi.cdef'typedef struct UnitWound UnitWound;'
makeVectorPtr'UnitWound'

-- caste_body_info.h

-- TODO
ffi.cdef'typedef struct CasteBodyInfo CasteBodyInfo;'

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
makeVectorPtr'Spatter'

-- unit_action.h

-- TODO
ffi.cdef[[typedef struct UnitAction UnitAction;]]
makeVectorPtr'UnitAction'

-- death_type.h

ffi.cdef[[
typedef int16_t DeathType;
enum {
	DeathType_NONE = -1, // -1, 0xFFFFFFFFFFFFFFFF
	DeathType_OLD_AGE, // 0, 0x0
	DeathType_HUNGER, // 1, 0x1
	DeathType_THIRST, // 2, 0x2
	DeathType_SHOT, // 3, 0x3
	DeathType_BLEED, // 4, 0x4
	DeathType_DROWN, // 5, 0x5
	DeathType_SUFFOCATE, // 6, 0x6
	DeathType_STRUCK_DOWN, // 7, 0x7
	DeathType_SCUTTLE, // 8, 0x8
	DeathType_COLLISION, // 9, 0x9
	DeathType_MAGMA, // 10, 0xA
	DeathType_MAGMA_MIST, // 11, 0xB
	DeathType_DRAGONFIRE, // 12, 0xC
	DeathType_FIRE, // 13, 0xD
	DeathType_SCALD, // 14, 0xE
	DeathType_CAVEIN, // 15, 0xF
	DeathType_DRAWBRIDGE, // 16, 0x10
	DeathType_FALLING_ROCKS, // 17, 0x11
	DeathType_CHASM, // 18, 0x12
	DeathType_CAGE, // 19, 0x13
	DeathType_MURDER, // 20, 0x14
	DeathType_TRAP, // 21, 0x15
	DeathType_VANISH, // 22, 0x16
	DeathType_QUIT, // 23, 0x17
	DeathType_ABANDON, // 24, 0x18
	DeathType_HEAT, // 25, 0x19
	DeathType_COLD, // 26, 0x1A
	DeathType_SPIKE, // 27, 0x1B
	DeathType_ENCASE_LAVA, // 28, 0x1C
	DeathType_ENCASE_MAGMA, // 29, 0x1D
	DeathType_ENCASE_ICE, // 30, 0x1E
	DeathType_BEHEAD, // 31, 0x1F
	DeathType_CRUCIFY, // 32, 0x20
	DeathType_BURY_ALIVE, // 33, 0x21
	DeathType_DROWN_ALT, // 34, 0x22
	DeathType_BURN_ALIVE, // 35, 0x23
	DeathType_FEED_TO_BEASTS, // 36, 0x24
	DeathType_HACK_TO_PIECES, // 37, 0x25
	DeathType_LEAVE_OUT_IN_AIR, // 38, 0x26
	DeathType_BOIL, // 39, 0x27
	DeathType_MELT, // 40, 0x28
	DeathType_CONDENSE, // 41, 0x29
	DeathType_SOLIDIFY, // 42, 0x2A
	DeathType_INFECTION, // 43, 0x2B
	DeathType_MEMORIALIZE, // 44, 0x2C
	DeathType_SCARE, // 45, 0x2D
	DeathType_DARKNESS, // 46, 0x2E
	DeathType_COLLAPSE, // 47, 0x2F
	DeathType_DRAIN_BLOOD, // 48, 0x30
	DeathType_SLAUGHTER, // 49, 0x31
	DeathType_VEHICLE, // 50, 0x32
	DeathType_FALLING_OBJECT, // 51, 0x33
	DeathType_LEAPT_FROM_HEIGHT, // 52, 0x34
	DeathType_DROWN_ALT2, // 53, 0x35
	DeathType_EXECUTION_GENERIC, // 54, 0x36
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
makeVectorPtr'UnitMiscTrait'

-- unit_soul.h

-- TODO
ffi.cdef'typedef struct UnitSoul UnitSoul;'
makeVectorPtr'UnitSoul'

-- unit_demand.h

-- TODO
ffi.cdef'typedef struct UnitDemand UnitDemand;'
makeVectorPtr'UnitDemand'

-- unit_item_wrestle.h

-- TODO
ffi.cdef'typedef struct UnitItemWrestle UnitItemWrestle;'
makeVectorPtr'UnitItemWrestle'

-- unit_complaint.h

-- TODO
ffi.cdef'typedef struct UnitComplaint UnitComplaint;'
makeVectorPtr'UnitComplaint'

-- unit_unk_138.h

-- TODO
ffi.cdef'typedef struct UnitUnknown138 UnitUnknown138;'
makeVectorPtr'UnitUnknown138'

-- unit_request.h

-- TODO
ffi.cdef'typedef struct UnitRequest UnitRequest;'
makeVectorPtr'UnitRequest'

-- unit_coin_debt.h

-- TODO
ffi.cdef'typedef struct UnitCoinDebt UnitCoinDebt;'
makeVectorPtr'UnitCoinDebt'

-- temperaturest.h

-- TODO
ffi.cdef'typedef struct Temperaturest Temperaturest;'
makeVectorPtr'Temperaturest'

-- tile_designation.h

-- TODO
ffi.cdef[[
typedef union {
	uint32_t flags;
	struct {
		uint32_t flow_size : 3; /*!< liquid amount */
		uint32_t pile : 1; /*!< stockpile; Adventure: lit */
		uint32_t/*df::tile_dig_designation*/ dig : 3; /*!< Adventure: line_of_sight, furniture_memory, item_memory */
		uint32_t smooth : 2; /*!< Adventure: creature_memory, original_cave */
		uint32_t hidden : 1;
		uint32_t geolayer_index : 4;
		uint32_t light : 1;
		uint32_t subterranean : 1;
		uint32_t outside : 1;
		uint32_t biome : 4;
		uint32_t/*df::tile_liquid*/ liquid_type : 1;
		uint32_t water_table : 1; /*!< aquifer */
		uint32_t rained : 1;
		uint32_t/*df::tile_traffic*/ traffic : 2;
		uint32_t flow_forbid : 1;
		uint32_t liquid_static : 1;
		uint32_t feature_local : 1;
		uint32_t feature_global : 1;
		uint32_t water_stagnant : 1;
		uint32_t water_salt : 1;
	};
} TileDesignation;
]]

-- unit_syndrome.h

-- TODO
ffi.cdef'typedef struct UnitSyndrome UnitSyndrome;'
makeVectorPtr'UnitSyndrome'

-- unit_health_info.h

-- TODO
ffi.cdef'typedef struct UnitHealthInfo UnitHealthInfo;'

-- unit_item_use.h

-- TODO
ffi.cdef'typedef struct UnitItemUse UnitItemUse;'
makeVectorPtr'UnitItemUse'

-- unit_appearance.h

-- TODO
ffi.cdef'typedef struct UnitAppearance UnitAppearance;'
makeVectorPtr'UnitAppearance'

-- witness_report.h

-- TODO
ffi.cdef'typedef struct WitnessReport WitnessReport;'
makeVectorPtr'WitnessReport'

-- entity_event.h

-- TODO
ffi.cdef'typedef struct EntityEvent EntityEvent;'
makeVectorPtr'EntityEvent'

-- army_controller.h

ffi.cdef'typedef struct ArmyController ArmyController;'
makeVectorPtr'ArmyController'

-- occupation.h

ffi.cdef'typedef struct Occupation Occupation;'
makeVectorPtr'Occupation'



-- unit.h

-- TODO
ffi.cdef[[
typedef struct UnitGhostInfo UnitGhostInfo;
]]
makeVectorPtr'UnitInventoryItem'

ffi.cdef[[
typedef int16_t SoldierMood;
enum {
	SoldierMood_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	SoldierMood_MartialTrance, // 0, 0x0
	SoldierMood_Enraged, // 1, 0x1
	SoldierMood_Tantrum, // 2, 0x2
	SoldierMood_Depressed, // 3, 0x3
	SoldierMood_Oblivious, // 4, 0x4
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
makeVectorPtr'UnitStatusUnknown1' 

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
makeVectorPtr'UnitEnemyUnknownv40Sub3_Unknown7_UnknownSub1'

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
		int16_t weaponBP;
		UnitAttribute physicalAttrs[6];
		BodySizeInfo sizeInfo;
		uint32_t bloodMax;
		uint32_t bloodCount;
		int32_t infectionLevel; /*!< GETS_INFECTIONS_FROM_ROT sets; DISEASE_RESISTANCE reduces; >=300 causes bleeding */
		vector_Spatter_ptr spatters;
	} body;
	
	struct {
		vector_int body_modifiers;
		vector_int bp_modifiers;
		int32_t size_modifier; /*!< product of all H/B/LENGTH body modifiers, in % */
		vector_short tissue_style;
		vector_int tissue_style_civ_id;
		vector_int tissue_style_id;
		vector_int tissue_style_type;
		vector_int tissue_length; /*!< description uses bp_modifiers[style_list_idx[index] ] */
		UnitGenes genes;
		vector_int colors;
	} appearance;
	
	vector_UnitAction_ptr actions;
	int32_t nextActionID;
	
	struct {
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
	
	struct {
		int32_t unk_0; /*!< moved from end of counters in 0.43.05 */
		CIEAddTagMask1 addTags1;
		CIEAddTagMask1 remTags1;
		CIEAddTagMask2 addTags2;
		CIEAddTagMask2 remTags2;
		bool nameVisible; /*!< since v0.34.01 */
		std_string name; /*!< since v0.34.01 */
		std_string namePlural; /*!< since v0.34.01 */
		std_string nameAdjective; /*!< since v0.34.01 */
		uint32_t symAndColor1; /*!< since v0.34.01 */
		uint32_t symAndColor2; /*!< since v0.34.01 */
		uint32_t flashPeriod; /*!< since v0.34.01 */
		uint32_t flashTime2; /*!< since v0.34.01 */
		vector_int body_appearance;
		vector_int bp_appearance; /*!< since v0.34.01; guess! */
		uint32_t speed_add; /*!< since v0.34.01 */
		uint32_t speed_mul_percent; /*!< since v0.34.01 */
		CurseAttrChange * attr_change; /*!< since v0.34.01 */
		uint32_t luck_mul_percent; /*!< since v0.34.01 */
		int32_t unk_98; /*!< since v0.42.01 */
		vector_int interaction_id; /*!< since v0.34.01 */
		vector_int interaction_time; /*!< since v0.34.01 */
		vector_int interaction_delay; /*!< since v0.34.01 */
		int32_t time_on_site; /*!< since v0.34.01 */
		vector_int own_interaction; /*!< since v0.34.01 */
		vector_int own_interaction_delay; /*!< since v0.34.01 */
	} curse;
	
	struct T_counters2 {
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
				vector_short item_subtype;
				MaterialVecRef material;
				vector_int year;
				vector_int yearTime;
			} food;
			struct {
				vector_ItemType item_type;
				vector_short itemSubType;
				MaterialVecRef material;
				vector_int year;
				vector_int yearTime;
			} drink;
		} * eat_history;
		int32_t demandTimeout;
		int32_t mandateTimeout;
		vector_int attackerIDs;
		vector_short attackerCountdown;
		uint8_t faceDirection; /*!< for wagons */
		LanguageName artifact_name;
		vector_UnitSoul_ptr souls;
		UnitSoul * current_soul;
		vector_UnitDemand_ptr demands;
		bool labors[94];
		vector_UnitItemWrestle_ptr wrestle_items;
		vector_int observedTraps;
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
		vector_int unk_7c4;
		vector_int unk_c; /*!< since v0.34.01 */
	} unknown7;
	
	struct {
		vector_UnitSyndrome_ptr active;
		vector_int reinfectionType;
		vector_short reinfectionCount;
	} syndromes;
	
	struct {
		vector_int log[3];
		int32_t last_year[3];
		int32_t last_year_tick[3];
	} reports;
	
	UnitHealthInfo * health;
	vector_UnitItemUse_ptr usedItems; /*!< Contains worn clothes, armor, weapons, arrows fired by archers */
	
	struct {
		vector_int sound_cooldown; /*!< since v0.34.01 */
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
		int32_t army_controller_id; /*!< since v0.40.01 */
		
		/**
		 * Since v0.40.01
		 */
		struct {
			ArmyController * controller; /*!< since v0.40.01 */
			struct {
				vector_int unk_1;
				vector_int unk_2;
				vector_int unk_3;
				vector_int unk_4;
			} * unk_2; /*!< since v0.40.01 */
			vector_int unk_3; /*!< since v0.40.01 */
			vector_int unk_4; /*!< since v0.40.01 */
			vector_int unk_5; /*!< since v0.40.01 */
			struct {
				vector_int unk_0;
				vector_int unk_10;
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
		int32_t combat_side_id;
		dfarray_bit/*CasteRawFlags*/ casteFlags; /*!< since v0.44.06 */
		int32_t enemyStatusSlot;
		int32_t unk_874_cntr;
		vector_byte body_part_878;
		vector_byte body_part_888;
		vector_int body_part_relsize; /*!< with modifiers */
		vector_byte body_part_8a8;
		vector_ushort body_part_base_ins;
		vector_ushort body_part_clothing_ins;
		vector_ushort body_part_8d8;
		vector_int unk_8e8;
		vector_ushort unk_8f8;
	} enemy;
	
	vector_int healing_rate;
	int32_t effective_rate;
	int32_t tendons_heal;
	int32_t ligaments_heal;
	int32_t weight;
	int32_t weight_fraction; /*!< 1e-6 */
	vector_int burrows;
	UnitVisionCone* vision_cone;
	vector_Occupation_ptr occupations; /*!< since v0.42.01 */
	std_string adjective; /*!< from physical descriptions for use in adv */

};
typedef struct Unit Unit;
]]

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
		if self.curse.rem_tags1.OPPOSED_TO_LIFE then
			return false
		end
		if self.curse.add_tags1.bits.OPPOSED_TO_LIFE then
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
	int8_t triggered;	/* vs bool?*/
	vector_int coffinSkeletons;
	int32_t disturbance;
	vector_int treasures;
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
makeVectorPtr'Job'

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
makeVectorPtr'JobHandlerPosting'

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
makeVectorPtr'BuildingJobClaimSuppress'

ffi.cdef[[
typedef struct {
	int32_t activityID;
	int32_t eventid;
} BuildingActivity;
]]
makeVectorPtr'BuildingActivity'

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
makeVectorPtr'Building'

-- projectile.h

-- TOOD
ffi.cdef'typedef struct Projectile Projectile;'

-- proj_list_link.h

makeList'Projectile'

-- machine.h

-- TODO
ffi.cdef'typedef struct Machine Machine;'
makeVectorPtr'Machine'

-- flow_guide.h

-- TODO
ffi.cdef'typedef struct FlowGuide FlowGuide;'
makeVectorPtr'FlowGuide'

-- plant.h

-- TODO
ffi.cdef'typedef struct Plant Plant;'
makeVectorPtr'Plant'

-- schedule_info.h

-- TODO
ffi.cdef'typedef struct ScheduleInfo ScheduleInfo;'
makeVectorPtr'ScheduleInfo'

-- squad.h

-- TODO
ffi.cdef'typedef struct Squad Squad;'
makeVectorPtr'Squad'

-- activity_entry.h

ffi.cdef'typedef struct ActivityEntry ActivityEntry;'
makeVectorPtr'ActivityEntry'

-- report.h

ffi.cdef'typedef struct Report Report;'
makeVectorPtr'Report'

-- popup_mesage.h

ffi.cdef'typedef struct PopupMessage PopupMessage;'
makeVectorPtr'PopupMessage'

-- mission_report.h

ffi.cdef'typedef struct MissionReport MissionReport;'
makeVectorPtr'MissionReport'

-- spoils_report.h

ffi.cdef'typedef struct SpoilsReport SpoilsReport;'
makeVectorPtr'SpoilsReport'

-- interrogation_report.h

ffi.cdef'typedef struct InterrogationReport InterrogationReport;'
makeVectorPtr'InterrogationReport'

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
makeVectorPtr'InteractionInstance'

-- written_content.h

ffi.cdef'typedef struct WrittenContent WrittenContent;'
makeVectorPtr'WrittenContent'

-- identity.h

ffi.cdef'typedef struct Identity Identity;'
makeVectorPtr'Identity'

-- incident.h

ffi.cdef'typedef struct Incident Incident;'
makeVectorPtr'Incident'

-- crime.h

ffi.cdef'typedef struct Crime Crime;'
makeVectorPtr'Crime'

-- vehicle.h

ffi.cdef'typedef struct Vehicle Vehicle;'
makeVectorPtr'Vehicle'

-- army.h

ffi.cdef'typedef struct Army Army;'
makeVectorPtr'Army'

-- cultural_identity.h

ffi.cdef'typedef struct CulturalIdentity CulturalIdentity;'
makeVectorPtr'CulturalIdentity'

-- agreement.h

ffi.cdef'typedef struct Agreement Agreement;'
makeVectorPtr'Agreement'

-- poetic_form.h

ffi.cdef'typedef struct PoeticForm PoeticForm;'
makeVectorPtr'PoeticForm'

-- musical_form.h

ffi.cdef'typedef struct MusicalForm MusicalForm;'
makeVectorPtr'MusicalForm'

-- dance_form.h

ffi.cdef'typedef struct DanceForm DanceForm;'
makeVectorPtr'DanceForm'

-- scale.h

ffi.cdef'typedef struct Scale Scale;'
makeVectorPtr'Scale'

-- rhythm.h

ffi.cdef'typedef struct Rhythm Rhythm;'
makeVectorPtr'Rhythm'

-- occupation.h

ffi.cdef'typedef struct Occupation Occupation;'
makeVectorPtr'Occupation'

-- belief_system.h

ffi.cdef'typedef struct BeliefSystem BeliefSystem;'
makeVectorPtr'BeliefSystem'

-- image_set.h

ffi.cdef'typedef struct ImageSet ImageSet;'
makeVectorPtr'ImageSet'

-- divination_set.h

ffi.cdef'typedef struct DivinationSet DivinationSet;'
makeVectorPtr'DivinationSet'

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
makeVectorPtr'MapBlock'

-- map_block_column.h

-- TODO
ffi.cdef'typedef struct MapBlockColumn MapBlockColumn;'
makeVectorPtr'MapBlockColumn'

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
makeVectorPtr'BlockSquareEventSpoorst'

-- historical_figure.h

-- TODO
makeVectorPtr'HistoricalFigure'

-- world_region_details.h

--- TODO
ffi.cdef'typedef struct WorldRegionDetails WorldRegionDetails;'
makeVectorPtr'WorldRegionDetails'

-- world_construction_square.h

--- TODO
ffi.cdef'typedef struct WorldConstructionSquare WorldConstructionSquare;'
makeVectorPtr'WorldConstructionSquare'

-- world_construction.h

--- TODO
ffi.cdef'typedef struct WorldConstruction WorldConstruction;'
makeVectorPtr'WorldConstruction'

-- entity_claim_mask.h

ffi.cdef[[
typedef uint8_t EntityClaimMaskMapRegionMask[16][16];
]]
makeVectorPtr'EntityClaimMaskMapRegionMask'

ffi.cdef[[
typedef struct {
	struct {
		vector_int entities;
		vector_EntityClaimMaskMapRegionMask_ptr regionMasks;
	} ** map;
	int16_t width;
	int16_t height;
} EntityClaimMask;
]]

-- world_site.h

--- TODO
ffi.cdef'typedef struct WorldSite WorldSite;'
makeVectorPtr'WorldSite'

-- world_site_unk130.h

--- TODO
ffi.cdef'typedef struct WorldSiteUnknown130 WorldSiteUnknown130;'
makeVectorPtr'WorldSiteUnknown130'

-- resource_allotment_data.h

--- TODO
ffi.cdef'typedef struct ResourceAllotmentData ResourceAllotmentData;'
makeVectorPtr'ResourceAllotmentData'

-- breed.h

--- TODO
ffi.cdef'typedef struct Breed Breed;'
makeVectorPtr'Breed'

-- battlefield.h

--- TODO
ffi.cdef'typedef struct Battlefield Battlefield;'
makeVectorPtr'Battlefield'

-- region_weather.h

--- TODO
ffi.cdef'typedef struct RegionWeather RegionWeather;'
makeVectorPtr'RegionWeather'

-- world_object_data.h

--- TODO
ffi.cdef'typedef struct WorldObjectData WorldObjectData;'
makeVectorPtr'WorldObjectData'

-- world_landmass.h

--- TODO
ffi.cdef'typedef struct WorldLandMass WorldLandMass;'
makeVectorPtr'WorldLandMass'

-- world_region.h

--- TODO
ffi.cdef'typedef struct WorldRegion WorldRegion;'
makeVectorPtr'WorldRegion'

-- world_underground_region.h

--- TODO
ffi.cdef'typedef struct WorldUndergroundRegion WorldUndergroundRegion;'
makeVectorPtr'WorldUndergroundRegion'

-- world_geo_biome.h

--- TODO
ffi.cdef'typedef struct WorldGeoBiome WorldGeoBiome;'
makeVectorPtr'WorldGeoBiome'

-- world_mountain_peak.h

--- TODO
ffi.cdef'typedef struct WorldMountainPeak WorldMountainPeak;'
makeVectorPtr'WorldMountainPeak'

-- world_river.h

--- TODO
ffi.cdef'typedef struct WorldRiver WorldRiver;'
makeVectorPtr'WorldRiver'

-- region_map_entry.h

--- TODO
ffi.cdef'typedef struct RegionMapEntry RegionMapEntry;'
makeVectorPtr'RegionMapEntry'

-- embark_note.h

--- TODO
ffi.cdef'typedef struct EmbarkNote EmbarkNote;'
makeVectorPtr'EmbarkNote'

-- feature_init.h

--- TODO
ffi.cdef'typedef struct FeatureInit FeatureInit;'
makeVectorPtr'FeatureInit'

-- world_geo_layer.h

--- TODO
ffi.cdef'typedef struct WorldGeoLayer WorldGeoLayer;'

-- entity_raw.h

--- TODO
ffi.cdef'typedef struct EntityRaw EntityRaw;'
makeVectorPtr'EntityRaw'

-- abstract_building.h

--- TODO
ffi.cdef'typedef struct AbstractBuilding AbstractBuilding;'
makeVectorPtr'AbstractBuilding'

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
makeVectorPtr'MaterialTemplate'

-- inorganic_raw.h

--- TODO
ffi.cdef'typedef struct InorganicRaw InorganicRaw;'
makeVectorPtr'InorganicRaw'

-- plant_raw.h

--- TODO
ffi.cdef'typedef struct PlantRaw PlantRaw;'
makeVectorPtr'PlantRaw'

-- tissue_template.h

--- TODO
ffi.cdef'typedef struct TissueTemplate TissueTemplate;'
makeVectorPtr'TissueTemplate'

-- body_detail_plan.h

--- TODO
ffi.cdef'typedef struct BodyDetailPlan BodyDetailPlan;'
makeVectorPtr'BodyDetailPlan'

-- body_template.h

--- TODO
ffi.cdef'typedef struct BodyTemplate BodyTemplate;'
makeVectorPtr'BodyTemplate'

-- creature_variation.h

--- TODO
ffi.cdef'typedef struct CreatureVariation CreatureVariation;'
makeVectorPtr'CreatureVariation'

-- creature_raw.h

--- TODO
ffi.cdef'typedef struct CreatureRaw CreatureRaw;'
makeVectorPtr'CreatureRaw'

-- creature_handler.h

ffi.cdef[[
typedef struct {
	void * table /* TODO */;
	vector_CreatureRaw_ptr alphabetic;
	vector_CreatureRaw_ptr all;
	int32_t numCaste; /*!< seems equal to length of vectors below */
	vector_int listCreature; /*!< Together with list_caste, a list of all caste indexes in order. */
	vector_int listCaste;
	vector_string actionStrings; /*!< since v0.40.01 */
} CreatureHandler;
]]

-- itemdef.h

--- TODO
ffi.cdef'typedef struct ItemDef ItemDef;'
makeVectorPtr'ItemDef'
makeVectorPtr'ItemDef_weaponst'
makeVectorPtr'ItemDef_trapcompst'
makeVectorPtr'ItemDef_toyst'
makeVectorPtr'ItemDef_toolst'
makeVectorPtr'ItemDef_toolst'
makeVectorPtr'ItemDef_instrumentst'
makeVectorPtr'ItemDef_armorst'
makeVectorPtr'ItemDef_ammost'
makeVectorPtr'ItemDef_siegeammost'
makeVectorPtr'ItemDef_glovesst'
makeVectorPtr'ItemDef_shoesst'
makeVectorPtr'ItemDef_shieldst'
makeVectorPtr'ItemDef_helmst'
makeVectorPtr'ItemDef_pantsst'
makeVectorPtr'ItemDef_foodst'

-- material.h

-- TODO
ffi.cdef'typedef struct Material Material;'
makeVectorPtr'Material'

-- descriptor_color.h

-- TODO
ffi.cdef'typedef struct DescriptorColor DescriptorColor;'
makeVectorPtr'DescriptorColor'

-- descriptor_shape.h

-- TODO
ffi.cdef'typedef struct DescriptorShape DescriptorShape;'
makeVectorPtr'DescriptorShape'

-- descriptor_pattern.h

-- TODO
ffi.cdef'typedef struct DescriptorPattern DescriptorPattern;'
makeVectorPtr'DescriptorPattern'

-- reaction.h

-- TODO
ffi.cdef'typedef struct Reaction Reaction;'
makeVectorPtr'Reaction'

-- reaction_category.h

-- TODO
ffi.cdef'typedef struct ReactionCategory ReactionCategory;'
makeVectorPtr'ReactionCategory'

-- building_def.h

-- TODO
ffi.cdef'typedef struct BuildingDef BuildingDef;'
makeVectorPtr'BuildingDef'

-- building_def_workshopst.h

-- TODO
ffi.cdef'typedef struct BuildingDefWorkshopst BuildingDefWorkshopst;'
makeVectorPtr'BuildingDefWorkshopst'

-- building_def_furnacest.h

-- TODO
ffi.cdef'typedef struct BuildingDefFurnacest BuildingDefFurnacest;'
makeVectorPtr'BuildingDefFurnacest'

-- interaction.h

-- TODO
ffi.cdef'typedef struct Interaction Interaction;'
makeVectorPtr'Interaction'

-- syndrome.h

-- TODO
ffi.cdef'typedef struct Syndrome Syndrome;'
makeVectorPtr'Syndrome'

-- creature_interaction_effect.h

-- TODO
ffi.cdef'typedef struct CreatureInteractionEffect CreatureInteractionEffect;'
makeVectorPtr'CreatureInteractionEffect'


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
makeVectorPtr'WorldRawsBodyGlosses'

ffi.cdef[[
typedef struct {
	vector_MaterialTemplate_ptr materialTemplates;
	vector_InorganicRaw_ptr inorganics;
	vector_InorganicRaw_ptr inorganicsSubset; /*!< all inorganics with value less than 4 */
	struct {
		vector_PlantRaw_ptr all;
		vector_PlantRaw_ptr bushes;
		vector_int bushesIndex;
		vector_PlantRaw_ptr trees;
		vector_int treesIndex;
		vector_PlantRaw_ptr grasses;
		vector_int grassesIndex;
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
		vector_int unk_1; /*!< since v0.47.01 */
		vector_int unk_2; /*!< since v0.47.01 */
		vector_int unk_3; /*!< since v0.47.01 */
	} descriptors;

	struct {
		vector_Reaction_ptr reactions;
		vector_ReactionCategory_ptr reactionCategories;
	} reactions;

	struct {
		vector_BuildingDef_ptr all;
		vector_BuildingDefWorkshopst_ptr workshops;
		vector_BuildingDefFurnacest_ptr furnaces;
		int32_t next_id;
	} buildings;

	vector_Interaction_ptr interactions; /*!< since v0.34.01 */

	struct {
		vector_short organicTypes[39];
		vector_int organicIndexes[39];
		vector_int organicUnknown[39]; /*!< everything 0 */
		Material * builtin[659];
	} matTable;

	struct {
		// first two fields match MaterialVecRef
		vector_short matTypes;
		vector_int matIndexes;
		vector_int interactions;
		vector_Syndrome_ptr all; /*!< since v0.34.01 */
	} syndromes;
	
	struct {
		// first two fields match MaterialVecRef
		// first three fields matches syndromes
		vector_short matTypes;
		vector_int matIndexes;
		vector_int interactions;
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

-- world_data.h

ffi.cdef[[
typedef int16_t FlipLatitude;
enum {
	FlipLatitude_None = -1, // -1, 0xFFFFFFFFFFFFFFFF
	FlipLatitude_North, // 0, 0x0
	FlipLatitude_South, // 1, 0x1
	FlipLatitude_Both, // 2, 0x2
};
]]

ffi.cdef[[
struct {
	int32_t unk_0;
	int32_t race;
	int32_t unk_8;
} WorldDataUnknown274Unknown10 ;
]]
makeVectorPtr'WorldDataUnknown274Unknown10'

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
makeVectorPtr'WorldDataUnknown274'

ffi.cdef[[
typedef struct {
	LanguageName name; /*!< name of the world */
	int8_t unk1[15];
	int32_t next_site_id;
	int32_t next_site_unk130_id;
	int32_t next_resource_allotment_id;
	int32_t next_breed_id;
	int32_t next_battlefield_id; /*!< since v0.34.01 */
	int32_t unk_v34_1; /*!< since v0.34.01 */
	int32_t world_width;
	int32_t world_height;
	int32_t unk_78;
	int32_t moon_phase;
	FlipLatitude flip_latitude;
	int16_t flip_longitude;
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
	vector_int old_sites;
	vector_int old_site_x;
	vector_int old_site_y;
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

-- save_version.h

ffi.cdef[[
typedef int32_t SaveVersion;
enum {
	SaveVersion_v0_21_93_19a = 1107, // 1107, 0x453
	SaveVersion_v0_21_93_19c = 1108, // 1108, 0x454
	SaveVersion_v0_21_95_19a = 1108, // 1108, 0x454
	SaveVersion_v0_21_95_19b = 1108, // 1108, 0x454
	SaveVersion_v0_21_95_19c = 1110, // 1110, 0x456
	SaveVersion_v0_21_104_19d = 1121, // 1121, 0x461
	SaveVersion_v0_21_104_21a = 1123, // 1123, 0x463
	SaveVersion_v0_21_104_21b = 1125, // 1125, 0x465
	SaveVersion_v0_21_105_21a = 1128, // 1128, 0x468
	SaveVersion_v0_22_107_21a = 1128, // 1128, 0x468
	SaveVersion_v0_22_110_22e = 1134, // 1134, 0x46E
	SaveVersion_v0_22_110_22f = 1137, // 1137, 0x471
	SaveVersion_v0_22_110_23a = 1148, // 1148, 0x47C
	SaveVersion_v0_22_120_23a = 1151, // 1151, 0x47F
	SaveVersion_v0_22_121_23b = 1161, // 1161, 0x489
	SaveVersion_v0_22_123_23a = 1165, // 1165, 0x48D
	SaveVersion_v0_23_130_23a = 1169, // 1169, 0x491
	SaveVersion_v0_27_169_32a = 1205, // 1205, 0x4B5
	SaveVersion_v0_27_169_33a = 1206, // 1206, 0x4B6
	SaveVersion_v0_27_169_33b = 1209, // 1209, 0x4B9
	SaveVersion_v0_27_169_33c = 1211, // 1211, 0x4BB
	SaveVersion_v0_27_169_33d = 1212, // 1212, 0x4BC
	SaveVersion_v0_28_181_39b = 1255, // 1255, 0x4E7
	SaveVersion_v0_28_181_39c = 1256, // 1256, 0x4E8
	SaveVersion_v0_28_181_39d = 1259, // 1259, 0x4EB
	SaveVersion_v0_28_181_39e = 1260, // 1260, 0x4EC
	SaveVersion_v0_28_181_39f = 1261, // 1261, 0x4ED
	SaveVersion_v0_28_181_40a = 1265, // 1265, 0x4F1
	SaveVersion_v0_28_181_40b = 1266, // 1266, 0x4F2
	SaveVersion_v0_28_181_40c = 1267, // 1267, 0x4F3
	SaveVersion_v0_28_181_40d = 1268, // 1268, 0x4F4
	SaveVersion_v0_31_01 = 1287, // 1287, 0x507
	SaveVersion_v0_31_02 = 1288, // 1288, 0x508
	SaveVersion_v0_31_03 = 1289, // 1289, 0x509
	SaveVersion_v0_31_04 = 1292, // 1292, 0x50C
	SaveVersion_v0_31_05 = 1295, // 1295, 0x50F
	SaveVersion_v0_31_06 = 1297, // 1297, 0x511
	SaveVersion_v0_31_08 = 1300, // 1300, 0x514
	SaveVersion_v0_31_09 = 1304, // 1304, 0x518
	SaveVersion_v0_31_10 = 1305, // 1305, 0x519
	SaveVersion_v0_31_11 = 1310, // 1310, 0x51E
	SaveVersion_v0_31_12 = 1311, // 1311, 0x51F
	SaveVersion_v0_31_13 = 1323, // 1323, 0x52B
	SaveVersion_v0_31_14 = 1325, // 1325, 0x52D
	SaveVersion_v0_31_15 = 1326, // 1326, 0x52E
	SaveVersion_v0_31_16 = 1327, // 1327, 0x52F
	SaveVersion_v0_31_17 = 1340, // 1340, 0x53C
	SaveVersion_v0_31_18 = 1341, // 1341, 0x53D
	SaveVersion_v0_31_19 = 1351, // 1351, 0x547
	SaveVersion_v0_31_20 = 1353, // 1353, 0x549
	SaveVersion_v0_31_21 = 1354, // 1354, 0x54A
	SaveVersion_v0_31_22 = 1359, // 1359, 0x54F
	SaveVersion_v0_31_23 = 1360, // 1360, 0x550
	SaveVersion_v0_31_24 = 1361, // 1361, 0x551
	SaveVersion_v0_31_25 = 1362, // 1362, 0x552
	SaveVersion_v0_34_01 = 1372, // 1372, 0x55C
	SaveVersion_v0_34_02 = 1374, // 1374, 0x55E
	SaveVersion_v0_34_03 = 1376, // 1376, 0x560
	SaveVersion_v0_34_04 = 1377, // 1377, 0x561
	SaveVersion_v0_34_05 = 1378, // 1378, 0x562
	SaveVersion_v0_34_06 = 1382, // 1382, 0x566
	SaveVersion_v0_34_07 = 1383, // 1383, 0x567
	SaveVersion_v0_34_08 = 1400, // 1400, 0x578
	SaveVersion_v0_34_09 = 1402, // 1402, 0x57A
	SaveVersion_v0_34_10 = 1403, // 1403, 0x57B
	SaveVersion_v0_34_11 = 1404, // 1404, 0x57C
	SaveVersion_v0_40_01 = 1441, // 1441, 0x5A1
	SaveVersion_v0_40_02 = 1442, // 1442, 0x5A2
	SaveVersion_v0_40_03 = 1443, // 1443, 0x5A3
	SaveVersion_v0_40_04 = 1444, // 1444, 0x5A4
	SaveVersion_v0_40_05 = 1445, // 1445, 0x5A5
	SaveVersion_v0_40_06 = 1446, // 1446, 0x5A6
	SaveVersion_v0_40_07 = 1448, // 1448, 0x5A8
	SaveVersion_v0_40_08 = 1449, // 1449, 0x5A9
	SaveVersion_v0_40_09 = 1451, // 1451, 0x5AB
	SaveVersion_v0_40_10 = 1452, // 1452, 0x5AC
	SaveVersion_v0_40_11 = 1456, // 1456, 0x5B0
	SaveVersion_v0_40_12 = 1459, // 1459, 0x5B3
	SaveVersion_v0_40_13 = 1462, // 1462, 0x5B6
	SaveVersion_v0_40_14 = 1469, // 1469, 0x5BD
	SaveVersion_v0_40_15 = 1470, // 1470, 0x5BE
	SaveVersion_v0_40_16 = 1471, // 1471, 0x5BF
	SaveVersion_v0_40_17 = 1472, // 1472, 0x5C0
	SaveVersion_v0_40_18 = 1473, // 1473, 0x5C1
	SaveVersion_v0_40_19 = 1474, // 1474, 0x5C2
	SaveVersion_v0_40_20 = 1477, // 1477, 0x5C5
	SaveVersion_v0_40_21 = 1478, // 1478, 0x5C6
	SaveVersion_v0_40_22 = 1479, // 1479, 0x5C7
	SaveVersion_v0_40_23 = 1480, // 1480, 0x5C8
	SaveVersion_v0_40_24 = 1481, // 1481, 0x5C9
	SaveVersion_v0_42_01 = 1531, // 1531, 0x5FB
	SaveVersion_v0_42_02 = 1532, // 1532, 0x5FC
	SaveVersion_v0_42_03 = 1533, // 1533, 0x5FD
	SaveVersion_v0_42_04 = 1534, // 1534, 0x5FE
	SaveVersion_v0_42_05 = 1537, // 1537, 0x601
	SaveVersion_v0_42_06 = 1542, // 1542, 0x606
	SaveVersion_v0_43_01 = 1551, // 1551, 0x60F
	SaveVersion_v0_43_02 = 1552, // 1552, 0x610
	SaveVersion_v0_43_03 = 1553, // 1553, 0x611
	SaveVersion_v0_43_04 = 1555, // 1555, 0x613
	SaveVersion_v0_43_05 = 1556, // 1556, 0x614
	SaveVersion_v0_44_01 = 1596, // 1596, 0x63C
	SaveVersion_v0_44_02 = 1597, // 1597, 0x63D
	SaveVersion_v0_44_03 = 1600, // 1600, 0x640
	SaveVersion_v0_44_04 = 1603, // 1603, 0x643
	SaveVersion_v0_44_05 = 1604, // 1604, 0x644
	SaveVersion_v0_44_06 = 1611, // 1611, 0x64B
	SaveVersion_v0_44_07 = 1612, // 1612, 0x64C
	SaveVersion_v0_44_08 = 1613, // 1613, 0x64D
	SaveVersion_v0_44_09 = 1614, // 1614, 0x64E
	SaveVersion_v0_44_10 = 1620, // 1620, 0x654
	SaveVersion_v0_44_11 = 1623, // 1623, 0x657
	SaveVersion_v0_44_12 = 1625, // 1625, 0x659
	SaveVersion_v0_47_01 = 1710, // 1710, 0x6AE
	SaveVersion_v0_47_02 = 1711, // 1711, 0x6AF
	SaveVersion_v0_47_03 = 1713, // 1713, 0x6B1
	SaveVersion_v0_47_04 = 1715, // 1715, 0x6B3
	SaveVersion_v0_47_05 = 1716, // 1716, 0x6B4
};
]]

-- history_event.h

-- TODO
ffi.cdef'typedef struct HistoryEvent HistoryEvent;'
makeVectorPtr'HistoryEvent'

-- relationship_event.h

-- TODO
ffi.cdef'typedef struct RelationshipEvent RelationshipEvent;'
makeVectorPtr'RelationshipEvent'

-- relationship_event_supplement.h

-- TODO
ffi.cdef'typedef struct RelationshipEventSupplement RelationshipEventSupplement;'
makeVectorPtr'RelationshipEventSupplement'

-- history_event_collection.h

-- TODO
ffi.cdef'typedef struct HistoryEventCollection HistoryEventCollection;'
makeVectorPtr'HistoryEventCollection'

-- history_era.h

-- TODO
ffi.cdef'typedef struct HistoryEra HistoryEra;'
makeVectorPtr'HistoryEra'

-- intrigue.h

-- TODO
ffi.cdef'typedef struct Intrigue Intrigue;'
makeVectorPtr'Intrigue'

-- entity_population.h

-- TODO
ffi.cdef'typedef struct EntityPopulation EntityPopulation;'
makeVectorPtr'EntityPopulation'

-- flow_info.h

-- TODO
ffi.cdef'typedef struct FlowInfo FlowInfo;'
makeVectorPtr'FlowInfo'

-- interaction_effect.h

-- TODO
ffi.cdef'typedef struct InteractionEffect InteractionEffect;'
makeVectorPtr'InteractionEffect'


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
	vector_int discoveredArtImageID;
	vector_short discoveredArtImageSubID;
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
typedef struct {
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
	bool have_bottom_layer_1;
	bool have_bottom_layer_2;
	int32_t levels_above_ground;
	int32_t levels_above_layer_1;
	int32_t levels_above_layer_2;
	int32_t levels_above_layer_3;
	int32_t levels_above_layer_4;
	int32_t levels_above_layer_5;
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
	int8_t allow_necromancer_lieutenants; /*!< since v0.47.01 */
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
	int32_t reveal_all_history;
	int32_t cull_historical_figures;
	int32_t erosion_cycle_count;
	int32_t periodically_erode_extremes;
	int32_t orographic_precipitation;
	int32_t playable_civilization_required;
	int32_t all_caves_visible;
	int32_t show_embark_tunnel;
	int32_t pole;
	bool unk_1;
} WorldGenParams;
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
Item_drinkst
Item_liquid_miscst
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
Building_stockpilest
Building_civzonest
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
Building_furnacest
Building_furnacest
Building_furnacest
Building_furnacest
Building_furnacest
Building_furnacest
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_workshopst
Building_weaponst
Building_instrumentst
Building_offering_placest


]]):gmatch'[%w_]+' do
	makeVectorPtr(T)
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
	vector_int grasses;
} WorldLayerGrasses;
]]
makeVectorPtr'WorldLayerGrasses'

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
makeVectorPtr'WorldUnknown131ec0'

ffi.cdef[[
typedef struct {
	std_string name;
	int32_t unknown1;
	int32_t unknown2;
} WorldLanguages;
]]
makeVectorPtr'WorldLanguages'

ffi.cdef[[
typedef struct {
	int32_t artifact;
	int32_t unk_1; /*!< only seen 1, and only family heirloom... */
	int32_t year; /*!< matches up with creation or a claim... */
	int32_t year_tick;
	int32_t unk_2; /*!< only seen -1 */
} World_Unknown131ef0_Claims;
]]
makeVectorPtr'World_Unknown131ef0_Claims'

ffi.cdef[[
typedef struct {
	int32_t hfid; /*!< confusing. usually the creator, but sometimes completely unrelated or culled */
	vector_World_Unknown131ef0_Claims_ptr claims;
	int32_t unk_hfid; /*!< hfid or completely unrelated hf seen? */
	int32_t unk_1; /*!< only seen 0 */
	int32_t unk_2; /*!< only seen 0 */
} WorldUnknown131ef0 ;
]]
makeVectorPtr'WorldUnknown131ef0'

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
typedef struct {
	ItemType itemType;
	int16_t itemSubType;
	int16_t matType;
	int32_t matIndex;
	bool unk_1;
} WorldItemTypes;
]]
makeVectorPtr'WorldItemTypes'

ffi.cdef[[
typedef struct {
	void * unk_1;
	int32_t unk_2;
	int16_t unk_3;
	int32_t unk_4;
	int32_t unk_5;
	int32_t unk_6;
} World_Unknown19325c_Unknown1;
]]
makeVectorPtr'World_Unknown19325c_Unknown1'

ffi.cdef[[
typedef struct {
	Item * unk_1;
	int32_t unk_2;
	int32_t unk_3;
} World_Unknown19325c_Unknown2;
]]
makeVectorPtr'World_Unknown19325c_Unknown2'

ffi.cdef[[
typedef struct {
	int16_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
} World_Unknown19325c_Unknown3;
]]
makeVectorPtr'World_Unknown19325c_Unknown3'

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
		vector_Item_liquid_miscst_ptr LIQUID_MISC;
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
		vector_int badTag;
	} items;

	struct {
		vector_ArtifactRecord_ptr all, bad;
	} artifacts;

	JobHandler jobs;
	list_Projectile projectileList;

	struct {
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
	} buildings;

	struct {
		vector_Machine_ptr all;
		vector_Machine_ptr bad;
	} machines;

	struct {
		vector_FlowGuide_ptr all, bad;
	} flowGuides;

	struct {
		int32_t numJobs[10];
		int32_t numHaulers[10];
		struct {
			int8_t unk_1, food, unk_2, unk_3;
		} simple1;
		vector_sbyte seeds, plants, cheese, meat_fish, eggs, leaves, plant_powder;
		struct {
			int8_t seeds, plants, cheese, fish, meat, leaves, powder, eggs;
		} simple2;
		vector_sbyte liquid_plant, liquid_animal, liquid_builtin;
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
		vector_InteractionInstance_ptr, all, bad;
	} interctinInstances;

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
		int16_t distance_lookup[53][53];
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
		vector_short unk_v40_3b;
		vector_short unk_v40_3c;
		vector_short unk_v40_3d;
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
		vector_short unk_21;
		int32_t civCount;
		int32_t civsLeftToPlace;
		vector_WorldRegion_ptr regions1[10];
		vector_WorldRegion_ptr regions2[10];
		vector_WorldRegion_ptr regions3[10];
		vector_int unk_22;
		vector_int unk_23;
		vector_int unk_24;
		vector_int unk_25;
		vector_int unk_26;
		vector_int unk_27;
		int32_t unk_28;
		int32_t unk_29;
		vector_short unk_10d298; /*!< since v0.40.01 */
		vector_short unk_10d2a4; /*!< since v0.40.01 */
		vector_AbstractBuilding_ptr libraries; /*!< since v0.42.01 */
		int32_t unk_30; /*!< since v0.42.01 */
		vector_AbstractBuilding_ptr temples; /*!< since v0.44.01 */
		vector_ArtifactRecord_ptr some_artifacts; /*!< since v0.44.01 */
		vector_ptr unk_31; /*!< since v0.47.01 */
		vector_int unk_32; /*!< since v0.47.01 */
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
		vector_short unk7a;
		vector_short unk7b;
		vector_short unk7c;
		vector_short unk7_cntdn;
	} flowEngine;

	vector_int busyBuildings;
	dfarray_bit caveInFlags;

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
		vector_int unk1[336]; /*!< since v0.40.01 */
		vector_int unk2[336]; /*!< since v0.40.01 */
		vector_int unk3[336]; /*!< since v0.40.01 */
		vector_int unk4[336]; /*!< since v0.40.01 */
		vector_int unk5[336]; /*!< since v0.40.01 */
		vector_int unk6[336]; /*!< since v0.40.01 */
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
		vector_short featureX;
		vector_short featureY;
		vector_short featureLocalIndex; /*!< same as map_block.local_feature */
		vector_int featureGlobalIndex;
		vector_FeatureInit_ptr unk_1; /*!< from unk_9C */
		vector_short unk_2; /*!< unk_9C.region.x */
		vector_short unk_3; /*!< unk_9C.region.y */
		vector_short unk_4; /*!< unk_9C.embark.x */
		vector_short unk_5; /*!< unk_9C.embark.y */
		vector_short unk_6; /*!< unk_9C.local_feature_idx */
		vector_int unk_7; /*!< unk_9C.global_feature_idx */
		vector_int unk_8; /*!< unk_9C.unk10 */
		vector_short unk_9; /*!< unk_9C.unk14 */
		vector_short unk_10; /*!< unk_9C.local.x */
		vector_short unk_11; /*!< unk_9C.local.y */
		vector_short unk_12; /*!< unk_9C.z_min */
		vector_short unk_13; /*!< unk_9C.z_min; yes, seemingly duplicate */
		vector_short unk_14; /*!< unk_9C.z_max */
		vector_bool unk_15; /*!< since v0.40.11 */
	} features;
	bool allowAnnouncements; /*!< announcements will not be processed at all if false */
	bool unknown_26a9a9;
	bool unknown_26a9aa; /*!< since v0.42.01 */

	struct {
		vector_short race;
		vector_short caste;
		int32_t type;
		std_string filter; /*!< since v0.34.08 */
		vector_WorldItemTypes_ptr itemTypes[107]; /*!< true array */
		vector_ptr unk_vec1;
		vector_ptr unk_vec2;
		vector_ptr unk_vec3;
		struct {
			vector_JobSkill skills;
			vector_int skill_levels;
			vector_ItemType itemTypes;
			vector_short itemSubTypes;
			MaterialVecRef itemMaterials;
			vector_int itemCounts;
		} equipment;
		int32_t side;
		int32_t interaction;
		int32_t tame; /*!< since v0.47.01; sets tame-mountable status when the creature creation menu is opened */
		vector_InteractionEffect_ptr interactions; /*!< since v0.34.01 */
		vector_int creature_cnt;
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
			vector_int unk_2;
			vector_short unk_3;
			vector_short unk_4;
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

-- global_objects.h


ffi.cdef[[
typedef Rect3D SelectionRect;
]]
