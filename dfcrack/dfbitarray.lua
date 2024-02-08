local bit = require 'bit'
local ffi = require 'ffi'
ffi.cdef[[
typedef struct DFBitArray {
	uint8_t * bits;
	uint32_t size;
} DFBitArray;
]]

local mt = {}
mt.__index = mt

function mt:isSet(index)
	local byte = bit.rshift(index, 3)
	if byte >= self.size then return false end
	local flag = bit.lshift(1, bit.band(index, 7))
	return bit.band(flag, self.bits[byte]) ~= 0
end

return ffi.metatype('DFBitArray', mt)
