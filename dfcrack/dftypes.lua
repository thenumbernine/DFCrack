local ffi = require 'ffi'

ffi.cdef[[
typedef struct {
	int16_t x, y;
} short2_t;
]]

ffi.cdef[[
typedef struct {
	int16_t x, y, z;
} short3_t;
]]

ffi.cdef[[
typedef struct {
	int32_t x, y, z;
} int3_t;
]]

-- TODO packed? { int3_t start, end; } ? verify sizeof...
ffi.cdef[[
typedef struct {
	int32_t start_x;
	int32_t start_y;
	int32_t start_z;
	int32_t end_x;
	int32_t end_y;
	int32_t end_z;
} rect3d_t;
]]

-- stl vector in my gcc / linux / df is 24 bytes
-- template type of our vector ... 8 bytes mind you
ffi.cdef[[
typedef struct {
	int16_t * start;
	int16_t * finish;
	int16_t * endOfStorage;
} vector_int16_t;
]]
assert(ffi.sizeof'vector_int16_t' == 24)
assert(ffi.sizeof'int16_t*' == 8)

ffi.cdef[[
typedef struct {
	vector_int16_t x;
	vector_int16_t y;
} path2d_t;
]]

ffi.cdef[[
typedef struct {
	vector_int16_t x;
	vector_int16_t y;
	vector_int16_t z;
} path3d_t;
]]
do return end

ffi.cdef[[
typedef struct {
	// why not uint32_t[8] ?
	uint16_t bits[16];
} tile_bitmask_t;
]]

ffi.cdef[[
struct block_burrow_t;
typedef struct {
	struct block_burrow_t * item;
	block_burrow_link_t * prev, next;
} block_burrow_link_t;
]]

ffi.cdef[[
struct block_burrow_t {
	int32_t id;
	tile_bitmask_t tile_bitmask;
	block_burrow_link_t * link;
};
typedef struct block_burrow_t block_burrow_t;
]]

--[[
typedef struct {
	dfhack_block_flags flags;
	dfhack_std_vector_block_square_event_ptr block_events;
	dfhack_df_linked_list block_burrows;
	int32_t local_feature;
	int32_t global_feature;
	int32_t unk2;
	int16_t layer_depth;
	int32_t dsgn_check_cooldown;
	dfhack_tile_designation default_liquid;
	dfhack_std_vector_int32_t items;
	dfhack_std_vector_flow_info_ptr flows;
	dfhack_flow_reuse_pool flow_pool;
	short3_t map_pos;
	short2_t region_pos;
	dfhack_static-array tiletype;
	dfhack_static-array designation;
	dfhack_static-array occupancy;
	dfhack_static-array fog_of_war;
	dfhack_static-array path_cost;
	dfhack_static-array path_tag;
	dfhack_static-array walkable;
	dfhack_static-array map_edge_distance;
	dfhack_static-array temperature_1;
	dfhack_static-array temperature_2;
	dfhack_static-array unk13;
	dfhack_static-array liquid_flow;
	dfhack_static-array region_offset;
} dfhack_map_block;

typedef struct {
	int16_t unk_z1;
	int16_t unk_z2;
	int16_t unk_3;
	dfhack_uint8_t unk_4;
} dfhack_cave_column;

typedef struct {
	int32_t unk_1;
	int16_t unk_x1;
	int16_t unk_y1;
	int16_t unk_x2;
	int16_t unk_y2;
	int16_t z_shift;
	path3d_t unk_6;
	int32_t unk_7;
} dfhack_cave_column_rectangle;

typedef struct {
	int16_t sink_level;
	int16_t beach_level;
	int16_t ground_level;
	dfhack_std_vector_pointer unmined_glyphs;
	int16_t z_base;
	dfhack_static-array cave_columns;
	dfhack_std_vector_cave_column_rectangle_ptr column_rectangles;
	int16_t z_shift;
	dfhack_df_flagarray flags;
	dfhack_static-array elevation;
	short2_t map_pos;
	int16_t unk_c3c;
	short2_t region_pos;
	dfhack_std_vector_plant_ptr plants;
} dfhack_map_block_column;

typedef struct {
} dfhack_block_square_event;

typedef struct {
	int32_t inorganic_mat;
	tile_bitmask_t tile_bitmask;
	int32_t flags;
} dfhack_block_square_event_mineralst;

typedef struct {
	dfhack_static-array tiles;
	dfhack_static-array liquid_type;
} dfhack_block_square_event_frozen_liquidst;

typedef struct {
	int32_t construction_id;
	tile_bitmask_t tile_bitmask;
} dfhack_block_square_event_world_constructionst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	dfhack_enum mat_state;
	dfhack_static-array amount;
	dfhack_uint16_t min_temperature;
	dfhack_uint16_t max_temperature;
} dfhack_block_square_event_material_spatterst;

typedef struct {
	int32_t plant_index;
	dfhack_static-array amount;
} dfhack_block_square_event_grassst;

typedef struct {
	dfhack_static-array flags;
	dfhack_static-array unk_2;
	dfhack_static-array unk_3;
	dfhack_static-array race;
	dfhack_static-array caste;
	dfhack_static-array age;
	int32_t year;
	int32_t year_tick;
} dfhack_block_square_event_spoorst;

typedef struct {
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mattype;
	int32_t matindex;
	int32_t unk1;
	dfhack_static-array amount;
	dfhack_static-array unk2;
	dfhack_uint16_t temp1;
	dfhack_uint16_t temp2;
} dfhack_block_square_event_item_spatterst;

typedef struct {
	dfhack_static-array priority;
} dfhack_block_square_event_designation_priorityst;

typedef struct {
	dfhack_std_vector_world_population_ptr population;
	int32_t irritation_level;
	int16_t irritation_attacks;
	path2d_t embark_pos;
	vector_int16_t min_map_z;
	vector_int16_t max_map_z;
} dfhack_feature;

typedef dfhack_feature dfhack_feature_outdoor_riverst;

typedef dfhack_feature dfhack_feature_cavest;

typedef dfhack_feature dfhack_feature_pitst;

typedef struct {
	int32_t magma_fill_z;
} dfhack_feature_magma_poolst;

typedef struct {
	int32_t magma_fill_z;
} dfhack_feature_volcanost;

typedef dfhack_feature dfhack_feature_deep_special_tubest;

typedef dfhack_feature dfhack_feature_deep_surface_portalst;

typedef dfhack_feature dfhack_feature_subterranean_from_layerst;

typedef dfhack_feature dfhack_feature_magma_core_from_layerst;

typedef dfhack_feature dfhack_feature_underworld_from_layerst;

typedef struct {
	dfhack_df_flagarray flags;
	dfhack_std_vector_feature_alteration_ptr alterations;
	int16_t start_x;
	int16_t start_y;
	int16_t end_x;
	int16_t end_y;
	dfhack_enum start_depth;
	dfhack_enum end_depth;
} dfhack_feature_init;

typedef struct {
	dfhack_pointer feature;
} dfhack_feature_init_outdoor_riverst;

typedef struct {
	dfhack_pointer feature;
} dfhack_feature_init_cavest;

typedef struct {
	dfhack_pointer feature;
} dfhack_feature_init_pitst;

typedef struct {
	dfhack_pointer feature;
} dfhack_feature_init_magma_poolst;

typedef struct {
	dfhack_pointer feature;
} dfhack_feature_init_volcanost;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	dfhack_pointer feature;
} dfhack_feature_init_deep_special_tubest;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	dfhack_pointer feature;
} dfhack_feature_init_deep_surface_portalst;

typedef struct {
	int32_t layer;
	dfhack_pointer feature;
} dfhack_feature_init_subterranean_from_layerst;

typedef struct {
	int32_t layer;
	dfhack_pointer feature;
} dfhack_feature_init_magma_core_from_layerst;

typedef struct {
	int32_t layer;
	int16_t mat_type;
	int32_t mat_index;
	dfhack_pointer feature;
} dfhack_feature_init_underworld_from_layerst;

typedef struct {
} dfhack_feature_alteration;

typedef struct {
	int32_t unk_1;
	int32_t unk_2;
} dfhack_feature_alteration_new_pop_maxst;

typedef struct {
	int32_t magma_fill_z;
} dfhack_feature_alteration_new_lava_fill_zst;

typedef struct {
	short2_t region_pos;
	int32_t construction_id;
	vector_int16_t embark_x;
	vector_int16_t embark_y;
	vector_int16_t embark_unk;
	vector_int16_t embark_z;
} dfhack_world_construction_square;

typedef struct {
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mat_type;
	int32_t mat_index;
} dfhack_world_construction_square_roadst;

typedef dfhack_world_construction_square dfhack_world_construction_square_tunnelst;

typedef struct {
	int32_t road_id;
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mat_type;
	int32_t mat_index;
} dfhack_world_construction_square_bridgest;

typedef struct {
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mat_type;
	int32_t mat_index;
} dfhack_world_construction_square_wallst;

typedef struct {
	int32_t id;
	dfhack_std_vector_world_construction_square_ptr square_obj;
	path2d_t square_pos;
} dfhack_world_construction;

typedef struct {
	dfhack_language_name name;
} dfhack_world_construction_roadst;

typedef struct {
	dfhack_language_name name;
} dfhack_world_construction_tunnelst;

typedef struct {
	dfhack_language_name name;
} dfhack_world_construction_bridgest;

typedef struct {
	dfhack_language_name name;
} dfhack_world_construction_wallst;

typedef struct {
	short3_t pos;
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mat_type;
	int32_t mat_index;
	dfhack_construction_flags flags;
	dfhack_enum original_tile;
} dfhack_construction;

typedef struct {
	dfhack_enum type;
	int16_t mat_type;
	int32_t mat_index;
	int16_t density;
	short3_t pos;
	short3_t dest;
	dfhack_bool expanding;
	dfhack_bool reuse;
	int32_t guide_id;
} dfhack_flow_info;

typedef struct {
	int32_t reuse_idx;
	int32_t flags;
} dfhack_flow_reuse_pool;

typedef struct {
	int32_t id;
	int8_t unk_8;
} dfhack_flow_guide;

typedef struct {
	dfhack_static-array unk_1;
} dfhack_flow_guide_trailing_flowst;

typedef struct {
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mattype;
	int32_t matindex;
	int32_t unk_18;
	int32_t unk_1c;
	dfhack_static-array unk_1;
} dfhack_flow_guide_item_cloudst;

typedef struct {
	int32_t id;
	dfhack_pointer job;
	int16_t type;
	int16_t foreground;
	int16_t background;
	int8_t bright;
	short3_t pos;
	int32_t timer;
} dfhack_effect_info;

typedef struct {
} dfhack_region_block_eventst;

typedef struct {
	dfhack_static-array unk_1;
} dfhack_region_block_event_sphere_fieldst;

typedef struct {
	int16_t race;
	int16_t caste;
	short3_t pos;
	dfhack_bool visible;
	int16_t countdown;
	dfhack_pointer item;
	dfhack_vermin_flags flags;
	int32_t amount;
	dfhack_world_population_ref population;
	dfhack_enum category;
	int32_t id;
} dfhack_vermin;

typedef struct {
	dfhack_plant_flags flags;
	int16_t material;
	short3_t pos;
	int32_t grow_counter;
	int32_t damage_flags;
	int32_t hitpoints;
	int16_t update_order;
	int32_t site_id;
	int32_t srb_id;
	dfhack_std_vector_spatter_common_ptr contaminants;
	dfhack_pointer tree_info;
} dfhack_plant;

typedef struct {
	dfhack_pointer body;
	dfhack_pointer extent_east;
	dfhack_pointer extent_south;
	dfhack_pointer extent_west;
	dfhack_pointer extent_north;
	int32_t body_height;
	int32_t dim_x;
	int32_t dim_y;
	dfhack_pointer roots;
	int32_t roots_depth;
	int16_t unk6;
} dfhack_plant_tree_info;

