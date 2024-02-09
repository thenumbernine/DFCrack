local ffi = require 'ffi'
local struct = require 'struct'
local template = require 'template'

-- TODO incorporate with ffi.cpp.vector?
-- and maybe move that to its own lib, like std-ffi.vector ?

local function makeStdVector(T, name)
	name = name or 'vector_'..T:gsub('%*', '_ptr'):gsub('%s+', '')
	local Tptr = T..' *'
	-- stl vector in my gcc / linux / df is 24 bytes
	-- template type of our vector ... 8 bytes mind you
	struct{
		name = name,
		fields = {
			{type = struct{
				anonymous = true,
				union = true,
				fields = {
					-- shorthand index access: .v[]
					{name = 'v', type = Tptr},
					{name = 'start', type = Tptr},
				},
			}},
			{name = 'finish', type = Tptr},
			{name = 'endOfStorage', type = Tptr},
		},
		metatable = function(mt)
			-- TODO __index for numbers to lookup in .v[] ?

			function mt:size()
				return self.finish - self.start
			end

			-- lua compat
			mt.__len = mt.size

			function mt:capacity()
				return self.endOfStorage - self.start
			end

			-- safe access
			-- returns ref for cdata or value for primitives (which means doesn't work for writing)
			function mt:at(i)
				if i < 0 or i >= self.finish - self.start then
					return nil, 'out of bounds'
				end
				return self.start[i]
			end

			-- safe access
			-- since there's no refs in luajit, here's a ptr version
			function mt:atPtr(i)
				if i < 0 or i >= self.finish - self.start then
					return nil, 'out of bounds'
				end
				return self.start + i
			end


			function mt:__ipairs()
				-- slow impl
				return coroutine.wrap(function()
					-- TODO validate size every iteration?
					-- or just claim that modifying invalidates iteration...
					for i=0,self:size()-1 do
						coroutine.yield(i, self.v[i])
					end
				end)
			end


		end,
	}

	assert(ffi.sizeof(name) == 24)
	assert(ffi.sizeof(T..'*') == 8)
end

return makeStdVector
