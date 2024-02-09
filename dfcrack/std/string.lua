local ffi = require 'ffi'

local string = require 'ext.string'

-- TODO move to ffi.cpp.string
-- or maybe move that to its own lib, like std-ffi.string ?

-- idk really about the implementation of the pointer , just winging it
ffi.cdef[[
typedef struct std_string_pointer {
	char * data;
	size_t len;
	/* maybe more, meh */
} std_string_pointer;

typedef struct std_string {
	std_string_pointer * ptr;
} std_string;
]]
assert(ffi.sizeof'std_string' == 8)

local mt = {}
mt.__index = mt
mt.__tostring = function(self)
	local ptr = self.ptr
	if ptr == nil then return '' end
	return ffi.string(ptr.data, ptr.len)
end
mt.__concat = string.concat

mt.str = mt.__tostring

function mt:empty()
--print("std_string:empty ptr=", self.ptr)
--print("std_string:empty ptr.data=", self.ptr ~= nil and self.ptr.data)
--print("std_string:empty ptr.len=", self.ptr ~= nil and self.ptr.len)
	return self.ptr == nil 
	or self.ptr.data == nil 
	or self.ptr.len == 0
end

ffi.metatype('std_string', mt)
return mt
