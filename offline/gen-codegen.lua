#!/usr/bin/env luajit
--[[
quick port of dfhack's codegen.out.xml into a lua file (so i don't have to parse the xml at runtime)
run this from the root dir, so everything is offline/
turns out xml2lua doesn't preserve node order so I'll use my htmlparser which does
hmm too many edge cases
maybe I'll just write a filter for the already-generated headers themselves...
--]]

local path = require 'ext.path'
local table = require 'ext.table'

local dfhacksrcdir = path'../../other/dfhack-0.47.05-r8/library/'

local htmlparser = require 'htmlparser'
local htmlcommon = require 'htmlparser.common'

local ffi = require 'ffi'
local osarch = ffi.os..'_'..ffi.arch	-- one dereference instead of two
local dfhack_osarch = assert(({
	Windows_x86 = 'SDL win32',	-- v0.47.05 SDL win32
	Windows_x64 = 'SDL win64',		
	Linux_x86 = 'linux32',
	Linux_x64 = 'linux64',	-- v0.47.05 linux64
	OSX_x86 = 'osx32',
	OSX_x64 = 'osx64',
})[osarch])
local dfhack_os = assert(({
	Linux = 'linux',
	Windows = 'windows',
	OSX = 'darwin',
})[ffi.os])


local md5
local vars = {}

local symbols = htmlparser.parse(assert((dfhacksrcdir/'xml/symbols.xml'):read()))

--local symbolsDataDef = htmlcommon.findtag(symbols, 'data-definition')
local symbolsDataDef = require 'htmlparser.xpath'(symbols, '/data-definition')[1]

local symbolsArch = htmlcommon.findchild(symbolsDataDef, 'symbol-table', {
	name = 'v0.47.05 '..dfhack_osarch,
	['os-type'] = dfhack_os,
})
for _,ch in ipairs(symbolsArch.child) do
	if ch.tag == 'md5-hash' then
		assert(not md5)
		md5 = htmlcommon.findattr(ch, 'value')	-- TODO do something with this if you want
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
local structDefs = table()
local ptrDefs = table()	-- or I could jut cycle thru a second time and output these

local function makeTypeName(name)
	return 'dfhack_'..name
end

