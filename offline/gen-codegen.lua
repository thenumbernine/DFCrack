#!/usr/bin/env luajit
--[[
quick port of dfhack's codegen.out.xml into a lua file (so i don't have to parse the xml at runtime)
run this from the root dir, so everything is offline/
turns out xml2lua doesn't preserve node order so I'll use my htmlparser which does
hmm too many edge cases
maybe I'll just write a filter for the already-generated headers themselves...
... nah, I think it's easier to just parse the xml, even tho there are a ton of edge cases for something as simple as just determining the type of a field ...
--]]

local path = require 'ext.path'
local table = require 'ext.table'
local string = require 'ext.string'

local thisDFVersion = 'v0.47.05'

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
	name = thisDFVersion..' '..dfhack_osarch,
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

-- primitive type names - don't require, don't transform
local primitiveTypeNames = {
	void = true,
	bool = true,
	char = true,
	['unsigned char'] = true,
	['signed char'] = true,
	int8_t = true,
	int16_t = true,
	int32_t = true,
	uint8_t = true,
	uint16_t = true,
	uint32_t = true,
	short = true,
	['unsigned short'] = true,
	['signed short'] = true,
	int = true,
	['unsigned int'] = true,
	['signed int'] = true,
	long = true,	-- long is ... int64?
	float = true,
	double = true,
	
	['s-float'] = 'float',	-- not sure where I should be doing this translation.  the lhs is an xml tag, the rhs is the C type.
	['stl-string'] = 'std_string',
	['df-flagarray'] = 'df_flagarray',
}
-- reserved = do require, don't transform
local reservedTypeNames = table(primitiveTypeNames, {
	'vector_bool',
	'vector_string',
	'vector_int',
}):setmetatable(nil)

local function snakeToCamelCase(name)
	return string.split(name, '_'):mapi(function(part,i)
		return i == 1 and part or part:sub(1,1):upper()..part:sub(2)
	end):concat()
end

local function snakeToCamelCaseUpper(name)
	assert(type(name) == 'string')
	return string.split(name, '_'):mapi(function(part)
		return part:sub(1,1):upper()..part:sub(2)
	end):concat()
end


local function makeTypeName(name)
	assert(type(name) == 'string')
	return reservedTypeNames[name]
		and name
		or snakeToCamelCaseUpper(name)
end

local function preprocess(tree)
	for i=#tree,1,-1 do
		local ch = tree[i]
		-- TODO also handle string children here?
		if type(ch) == 'string' then
			-- remove text nodes.  they're not used. of course.
			table.remove(tree, i)
		elseif type(ch) == 'table' then
			-- remove <comment> nodes ... because xml ... smh
			if (ch.type == 'tag' and ch.tag == 'comment')
			-- remove real xml comments
			or ch.type == 'comment'
			then
				table.remove(tree, i)
			elseif ch.child then
				preprocess(ch.child)
				if #ch.child == 0 then
					ch.child = nil
				end
			end
		end
	end
end

local class = require 'ext.class'

local Type = class()
function Type:init(name) self.name = assert(name) end
function Type:makeLuaName()
	local res = reservedTypeNames[self.name]
	if res == true then res = self.name end
	if res then return res end
	return makeTypeName(self.name)
end
function Type:getBase() return self end
function Type:declare(var)
	if var then
		var = snakeToCamelCase(var)
	end
	return self:makeLuaName()..' '..(var or '')
end
function Type:addTypeUsed(typesUsed)
	local baseType = self:getBase().name
	if not baseType then return end
	if not reservedTypeNames[baseType] then
		typesUsed[makeTypeName(baseType)] = true
	end
end

local ArrayType = Type:subclass()
function ArrayType:init(base, count)
	assert(Type:isa(base))
	self.base = assert(base)
	self.count = assert(count)
end
function ArrayType:getBase() return self.base:getBase() end
function ArrayType:makeLuaName()
	return self.base:makeLuaName()..'['..self.count..']'
end
function ArrayType:declare(var)
	if var then
		var = snakeToCamelCase(var)
	end
	return self.base:declare(var)..'['..self.count..']'
end

local PtrType = Type:subclass()
function PtrType:init(base)
	assert(Type:isa(base))
	self.base = assert(base)
end
function PtrType:getBase()
	return self.base:getBase()
