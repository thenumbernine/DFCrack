#!/usr/bin/env lua
--[[
quick port of dfhack's codegen.out.xml into a lua file (so i don't have to parse the xml at runtime)
run this from the root dir, so everything is offline/
--]]
local path = require 'ext.path'
local tolua = require 'ext.tolua'
local xml = path'offline/codegen.out.xml':read()	-- incomplete xml document ... why
--local xml = path'offline/tmp.xml':read()

-- hmm results via out arg, hmmmmm... why would you do this.
local handler = require 'xmlhandler.tree'
local xml2lua = require 'xml2lua'
local parser = xml2lua.parser(handler)
parser:parse(xml)

path'offline/codegen.lua':write('return '..tolua(handler.root))