for f in (dfhacksrcdir/'xml'):dir() do
	local res, err = xpcall(function()
		if f.path:match'^df%.' then
			local globals = htmlparser.parse(assert((dfhacksrcdir/'xml'/f):read()))
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
						ptrDefs:insert('-- global '..name..' has no address...')
					elseif typename then
						local comment = ({
							bool = true,
							int32_t = true,
						})[typename] and '' or '--'
						ptrDefs:insert(comment.."df."..name.." = ffi.cast('"..typename.."*', "..('0x%x'):format(var.addr)..")")
					else
						-- is a singleton structure
						-- TODO dont do this? instead use the struct-type?
						if not ch.child then
						elseif #ch.child == 1 
						and ch.child[1].type == 'tag'
						then
							local typenode = ch.child[1]
							if typenode.tag == 'int32_t' then	-- or any other primitive...
								local typename = typenode.tag
								ptrDefs:insert("df."..name.." = ffi.cast('"..typename.."*', "..('0x%x'):format(var.addr)..")")
							elseif typenode.tag == 'enum' then
								-- only one field.  typedef.  maybe an enum.
								-- how come the base-type is specified in the variable and not in the type definition?
								local typename = htmlcommon.findattr(typenode, 'type-name')
								local basetype = htmlcommon.findattr(typenode, 'base-type')
								-- in fact for that reason, how about I don't make typedefs of enums ...
								--print('ffi.cdef[[typedef '..basetype..' df_enum_'..typename..';]]')
								-- typename will point to the enum info
								-- basetype is the C type
								ptrDefs:insert("df."..name.." = ffi.cast('"..basetype.."*', "..('0x%x'):format(var.addr)..")")
							elseif typenode.tag == 'static-array' then
								--[[ same here and stl-vector
								-- type is either with 0-child in the attr ('type-name' for static-array)
								-- or as a 1-child
								local typename = assert(htmlcommon.findattr(typenode, 'type-name'), "static-array expected attr type-name")
								local count = assert(htmlcommon.findattr(typenode, 'count'), "static-array expected attr count")
								-- ok like C, luajit ffi doesn't let you just cast to array (or ... whats the syntax?)
								-- but you can typedef arrays and then cast to that type ... as a pointer
								-- so that if you do this, your subsequet derferences will need to be [0][index]
								-- but its not like luajit or C bounds-checks anyways
								-- so other than wasting typedefs, whats the point here?
								-- but for record-keeping i just might make those typedefs later ...
								--ptrDefs:insert("df."..name.." = ffi.cast('"..typename.."["..count.."]*', "..('0x%x'):format(var.addr)..")")
								ptrDefs:insert("df."..name.." = ffi.cast('"..typename.."*', "..('0x%x'):format(var.addr)..")")
								--]]
								-- [[
								ptrDefs:insert("-- df."..name.." = ffi.cast('static-array*', "..('0x%x'):format(var.addr)..")")
								--]]
							elseif typenode.tag == 'static-string' then
								local size = assert(htmlcommon.findattr(typenode, 'size'), "static-string expected attr size")
								--ptrDefs:insert("df."..name.." = ffi.cast('char["..size.."]*', "..('0x%x'):format(var.addr)..")")
								ptrDefs:insert("df."..name.." = ffi.cast('char*', "..('0x%x'):format(var.addr)..")")
							elseif typenode.tag == 'stl-vector' then
								-- ok now we can have 0-children and attr pointer-type
								-- or we can have 1 child with more info as to what the value refers to
								ptrDefs:insert("-- df."..name.." = ffi.cast('vector<TODO>*', "..('0x%x'):format(var.addr)..")")
							else
								error('need to handle single-child singleton-type for global '..name)
							end
						else
							local structName = 'dfhack_globalobject_'..name
							structDefs:insert('typedef struct {')
							for _,fieldnode in ipairs(ch.child) do
								-- tag name is the c-type, name is the field name
								if type(fieldnode) == 'table'
								and fieldnode.type == 'tag'
								then
									local fieldname = htmlcommon.findattr(fieldnode, 'name')
									assert(fieldname, "failed to find field name for singleton type of global "..tostring(name))
									structDefs:insert('\t'..fieldnode.tag..' '..fieldname..';')
								end
							end
							structDefs:insert('} '..structName..';')
							structDefs:insert'\n'
							typename = structName
							ptrDefs:insert("df."..name.." = ffi.cast('"..typename.."*', "..('0x%x'):format(var.addr)..")")
						end
					end
				elseif ch.tag == 'class-type' 
				or ch.tag == 'struct-type'
				then
					local typename = htmlcommon.findattr(ch, 'type-name')
					-- matches global-object with >1 child
					local structName = makeTypeName(typename)
					local parentType = htmlcommon.findattr(ch, 'inherits-from')
					if not ch.child then
						assert(parentType)
						parentType = makeTypeName(parentType)
						structDefs:insert('typedef '..parentType..' '..structName..';')
					else
						structDefs:insert('typedef struct {')
						for _,fieldnode in ipairs(ch.child) do
							-- tag name is the c-type, name is the field name
							if type(fieldnode) == 'table'
							and fieldnode.type == 'tag'
							then
								local fieldtag = fieldnode.tag
								-- ignore some tags
								if fieldtag == 'custom-methods' then
								elseif fieldtag == 'extra-include' then
								elseif fieldtag == 'virtual-methods' then
									-- TODO make room for the vtable here
								else
									-- sometimes the type is in the tag name, some times it is in the type-name attribute ...
									local fieldtype
									if fieldtag == 'compound' then
										fieldtype = htmlcommon.findattr(fieldnode, 'type-name')
									elseif fieldtag == 'bitfield' then
										-- TODO sometimes this has a type-name attr , and then i guess it points to another def somewhere else .... smh just write it in C++ not XML
										fieldtype = 
											htmlcommon.findattr(fieldnode, 'type-name')
											or htmlcommon.findattr(fieldnode, 'base-type')
											or 'int32_t'	-- sometimes a bitfield has a name and some flag bits, but not base-type or type-name.  ex: cave_column_rectangle::unk_7
									elseif fieldtag == 'stl-vector' then
										local vectype = htmlcommon.findattr(fieldnode, 'type-name')
										if not vectype then
											local ptrtype = htmlcommon.findattr(fieldnode, 'pointer-type')
											if ptrtype then
												vectype = ptrtype .. '_ptr'
											end
										end
										if not vectype then
											-- see if it has just 1 child
											-- smh how many ways do you need just to specify a type ...
											if fieldnode.child
											and #fieldnode.child == 1 
											then
												-- then try to read a single type from the ... smh
												-- this xml doesn't distinguish between single-field structs and fields themselves
												vectype = fieldnode.child[1].tag
											end
										end
										-- TODO seems if no template is provided for std::vector then they just use void*
										vectype = vectype or 'void_ptr'
										fieldtype = 'std_vector_'..vectype
									else
										fieldtype = fieldtag	-- prim
									end
									local fieldname = htmlcommon.findattr(fieldnode, 'name')
									assert(fieldtype, "failed to find a type for field name "..tostring(fieldname).." on struct "..structName)
									-- and not unlike the globals,
									-- if no type is specified then we just assume it's a struct or something
									assert(fieldname, "failed to find field name for type "..tostring(fieldtype)..' for struct '..structName)
									structDefs:insert('\t'..makeTypeName(fieldtype)..' '..fieldname..';')
								end
							end
						end
						structDefs:insert('} '..structName..';')
					end
					structDefs:insert'\n'
					typename = structName
		
				elseif ch.tag == 'bitfield-type' then
				elseif ch.tag == 'df-linked-list-type' then
				elseif ch.tag == 'df-other-vectors-type' then
				else
					error("unknown node: "..require 'ext.tolua'{
						f = tostring(f),
						type = ch.type,
						tag = ch.tag,
					})
				end
			end
		end
	end, function(err)
		return 
			'for file '..f..'\n'
			..err..'\n'
			..debug.traceback()
	end)
	if not res then io.stderr:write(err) end
end

print"local ffi = require 'ffi'"
print'ffi.cdef[['
print(structDefs:concat'\n'..'\n')
print']]'
print'local df = {}'
print(ptrDefs:concat'\n'..'\n')
print'return df'