end
-- [[
function PtrType:declare(var)
	-- if this is a pointer-to-an-array then you als need to wrap parenthesis
	if ArrayType:isa(self.base) then
		return self.base.base:declare''
			..' (*'..(var or '')..')['..self.base.count..']'
	end
	-- base (*field)[count]
	-- and if you do that ... you also need the field name
	return PtrType.super.declare(self, var)
end
--]]
function PtrType:makeLuaName()
--[[
	-- if this is a pointer-to-an-array then you als need to wrap parenthesis
	if ArrayType:isa(self.base) then
		return self.base.base:makeLuaName()..' (*)'..self.base.count
	end
--]]
	-- base (*field)[count]
	-- and if you do that ... you also need the field name
	return self.base:makeLuaName()..' *'
end

local STLVectorType = Type:subclass()
function STLVectorType:init(T)
	assert(Type:isa(T))
	self.T = T
end
function STLVectorType:getBase() return self.T:getBase() end
function STLVectorType:makeLuaName()
	-- TODO the suffix substitution will screw up for vector-of-pointers-to-fixed-size-arrays
	return 'vector_'..self.T:makeLuaName():gsub(' %*', '_ptr')
end

local STLDequeType = Type:subclass()
function STLDequeType:init(T)
	assert(Type:isa(T))
	self.T = T
end
function STLDequeType:getBase() return self.T:getBase() end
function STLDequeType:makeLuaName()
	return 'deque_'..self.T:makeLuaName():gsub(' %*', '_ptr')
end


local AnonStructType = Type:subclass()
function AnonStructType:init() end
function AnonStructType:getBase() return self end
function AnonStructType:makeLuaName() return '' end	-- assume the caller does stuff right
function AnonStructType:addTypeUsed(typesUsed) end


local function buildTypesUsed(typesUsed)
	return table.keys(typesUsed):sort():mapi(function(t)
		local w = t:match'[%a_][%a%d_]*'
		if not w then error("got a bad type "..t) end
		return "require 'df."..w.."'"
	end):concat'\n'
end

-- make an enum type, write it to its respective file
local function makeEnumType(node)
	local out = table()
	-- TODO doesn't have type-name for some nested enum inline type declarations ...
	-- in those cases, pick the name from the struct and field name?
	local enumTypeName = assert(htmlcommon.findattr(node, 'type-name'))
	enumTypeName = makeTypeName(enumTypeName)
	local enumBaseType = htmlcommon.findattr(node, 'base-type') or 'int32_t'
	out:insert('typedef '..enumBaseType..' '..enumTypeName..';')
	out:insert('enum {')
	local anonIndex = 1
	local lastEnumValue = -1
	for _,fieldnode in ipairs(node.child) do
		if fieldnode.type == 'tag' and fieldnode.tag == 'enum-item' then
			local enumName = htmlcommon.findattr(fieldnode, 'name')
			if enumName then
				enumName = snakeToCamelCase(enumName)
			else
				enumName = 'anon'..anonIndex
				anonIndex = anonIndex + 1
			end
			local enumValue = htmlcommon.findattr(fieldnode, 'value')
			if enumValue then
				enumValue = assert(tonumber(enumValue))
				lastEnumValue = enumValue
			else
				lastEnumValue = lastEnumValue + 1	 -- track but don't write
			end
			out:insert('\t'..enumTypeName..'_'..enumName..(enumValue and (' = '..enumValue) or '')..',')
		end
	end
	out:insert('\tNum_'..enumTypeName..' = '..lastEnumValue..',')
	out:insert'};'
	return out:concat'\n'
end

local makeStructNode
local baseFieldName
local makeTypeNode

