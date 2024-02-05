local ffi = require 'ffi'
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
