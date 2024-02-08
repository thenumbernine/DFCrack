local ffi = require 'ffi'
local template = require 'template'

local function makeDfArray(T, name, SizeType)
	name = name or 'dfarray_'..T
	-- uint16_t is default for DFArray
	SizeType = SizeType or 'uint16_t'
	ffi.cdef(template([[
typedef struct <?=name?> {
	<?=T?> * data;
	uint16_t size;
} <?=name?>;
]], {
		T = T,
		name = name,
		SizeType = SizeType,
	}))
end

return makeDfArray
