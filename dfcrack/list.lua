-- is this std::list or is it just df's impl?

local ffi = require 'ffi'
local template = require 'template'

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

return makeList
