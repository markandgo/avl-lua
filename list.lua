--[[
Copyright (c) 2012 Minh Ngo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
and associated documentation files (the "Software"), to deal in the Software without 
restriction, including without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or 
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The list is a wrapper for avl.lua to allow duplicate values
]]--

local path  = (...):match('^.*[%.%/]') or ''
local avl   = require (path .. 'avl')

local iterator = function(state)
	local tree    = state.list.tree
	local iter    = tree:iterate(state.mode) 
	local vc      = state.list.value_counter
	local value   = iter(tree)
	while value do
		for i = 1,vc[value] do
			coroutine.yield(value)
		end
		value = iter()
	end
end

local list    = {tree = avl(),value_counter = {}}
list.__index  = list

-- insert value
list.add = function(self,value,amt) 
	if self.tree:add(value) then 
		self.value_counter[value] = amt or 1
	else
		self.value_counter[value] = self.value_counter[value] + (amt or 1)
	end 
end

list.delete = function(self,value,amt)
	local vc  = self.value_counter
	vc[value] = vc[value] - (amt or math.huge)
	if vc[value] < 1 then
		self.tree:delete(value)
		vc[value] = nil
	end
end

-- return value and amount
list.get = function(self,value) 
	local vc = self.value_counter
	if vc[value] then
		return value,vc[value]
	end
end

list.pop = function(self,side,dup)
	if dup == 'dup' then
		local value = self.tree:pop(side)
		local amt   = self.value_counter[value]
		self.value_counter[value] = nil
		return value,amt
	else 
		local value = self.tree:peek(side)
		local vc    = self.value_counter
		local c     = vc[value] - 1
		vc[value]   = c
		if c < 1 then
			list.pop(self,side,'dup')
		end
		return value,1
	end
end

list.peek = function(self,side)
	return self.tree:peek(side)
end

-- iterate over all key value pairs
list.iterate = function(self,mode) 
	local state = {mode = mode,list = self}
	return coroutine.wrap(iterator),state
end

list.printTree = function(self)
	self.tree:printTree()
end

return setmetatable(list,{__call = 
	function() return setmetatable(
		{
		tree          = avl(),
		value_counter = {},
		},list) 
	end,
})