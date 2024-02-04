#!/usr/bin/env luajit
--[[
this tool runs across the generated C++ headers in dfhack and makes a C header for luajit.
here's hoping alignments and sizeof()'s work out =D

todo
* inheritence has to be baked
* no vtables, cuz this is C
* no forward declare strcutres (or you could)
* no includes.

--]]

local path = require 'ext.path'
local table = require 'ext.table'
local string = require 'ext.string'

local dfhacksrcdir = path'../../other/dfhack-0.47.05-r8/library/include/df'
-- only subdir is custom/ so ...
for f in dfhacksrcdir:dir() do
	print(dfhacksrcdir/f)
	local d = (dfhacksrcdir/f):read()
	d = d:match('^'..string.patescape[[
/* THIS FILE WAS GENERATED. DO NOT EDIT. */
#pragma once
#ifdef __GNUC__
#pragma GCC system_header
#endif
]]..'(.*)$')
	local ls = string.split(string.trim(d), '\n'):mapi(function(l)
		return (l:gsub('  ', '\t'))
	end)
	while #ls > 0 and ls[1]:match'^#include' do 
		-- TODO also keep track of ... dag?  other deps? idk? 
		ls:remove(1) 
	end
	assert(ls:remove(1) == 'namespace df {')
	assert(ls:remove() == '}')
	
	-- assert tab?
	for i=1,#ls do
		assert(ls[i]:sub(1,1) == '\t')
		ls[i] = ls[i]:sub(2)
	end

	-- now scan for the end of the struct
	-- cuz after it comes some template specializations
	do
		local j = ls:find(nil, function(l) return l == '};' end)
		assert(j, "didn't find a struct end")
		ls = ls:sub(1, j)
	end

	-- now remove protected members?
	-- are they all just member functions anyways?
	do
		local j = ls:find(nil, function(l) return l == 'protected:' end)
		if j then
			ls = ls:sub(1, j-1):append{ls:last()}
		end
	end

	-- TODO also scan for and remove internal enum typedefs

	for i=#ls-1,2,-1 do
		-- remove all statics
		if ls[i]:match'^\tstatic ' then
			ls:remove(i)
			-- and ... vtable entry?
		else
			-- remove ctors (/methods?)
			
			-- now replace any fields that might be templates with fields that are not
			local ctype, name = ls[i]:match'^\t(.*) (%S+);$'
			if ctype and name then
				local enumtype, basetype = ctype:match'^enum_field<(.*),(.*)>$'
				if enumtype then
					ls[i] = '\t'..basetype..' '..name..';'
				end
			end
		end
	end

	-- TODO maybe have to remove struct fwd declares
	assert(ls:last() == '};')
	local name, parent = ls[1]:match'^struct DFHACK_EXPORT (.*) : (.*) {$'
	if name then
		ls[1] = 'typedef struct '..name..'_t {'
		ls:insert(2, '\t'..parent..'_t super;')	-- TODO make sure it's not used anywhere else
		ls[#ls] = '} '..name..'_t;'
	else
		error("failed to parse struct def "..require 'ext.tolua'(ls[1]))
	end

	for i,l in ipairs(ls) do
		print(i,l)
	end
	break
end
