#!/usr/bin/env lua
--[[
quick port of dfhack's codegen.out.xml into a lua file (so i don't have to parse the xml at runtime)
run this from the root dir, so everything is offline/
--]]
local path = require 'ext.path'
local tolua = require 'ext.tolua'
local table = require 'ext.table'

local dfhacksrcdir = path'../../other/dfhack-0.47.05-r8/library/'

local xmlhandler = require 'xmlhandler.tree'
local xml2lua = require 'xml2lua'
local function xmlparse(xml)
	-- hmm results via out arg, hmmmmm... why would you do this.
	-- hmm and why is this require()'ing (singleton cached in package.loaded) the handler, which holds the results in a member field? modularity plz ....)
	local res = xmlhandler:new()
	local parser = xml2lua.parser(res)
	parser:parse(xml)
	return res.root
end

--local codegenout = xmlparse(assert((dfhacksrcdir/'include/df/codegen.out.xml'):read()))

local mem = {}

-- [[ holds the addresses
local symbols = xmlparse(assert((dfhacksrcdir/'xml/symbols.xml'):read()))
local symbolTable = symbols['data-definition']['symbol-table']
local arch = select(2, table.find(symbolTable, nil, function(t) return t._attr.name == 'v0.47.05 linux64' end))
local md5 = arch['md5-hash']._attr.value -- TODO verify
-- [=[ 162 of these
--print'global-address'
for i,var in ipairs(arch['global-address']) do
	--print(i, var._attr.name, var._attr.value)
	mem[var._attr.name] = {addr = var._attr.value}
end
--]=]

--[=[ 
print'vtable-address'	-- 940 of these
for i,var in ipairs(arch['vtable-address']) do
	if var._attr.mangled then
		print(i, var._attr.name, var._attr.mangled, var._attr.offset)
	else
		print(i, var._attr.name, var._attr.value)
	end
end
--]=]
--]]

-- [[ holds the type information
-- calling xmlparse a 2nd time produces errors.  hmm.
local globals = xmlparse(assert((dfhacksrcdir/'xml/df.globals.xml'):read()))
--for k,v in pairs(codegenout['ld:data-definition']) do print(k,v) end
-- 160 of these
for i,var in ipairs(globals['data-definition']['global-object']) do
	local name = var._attr.name
	if var._attr['type-name'] then
		-- then expect a type name
		local addr = mem[var._attr.name].addr
		if not addr then
			print('-- global '..name..' has no address...')
		else
			print('df.'..var._attr.name..' = ffi.cast("'..var._attr['type-name']..'*", '..addr..')')
		end
	else
		print(i, '-- TODO', var._attr.name)
		for k,v in pairs(var) do
			print(i,k,v)
		end
do return end
	end
end
--for k,v in pairs(globals['data-definition']['global-object']) do print(k,v) end
--]]


