#!/usr/bin/env luajit
--[[
quick port of dfhack's codegen.out.xml into a lua file (so i don't have to parse the xml at runtime)
run this from the root dir, so everything is offline/

turns out xml2lua isn't a dom parser, so ...
--]]

local path = require 'ext.path'
local table = require 'ext.table'

local dfhacksrcdir = path'../../other/dfhack-0.47.05-r8/library/'

local htmlparser = require 'htmlparser'
local htmlcommon = require 'htmlparser.common'

local ffi = require 'ffi'
local osarch = ffi.os..'_'..ffi.arch	-- one dereference instead of two
local dfosarch = assert(({
	Windows_x86 = 'SDL win32',	-- v0.47.05 SDL win32
	Windows_x64 = 'SDL win64',		
	Linux_x86 = 'linux32',
	Linux_x64 = 'linux64',	-- v0.47.05 linux64
	OSX_x86 = 'osx32',
	OSX_x64 = 'osx64',
})[osarch])
local dfos = assert(({
	Linux = 'linux',
	Windows = 'windows',
	OSX = 'darwin',
})[ffi.os])


local md5
local vars = {}

local symbols = htmlparser.parse(assert((dfhacksrcdir/'xml/symbols.xml'):read()))
local symbolsDataDef = htmlcommon.findtag(symbols, 'data-definition')
local symbolsArch = htmlcommon.findchild(symbolsDataDef, 'symbol-table', {name='v0.47.05 '..dfosarch, ['os-type']=dfos})
for _,ch in ipairs(symbolsArch.child) do
	if ch.tag == 'md5-hash' then
		assert(not md5)
		md5 = htmlcommon.findattr(ch, 'value')
	elseif ch.tag == 'global-address' then
		-- 162 of these
		local name = assert(htmlcommon.findattr(ch, 'name'), "expected name")
		local value = assert(htmlcommon.findattr(ch, 'value'), "expected value")
		vars[name] = {name=name, addr=value}
	elseif ch.tag == 'vtable-address' then
		-- 940 of these
		local name = assert(htmlcommon.findattr(ch, 'name'), "expected name")
		local value = htmlcommon.findattr(ch, 'value')
		local mangled = htmlcommon.findattr(ch, 'mangled')
		local offset = htmlcommon.findattr(ch, 'offset')
		assert(value or (mangled and offset), "expected either value or both mangled and offset")
		vars[name] = {name=name, addr=value or offset, mangled=mangled}
	else
		error("unknown symbol-table child tag: "..tostring(ch.tag))
	end
end

--[[
-- offset by linux address
-- hmm need to do this at runtime?
ok while dfhack library/include/Memory.h does list these,
it only assigns them in Process::getBase
which I only see called by Process-windows (not by linux or osx ...)
also called in VersionInfoFactory::ParserVersion setBase for all OS's
so this is handy ...
--]]
--[[
local baseaddr = assert(({
	Windows_x64 = 0x140000000, Windows_x86 = 0x400000,
	OSX_x64 = 0x100000000, OSX_x86 = 0x1000,
	Linux_x64 = 0x400000, Linux_x86 = 0x8048000,
})[osarch], "couldn't find baseaddr for os/arch "..tostring(osarch))
print(('-- image base: 0x%x'):format(baseaddr))
for _,var in pairs(vars) do
	if var.addr then
		var.addr = var.addr + baseaddr
	end
end
--]]

print"local ffi = require 'ffi'"
local globals = htmlparser.parse(assert((dfhacksrcdir/'xml/df.globals.xml'):read()))
local globalsDataDef = htmlcommon.findtag(globals, 'data-definition')
for _,ch in ipairs(globalsDataDef.child) do
	if type(ch) == 'string' then	 -- text node ... used as comments
	elseif ch.type == 'comment' then	-- comment node
	elseif ch.tag == 'enum-type' then
		-- TODO make enum code
	elseif ch.tag == 'global-object' then
		local name = htmlcommon.findattr(ch, 'name')
		local typename = htmlcommon.findattr(ch, 'type-name')
		local var = vars[name]
		if not var then
			print('-- global '..name..' has no address...')
		elseif typename then
			local comment = ({
				bool = true,
				int32_t = true,
			})[typename] and '' or '--'
			print(comment.."df."..name.." = ffi.cast('"..typename.."*', "..('0x%x'):format(var.addr)..")")
		else
			-- is a singleton structure
			if ch.child 
			and #ch.child == 1 
			and ch.child[1].type == 'tag'
			and ch.child[1].tag == 'enum'
			then
				-- only one field.  typedef.  maybe an enum.
				-- how come the base-type is specified in the variable and not in the type definition?
				local typename = htmlcommon.findattr(ch.child[1], 'type-name')
				local basetype = htmlcommon.findattr(ch.child[1], 'base-type')
				-- in fact for that reason, how about I don't make typedefs of enums ...
				--print('ffi.cdef[[typedef '..basetype..' df_enum_'..typename..';]]')
				-- typename will point to the enum info
				-- basetype is the C type
				print("df."..name.." = ffi.cast('"..basetype.."*', "..('0x%x'):format(var.addr)..")")
			else
				print('-- TODO '..name)
			end
		end
	else
		error("unknown node: "..tostring(ch.type))
	end
end
