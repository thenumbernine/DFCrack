local ffi = require 'ffi'
local template = require 'template'

local defined = {}

local function makeStdDeque(T, name)
	name = name or 'std_deque_'..T:gsub('%*', '_ptr'):gsub('%s+', '')

	-- cache types so I don't declare one twice (and error luajit)
	local ctype = defined[name] 
	if ctype then return ctype end

	-- https://gcc.gnu.org/onlinedocs/gcc-4.6.3/libstdc++/api/a00464.html
	ffi.cdef(template([[
typedef struct <?=name?> {
	<?=T?> ** map;
	size_t size;
	<?=T?> * start, finish;
} <?=name?>;
]], 	{
			name = name,
			T = T,
		}))

	-- TODO size assert

	local mt = {}
	mt.__index = mt
	
	ctype = ffi.typeof(name)
	defined[name] = ctype
	ffi.metatype(name, mt)
	return ctype
end

return makeStdDeque