typedef struct {
	dfhack_std_string layer_name;
	int32_t tissue_id;
	dfhack_df_flagarray flags;
	int32_t part_fraction;
	int32_t healing_rate;
	int32_t vascular;
	int32_t pain_receptors;
	int32_t unk6;
	int16_t unk7;
	dfhack_std_vector_int32_t bp_modifiers;
	int32_t layer_id;
	int32_t parent_idx;
	int32_t parent_layer_id;
	int32_t layer_depth;
	int32_t leak_barrier_id;
	int32_t nonsolid_id;
	int32_t styleable_id;
} dfhack_body_part_layer_raw;

typedef struct {
	dfhack_std_string token;
	dfhack_std_string category;
	int16_t con_part_id;
	dfhack_df_flagarray flags;
	dfhack_std_vector_body_part_layer_raw_ptr layers;
	int32_t fraction_total;
	int32_t fraction_base;
	int32_t fraction_fat;
	int32_t fraction_muscle;
	int32_t relsize;
	int32_t number;
	int16_t unk7b;
	dfhack_std_vector_std_string_ptr name_singular;
	dfhack_std_vector_std_string_ptr name_plural;
	dfhack_pointer bp_relation_part_id;
	dfhack_pointer bp_relation_code;
	dfhack_pointer bp_relation_coverage;
	dfhack_uint16_t min_temp;
	dfhack_uint16_t max_temp;
	dfhack_uint16_t temp_factor;
	int32_t numbered_idx;
	int16_t insulation_fat;
	int16_t insulation_muscle;
	int16_t insulation_base;
	int32_t clothing_item_id;
} dfhack_body_part_raw;

typedef struct {
	dfhack_std_vector_int32_t pattern_index;
	dfhack_std_vector_int32_t pattern_frequency;
	vector_int16_t body_part_id;
	vector_int16_t tissue_layer_id;
	int16_t unk5;
	int32_t start_date;
	int32_t end_date;
	int32_t unk6;
	dfhack_std_string part;
	int16_t unk_6c;
	int16_t unk_6e;
	int32_t unk_70;
	int32_t id;
	dfhack_std_vector_std_string_ptr unk_78;
	dfhack_std_vector_std_string_ptr unk_88;
} dfhack_color_modifier_raw;

typedef struct {
	dfhack_enum type;
	dfhack_static-array ranges;
	dfhack_static-array desc_range;
	int32_t growth_rate;
	dfhack_enum growth_interval;
	int32_t growth_min;
	int32_t growth_max;
	int32_t growth_start;
	int32_t growth_end;
	int32_t importance;
	dfhack_std_string noun;
	int16_t unk_1;
	int16_t unk_2;
	int32_t id;
	int32_t id2;
} dfhack_body_appearance_modifier;

typedef struct {
	dfhack_enum type;
	dfhack_static-array ranges;
	dfhack_static-array desc_range;
	int32_t growth_rate;
	dfhack_enum growth_interval;
	int32_t growth_min;
	int32_t growth_max;
	int32_t growth_start;
	int32_t growth_end;
	int32_t importance;
	dfhack_std_string noun;
	int16_t single_plural;
	int16_t unk1;
	int32_t id1;
	vector_int16_t body_parts;
	vector_int16_t tissue_layer;
	int32_t id;
} dfhack_bp_appearance_modifier;

typedef struct {
	int16_t body_part_id;
	int32_t unk_4;
	dfhack_static-array item;
	dfhack_static-array unk_14;
	dfhack_static-array size;
	dfhack_static-array permit;
	dfhack_static-array unk_38;
} dfhack_caste_clothing_item;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string verb_3rd;
	dfhack_std_string verb_2nd;
	dfhack_uint16_t flags;
	dfhack_std_vector_int32_t specialattack_type;
	vector_int16_t specialattack_mat_type;
	dfhack_std_vector_int32_t specialattack_mat_index;
	dfhack_std_vector_matter_state specialattack_mat_state;
	dfhack_static-array specialattack_temp_mat;
	dfhack_std_vector_int32_t specialattack_min;
	dfhack_std_vector_int32_t specialattack_max;
	int32_t contact_perc;
	int32_t penetration_perc;
	int16_t unk_v40_1;
	int16_t unk_v40_2;
	vector_int16_t body_part_idx;
	vector_int16_t tissue_layer_idx;
	dfhack_enum skill;
	int32_t velocity_modifier;
	dfhack_std_vector_std_string_ptr specialattack_interaction_tmp_name;
	dfhack_std_vector_int32_t specialattack_interaction_id;
	int32_t unk_v40_3;
	int32_t unk_v40_4;
} dfhack_caste_attack;

typedef struct {
	int32_t action_string_idx;
	int32_t full_speed;
	int32_t buildup_time;
	int32_t turn_max;
	int32_t start_speed;
	int32_t energy_use;
	int32_t flags;
	int32_t stealth_slows;
} dfhack_gait_info;

typedef struct {
	dfhack_std_vector_std_string_ptr bp_required_type;
	dfhack_std_vector_std_string_ptr bp_required_name;
	dfhack_std_string unk_1;
	dfhack_std_string unk_2;
	dfhack_std_string material_str0;
	dfhack_std_string material_str1;
	dfhack_std_string material_str2;
	dfhack_enum material_breath;
	dfhack_std_string verb_2nd;
	dfhack_std_string verb_3rd;
	dfhack_std_string verb_mutual;
	dfhack_std_string verb_reverse_2nd;
	dfhack_std_string verb_reverse_3rd;
	dfhack_std_string target_verb_2nd;
	dfhack_std_string target_verb_3rd;
	dfhack_std_string interaction_type;
	int32_t type_id;
	dfhack_std_vector_interaction_source_usage_hint usage_hint;
	dfhack_std_vector_interaction_effect_location_hint location_hint;
	int32_t flags;
	dfhack_std_vector_std_string_ptr unk_3;
	dfhack_std_vector_creature_interaction_target_flags target_flags;
	dfhack_std_vector_int32_t target_ranges;
	dfhack_std_vector_std_string_ptr unk_4;
	dfhack_std_vector_int32_t max_target_numbers;
	dfhack_std_vector_int32_t verbal_speeches;
	dfhack_std_vector_void_ptr unk_5;
	dfhack_std_string adv_name;
	int32_t wait_period;
} dfhack_creature_interaction;

typedef struct {
	dfhack_std_vector_body_part_raw_ptr body_parts;
	dfhack_std_vector_caste_attack_ptr attacks;
	dfhack_std_vector_pointer interactions;
	dfhack_std_vector_pointer extra_butcher_objects;
	int32_t total_relsize;
	vector_int16_t layer_part;
	vector_int16_t layer_idx;
	dfhack_std_vector_uint32_t numbered_masks;
	dfhack_std_vector_void_ptr layer_nonsolid;
	dfhack_std_vector_void_ptr nonsolid_layers;
	int32_t flags;
	dfhack_static-array gait_info;
	dfhack_material_vec_ref materials;
	int32_t fraction_total;
	int32_t fraction_base;
	int32_t fraction_fat;
	int32_t fraction_muscle;
	dfhack_static-array unk_v40_2;
} dfhack_caste_body_info;

