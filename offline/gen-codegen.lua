#!/usr/bin/env lua
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
			print("df."..name.." = ffi.cast('"..typename.."*', "..var.addr..")")
		else
			-- is a singleton structure
			print('-- TODO '..name)
		end
	else
		error("unknown node: "..tostring(ch.type))
	end
end
