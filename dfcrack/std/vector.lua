local ffi = require 'ffi'
local struct = require 'struct'

local defined = {}

-- TODO incorporate with ffi.cpp.vector?
-- and maybe move that to its own lib, like std-ffi.vector ?

local function makeStdVector(T, name)
	-- TODO std_vector_*
	name = name or 'vector_'..T:gsub('%*', '_ptr'):gsub('%s+', '')
	
	-- cache types so I don't declare one twice (and error luajit)
	local ctype = defined[name] 
	if ctype then return ctype end

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

			function mt:reserve(newcap)
				local oldcap = self:capacity()
				if newcap <= oldcap then return end
				-- so self.capacity < newcap
				local newv = ffi.C.malloc(ffi.sizeof(T) * newcap)
				local size = self:size()
				assert(size <= oldcap)
				ffi.C.copy(newv, self.v, ffi.sizeof(T) * size)
				if self.v ~= nil then ffi.C.free(self.v) end
				self.v = newv
				self.finish = self.v + size
				self.endOfStorage = self.v + newcap
			end

			function mt:resize(newsize)
				-- TODO increase by %age?  like 20% or so? with a min threshold of 32 / increments of 32?
				self:reserve(
					bit.lshift(
						ffi.cast('size_t', bit.rshift(newsize, 5)) + 1,
						5
					)
				)
				-- TODO ffi.fill with zero here?
				self.finish = self.v + newsize
			end

			function mt:clear()
				self:resize(0)
			end

			function mt:push_back(obj)
				self:resize(self:size() + 1)
				self.finish[-1] = obj
			end

			function mt:emplace_back()
				self:resize(self:size() + 1)
				return self.finish - 1
			end

			-- returns a ptr to the first element
			function mt:front()
				return self.start
			end

			-- returns a ptr to the last element
			function mt:back()
				assert(self:size() > 0)
				return self.finish - 1
			end

			-- because the __index removes access from the object itself ...
			mt.data = mt.front

			-- TODO use iterators and coroutines?  even though they are horribly slow
			mt.begin = mt.front

			-- returns a ptr past the last element
			function mt:iend()
				return self.finish
			end

			mt.rbegin = mt.back

			function mt:rend()
				return self.start - 1
			end

			--[[
			insert(where, ptr first, ptr last)
			insert(where, ref value)
			--]]
			function mt:insert(...)
				local n = select('#', ...)
				if n == 3 then
					local where, first, last = ...
					first = ffi.cast(Tptr, first)
					last = ffi.cast(Tptr, last)

					local numToCopy = last - first
					if numToCopy == 0 then return end
					assert(numToCopy > 0)

					local offset = where - self.v
					assert(offset >= 0 and offset <= self:size())

					local origSize = self:size()
					self:resize(self:size() + numToCopy)
					if offset < origSize then
						ffi.copy(self.v + offset + numToCopy, self.v + offset, ffi.sizeof(T) * (origSize - offset))
					end
					ffi.copy(self.v + offset, first, ffi.sizeof(T) * numToCopy)
				elseif n == 2 then
					local where, value = ...
					local offset = where - self.v
					assert(0 <= offset and offset <= self:size())
					self:resize(self:size() + 1)
					for i=self:size()-1,offset+1,-1 do
						self.v[i] = self.v[i-1]
					end
					self.v[offset] = value
				end
			end

			--[[
			first = ptr into v, inclusive
			last = ptr into v, exclusive
			--]]
			function mt:erase(first, last)
				if first >= last then return end
				local iend = self:iend()
				assert(first >= self.v and first <= iend)
				assert(last >= self.v and last <= iend)
				local change = last - first
				-- [[
				while last < iend do
					first[0] = last[0]
					first = first + 1
					last = last + 1
				end
				--]]
				--[[
				local count = iend - last
				ffi.copy(first, last, ffi.sizeof(T) * count)
				--]]
				self.finish = self.finish - change
			end

			-- returns a Lua table of the elements.
			function mt:totable()
				return range(0,self:size()-1):mapi(function(i)
					return self.v[i]
				end)
			end

			function mt:empty()
				return self.start == self.finish
			end

			function mt:__tostring()
				local s = '['
				local sep = ''
				for i=0,self:size()-1 do
					s = s .. sep .. self.v[i]
					sep = ', '
				end
				return s .. ']'
			end

		end,
	}

	assert(ffi.sizeof(name) == 24)
	assert(ffi.sizeof(Tptr) == 8)

	ctype = ffi.typeof(name)
	defined[name] = ctype
	return ctype
end

return makeStdVector
