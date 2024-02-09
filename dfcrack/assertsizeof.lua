local ffi = require 'ffi'
local asserteq = require 'asserteq'

-- I do this often enough, here's its own function
local function assertsizeof(t, s)
	if ffi.sizeof(t) ~= s then
		error("expected sizeof("..t..") == "..s..", but found "..ffi.sizeof(t))
	end
end

return assertsizeof
