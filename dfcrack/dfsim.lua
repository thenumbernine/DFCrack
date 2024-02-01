package.path = package.path .. ';/home/chris/Projects/lua/?.lua'
package.path = package.path .. ';/home/chris/Projects/lua/?/?.lua'

local ffi = require 'ffi'
require 'ffi.req' 'c.pthread'
local pthread = ffi.C	-- luajit could stand to use some encapsulation of its ffi content

local dfsim = {}

function dfsim.update()
	print(('dfmain.update pthread_self: %x'):format(pthread.pthread_self()))
end

return dfsim
