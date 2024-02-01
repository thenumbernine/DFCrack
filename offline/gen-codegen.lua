#!/usr/bin/env luajit
--[[
quick port of dfhack's codegen.out.xml into a lua file (so i don't have to parse the xml at runtime)
run this from the root dir, so everything is offline/

turns out xml2lua isn't a dom parser, so ...
--]]

local path = require 'ext.path'
local tolua = require 'ext.tolua'
local table = require 'ext.table'

local dfhacksrcdir = path'../../other/dfhack-0.47.05-r8/library/'

local htmlparser = require 'htmlparser'
local htmlcommon = require 'htmlparser.common'

local md5
local vars = {}

local symbols = htmlparser.parse(assert((dfhacksrcdir/'xml/symbols.xml'):read()))
local symbolsDataDef = htmlcommon.findtag(symbols, 'data-definition')
local arch = htmlcommon.findchild(symbolsDataDef, 'symbol-table', {name='v0.47.05 linux64', ['os-type']='linux'})
for _,ch in ipairs(arch.child) do
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

-- offset by linux address
-- hmm need to do this at runtime?
local ffi = require 'ffi'
local baseaddr = ({
	Windows = {x64 = 0x140000000, x86 = 0x400000},
	OSX = {x64 = 0x100000000, x86 = 0x1000},
	Linux = {x64 = 0x400000, x86 = 0x8048000},
})[ffi.os][ffi.arch]
for _,var in pairs(vars) do
	if var.addr then
		var.addr = var.addr + baseaddr
	end
end

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
