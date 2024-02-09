local ffi = require 'ffi'

local string = require 'ext.string'
local assertsizeof = require 'assertsizeof'

-- TODO move to ffi.cpp.string
-- or maybe move that to its own lib, like std-ffi.string ?

-- idk really about the implementation of the pointer , just winging it
-- https://stackoverflow.com/a/29401096/2714073
-- whyyyyyy
ffi.cdef[[
typedef struct std_string_impl {
	char * data;
	size_t size; // this looks like it has a pointer in it ...
	size_t cap;
} std_string_impl;

typedef union std_string {
	// this is a char* pointer to the start of the string ...
	char * s;
	// this is for easy access of the members stored behind the start ...
	// i[-1] == refcount
	// i[-2] == capacity
	// i[-3] == size
	int * i;
} std_string;

enum {
	STL_STRING_SIZE = -3,
	STL_STRING_CAPACITY = -2,
	STL_STRING_REFCOUNT = -1,
};
]]
-- ok gdb sizeof(std::string) says 8
-- but c++ code sizeof(std::string) says 32
-- so ... ???
-- tie-breaker, compiling dfhack and echoing sizeof(std::string) says 8
-- and what is causing this? looks like compiling with `-D_GLIBCXX_USE_CXX11_ABI=0` will set the sizeof(std::string) to 8
assert(ffi.sizeof'std_string' == 8)
--assertsizeof('std_string', 32)

local mt = {}
mt.__index = mt

mt.__concat = string.concat

function mt:length()
	assert(self.s ~= nil)	-- TODO is this ever the case?
	return self.i[ffi.C.STL_STRING_SIZE]
end
mt.size = mt.length

function mt:capacity()
	assert(self.s ~= nil)	-- TODO is this ever the case?
	return self.i[ffi.C.STL_STRING_CAPACITY]
end

function mt:empty()
	assert(self.s ~= nil)	-- TODO is this ever the case?
	return self:length() == 0
end

ffi.metatype('std_string', mt)

-- cuz i'm lazy
function mt:str()
	assert(self.s ~= nil)	-- TODO is this ever the case?
	return ffi.string(self.s, self:size())
end

-- stl api compat
mt.c_str = mt.str

-- lua compat
mt.__tostring = mt.string

-- return mt or ffi.metatype(...) == ffi.typeof'std_string' ?
return mt
