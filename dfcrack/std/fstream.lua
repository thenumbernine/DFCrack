local ffi = require 'ffi'

-- TODO move to ffi.cpp.*
-- or maybe move that to its own lib, like std-ffi.* ?

ffi.cdef[[
typedef struct std_fstream {
	char tmp[0x210];
} std_fstream;
]]
-- gdb is telling me sizeof(std::fstream) == 0 ... hmm
-- but using offsetof() in df::file_compressorst tells me std::fstream is at most 0x210 bytes
-- or at least, its size, 8-byte-aligned, is 0x210
assert(ffi.sizeof'std_fstream' == 0x210)

local mt = {}
mt.__index = mt
ffi.metatype('std_fstream', mt)
return mt
