local ffi = require 'ffi'
local template = require 'template'
local function makeStdVector(T, name)
	name = name or 'vector_'..T
	-- stl vector in my gcc / linux / df is 24 bytes
	-- template type of our vector ... 8 bytes mind you
	-- TODO rewrite my ffi.cpp.vector file to be a C struct this
	local code = template([[
typedef struct <?=name?> {
	union {
		<?=T?> * v;		/* shorthand index access: .v[] */
		<?=T?> * start;
	};
	<?=T?> * finish;
	<?=T?> * endOfStorage;
} <?=name?>;
]], {
		T = T,			-- vector type / template arg
		name = name,	-- vector name
	})
	assert(xpcall(function()
		ffi.cdef(code)
	end, function(err)
		print(require 'template.showcode'(code))
		return err..'\n'..debug.traceback()
	end))
	assert(ffi.sizeof(name) == 24)
	assert(ffi.sizeof(T..'*') == 8)

	local mt = {}
	mt.__index = mt
	function mt:size()
		return self.finish - self.start
	end
	function mt:capacity()
		return self.endOfStorage - self.start
	end

	-- slow impl
	function mt:__ipairs()
		return coroutine.wrap(function()
			-- TODO validate size every iteration?
			-- or just claim that modifying invalidates iteration...
			for i=0,self:size()-1 do
				coroutine.yield(i, self.v[i])
			end
		end)
	end

	assert(xpcall(function()
		ffi.metatype(name, mt)
	end, function(err)
		print(require 'template.showcode'(code))
		return 'for metatype '..name..'\n'
			..err..'\n'
			..debug.traceback()
	end))
end

return makeStdVector