typedef struct {
	dfhack_std_string caste_id;
	dfhack_static-array caste_name;
	dfhack_std_string vermin_bite_txt;
	dfhack_std_string gnawer_txt;
	dfhack_static-array baby_name;
	dfhack_static-array child_name;
	dfhack_static-array itemcorpse_str;
	dfhack_static-array remains;
	dfhack_std_string description;
	dfhack_static-array mannerisms;
	dfhack_uint8_t caste_tile;
	dfhack_uint8_t caste_soldier_tile;
	dfhack_uint8_t caste_alttile;
	dfhack_uint8_t caste_soldier_alttile;
	dfhack_uint8_t caste_glowtile;
	dfhack_uint16_t homeotherm;
	dfhack_uint16_t min_temp;
	dfhack_uint16_t max_temp;
	dfhack_uint16_t fixed_temp;
	dfhack_static-array caste_color;
typedef struct {
	int32_t index;
	dfhack_static-array unk_4;
} dfhack_world_site_unk130;

typedef struct {
	int8_t tile;
	int16_t fg_color;
	int16_t bg_color;
	dfhack_std_string name;
	short2_t pos;
	int16_t left;
	int16_t right;
	int16_t top;
	int16_t bottom;
} dfhack_embark_note;

typedef struct {
	int16_t region_x;
	int16_t region_y;
	int16_t feature_idx;
	int32_t cave_id;
	int32_t unk_28;
	int32_t population_idx;
	dfhack_enum depth;
} dfhack_world_population_ref;

typedef struct {
	dfhack_enum type;
typedef struct {
	int32_t machine_id;
	int32_t flags;
} dfhack_machine_info;

typedef struct {
	int32_t produced;
	int32_t consumed;
} dfhack_power_info;

typedef struct {
	path3d_t tiles;
	dfhack_std_vector_bitfield can_connect;
} dfhack_machine_tile_set;

typedef struct {
	int32_t x;
	int32_t y;
	int32_t z;
	int32_t id;
	dfhack_std_vector_pointer components;
	int32_t cur_power;
	int32_t min_power;
	int8_t visual_phase;
	int16_t phase_timer;
	int32_t flags;
} dfhack_machine;

typedef dfhack_machine dfhack_machine_standardst;

typedef struct {
	dfhack_machine_info machine;
	dfhack_bool is_vertical;
} dfhack_building_axle_horizontalst;

typedef struct {
	dfhack_machine_info machine;
} dfhack_building_axle_verticalst;

typedef struct {
	dfhack_machine_info machine;
	int32_t gear_flags;
} dfhack_building_gear_assemblyst;

typedef struct {
	dfhack_machine_info machine;
	int16_t orient_x;
	int16_t orient_y;
	int16_t is_working;
	dfhack_bool visual_rotated;
	int16_t rotate_timer;
	int16_t orient_timer;
} dfhack_building_windmillst;

typedef struct {
	dfhack_machine_info machine;
	dfhack_bool is_vertical;
	dfhack_bool gives_power;
} dfhack_building_water_wheelst;

typedef struct {
	dfhack_machine_info machine;
	dfhack_uint8_t pump_energy;
	dfhack_enum direction;
	dfhack_bool pump_manually;
} dfhack_building_screw_pumpst;

typedef struct {
	dfhack_machine_info machine;
	dfhack_enum direction;
	int32_t speed;
} dfhack_building_rollersst;

typedef struct {
	dfhack_std_string name;
	int32_t id;
	dfhack_std_vector_std_string_ptr str;
	dfhack_df_flagarray flags;
	dfhack_std_vector_interaction_source_ptr sources;
	dfhack_std_vector_interaction_target_ptr targets;
	dfhack_std_vector_interaction_effect_ptr effects;
	int32_t source_hfid;
	int32_t source_enid;
} dfhack_interaction;

typedef struct {
	int32_t index;
	dfhack_std_vector_std_string_ptr targets;
	dfhack_std_vector_int32_t targets_index;
	int32_t intermittent;
	dfhack_std_vector_interaction_effect_location_hint locations;
	dfhack_uint32_t flags;
	int32_t interaction_id;
	dfhack_std_string arena_name;
} dfhack_interaction_effect;

typedef struct {
	int32_t unk_1;
	dfhack_std_vector_syndrome_ptr syndrome;
} dfhack_interaction_effect_animatest;

typedef struct {
	int32_t unk_1;
	dfhack_std_vector_syndrome_ptr syndrome;
} dfhack_interaction_effect_add_syndromest;

typedef struct {
	int32_t unk_1;
	dfhack_std_vector_syndrome_ptr syndrome;
} dfhack_interaction_effect_resurrectst;

typedef struct {
	int32_t grime_level;
	dfhack_syndrome_flags syndrome_tag;
	int32_t unk_1;
} dfhack_interaction_effect_cleanst;

typedef struct {
	int32_t unk_1;
} dfhack_interaction_effect_contactst;

typedef struct {
	int32_t unk_1;
} dfhack_interaction_effect_material_emissionst;

typedef struct {
	int32_t unk_1;
} dfhack_interaction_effect_hidest;

typedef struct {
	int32_t quality_added;
	int32_t quality_set;
} dfhack_interaction_effect_change_item_qualityst;

typedef struct {
	int32_t unk_1;
	int32_t unk_2;
} dfhack_interaction_effect_change_weatherst;

typedef struct {
	int32_t unk_1;
	dfhack_std_vector_syndrome_ptr syndrome;
} dfhack_interaction_effect_raise_ghostst;

typedef struct {
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mat_type;
	int32_t mat_index;
	int16_t probability;
	int16_t quantity;
	int32_t quality_min;
	int32_t quality_max;
	int32_t create_artifact;
	dfhack_std_string unk_1;
	dfhack_std_string unk_2;
	dfhack_std_string unk_3;
	dfhack_std_string unk_4;
	dfhack_std_string unk_5;
} dfhack_interaction_effect_create_itemst;

typedef struct {
	int32_t unk_1;
	int32_t propel_force;
} dfhack_interaction_effect_propel_unitst;

typedef struct {
	int32_t make_pet;
	dfhack_std_string race_str;
	dfhack_std_string caste_str;
	dfhack_std_vector_int32_t unk_1;
	vector_int16_t unk_2;
	dfhack_std_vector_int32_t required_creature_flags;
	dfhack_std_vector_int32_t forbidden_creature_flags;
	dfhack_std_vector_int32_t required_caste_flags;
	dfhack_std_vector_int32_t forbidden_caste_flags;
	int32_t unk_3;
	int32_t unk_4;
	int32_t time_range_min;
	int32_t time_range_max;
} dfhack_interaction_effect_summon_unitst;

typedef struct {
	int32_t id;
	int32_t frequency;
	dfhack_std_string name;
	dfhack_std_string hist_string_1;
	dfhack_std_string hist_string_2;
	dfhack_std_string trigger_string_second;
	dfhack_std_string trigger_string_third;
	dfhack_std_string trigger_string;
} dfhack_interaction_source;

typedef struct {
	dfhack_uint32_t region_flags;
	dfhack_static-array regions;
} dfhack_interaction_source_regionst;

typedef struct {
	dfhack_uint32_t learn_flags;
	dfhack_std_vector_enum spheres;
	dfhack_std_vector_goal_type goals;
	dfhack_std_string book_title_filename;
	dfhack_std_string book_name_filename;
	int32_t unk_1;
	int32_t unk_2;
} dfhack_interaction_source_secretst;

typedef struct {
	int32_t unk_1;
} dfhack_interaction_source_disturbancest;

typedef struct {
	int32_t unk_1;
	dfhack_std_vector_interaction_source_usage_hint usage_hint;
} dfhack_interaction_source_deityst;

typedef struct {
	int32_t unk_1;
} dfhack_interaction_source_attackst;

typedef struct {
	int32_t unk_1;
} dfhack_interaction_source_ingestionst;

typedef struct {
	int32_t unk_1;
} dfhack_interaction_source_creature_actionst;

typedef dfhack_interaction_source dfhack_interaction_source_underground_specialst;

typedef struct {
	int32_t unk_1;
} dfhack_interaction_source_experimentst;

typedef struct {
	int32_t index;
	dfhack_std_string name;
	dfhack_std_string manual_input;
	dfhack_enum location;
	dfhack_std_string reference_name;
	int32_t reference_distance;
} dfhack_interaction_target;

typedef struct {
	dfhack_static-array affected_creature_str;
	dfhack_std_vector_int32_t affected_creature;
	dfhack_std_vector_std_string_ptr affected_class;
	dfhack_static-array immune_creature_str;
	dfhack_std_vector_int32_t immune_creature;
	dfhack_std_vector_std_string_ptr immune_class;
	dfhack_std_vector_std_string_ptr forbidden_syndrome_class;
	int32_t requires_1;
	int32_t requires_2;
	int32_t forbidden_1;
	int32_t forbidden_2;
	dfhack_uint32_t restrictions;
} dfhack_interaction_target_info;

typedef struct {
	dfhack_interaction_target_info target_info;
} dfhack_interaction_target_corpsest;

typedef struct {
	dfhack_interaction_target_info target_info;
} dfhack_interaction_target_creaturest;

typedef struct {
	dfhack_static-array material_str;
	int16_t mat_type;
	int32_t mat_index;
	int16_t parent_interaction_index;
	dfhack_enum breath_attack_type;
	dfhack_uint32_t restrictions;
} dfhack_interaction_target_materialst;

typedef dfhack_interaction_target dfhack_interaction_target_locationst;

typedef struct {
	int32_t id;
	int32_t interaction_id;
	int32_t unk_1;
	int32_t region_index;
	dfhack_std_vector_int32_t affected_units;
} dfhack_interaction_instance;

typedef struct {
	int32_t count;
} dfhack_art_image_element;

typedef struct {
	int32_t race;
	int16_t caste;
	int32_t histfig;
} dfhack_art_image_element_creaturest;

typedef struct {
	int32_t plant_id;
} dfhack_art_image_element_plantst;

typedef struct {
	int32_t plant_id;
} dfhack_art_image_element_treest;

typedef struct {
	int32_t shape_id;
	int16_t shape_adj;
} dfhack_art_image_element_shapest;

typedef struct {
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mat_type;
	int16_t mat_index;
	dfhack_item_flags flags;
	int32_t item_id;
} dfhack_art_image_element_itemst;

typedef struct {
	dfhack_df_flagarray flags;
} dfhack_art_image_property;

typedef struct {
	int32_t subject;
	int32_t object;
	dfhack_enum verb;
} dfhack_art_image_property_transitive_verbst;

typedef struct {
	int32_t subject;
	dfhack_enum verb;
} dfhack_art_image_property_intransitive_verbst;

typedef struct {
	dfhack_std_vector_art_image_element_ptr elements;
	dfhack_std_vector_art_image_property_ptr properties;
	int32_t event;
	dfhack_language_name name;
	dfhack_enum spec_ref_type;
	int16_t mat_type;
	int32_t mat_index;
	dfhack_enum quality;
	int32_t artist;
	int32_t site;
	dfhack_pointer ref;
	int32_t year;
	int32_t unk_1;
	int32_t id;
	int16_t subid;
} dfhack_art_image;

typedef struct {
	int32_t id;
	dfhack_static-array images;
} dfhack_art_image_chunk;

typedef struct {
	int32_t id;
	int16_t subid;
	int32_t civ_id;
	int32_t site_id;
} dfhack_art_image_ref;

typedef struct {
typedef struct {
	dfhack_std_string id;
	dfhack_std_vector_std_string_ptr word_unk;
	dfhack_std_vector_int32_t words;
	dfhack_std_string name;
	dfhack_enum color;
	int8_t bold;
	dfhack_s-float red;
	dfhack_s-float green;
	dfhack_s-float blue;
} dfhack_descriptor_color;

typedef struct {
	dfhack_std_string id;
	dfhack_std_vector_std_string_ptr words_str;
	dfhack_std_vector_int32_t words;
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_vector_std_string_ptr adj;
	int32_t gems_use;
	dfhack_std_vector_std_string_ptr category;
	int32_t faces;
	dfhack_uint8_t tile;
} dfhack_descriptor_shape;

typedef struct {
	dfhack_std_string id;
	vector_int16_t colors;
	dfhack_enum pattern;
	dfhack_std_vector_std_string_ptr cp_color;
} dfhack_descriptor_pattern;

typedef struct {
	dfhack_std_vector_enum mode;
	dfhack_std_vector_std_string_ptr key;
	dfhack_std_vector_std_string_ptr tissue;
} dfhack_creature_interaction_effect_target;

typedef struct {
	dfhack_creature_interaction_effect_flags flags;
	int32_t prob;
	int32_t start;
	int32_t peak;
	int32_t end;
	int32_t dwf_stretch;
	int32_t syn_id;
	int32_t id;
	int32_t syn_index;
	int32_t moon_phase_min;
	int32_t moon_phase_max;
typedef struct {
	int32_t id;
	dfhack_std_string script_file;
	dfhack_std_vector_script_stepst_ptr script_steps;
	dfhack_std_vector_script_varst_ptr script_vars;
	dfhack_std_string code;
} dfhack_dipscript_info;

typedef struct {
	dfhack_pointer meeting_holder;
	dfhack_pointer activity;
	int32_t flags;
} dfhack_dipscript_popup;

typedef struct {
	int32_t next_step_idx;
} dfhack_script_stepst;

typedef struct {
	dfhack_std_string dest_type;
	dfhack_std_string dest_name;
	dfhack_std_string src_type;
	dfhack_std_string src_name;
} dfhack_script_step_setvarst;

typedef struct {
	dfhack_std_string type;
	dfhack_std_string subtype;
} dfhack_script_step_simpleactionst;

typedef struct {
typedef struct {
	dfhack_std_vector_creature_raw_ptr alphabetic;
	dfhack_std_vector_creature_raw_ptr all;
	int32_t num_caste;
	dfhack_std_vector_int32_t list_creature;
	dfhack_std_vector_int32_t list_caste;
	dfhack_std_vector_std_string_ptr action_strings;
} dfhack_creature_handler;

typedef struct {
	dfhack_std_vector_material_template_ptr material_templates;
	dfhack_std_vector_inorganic_raw_ptr inorganics;
	dfhack_std_vector_inorganic_raw_ptr inorganics_subset;
typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t dyer;
	dfhack_enum quality;
	dfhack_enum skill_rating;
	int32_t unk_1;
} dfhack_dye_info;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t maker;
	int32_t masterpiece_event;
	dfhack_enum quality;
	dfhack_enum skill_rating;
	int32_t unk_1;
} dfhack_itemimprovement;

typedef struct {
	dfhack_art_image_ref image;
} dfhack_itemimprovement_art_imagest;

typedef struct {
	int32_t cover_flags;
	int32_t shape;
} dfhack_itemimprovement_coveredst;

typedef dfhack_itemimprovement dfhack_itemimprovement_rings_hangingst;

typedef struct {
	int32_t shape;
} dfhack_itemimprovement_bandsst;

typedef dfhack_itemimprovement dfhack_itemimprovement_spikesst;

typedef struct {
	dfhack_enum type;
} dfhack_itemimprovement_itemspecificst;

typedef struct {
	dfhack_dye_info dye;
} dfhack_itemimprovement_threadst;

typedef dfhack_itemimprovement dfhack_itemimprovement_clothst;

typedef struct {
	dfhack_art_image_ref image;
typedef struct {
	int32_t id;
	dfhack_pointer list_link;
	int32_t posting_index;
	dfhack_enum job_type;
	int32_t job_subtype;
	short3_t pos;
	int32_t completion_timer;
	dfhack_uint32_t unk4;
	dfhack_job_flags flags;
	int16_t mat_type;
	int32_t mat_index;
	int16_t unk5;
	dfhack_enum item_type;
	int16_t item_subtype;
	dfhack_stockpile_group_set item_category;
typedef struct {
} dfhack_general_ref;

typedef struct {
	int32_t artifact_id;
} dfhack_general_ref_artifact;

typedef struct {
	int32_t nemesis_id;
} dfhack_general_ref_nemesis;

typedef struct {
	int32_t item_id;
	int32_t cached_index;
} dfhack_general_ref_item;

typedef struct {
	dfhack_enum type;
	int32_t subtype;
	int16_t mat_type;
	int16_t mat_index;
} dfhack_general_ref_item_type;

typedef struct {
	int32_t batch;
} dfhack_general_ref_coinbatch;

typedef struct {
	dfhack_enum tiletype;
	int16_t mat_type;
	int32_t mat_index;
} dfhack_general_ref_mapsquare;

typedef struct {
	int32_t entity_id;
	int32_t index;
} dfhack_general_ref_entity_art_image;

typedef struct {
	int32_t projectile_id;
} dfhack_general_ref_projectile;

typedef struct {
	int32_t unit_id;
	int32_t cached_index;
} dfhack_general_ref_unit;

typedef struct {
	int32_t building_id;
} dfhack_general_ref_building;

typedef struct {
	int32_t entity_id;
} dfhack_general_ref_entity;

typedef struct {
	int32_t x;
	int32_t y;
	int32_t z;
} dfhack_general_ref_locationst;

typedef struct {
	int32_t interaction_id;
	int32_t source_id;
	int32_t unk_08;
	int32_t unk_0c;
} dfhack_general_ref_interactionst;

typedef struct {
	int32_t site_id;
	int32_t building_id;
} dfhack_general_ref_abstract_buildingst;

typedef struct {
	int32_t event_id;
} dfhack_general_ref_historical_eventst;

typedef struct {
	dfhack_enum sphere_type;
} dfhack_general_ref_spherest;

typedef struct {
	int32_t site_id;
} dfhack_general_ref_sitest;

typedef struct {
	int32_t region_id;
} dfhack_general_ref_subregionst;

typedef struct {
	int32_t underground_region_id;
} dfhack_general_ref_feature_layerst;

typedef struct {
	int32_t hist_figure_id;
} dfhack_general_ref_historical_figurest;

typedef struct {
	int32_t unk_1;
	int32_t race;
	int32_t unk_2;
	dfhack_undead_flags flags;
} dfhack_general_ref_entity_popst;

typedef struct {
	int32_t race;
	int32_t caste;
	int32_t unk_1;
	int32_t unk_2;
	dfhack_undead_flags flags;
} dfhack_general_ref_creaturest;

typedef struct {
	dfhack_knowledge_scholar_category_flag knowledge;
} dfhack_general_ref_knowledge_scholar_flagst;

typedef struct {
	int32_t activity_id;
	int32_t event_id;
} dfhack_general_ref_activity_eventst;

typedef struct {
	dfhack_enum value;
	int32_t level;
} dfhack_general_ref_value_levelst;

typedef struct {
	int32_t unk_1;
} dfhack_general_ref_languagest;

typedef struct {
	int32_t written_content_id;
} dfhack_general_ref_written_contentst;

typedef struct {
	int32_t poetic_form_id;
} dfhack_general_ref_poetic_formst;

typedef struct {
	int32_t musical_form_id;
} dfhack_general_ref_musical_formst;

typedef struct {
	int32_t dance_form_id;
} dfhack_general_ref_dance_formst;

typedef dfhack_general_ref_artifact dfhack_general_ref_is_artifactst;

typedef dfhack_general_ref_nemesis dfhack_general_ref_is_nemesisst;

typedef dfhack_general_ref_unit dfhack_general_ref_contains_unitst;

typedef dfhack_general_ref_item dfhack_general_ref_contains_itemst;

typedef dfhack_general_ref_item dfhack_general_ref_contained_in_itemst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_milkeest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_traineest;

typedef struct {
	int32_t flags;
} dfhack_general_ref_unit_itemownerst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_tradebringerst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_holderst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_workerst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_cageest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_beateest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_foodreceiverst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_kidnapeest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_patientst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_infantst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_slaughtereest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_sheareest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_suckeest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_reporteest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_riderst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_climberst;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_geldeest;

typedef dfhack_general_ref_unit dfhack_general_ref_unit_interrogateest;

typedef dfhack_general_ref_building dfhack_general_ref_building_civzone_assignedst;

typedef dfhack_general_ref_building dfhack_general_ref_building_triggerst;

typedef dfhack_general_ref_building dfhack_general_ref_building_triggertargetst;

typedef dfhack_general_ref_building dfhack_general_ref_building_chainst;

typedef dfhack_general_ref_building dfhack_general_ref_building_cagedst;

typedef dfhack_general_ref_building dfhack_general_ref_building_holderst;

typedef struct {
	int8_t direction;
} dfhack_general_ref_building_well_tag;

typedef dfhack_general_ref_building dfhack_general_ref_building_use_target_1st;

typedef dfhack_general_ref_building dfhack_general_ref_building_use_target_2st;

typedef dfhack_general_ref_building dfhack_general_ref_building_destinationst;

typedef dfhack_general_ref_building dfhack_general_ref_building_nest_boxst;

typedef dfhack_general_ref_building dfhack_general_ref_building_display_furniturest;

typedef dfhack_general_ref_entity dfhack_general_ref_entity_stolenst;

typedef dfhack_general_ref_entity dfhack_general_ref_entity_offeredst;

typedef dfhack_general_ref_entity dfhack_general_ref_entity_itemownerst;

typedef struct {
	dfhack_enum type;
typedef struct {
	int32_t id;
	dfhack_std_string name;
	dfhack_uint8_t tile;
	int16_t fg_color;
	int16_t bg_color;
	dfhack_std_vector_int32_t block_x;
	dfhack_std_vector_int32_t block_y;
	dfhack_std_vector_int32_t block_z;
	dfhack_std_vector_int32_t units;
	int32_t limit_workshops;
} dfhack_burrow;

typedef struct {
	dfhack_std_string name;
	dfhack_enum cmd;
	int32_t x;
	int32_t y;
	int32_t z;
typedef struct {
	dfhack_language_name name;
	dfhack_std_string custom_profession;
	dfhack_enum profession;
	dfhack_enum profession2;
	int32_t race;
	short3_t pos;
	short3_t idle_area;
	int32_t idle_area_threshold;
	dfhack_enum idle_area_type;
	int32_t follow_distance;
typedef struct {
	dfhack_enum type;
	int16_t value;
	int16_t unk_1;
	int32_t flags;
} dfhack_item_magicness;

typedef struct {
	dfhack_uint16_t whole;
	int16_t fraction;
} dfhack_temperaturest;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	dfhack_enum mat_state;
	dfhack_temperaturest temperature;
	int32_t size;
	dfhack_uint16_t base_flags;
	dfhack_padding pad_1;
} dfhack_spatter_common;

typedef struct {
	int16_t body_part_id;
	dfhack_uint16_t flags;
} dfhack_spatter;

typedef struct {
	short3_t pos;
	dfhack_item_flags flags;
	dfhack_item_flags2 flags2;
	dfhack_uint32_t age;
	int32_t id;
	dfhack_std_vector_specific_ref_ptr specific_refs;
	dfhack_std_vector_general_ref_ptr general_refs;
	int32_t world_data_id;
	int32_t world_data_subid;
	dfhack_uint8_t stockpile_countdown;
	dfhack_uint8_t stockpile_delay;
	int16_t unk2;
	int32_t base_uniform_score;
	int16_t walkable_id;
	dfhack_uint16_t spec_heat;
	dfhack_uint16_t ignite_point;
	dfhack_uint16_t heatdam_point;
	dfhack_uint16_t colddam_point;
	dfhack_uint16_t boiling_point;
	dfhack_uint16_t melting_point;
	dfhack_uint16_t fixed_temp;
	int32_t weight;
	int32_t weight_fraction;
} dfhack_item;

typedef struct {
	dfhack_historical_kills targets;
	dfhack_std_vector_int32_t slayers;
	dfhack_std_vector_int32_t slayer_kill_counts;
} dfhack_item_kill_info;

typedef struct {
	dfhack_pointer kills;
	int32_t attack_counter;
	int32_t defence_counter;
} dfhack_item_history_info;

typedef struct {
	int32_t stack_size;
	dfhack_pointer history_info;
	dfhack_pointer magic;
	dfhack_pointer contaminants;
	dfhack_temperaturest temperature;
	int16_t wear;
	int32_t wear_timer;
	int32_t unk_1;
	int32_t temp_updated_frame;
} dfhack_item_actual;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int16_t maker_race;
	dfhack_enum quality;
	dfhack_enum skill_rating;
	int32_t maker;
	int32_t masterpiece_event;
} dfhack_item_crafted;

typedef struct {
	dfhack_std_vector_itemimprovement_ptr improvements;
} dfhack_item_constructed;

typedef struct {
	dfhack_std_vector_body_part_status body_part_status;
	dfhack_std_vector_uint32_t numbered_masks;
	dfhack_std_vector_uint32_t nonsolid_remaining;
	dfhack_std_vector_body_layer_status layer_status;
	dfhack_std_vector_uint32_t layer_wound_area;
	dfhack_std_vector_uint32_t layer_cut_fraction;
	dfhack_std_vector_uint32_t layer_dent_fraction;
	dfhack_std_vector_uint32_t layer_effect_fraction;
} dfhack_body_component_info;

typedef struct {
	int32_t size_cur;
	int32_t size_base;
	int32_t area_cur;
	int32_t area_base;
	int32_t length_cur;
	int32_t length_base;
} dfhack_body_size_info;

typedef struct {
	int16_t race;
	int32_t hist_figure_id;
	int32_t unit_id;
	int16_t caste;
	dfhack_enum sex;
	int16_t normal_race;
	int16_t normal_caste;
	int32_t rot_timer;
	int8_t unk_8c;
typedef struct {
	dfhack_std_string id;
	int32_t index;
	dfhack_std_vector_std_string_ptr raws;
	dfhack_df_flagarray flags;
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string adj;
	dfhack_std_string seed_singular;
	dfhack_std_string seed_plural;
	dfhack_std_string leaves_singular;
	dfhack_std_string leaves_plural;
	int32_t source_hfid;
	int32_t unk_v4201_1;
	dfhack_uint8_t unk1;
	dfhack_uint8_t unk2;
typedef struct {
	dfhack_std_string code;
	dfhack_std_string name;
	dfhack_df_flagarray flags;
	dfhack_std_vector_reaction_reagent_ptr reagents;
	dfhack_std_vector_reaction_product_ptr products;
	dfhack_enum skill;
	int32_t max_multiplier;
typedef struct {
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
} dfhack_resource_allotment_specifier;

typedef struct {
	int32_t mat_type;
	int32_t unk_4;
	int32_t unk_v40_01;
	dfhack_static-array unk_5;
} dfhack_resource_allotment_specifier_cropst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
	int32_t unk_5;
	dfhack_static-array unk_6;
} dfhack_resource_allotment_specifier_stonest;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
	dfhack_static-array unk_5;
} dfhack_resource_allotment_specifier_metalst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
	int32_t unk_5;
	int32_t unk_6;
	int32_t unk_7;
	int32_t unk_8;
	int32_t unk_9;
} dfhack_resource_allotment_specifier_woodst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_armor_bodyst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_armor_pantsst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_armor_glovesst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_armor_bootsst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_armor_helmst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_clothing_bodyst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_clothing_pantsst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_clothing_glovesst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_clothing_bootsst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_clothing_helmst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_weapon_meleest;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_weapon_rangedst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_ammost;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_anvilst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_gemsst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
} dfhack_resource_allotment_specifier_threadst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
	int32_t unk_5;
	int32_t unk_6;
	int32_t unk_7;
	int32_t unk_8;
} dfhack_resource_allotment_specifier_clothst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
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
} dfhack_resource_allotment_specifier_leatherst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_quiverst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_backpackst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_flaskst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_bagst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_tablest;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_cabinetst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_chairst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_boxst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_bedst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_craftsst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_meatst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
} dfhack_resource_allotment_specifier_bonest;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
} dfhack_resource_allotment_specifier_hornst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
} dfhack_resource_allotment_specifier_shellst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_tallowst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
} dfhack_resource_allotment_specifier_toothst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_pearlst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_soapst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
	int16_t mat_type2;
	int32_t mat_index2;
	int32_t unk_5;
} dfhack_resource_allotment_specifier_extractst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
} dfhack_resource_allotment_specifier_cheesest;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int16_t mat_type2;
	int32_t mat_index2;
	int32_t unk_4;
} dfhack_resource_allotment_specifier_skinst;

