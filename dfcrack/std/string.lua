local ffi = require 'ffi'

local string = require 'ext.string'

-- TODO move to ffi.cpp.string
-- or maybe move that to its own lib, like std-ffi.string ?

ffi.cdef[[
typedef struct std_string_pointer {
	char * data;
	size_t len;
	/* maybe more, meh */
} std_string_pointer;
typedef struct std_string {
	std_string_pointer * _M_p;
} std_string;
]]
assert(ffi.sizeof'std_string' == 8)

local mt = {}
mt.__index = mt
mt.__tostring = function(self)
	return ffi.string(self.data, self.len)
end
mt.__concat = string.concat
ffi.metatype('std_string', mt)
return mt