--[[
I think the intended interpretation is, for a particular global-type/field-type/templated-type is ...
1) look at attr type-name
2) look at attr pointer-type , then treat this as ({type-name} *) 
3) look for a single child element
4) multiple child elements = implicit struct
--]]
local function getTypeFromAttrOrChildren(node, namespace, typesUsed)
	-- this is always passed a value or variable
	-- but sometimes from 
	assert(namespace)
	
	local typeName = htmlcommon.findattr(node, 'type-name')
	if typeName then return Type(typeName) end
	
	local pointerType = htmlcommon.findattr(node, 'pointer-type')
	if pointerType then return PtrType(Type(pointerType)) end

	if node.child then
		assert(#node.child > 0)
		
		-- single child node is the type ... not a struct of a single child as xml layout in other places might imply ...
		if #node.child == 1 then
			local ch = node.child[1]
			assert(ch.type == 'tag')
			return makeTypeNode(
				ch, 
				namespace,
				typesUsed
			)
		end

		-- implicit inline struct
		return makeStructNode(
			node,
			namespace:concat'_'..makeTypeName(baseFieldName or ''),
			namespace,
			typesUsed
		)
	end

	-- no type
	return nil, ''
end

-- hmm try to use getTypeFromAttrOrChildren more and makeTypeNode less
function makeTypeNode(fieldnode, namespace, typesUsed)
	assert(typesUsed)
	local fieldtag = fieldnode.tag

	-- out for this type node
	local out = table()

	-- try to get the type
	local result, fieldType = assert(xpcall(function()

		-- sometimes the type is in the tag name, some times it is in the type-name attribute ...
		if fieldtag == 'static-string' then
			local arrayCount = htmlcommon.findattr(fieldnode, 'size')
			assert(arrayCount, "got a static-string without a size")
			return ArrayType(Type'char', arrayCount)
		elseif fieldtag == 'static-array' then

			-- here, parse the children as if they were a type of their own
			-- then append the arrayCount to what you get

			local arrayCount = htmlcommon.findattr(fieldnode, 'count')
			-- not specified? maybe it's in index-enum
			if not arrayCount then
				local indexEnum = htmlcommon.findattr(fieldnode, 'index-enum')
				if not indexEnum then
					error("I don't know how to get the size of this array")
				else
					indexEnum = makeTypeName(indexEnum)
					arrayCount = 'Num_'..indexEnum
				end
			end

			local baseType, code = getTypeFromAttrOrChildren(fieldnode, namespace, typesUsed)
			assert(baseType)
			if code and string.trim(code) ~= '' then
				out:insert(code)
			end
			return ArrayType(baseType, arrayCount)

		elseif fieldtag == 'compound' then
			local fieldTypeStr = htmlcommon.findattr(fieldnode, 'type-name')
			if fieldTypeStr then
				assert(not fieldnode.child, "found a compound with a type-name and with children ...")
			else
				assert(fieldnode.child, "found a compound without a type and without children...")

				structType, fieldTypeStr = makeStructNode(
					fieldnode,
					nil, -- no trailing ;, no name, anonymous struct
					namespace,
					typesUsed)
				-- insert the anonymous nested struct
				out:insert('\t'..fieldTypeStr:gsub('\n', '\n\t'))
				return structType
			end
			return Type(fieldTypeStr)
		elseif fieldtag == 'bitfield' then
			-- TODO sometimes this has a type-name attr , and then i guess it points to another def somewhere else .... smh just write it in C++ not XML
			local fieldTypeStr = htmlcommon.findattr(fieldnode, 'type-name')
				or htmlcommon.findattr(fieldnode, 'base-type')
				or 'int32_t'	-- sometimes a bitfield has a name and some flag bits, but not base-type or type-name.  ex: cave_column_rectangle::unk_7
			return Type(fieldTypeStr)
		elseif fieldtag == 'stl-deque' then
			-- uhhh ... same as stl-vector, sometimes no type-name nor pointer-type nor single-child-node are used, and an inline struct is implied
			local templateType, code = getTypeFromAttrOrChildren(fieldnode, namespace, typesUsed)
			assert(templateType)
			if code and string.trim(code) ~= '' then
				out:insert(code)
			end
			return STLDequeType(templateType)
		elseif fieldtag == 'stl-vector' then
			local templateType, code = getTypeFromAttrOrChildren(fieldnode, namespace, typesUsed)
			-- stl-vector has default template-type of void*
			templateType = templateType or PtrType(Type'void')
			if code and string.trim(code) ~= '' then
				out:insert(code)
			end
			return STLVectorType(templateType)
		elseif fieldtag == 'df-flagarray' then
			local indexEnum = htmlcommon.findattr(fieldnode, 'index-enum')
			return Type'df-flagarray'
		elseif fieldtag == 'pointer' then
			local ptrBaseType, code = getTypeFromAttrOrChildren(fieldnode, namespace, typesUsed)
			-- pointer has default base type of void, i.e. the pointer has a default type of void*
			ptrBaseType = ptrBaseType or Type'void'
			
			if code and string.trim(code) ~= '' then
				out:insert(code)
			end

			--[[ not sure what this does at all
			local isArray = htmlcommon.findattr(fieldnode, 'is-array') == 'true'
			--]]
			
			return PtrType(ptrBaseType)
		elseif fieldtag == 'enum' then
			-- TODO here, if we have children, create a new type based on the children
			-- and use the field name (and the struct name) as the enum name
			-- and insert it before the struct
			local fieldTypeStr = htmlcommon.findattr(fieldnode, 'type-name')
			-- if no type-name, then ... base-type ... ?
			-- and if base-type exists ... then ...
			-- ... use the name of the field of the parent node?
			-- which had beter be a static-array?
			if fieldTypeStr then
				assert(not fieldnode.child)
			else
				assert(fieldnode.child)
				out:insert'-- TODO build a new inline enum here'
				fieldTypeStr = htmlcommon.findattr(fieldnode, 'base-type') or 'int32_t'
			end

			assert(fieldTypeStr)

			if fieldnode.child then
				out:insert(' -- TODO need to insert an enum here for field '..baseFieldName)
			end

			return Type(fieldTypeStr)
		elseif fieldtag == 'stl-string' then
			return Type'stl-string'
		else
			return Type(fieldtag)	-- prim
		end
	end, function(err)
		return 'for base name '..tostring(baseFieldName)..'\n'
			..'and current tag '..tostring(fieldnode.tag)..'\n'
			..err..'\n'
			..debug.traceback()
	end))
	if not result then error(fieldType) end
	assert(Type:isa(fieldType))
	return fieldType, out:concat'\n'
end

--[[
structNode = element in xml dom
structName = passed into this function, since it may or may not exist
	but it is usually (always?) defined by structNode's 'name' attr
namespace = namespace
typesUsed = used for recording require()'s
--]]
function makeStructNode(structNode, structName, namespace, typesUsed)
	assert(typesUsed)

	local structDefs = table()
	local out = table()

	local result, structType = xpcall(function()

		local parentType = htmlcommon.findattr(structNode, 'inherits-from')
		if not structNode.child then
			assert(parentType)
			parentType = makeTypeName(parentType)
			out:insert('typedef '..parentType..' '..structName..';')
		else
			local structVsUnion = htmlcommon.findattr(structNode, 'is-union') and 'union' or 'struct'
			if structName then
				out:insert('typedef '..structVsUnion..' '..structName..' {')
			else
				out:insert(structVsUnion..' {')
			end
			for _,fieldnode in ipairs(structNode.child) do
				-- tag name is the c-type, name is the field name
				if type(fieldnode) == 'table'
				and fieldnode.type == 'tag'
				then
					-- remove fields that don't belong to this version
					local since = htmlcommon.findattr(fieldnode, 'since')
					if not since or since <= thisDFVersion then
						local fieldtag = fieldnode.tag
						-- ignore some tags
						if fieldtag == 'custom-methods' then
						elseif fieldtag == 'extra-include' then
						elseif fieldtag == 'code-helper' then
						elseif fieldtag == 'virtual-methods' then
							-- TODO make room for the vtable here
						else
							-- might be nil , should only be nil for anonymous struct/union's
							local fieldName = htmlcommon.findattr(fieldnode, 'name')
							
							-- capture the first name.
							-- what to do if it's nil?
							-- it is nil for anonymous nested structs ...
							baseFieldName = fieldName or baseFieldName

							-- since most inline structs are named by their fields ...
							local fieldNamespace = table(namespace) --:append{fieldName and makeTypeName(fieldName)}

							-- TODO can I safely call getTypeFromAttrOrChildren here?
							-- or maybe I can't since too often the element is specifying the type in the tag name ...
							local fieldType, code = makeTypeNode(fieldnode, fieldNamespace, typesUsed)

							assert(Type:isa(fieldType))
							assert(fieldType, "failed to find a type for field name "..tostring(fieldName))
							-- and not unlike the globals,
							-- if no type is specified then we just assume it's an anonymous struct/union
							--assert(fieldName, "failed to find field name for type "..tostring(fieldType))

							if string.trim(code) ~= '' then
								if AnonStructType:isa(fieldType) then
									out:insert(code)
								else
									-- TODO we don't just want one contiguous code for a single ffi.cdef
									-- we want multiple ffi.cdef's with calls for building vectors, deques, etc in between
									structDefs:insert(code)
								end
							end
							out:insert('\t'..fieldType:declare(fieldName or '')..';')

							-- TODO find which file has which type
							fieldType:addTypeUsed(typesUsed)
						end
					end
				end
			end
			-- ugly hack: leeave the ; off the end if we're going to return this to-be-used for anonymous nested structs with vars
			-- TODO if no struct name then we want the caller to insert this struct at the top of the file - no inline structs in luajit ... ? i think?
			-- more specifically, no vectors-of-anon-structs, nor are there in the generated c++ headers
			-- but we do want nameless inline structs because that is used for struct/union memory alignment more than anything
			out:insert('} '..(structName and structName..';' or ''))
		end

	end, function(err)
		return 'for struct '..tostring(structName)..'\n'
			..err..'\n'
			..debug.traceback()
	end)
	if not result then error(structType) end

	local structType
	if structName then
		structType = Type(structName)
	else
		-- I think even nested structs will need name in LuaJIT
		--error("what to call this struct")
		structType = AnonStructType()
	end

	-- TODO the caller needs to ... sometimes ... put this at the top of the other defs
	return structType,
		(structName and (' /* begin struct def '..structName..' */\n') or '')
		..table():append(structDefs, out):concat'\n'..'\n'
		..(structName and (' /* end struct def '..structName..' */\n') or '')
end


local globalStructDefs = table()
local globalObjDefs = table()
local globalTypesUsed = {}

local destdir = path'dfcrack/df'
destdir:mkdir()
for f in (dfhacksrcdir/'xml'):dir() do
	io.stderr:write('processing ', f.path, '\n')
	local res, err = xpcall(function()
		local basefilename = f.path:match'^df%.(.*)%.xml$'
		if not basefilename then
			print("skipping file "..tostring(f))
			return
		end

		-- TODO apply xslt ... or not.
		local dfheaderxml = htmlparser.parse(assert((dfhacksrcdir/'xml'/f):read()))
		preprocess(dfheaderxml)
		local dataDef = htmlcommon.findtag(dfheaderxml, 'data-definition')

		for _,ch in ipairs(dataDef.child) do
			if ch.tag == 'enum-type' then
				local enumTypeName = assert(htmlcommon.findattr(ch, 'type-name'))
				enumTypeName = makeTypeName(enumTypeName)
				local outpath = (destdir/(enumTypeName..'.lua'))
				assert(not outpath:exists(), "file "..outpath.." already exists!")

				local out = table()
				out:insert"local ffi = require 'ffi'"
				out:insert'ffi.cdef[['
				out:insert(makeEnumType(ch))
				out:insert']]'
				outpath:write((
					(out:concat'\n'..'\n'):gsub('}%s+;', '};')
				))

			elseif ch.tag == 'class-type'
			or ch.tag == 'struct-type'
			then
				local typeName = htmlcommon.findattr(ch, 'type-name')
				-- matches global-object with >1 child
				local structName = makeTypeName(typeName)
				assert(structName)

				local outpath = (destdir/(structName..'.lua'))
				assert(not outpath:exists(), "file "..outpath.." already exists!")

				local out = table()
				local typesUsed = {}

				out:insert"local ffi = require 'ffi'"
				out:insert'ffi.cdef[['
				local structType, structStr = makeStructNode(ch, structName, table{structName}, typesUsed)
				if string.trim(structStr) ~= '' then
					out:insert(structStr)
				end
				out:insert']]'

				out:insert(1, buildTypesUsed(typesUsed))

				outpath:write((
					(out:concat'\n'..'\n'):gsub('}%s+;', '};')
				))

			elseif ch.tag == 'bitfield-type' then
				local typename = makeTypeName(assert(htmlcommon.findattr(ch, 'type-name')))
				local basetype = htmlcommon.findattr(ch, 'base-type') or 'uint32_t'

				local outpath = (destdir/(typename..'.lua'))
				assert(not outpath:exists(), "file "..outpath.." already exists!")
				local out = table()

				out:insert"local ffi = require 'ffi'"
				out:insert"ffi.cdef[["
				out:insert("typedef union "..typename.." {")
				out:insert('\t'..basetype..' flags;')
				out:insert('\tstruct {')
				local totalBitCount = 0
				local maxBits = bit.lshift(ffi.sizeof(basetype), 3)
				local anonIndex = 1
				for _,fieldnode in ipairs(ch.child) do
					if fieldnode.type == 'tag' and fieldnode.tag == 'flag-bit' then
						local fieldName = htmlcommon.findattr(fieldnode, 'name')
						if fieldName then
							fieldName = snakeToCamelCase(fieldName)
						else
							fieldName = 'anon' .. anonIndex
							anonIndex = anonIndex + 1
						end
						local count = htmlcommon.findattr(fieldnode, 'count')
						if count then
							count = assert(tonumber(count), "got a count that wasn't a valid number")
						else
							count = 1
						end
						totalBitCount = totalBitCount + count
						if totalBitCount > maxBits then
							error("exceeded our base type number of bits")
						end
						out:insert('\t\t'..basetype..' '..fieldName..' : '..count..';')
					end
				end
				out:insert('\t};')
				out:insert("} "..typename..";")
				out:insert"]]"

				outpath:write((
					(out:concat'\n'..'\n'):gsub('}%s+;', '};')
				))

			elseif ch.tag == 'df-linked-list-type' then
			elseif ch.tag == 'df-other-vectors-type' then


			elseif ch.tag == 'global-object' then
				
				-- accumulate these

				-- TODO duplicate for struct and class below?
				local name = htmlcommon.findattr(ch, 'name')
				local since = htmlcommon.findattr(ch, 'since')
				if since then
					error("haven't got this handled yet") -- cuz no one is using it yet ...
				end

				assert(xpcall(function()

					-- I would dereference [0] each of these
					-- and for fixed-size arrays that'd be great, complete with array bounds
					-- for structs / non-prim-pointers I think that would give a ref to the memory (i think? how does luajit do it?)
					-- (seems luajit has ref &'s in its ctypes / printing info, but doesn't allow them in its casting / for ppl using its API ... i think?)
					-- but for prims, casting to prim ptr and then [0]'ing will give you back the prim data, if not Lua data, rather than a ref
					-- so until then, keep in pointers (and for static-sized arrays, pointer-to-pointers)

					local var = vars[name]
					if not var then
						globalObjDefs:insert('-- global '..snakeToCamelCase(name)..' has no address...')
					else
						-- TODO here read the type just like you would for any other struct-field
						local globalType, code = getTypeFromAttrOrChildren(ch, table{'Global'}, globalTypesUsed)
						assert(globalType)
						assert(Type:isa(globalType))
						globalType:addTypeUsed(globalTypesUsed)
						if code and string.trim(code) ~= '' then
							globalStructDefs:insert(code)
						end
						globalObjDefs:insert("df."..snakeToCamelCase(name).." = ffi.cast('"..PtrType(globalType):declare().."', "..('0x%x'):format(var.addr)..")")
					end
				end, function(err)
					return 'for global '..name..'\n'
						..err..'\n'
						..debug.traceback()
				end))
			else
				error("unknown node: "..require 'ext.tolua'{
					f = tostring(f),
					type = ch.type,
					tag = ch.tag,
				})
			end
		end

	end, function(err)
		return
			'for file '..f..'\n'
			..err..'\n'
			..debug.traceback()
	end)
	if not res then
		io.stderr:write(err)
		break
	end
end

local globalOutPath = (destdir/('globals.lua'))
assert(not globalOutPath:exists(), "file "..globalOutPath.." already exists!")
globalOutPath:write(
	table()
	:append{ (function()
		local s = string.trim(buildTypesUsed(globalTypesUsed))
		return s ~= '' and s or nil
	end)() }
	:append( (function()
		if #globalStructDefs == 0 then return nil end
		return table{
			"local ffi = require 'ffi'",
			"ffi.cdef[[",
		}:append(globalStructDefs):append{
			"]]",
		}
	end)() )
	:append{
		"local df = {}",
	}
	:append(globalObjDefs)
	:append{
		"return df",
	}
	:concat'\n'..'\n'
)