typedef struct {
	int16_t mat_type;
	int32_t mat_index;
	int32_t unk_4;
} dfhack_resource_allotment_specifier_powderst;

typedef struct {
	int32_t index;
	dfhack_static-array resource_allotments;
	int32_t unk1;
	int32_t unk2;
	int32_t unk3;
	int32_t unk_650;
	dfhack_std_vector_pointer unk_654;
} dfhack_resource_allotment_data;

typedef struct {
typedef struct {
	dfhack_std_string word;
	dfhack_static-array forms;
	dfhack_uint8_t adj_dist;
	dfhack_padding pad_1;
	dfhack_language_word_flags flags;
	dfhack_std_vector_std_string_ptr str;
} dfhack_language_word;

typedef struct {
	dfhack_std_string name;
	dfhack_std_vector_std_string_ptr unknown1;
	dfhack_std_vector_std_string_ptr unknown2;
	dfhack_std_vector_std_string_ptr words;
	int32_t flags;
	dfhack_std_vector_std_string_ptr str;
} dfhack_language_translation;

typedef struct {
	dfhack_std_string name;
	dfhack_std_vector_void_ptr unknown;
	dfhack_std_vector_int32_t words;
	int32_t flags;
	dfhack_std_vector_std_string_ptr str;
} dfhack_language_symbol;

typedef struct {
	dfhack_std_string first_name;
	dfhack_std_string nickname;
	dfhack_static-array words;
	dfhack_static-array parts_of_speech;
	int32_t language;
	dfhack_enum type;
	dfhack_bool has_name;
} dfhack_language_name;

typedef struct {
	dfhack_static-array words;
	dfhack_static-array parts;
} dfhack_language_word_table;

typedef struct {
	dfhack_pointer extents;
	int32_t x;
	int32_t y;
	int32_t width;
	int32_t height;
} dfhack_building_extents;

typedef struct {
	dfhack_static-array tile;
	dfhack_static-array fore;
	dfhack_static-array back;
	dfhack_static-array bright;
	int16_t x1;
	int16_t x2;
	int16_t y1;
	int16_t y2;
} dfhack_building_drawbuffer;

typedef struct {
	int32_t x1;
	int32_t y1;
	int32_t centerx;
	int32_t x2;
	int32_t y2;
	int32_t centery;
	int32_t z;
	dfhack_building_flags flags;
	int16_t mat_type;
	int32_t mat_index;
	dfhack_building_extents room;
	int32_t age;
	int16_t race;
	int32_t id;
	dfhack_std_vector_job_ptr jobs;
	dfhack_std_vector_specific_ref_ptr specific_refs;
	dfhack_std_vector_general_ref_ptr general_refs;
	dfhack_bool is_room;
	dfhack_std_vector_building_ptr children;
	dfhack_std_vector_building_ptr parents;
	int32_t owner_id;
	dfhack_pointer owner;
	dfhack_std_vector_pointer job_claim_suppress;
	dfhack_std_string name;
	dfhack_std_vector_pointer activities;
	int32_t world_data_id;
	int32_t world_data_subid;
	int32_t unk_v40_2;
	int32_t site_id;
	int32_t location_id;
	int32_t unk_v40_3;
} dfhack_building;

typedef struct {
	dfhack_std_vector_building_ptr give_to_pile;
	dfhack_std_vector_building_ptr take_from_pile;
	dfhack_std_vector_building_ptr give_to_workshop;
	dfhack_std_vector_building_ptr take_from_workshop;
} dfhack_stockpile_links;

typedef struct {
	dfhack_stockpile_settings settings;
	int16_t max_barrels;
	int16_t max_bins;
	int16_t max_wheelbarrows;
	dfhack_std_vector_enum container_type;
	dfhack_std_vector_int32_t container_item_id;
	vector_int16_t container_x;
	vector_int16_t container_y;
	dfhack_stockpile_links links;
	int32_t use_links_only;
	int32_t stockpile_number;
	dfhack_std_vector_hauling_stop_ptr linked_stops;
} dfhack_building_stockpilest;

typedef struct {
	dfhack_uint32_t supplies_needed;
	int32_t max_splints;
	int32_t max_thread;
	int32_t max_cloth;
	int32_t max_crutches;
	int32_t max_plaster;
	int32_t max_buckets;
	int32_t max_soap;
	int32_t cur_splints;
	int32_t cur_thread;
	int32_t cur_cloth;
	int32_t cur_crutches;
	int32_t cur_plaster;
	int32_t cur_buckets;
	int32_t cur_soap;
	int32_t supply_recheck_timer;
} dfhack_hospital_supplies;

typedef struct {
	dfhack_std_vector_int32_t assigned_units;
	dfhack_std_vector_int32_t assigned_items;
	dfhack_enum type;
	dfhack_uint32_t zone_flags;
	int32_t unk_1;
	int32_t unk_2;
	int32_t zone_num;
	int32_t unk_3;
	dfhack_uint32_t pit_flags;
	int16_t fill_timer;
	dfhack_hospital_supplies hospital;
	dfhack_uint32_t gather_flags;
	int32_t gather_update_cooldown;
	dfhack_std_vector_int32_t unk_v43_1;
} dfhack_building_civzonest;

typedef struct {
	int16_t construction_stage;
	dfhack_std_vector_pointer contained_items;
	dfhack_pointer design;
} dfhack_building_actual;

typedef struct {
	int32_t architect;
	int32_t unk2;
	int16_t design_skill;
	int32_t builder1;
	int32_t unk5;
	int16_t build_skill;
	int16_t build_timer1;
	int32_t builder2;
	int16_t build_timer2;
	dfhack_enum quality1;
	dfhack_enum quality2;
	dfhack_uint32_t flags;
	int32_t hitpoints;
	int32_t max_hitpoints;
} dfhack_building_design;

typedef struct {
	dfhack_std_vector_int32_t melt_remainder;
	int16_t unk_108;
	dfhack_enum type;
	dfhack_workshop_profile profile;
	int32_t custom_type;
} dfhack_building_furnacest;

typedef struct {
	dfhack_std_vector_int32_t permitted_workers;
	int32_t min_level;
	int32_t max_level;
	dfhack_stockpile_links links;
	int32_t max_general_orders;
	dfhack_bool block_general_orders;
	dfhack_padding pad_1;
	dfhack_static-array blocked_labors;
} dfhack_workshop_profile;

typedef struct {
	dfhack_enum type;
	dfhack_workshop_profile profile;
	dfhack_machine_info machine;
	int32_t custom_type;
} dfhack_building_workshopst;

typedef struct {
	int16_t bait_type;
	int16_t fill_timer;
} dfhack_building_animaltrapst;

typedef struct {
	dfhack_enum archery_direction;
} dfhack_building_archerytargetst;

typedef struct {
	int16_t unk_c0;
	dfhack_std_vector_building_squad_use_ptr squads;
	int32_t specific_squad;
	int32_t specific_position;
} dfhack_building_armorstandst;

typedef struct {
	dfhack_gate_flags gate_flags;
	int8_t timer;
} dfhack_building_bars_verticalst;

typedef struct {
	dfhack_gate_flags gate_flags;
	int8_t timer;
} dfhack_building_bars_floorst;

typedef struct {
	dfhack_std_vector_int32_t unit;
	vector_int16_t mode;
} dfhack_building_users;

typedef struct {
	dfhack_uint16_t bed_flags;
	dfhack_std_vector_building_squad_use_ptr squads;
	int32_t specific_squad;
	int32_t specific_position;
	dfhack_building_users users;
} dfhack_building_bedst;

typedef dfhack_building_actual dfhack_building_bookcasest;

typedef struct {
	int16_t unk_1;
	dfhack_std_vector_building_squad_use_ptr squads;
	int32_t specific_squad;
	int32_t specific_position;
} dfhack_building_boxst;

typedef struct {
	dfhack_gate_flags gate_flags;
	int8_t timer;
	dfhack_enum direction;
	int32_t material_amount;
} dfhack_building_bridgest;

typedef struct {
	int16_t unk_1;
	dfhack_std_vector_building_squad_use_ptr squads;
	int32_t specific_squad;
	int32_t specific_position;
} dfhack_building_cabinetst;

typedef struct {
	dfhack_std_vector_int32_t assigned_units;
	dfhack_std_vector_int32_t assigned_items;
	dfhack_uint16_t cage_flags;
	int16_t fill_timer;
} dfhack_building_cagest;

typedef struct {
	dfhack_pointer assigned;
	dfhack_pointer chained;
	dfhack_uint16_t chain_flags;
} dfhack_building_chainst;

typedef struct {
	int16_t unk_1;
	dfhack_building_users users;
} dfhack_building_chairst;

typedef struct {
	dfhack_uint16_t burial_mode;
} dfhack_building_coffinst;

typedef struct {
	dfhack_enum type;
} dfhack_building_constructionst;

typedef struct {
	dfhack_std_vector_int32_t displayed_items;
} dfhack_building_display_furniturest;

typedef struct {
	dfhack_door_flags door_flags;
	int16_t close_timer;
} dfhack_building_doorst;

typedef struct {
	dfhack_static-array plant_id;
	int32_t material_amount;
	int32_t farm_flags;
	dfhack_enum last_season;
	int32_t current_fertilization;
	int32_t max_fertilization;
	int16_t terrain_purge_timer;
} dfhack_building_farmplotst;

typedef struct {
	dfhack_gate_flags gate_flags;
	int8_t timer;
} dfhack_building_floodgatest;

typedef struct {
	dfhack_gate_flags gate_flags;
	int8_t timer;
} dfhack_building_grate_floorst;

typedef struct {
	dfhack_gate_flags gate_flags;
	int8_t timer;
} dfhack_building_grate_wallst;

typedef struct {
	dfhack_door_flags door_flags;
	int16_t close_timer;
} dfhack_building_hatchst;

typedef struct {
	dfhack_hive_flags hive_flags;
	int32_t split_timer;
	int32_t activity_timer;
	int32_t install_timer;
	int32_t gather_timer;
} dfhack_building_hivest;

typedef struct {
	int32_t unk_1;
} dfhack_building_instrumentst;

typedef dfhack_building_actual dfhack_building_nestst;

typedef struct {
	int32_t claimed_by;
	int32_t claim_timeout;
} dfhack_building_nest_boxst;

typedef dfhack_building_actual dfhack_building_offering_placest;

typedef dfhack_building_actual dfhack_building_roadst;

typedef struct {
	int32_t material_amount;
} dfhack_building_road_dirtst;

typedef struct {
	int32_t material_amount;
	int16_t terrain_purge_timer;
} dfhack_building_road_pavedst;

typedef struct {
	dfhack_pointer owner;
	int32_t timer;
	int16_t shop_flags;
	dfhack_enum type;
} dfhack_building_shopst;

typedef struct {
	dfhack_enum type;
	dfhack_enum facing;
	dfhack_enum action;
	int8_t fire_timer;
	int16_t fill_timer;
} dfhack_building_siegeenginest;

typedef struct {
	int16_t unk_1;
} dfhack_building_slabst;

typedef struct {
	int16_t unk_1;
} dfhack_building_statuest;

typedef struct {
	dfhack_uint16_t support_flags;
} dfhack_building_supportst;

typedef struct {
	int16_t table_flags;
	dfhack_building_users users;
} dfhack_building_tablest;

typedef struct {
	int16_t unk_1;
	dfhack_building_users users;
} dfhack_building_traction_benchst;

typedef struct {
	dfhack_uint32_t trade_flags;
	int8_t accessible;
} dfhack_building_tradedepotst;

typedef struct {
	int32_t unit_min;
	int32_t unit_max;
	int8_t water_min;
	int8_t water_max;
	int8_t magma_min;
	int8_t magma_max;
	int32_t track_min;
	int32_t track_max;
	int32_t flags;
} dfhack_pressure_plate_info;

typedef struct {
	dfhack_enum trap_type;
	dfhack_uint8_t state;
	int16_t ready_timeout;
	int16_t fill_timer;
	dfhack_uint16_t stop_flags;
	dfhack_std_vector_item_ptr linked_mechanisms;
	dfhack_std_vector_int32_t observed_by_civs;
	dfhack_workshop_profile profile;
	dfhack_pressure_plate_info plate_info;
	int32_t friction;
	int32_t use_dump;
	int32_t dump_x_shift;
	int32_t dump_y_shift;
	int8_t stop_trigger_timer;
} dfhack_building_trapst;

typedef dfhack_building_actual dfhack_building_wagonst;

typedef struct {
	dfhack_gate_flags gate_flags;
	int8_t timer;
} dfhack_building_weaponst;

typedef struct {
	int32_t squad_id;
	dfhack_squad_use_flags mode;
} dfhack_building_squad_use;

typedef struct {
	int16_t unk_c0;
	dfhack_std_vector_building_squad_use_ptr squads;
	int32_t specific_squad;
} dfhack_building_weaponrackst;

typedef struct {
	int16_t well_flags;
	int8_t unk_1;
	int16_t bucket_z;
	int8_t bucket_timer;
	int16_t check_water_timer;
} dfhack_building_wellst;

typedef struct {
	int16_t unk_1;
} dfhack_building_windowst;

typedef dfhack_building_windowst dfhack_building_window_glassst;

typedef dfhack_building_windowst dfhack_building_window_gemst;

typedef struct {
typedef struct {
	dfhack_stockpile_group_set flags;
typedef struct {
	dfhack_static-array flags;
	dfhack_pointer unused;
} dfhack_announcements;

typedef struct {
	dfhack_enum type;
	dfhack_std_string text;
	int16_t color;
	dfhack_bool bright;
	int32_t duration;
	dfhack_uint8_t flags;
	int32_t repeat_count;
	dfhack_enum zoom_type;
	short3_t pos;
	dfhack_enum zoom_type2;
	short3_t pos2;
	int32_t id;
	int32_t year;
	int32_t time;
	int32_t unk_v40_1;
	int32_t unk_v40_2;
	int32_t speaker_id;
} dfhack_report;

typedef struct {
	dfhack_std_string text;
	int16_t color;
	dfhack_bool bright;
} dfhack_popup_message;

typedef struct {
	dfhack_enum type;
	int16_t color;
	dfhack_bool bright;
	short3_t pos;
	dfhack_enum zoom_type;
	short3_t pos2;
	dfhack_enum zoom_type2;
	int16_t display_timer;
	dfhack_pointer unit1;
	dfhack_pointer unit2;
	int32_t unk_v40_1;
	int32_t unk_v40_2;
	int32_t speaker_id;
	dfhack_uint8_t flags;
} dfhack_report_init;

typedef struct {
	dfhack_std_string id;
	dfhack_std_string gem_name1;
	dfhack_std_string gem_name2;
	dfhack_std_string stone_name;
typedef struct {
	dfhack_std_string code;
	int32_t index;
	dfhack_std_vector_std_string_ptr raws;
	vector_int16_t creature_ids;
	dfhack_std_vector_std_string_ptr creatures;
typedef struct {
	int32_t id;
	int32_t civ_id;
	int32_t active_size1;
	int32_t active_size2;
	int32_t size;
	int32_t duration_counter;
	dfhack_uint16_t flags;
	int16_t unk4b;
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
	int32_t unk_5;
} dfhack_invasion_info;

typedef struct {
	dfhack_std_vector_pointer unk_1;
	dfhack_std_vector_pointer unk_2;
	dfhack_std_vector_pointer unk_3;
} dfhack_entity_population_unk4;

typedef struct {
	dfhack_language_name name;
	vector_int16_t races;
	dfhack_std_vector_int32_t counts;
	dfhack_std_vector_int32_t unk3;
	dfhack_std_vector_pointer unk4;
	int32_t unk5;
	int32_t layer_id;
	int32_t id;
	int32_t flags;
	int32_t civ_id;
} dfhack_entity_population;

typedef struct {
	int32_t id;
	int32_t unit_id;
	int32_t save_file_id;
	int16_t member_idx;
	dfhack_pointer figure;
	dfhack_pointer unit;
	int32_t group_leader_id;
	dfhack_std_vector_int32_t companions;
	int16_t unk10;
	int32_t unk11;
	int32_t unk12;
	int32_t unk_v47_1;
	int32_t unk_v47_2;
	dfhack_df_flagarray flags;
} dfhack_nemesis_record;

typedef struct {
	int32_t id;
	dfhack_language_name name;
	dfhack_df_flagarray flags;
	dfhack_pointer item;
	int32_t abs_tile_x;
	int32_t abs_tile_y;
	int32_t abs_tile_z;
	int32_t unk_1;
	int32_t site;
	int32_t structure_local;
	int32_t unk_2;
	int32_t subregion;
	int32_t feature_layer;
	int32_t owner_hf;
	dfhack_std_vector_int32_t remote_claims;
	dfhack_std_vector_int32_t entity_claims;
	dfhack_std_vector_int32_t direct_claims;
	int32_t storage_site;
	int32_t storage_structure_local;
	int32_t loss_region;
	int32_t unk_3;
	int32_t holder_hf;
	int32_t year;
	int32_t unk_4;
	int32_t unk_5;
} dfhack_artifact_record;

typedef struct {
	dfhack_enum flag_type;
typedef struct {
	dfhack_df_flagarray flags1;
	dfhack_static-array nickname;
	dfhack_uint8_t sky_tile;
	dfhack_static-array sky_color;
	dfhack_uint8_t chasm_tile;
	dfhack_uint8_t pillar_tile;
	dfhack_static-array track_tiles;
	dfhack_static-array track_tile_invert;
	dfhack_static-array track_ramp_tiles;
	dfhack_static-array track_ramp_invert;
	dfhack_static-array tree_tiles;
	dfhack_static-array chasm_color;
typedef struct {
	dfhack_enum item_type;
	int16_t item_subtype;
	dfhack_enum material_class;
	int16_t mattype;
	int32_t matindex;
} dfhack_item_filter_spec;

typedef struct {
	int32_t item;
	dfhack_item_filter_spec item_filter;
	int32_t color;
	dfhack_std_vector_int32_t assigned;
	dfhack_uniform_indiv_choice indiv_choice;
} dfhack_squad_uniform_spec;

typedef struct {
	dfhack_item_filter_spec item_filter;
	int32_t amount;
	dfhack_uint32_t flags;
	dfhack_std_vector_int32_t assigned;
} dfhack_squad_ammo_spec;

typedef struct {
	int32_t occupant;
	dfhack_std_vector_squad_order_ptr orders;
	dfhack_static-array preferences;
	dfhack_static-array uniform;
	dfhack_std_string unk_c4;
	dfhack_uniform_flags flags;
	dfhack_std_vector_int32_t assigned_items;
	int32_t quiver;
	int32_t backpack;
	int32_t flask;
	int32_t unk_1;
	dfhack_static-array activities;
	dfhack_static-array events;
	int32_t unk_2;
} dfhack_squad_position;

typedef struct {
	dfhack_pointer order;
	int32_t min_count;
	dfhack_stl-bit-vector positions;
} dfhack_squad_schedule_order;

typedef struct {
	dfhack_std_string name;
	int16_t sleep_mode;
	int16_t uniform_mode;
	dfhack_std_vector_squad_schedule_order_ptr orders;
	dfhack_std_vector_void_ptr order_assignments;
} dfhack_squad_schedule_entry;

typedef struct {
	int32_t id;
	dfhack_language_name name;
	dfhack_std_string alias;
	dfhack_std_vector_squad_position_ptr positions;
	dfhack_std_vector_squad_order_ptr orders;
	dfhack_std_vector_pointer schedule;
	int32_t cur_alert_idx;
	dfhack_std_vector_pointer rooms;
	dfhack_std_vector_int32_t rack_combat;
	dfhack_std_vector_int32_t rack_training;
	int32_t uniform_priority;
	int32_t activity;
	dfhack_std_vector_squad_ammo_spec_ptr ammunition;
	dfhack_std_vector_int32_t train_weapon_free;
	dfhack_std_vector_int32_t train_weapon_inuse;
	dfhack_std_vector_int32_t ammo_items;
	dfhack_std_vector_int32_t ammo_units;
	int16_t carry_food;
	int16_t carry_water;
	int32_t entity_id;
	int32_t leader_position;
	int32_t leader_assignment;
	int32_t unk_1;
} dfhack_squad;

typedef struct {
	int32_t unk_v40_1;
	int32_t unk_v40_2;
	int32_t year;
	int32_t year_tick;
	int32_t unk_v40_3;
	int32_t unk_1;
} dfhack_squad_order;

typedef struct {
	short3_t pos;
	int32_t point_id;
} dfhack_squad_order_movest;

typedef struct {
	dfhack_std_vector_int32_t units;
	dfhack_std_vector_int32_t histfigs;
	dfhack_std_string title;
} dfhack_squad_order_kill_listst;

typedef struct {
	dfhack_std_vector_int32_t burrows;
} dfhack_squad_order_defend_burrowsst;

typedef struct {
	int32_t route_id;
} dfhack_squad_order_patrol_routest;

typedef dfhack_squad_order dfhack_squad_order_trainst;

typedef struct {
	int32_t unk_2;
	int32_t unk_3;
	dfhack_std_string unk_4;
} dfhack_squad_order_drive_entity_off_sitest;

typedef struct {
	int32_t entity_id;
	dfhack_std_string override_name;
} dfhack_squad_order_cause_trouble_for_entityst;

typedef struct {
	int32_t histfig_id;
	dfhack_std_string title;
} dfhack_squad_order_kill_hfst;

typedef struct {
	int32_t unk_2;
	int32_t unk_3;
	dfhack_std_string unk_4;
} dfhack_squad_order_drive_armies_from_sitest;

typedef struct {
	int32_t artifact_id;
	short3_t unk_2;
} dfhack_squad_order_retrieve_artifactst;

typedef struct {
	int32_t unk_2;
	short3_t unk_3;
} dfhack_squad_order_raid_sitest;

typedef struct {
	int32_t unk_2;
	short3_t unk_3;
} dfhack_squad_order_rescue_hfst;

typedef struct {
	int32_t id;
	int32_t entity_id;
	int32_t site_id;
	int32_t unk_1;
	int32_t pos_x;
	int32_t pos_y;
	int32_t unk_18;
	int32_t unk_1c;
	dfhack_std_vector_int32_t unk_20;
	int32_t year;
	int32_t year_tick;
	int32_t unk_34;
	int32_t unk_38;
	int32_t master_hf;
	int32_t general_hf;
	int32_t unk_44_1;
	int32_t unk_44_2;
	int32_t visitor_nemesis_id;
	int32_t unk_44_4;
	dfhack_pointer unk_44_5;
	dfhack_pointer unk_v47_1;
	dfhack_pointer unk_v47_2;
	int32_t unk_50;
	dfhack_std_vector_int32_t unk_54;
	dfhack_std_vector_void_ptr unk_44_11v;
	dfhack_pointer mission_report;
typedef struct {
	dfhack_bool compressed;
	dfhack_stl-fstream f;
	dfhack_pointer in_buffer;
	dfhack_long in_buffersize;
	dfhack_long in_buffer_amount_loaded;
	dfhack_long in_buffer_position;
	dfhack_pointer out_buffer;
	dfhack_long out_buffersize;
	int32_t out_buffer_amount_written;
} dfhack_file_compressorst;

typedef struct {
	dfhack_pointer child;
	dfhack_pointer parent;
	dfhack_enum breakdown_level;
	int8_t option_key_pressed;
} dfhack_viewscreen;

typedef struct {
	dfhack_std_vector_layer_object_ptr layer_objects;
} dfhack_viewscreen_layer;

typedef struct {
	int32_t original_fps;
	dfhack_viewscreen view;
	dfhack_uint32_t flag;
	int32_t shutdown_interface_tickcount;
	int32_t shutdown_interface_for_ms;
	int8_t supermovie_on;
	int32_t supermovie_pos;
	int32_t supermovie_delayrate;
	int32_t supermovie_delaystep;
	dfhack_std_vector_std_string_ptr supermovie_sound;
	dfhack_static-array supermovie_sound_time;
	dfhack_static-array supermoviebuffer;
	dfhack_static-array supermoviebuffer_comp;
	int32_t currentblocksize;
	int32_t nextfilepos;
	int8_t first_movie_write;
	dfhack_std_string movie_file;
} dfhack_interfacest;

typedef struct {
	dfhack_bool enabled;
	dfhack_bool active;
} dfhack_layer_object;

typedef struct {
	int32_t cursor;
	int32_t num_entries;
	int32_t x1;
	int32_t y1;
	int32_t page_size;
	int32_t x2;
	int32_t y2;
	int32_t mouse_l_cur;
	int32_t mouse_r_cur;
	dfhack_bool rclick_scrolls;
	int32_t flag;
	dfhack_enum key_lclick;
	dfhack_enum key_rclick;
} dfhack_layer_object_listst;

typedef struct {
	int32_t x1;
	int32_t y1;
	int32_t x2;
	int32_t y2;
	int32_t has_mouse_lclick;
	int32_t has_mouse_rclick;
	int32_t mouse_lclick_x;
	int32_t mouse_lclick_y;
	int32_t mouse_rclick_x;
	int32_t mouse_rclick_y;
	int32_t mouse_x;
	int32_t mouse_y;
	int32_t mouse_x_old;
	int32_t mouse_y_old;
	int8_t handle_mouselbtndown;
	int8_t handle_mouserbtndown;
} dfhack_layer_object_buttonst;

typedef struct {
	dfhack_padding pad_1;
	int32_t selection;
	int32_t last_displayheight;
	dfhack_bool bleached;
	dfhack_padding pad_2;
} dfhack_widget_menu;

typedef struct {
	dfhack_std_string text;
	dfhack_bool keep;
} dfhack_widget_textbox;

typedef struct {
	dfhack_enum mode;
	dfhack_widget_menu main;
	dfhack_widget_menu keyL;
	dfhack_widget_menu keyR;
	dfhack_widget_menu macro;
	dfhack_widget_menu keyRegister;
} dfhack_KeybindingScreen;

typedef struct {
	dfhack_widget_menu menu;
	int32_t width;
	int32_t height;
} dfhack_MacroScreenLoad;

typedef struct {
	dfhack_widget_textbox id;
} dfhack_MacroScreenSave;

typedef struct {
	dfhack_language_name name;
	dfhack_std_string unk_1;
	dfhack_static-array unk_2;
typedef struct {
	dfhack_pointer link;
	int32_t id;
	dfhack_pointer firer;
	short3_t origin_pos;
	short3_t target_pos;
	short3_t cur_pos;
	short3_t prev_pos;
	int32_t distance_flown;
	int32_t fall_threshold;
	int32_t min_hit_distance;
	int32_t min_ground_distance;
	dfhack_projectile_flags flags;
	int16_t fall_counter;
	int16_t fall_delay;
	int32_t hit_rating;
	int32_t unk21;
	int32_t unk22;
	int32_t bow_id;
	int32_t unk_item_id;
	int32_t unk_unit_id;
	int32_t unk_v40_1;
	int32_t pos_x;
	int32_t pos_y;
	int32_t pos_z;
	int32_t speed_x;
	int32_t speed_y;
	int32_t speed_z;
	int32_t accel_x;
	int32_t accel_y;
	int32_t accel_z;
} dfhack_projectile;

typedef struct {
	dfhack_pointer item;
} dfhack_proj_itemst;

typedef struct {
	dfhack_pointer unit;
} dfhack_proj_unitst;

typedef struct {
	int16_t type;
	int16_t damage;
} dfhack_proj_magicst;

typedef struct {
	int32_t hfid;
	int32_t unk_hfid;
	int32_t unk_hfid2;
	dfhack_std_vector_int32_t unk_3;
} dfhack_incident_hfid;

typedef struct {
	int32_t id;
	dfhack_enum type;
	dfhack_std_vector_int32_t witnesses;
	int32_t unk_year;
	int32_t unk_year_tick;
	int32_t victim;
	dfhack_incident_hfid victim_hf;
	int32_t victim_race;
	int32_t victim_caste;
	int32_t entity2;
	int32_t unk_v40_1c;
	int32_t criminal;
	dfhack_incident_hfid criminal_hf;
	int32_t criminal_race;
	int32_t criminal_caste;
	int32_t entity1;
	dfhack_incident_hfid unk_v40_2c;
	int32_t crime_id;
	int32_t site;
	int32_t unk_v40_3a;
	int32_t unk_v40_3b;
	int32_t entity;
	int32_t event_year;
	int32_t event_time;
	int32_t flags;
	dfhack_enum death_cause;
	dfhack_enum conflict_level;
	int32_t activity_id;
	int32_t world_x;
	int32_t world_y;
	int32_t world_z;
	int32_t unk_80;
	int32_t unk_10c;
typedef struct {
	dfhack_std_string conv_title;
	dfhack_enum state;
	vector_int16_t talk_choices;
	int32_t unk_30;
	int32_t unk_34;
	int32_t unk_38;
	int32_t unk_3c;
	int32_t unk_40;
	int32_t unk_44;
	int32_t unk_48;
	int32_t unk_4c;
	int32_t unk_50;
	dfhack_std_vector_nemesis_record_ptr unk_54;
	dfhack_std_vector_historical_entity_ptr unk_64;
	int8_t unk_74;
	int32_t unk_78;
	int32_t unk_7c;
	int16_t unk_80;
	dfhack_std_vector_void_ptr unk_84;
	dfhack_std_vector_void_ptr unk_94;
	dfhack_std_vector_void_ptr unk_a4;
	dfhack_pointer location;
	int8_t unk_b8;
	int32_t unk_bc;
	dfhack_std_vector_pointer speech;
} dfhack_conversation;

typedef struct {
	dfhack_enum type;
typedef struct {
	dfhack_df_flagarray flag;
	dfhack_enum windowed;
	int32_t grid_x;
	int32_t grid_y;
	int32_t desired_fullscreen_width;
	int32_t desired_fullscreen_height;
	int32_t desired_windowed_width;
	int32_t desired_windowed_height;
	int8_t partial_print_count;
} dfhack_init_display;

typedef struct {
	dfhack_df_flagarray flag;
	int32_t volume;
} dfhack_init_media;

typedef struct {
	dfhack_long hold_time;
	dfhack_long repeat_time;
	dfhack_long macro_time;
	dfhack_long pause_zoom_no_interface_ms;
	dfhack_df_flagarray flag;
	dfhack_long zoom_speed;
	int32_t repeat_accel_start;
	int32_t repeat_accel_limit;
} dfhack_init_input;

typedef struct {
	dfhack_static-array small_font_texpos;
	dfhack_static-array large_font_texpos;
	dfhack_static-array small_font_datapos;
	dfhack_static-array large_font_datapos;
	dfhack_s-float small_font_adjx;
	dfhack_s-float small_font_adjy;
	dfhack_s-float large_font_adjx;
	dfhack_s-float large_font_adjy;
	dfhack_long small_font_dispx;
	dfhack_long small_font_dispy;
	dfhack_long large_font_dispx;
	dfhack_long large_font_dispy;
	dfhack_enum use_ttf;
	int32_t ttf_limit;
} dfhack_init_font;

typedef struct {
	dfhack_df_flagarray flag;
} dfhack_init_window;

typedef struct {
	dfhack_init_display display;
	dfhack_init_media media;
	dfhack_init_input input;
	dfhack_init_font font;
	dfhack_init_window window;
} dfhack_init;

typedef struct {
	dfhack_std_string token;
	dfhack_std_string filename;
	int16_t tile_dim_x;
	int16_t tile_dim_y;
	int16_t page_dim_x;
	int16_t page_dim_y;
	dfhack_std_vector_int32_t texpos;
	dfhack_std_vector_int32_t datapos;
	dfhack_std_vector_int32_t texpos_gs;
	dfhack_std_vector_int32_t datapos_gs;
	dfhack_bool loaded;
} dfhack_tile_page;

typedef struct {
	dfhack_std_vector_tile_page_ptr page;
	dfhack_std_vector_int32_t texpos;
	dfhack_std_vector_int32_t datapos;
} dfhack_texture_handler;

typedef struct {
	int32_t idmaybe;
	int32_t unk_1;
	int32_t item_id;
	int32_t written_content_id;
	int32_t unit_id;
	int32_t activity_entry_id;
	int32_t unk_2;
} dfhack_scribejob;

typedef struct {
	int32_t site_id;
	int32_t location_id;
	int32_t unk_1;
	int32_t unk_2;
	int32_t year;
	int32_t tickmaybe;
	dfhack_static-array unk_3;
} dfhack_site_reputation_report;

typedef struct {
	dfhack_std_vector_site_reputation_report_ptr reports;
} dfhack_site_reputation_info;

typedef struct {
	dfhack_std_vector_scribejob_ptr scribejobs;
	int32_t nextidmaybe;
	int32_t year;
	dfhack_uint16_t unk_1;
	int16_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
	int32_t unk_5;
} dfhack_location_scribe_jobs;

typedef struct {
	dfhack_std_vector_pointer populations;
	dfhack_std_vector_int32_t histfigs;
} dfhack_abstract_building_entombed;

typedef struct {
	int32_t need_more;
	dfhack_enum profession;
	int32_t desired_goblets;
	int32_t desired_instruments;
	int32_t desired_paper;
	int32_t desired_copies;
	int32_t location_tier;
	int32_t location_value;
	int32_t count_goblets;
	int32_t count_instruments;
	int32_t count_paper;
	int32_t unk_v47_2;
	int32_t unk_v47_3;
	dfhack_std_vector_int32_t building_ids;
} dfhack_abstract_building_contents;

typedef struct {
	int32_t id;
	dfhack_std_vector_pointer inhabitants;
	dfhack_df_flagarray flags;
	dfhack_pointer unk1;
	dfhack_std_vector_int32_t unk2;
	int32_t parent_building_id;
	dfhack_std_vector_int32_t child_building_ids;
	int32_t site_owner_id;
	dfhack_pointer scribeinfo;
	dfhack_pointer reputation_reports;
	dfhack_pointer unk_v42_3;
	int32_t site_id;
	short2_t pos;
	dfhack_std_vector_occupation_ptr occupations;
} dfhack_abstract_building;

typedef struct {
	dfhack_language_name name;
	dfhack_site_building_item item1;
	dfhack_site_building_item item2;
} dfhack_abstract_building_mead_hallst;

typedef struct {
	dfhack_language_name name;
} dfhack_abstract_building_keepst;

typedef struct {
	int32_t Deity;
	int32_t Religion;
} dfhack_temple_deity_data;

typedef struct {
	dfhack_enum deity_type;
	dfhack_temple_deity_data deity_data;
	dfhack_language_name name;
	dfhack_abstract_building_contents contents;
} dfhack_abstract_building_templest;

typedef struct {
	dfhack_language_name name;
} dfhack_abstract_building_dark_towerst;

typedef struct {
	dfhack_language_name name;
} dfhack_abstract_building_marketst;

typedef struct {
	dfhack_language_name name;
	dfhack_abstract_building_entombed entombed;
	int32_t precedence;
} dfhack_abstract_building_tombst;

typedef struct {
	dfhack_language_name name;
	dfhack_enum dungeon_type;
	int32_t unk_1;
	dfhack_abstract_building_entombed entombed;
	int32_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
} dfhack_abstract_building_dungeonst;

typedef struct {
	dfhack_language_name name;
	int32_t unk_bc;
} dfhack_abstract_building_underworld_spirest;

typedef struct {
	dfhack_language_name name;
	dfhack_abstract_building_contents contents;
	dfhack_std_vector_pointer room_info;
	int32_t next_room_info_id;
} dfhack_abstract_building_inn_tavernst;

typedef struct {
	dfhack_language_name name;
	dfhack_std_vector_int32_t copied_artifacts;
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
	int32_t unk_4;
	dfhack_abstract_building_contents contents;
} dfhack_abstract_building_libraryst;

typedef struct {
	dfhack_language_name name;
} dfhack_abstract_building_counting_housest;

typedef struct {
	dfhack_language_name name;
	dfhack_abstract_building_contents contents;
} dfhack_abstract_building_guildhallst;

typedef struct {
	dfhack_language_name name;
	int32_t unk_1;
} dfhack_abstract_building_towerst;

typedef struct {
	int32_t index;
	dfhack_bool is_concrete_property;
	dfhack_padding pad_1;
	int32_t property_index;
	int32_t unk_hfid;
	int32_t owner_entity_id;
	int32_t owner_hfid;
	int32_t unk_owner_entity_id;
} dfhack_property_ownership;

typedef struct {
	dfhack_language_name name;
	int32_t civ_id;
	int32_t cur_owner_id;
	dfhack_enum type;
	short2_t pos;
	int32_t id;
typedef struct {
	dfhack_std_string code;
	int32_t id;
	dfhack_std_string name;
	dfhack_enum building_type;
	int32_t building_subtype;
	dfhack_static-array name_color;
	dfhack_static-array tile;
	dfhack_static-array tile_color;
	dfhack_static-array tile_block;
	dfhack_long build_key;
	dfhack_bool needs_magma;
	dfhack_std_vector_building_def_item_ptr build_items;
	int32_t dim_x;
	int32_t dim_y;
	int32_t workloc_x;
	int32_t workloc_y;
	dfhack_std_vector_enum build_labors;
	dfhack_std_string labor_description;
	int32_t build_stages;
} dfhack_building_def;

typedef struct {
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mat_type;
	int16_t mat_index;
	dfhack_std_string reaction_class;
	dfhack_std_string has_material_reaction_product;
	dfhack_job_item_flags1 flags1;
	dfhack_job_item_flags2 flags2;
	dfhack_job_item_flags3 flags3;
	dfhack_uint32_t flags4;
	dfhack_uint32_t flags5;
	int32_t metal_ore;
	int32_t min_dimension;
	int32_t quantity;
	dfhack_enum has_tool_use;
	dfhack_static-array item_str;
	dfhack_static-array material_str;
	dfhack_std_string metal_ore_str;
} dfhack_building_def_item;

typedef dfhack_building_def dfhack_building_def_workshopst;

typedef dfhack_building_def dfhack_building_def_furnacest;

typedef struct {
	dfhack_std_vector_int32_t events;
	vector_int16_t killed_race;
	vector_int16_t killed_caste;
	dfhack_std_vector_int32_t killed_underground_region;
	dfhack_std_vector_int32_t killed_region;
	dfhack_std_vector_int32_t killed_site;
	dfhack_std_vector_bitfield killed_undead;
	dfhack_std_vector_int32_t killed_count;
} dfhack_historical_kills;

typedef struct {
	int32_t item;
	dfhack_enum item_type;
	int16_t item_subtype;
	int16_t mattype;
	int32_t matindex;
	int32_t shooter_item;
	dfhack_enum shooter_item_type;
	int16_t shooter_item_subtype;
	int16_t shooter_mattype;
	int32_t shooter_matindex;
} dfhack_history_hit_item;

typedef struct {
	int32_t actor_id;
	dfhack_enum plot_role;
	int32_t agreement_id;
	dfhack_bool agreement_has_messenger;
} dfhack_plot_agreement;

typedef struct {
	dfhack_pointer spheres;
	dfhack_pointer skills;
	dfhack_pointer pets;
	dfhack_pointer personality;
	dfhack_pointer masterpieces;
	dfhack_pointer whereabouts;
	dfhack_pointer kills;
	dfhack_pointer wounds;
	dfhack_pointer known_info;
	dfhack_pointer curse;
	dfhack_pointer books;
	dfhack_pointer reputation;
	dfhack_pointer relationships;
} dfhack_historical_figure_info;

typedef struct {
	dfhack_std_vector_pointer hf_visual;
	dfhack_std_vector_pointer hf_historical;
	dfhack_std_vector_pointer unk_1;
	dfhack_std_vector_int32_t identities;
	dfhack_std_vector_pointer artifact_claims;
	int32_t unk_2;
	dfhack_pointer intrigues;
} dfhack_historical_figure_relationships;

typedef struct {
	dfhack_enum profession;
	int16_t race;
	int16_t caste;
	dfhack_enum sex;
	dfhack_orientation_flags orientation_flags;
	int32_t appeared_year;
	int32_t born_year;
	int32_t born_seconds;
	int32_t curse_year;
	int32_t curse_seconds;
	int32_t birth_year_bias;
	int32_t birth_time_bias;
	int32_t old_year;
	int32_t old_seconds;
	int32_t died_year;
	int32_t died_seconds;
	dfhack_language_name name;
	int32_t civ_id;
	int32_t population_id;
	int32_t breed_id;
	int32_t cultural_identity;
	int32_t family_head_id;
	dfhack_df_flagarray flags;
	int32_t unit_id;
	int32_t nemesis_id;
	int32_t id;
	int32_t unk4;
	dfhack_std_vector_histfig_entity_link_ptr entity_links;
	dfhack_std_vector_histfig_site_link_ptr site_links;
	dfhack_std_vector_histfig_hf_link_ptr histfig_links;
	dfhack_pointer info;
	dfhack_pointer vague_relationships;
	dfhack_pointer unk_f0;
	dfhack_pointer unk_f4;
	dfhack_pointer unk_f8;
	dfhack_pointer unk_fc;
	dfhack_pointer unk_v47_2;
	int32_t unk_v47_3;
	int32_t unk_v47_4;
	int32_t unk_v4019_1;
	int32_t unk_5;
} dfhack_historical_figure;

typedef struct {
	int32_t id;
	dfhack_language_name name;
	int32_t race;
	int16_t caste;
	int32_t impersonated_hf;
typedef struct {
	dfhack_std_vector_entity_occasion_ptr occasions;
	int32_t next_occasion_id;
	dfhack_static_array events;
	int32_t count;
} dfhack_entity_occasion_info;

typedef struct {
	int32_t id;
	int32_t unk_1;
	int32_t site;
	int32_t unk_2;
	dfhack_language_name name;
	int32_t start_year_tick;
	int32_t end_year_tick;
	int32_t unk_3;
	int32_t event;
	int32_t unk_4;
	dfhack_std_vector_entity_occasion_schedule_ptr schedule;
	int32_t unk_5;
} dfhack_entity_occasion;

typedef struct {
	dfhack_enum type;
	int32_t reference;
	int32_t reference2;
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
	dfhack_std_vector_entity_occasion_schedule_feature_ptr features;
	int32_t start_year_tick;
	int32_t end_year_tick;
} dfhack_entity_occasion_schedule;

typedef struct {
	dfhack_enum feature;
	int32_t reference;
	int32_t unk_1;
	int32_t unk_2;
	int32_t unk_3;
} dfhack_entity_occasion_schedule_feature;

typedef struct {
typedef struct {
	dfhack_bool edged;
	int32_t contact;
	int32_t penetration;
	int32_t velocity_mult;
	dfhack_std_string verb_2nd;
	dfhack_std_string verb_3rd;
	dfhack_std_string noun;
	int32_t prepare;
	int32_t recover;
	int32_t flags;
} dfhack_weapon_attack;

typedef struct {
	dfhack_std_string id;
	int16_t subtype;
	dfhack_df_flagarray base_flags;
	int32_t source_hfid;
	int32_t source_enid;
	dfhack_std_vector_std_string_ptr raw_strings;
} dfhack_itemdef;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string adjective;
	dfhack_std_string ammo_class;
	dfhack_df_flagarray flags;
	int32_t size;
	int32_t value;
	dfhack_std_vector_weapon_attack_ptr attacks;
} dfhack_itemdef_ammost;

typedef struct {
	dfhack_df_flagarray flags;
	int32_t layer;
	int16_t layer_size;
	int16_t layer_permit;
	int16_t coverage;
} dfhack_armor_properties;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string name_preplural;
	dfhack_std_string material_placeholder;
	dfhack_std_string adjective;
	int32_t value;
	int8_t armorlevel;
	int16_t ubstep;
	int16_t lbstep;
	int32_t material_size;
	dfhack_armor_properties props;
	dfhack_df_flagarray flags;
} dfhack_itemdef_armorst;

typedef struct {
	dfhack_std_string name;
	int16_t level;
} dfhack_itemdef_foodst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string adjective;
	int32_t value;
	int8_t armorlevel;
	int16_t upstep;
	dfhack_df_flagarray flags;
	int32_t material_size;
	dfhack_armor_properties props;
} dfhack_itemdef_glovesst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string adjective;
	int32_t value;
	int8_t armorlevel;
	dfhack_df_flagarray flags;
	int32_t material_size;
	dfhack_armor_properties props;
} dfhack_itemdef_helmst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_df_flagarray flags;
	dfhack_enum music_skill;
	int32_t size;
	int32_t value;
	int32_t material_size;
	dfhack_std_vector_instrument_piece_ptr pieces;
	dfhack_std_string dominant_instrument_piece;
	int32_t pitch_range_min;
	int32_t pitch_range_max;
	int32_t volume_mb_min;
	int32_t volume_mb_max;
	dfhack_std_vector_sound_production_type sound_production;
	dfhack_std_vector_std_string_ptr sound_production_parm1;
	dfhack_std_vector_std_string_ptr sound_production_parm2;
	dfhack_std_vector_int32_t unk_100;
	dfhack_std_vector_int32_t unk_110;
	dfhack_std_vector_pitch_choice_type pitch_choice;
	dfhack_std_vector_std_string_ptr pitch_choice_parm1;
	dfhack_std_vector_std_string_ptr pitch_choice_parm2;
	dfhack_std_vector_int32_t unk_150;
	dfhack_std_vector_int32_t unk_160;
	dfhack_std_vector_tuning_type tuning;
	dfhack_std_vector_std_string_ptr tuning_parm;
	dfhack_std_vector_int32_t unk_190;
	dfhack_std_vector_instrument_register_ptr registers;
	dfhack_std_vector_timbre_type timbre;
	dfhack_std_string description;
} dfhack_itemdef_instrumentst;

typedef struct {
	dfhack_std_string type;
	dfhack_std_string id;
	int32_t index;
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_uint32_t flags;
} dfhack_instrument_piece;

typedef struct {
	int32_t pitch_range_min;
	int32_t pitch_range_max;
	dfhack_std_vector_timbre_type timbres;
} dfhack_instrument_register;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string name_preplural;
	dfhack_std_string material_placeholder;
	dfhack_std_string adjective;
	int32_t value;
	int8_t armorlevel;
	dfhack_df_flagarray flags;
	int32_t material_size;
	int16_t lbstep;
	dfhack_armor_properties props;
} dfhack_itemdef_pantsst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string adjective;
	int32_t value;
	int32_t blockchance;
	int8_t armorlevel;
	int16_t upstep;
	int32_t material_size;
} dfhack_itemdef_shieldst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string adjective;
	int32_t value;
	int8_t armorlevel;
	int16_t upstep;
	dfhack_df_flagarray flags;
	int32_t material_size;
	dfhack_armor_properties props;
} dfhack_itemdef_shoesst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string ammo_class;
} dfhack_itemdef_siegeammost;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_df_flagarray flags;
	int32_t value;
	dfhack_uint8_t tile;
	dfhack_std_vector_enum tool_use;
	dfhack_std_string adjective;
	int32_t size;
	dfhack_enum skill_melee;
	dfhack_enum skill_ranged;
	dfhack_std_string ranged_ammo;
	int32_t two_handed;
	int32_t minimum_size;
	int32_t material_size;
	dfhack_std_vector_weapon_attack_ptr attacks;
	int32_t shoot_force;
	int32_t shoot_maxvel;
	int32_t container_capacity;
	dfhack_std_vector_std_string_ptr shape_category_str;
	dfhack_std_vector_int32_t shape_category;
	dfhack_std_string description;
	dfhack_std_vector_pointer default_improvements;
} dfhack_itemdef_toolst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_df_flagarray flags;
} dfhack_itemdef_toyst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string adjective;
	int32_t size;
	int32_t value;
	int32_t hits;
	int32_t material_size;
	dfhack_df_flagarray flags;
	dfhack_std_vector_weapon_attack_ptr attacks;
} dfhack_itemdef_trapcompst;

typedef struct {
	dfhack_std_string name;
	dfhack_std_string name_plural;
	dfhack_std_string adjective;
	int32_t size;
	int32_t value;
	dfhack_enum skill_melee;
	dfhack_enum skill_ranged;
	dfhack_std_string ranged_ammo;
	int32_t two_handed;
	int32_t minimum_size;
	int32_t material_size;
	dfhack_df_flagarray flags;
	dfhack_std_vector_weapon_attack_ptr attacks;
	int32_t shoot_force;
	int32_t shoot_maxvel;
} dfhack_itemdef_weaponst;

]]
