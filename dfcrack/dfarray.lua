local ffi = require 'ffi'
local template = require 'template'

local function makeDfArray(T, name)
	name = name or 'dfarray_'..T
	ffi.cdef(template([[
typedef struct <?=name?> {
	<?=T?> * data;
	uint16_t size;
} <?=name?>;
]], {
		T = T,
		name = name,
	}))
end

return makeDfArray
