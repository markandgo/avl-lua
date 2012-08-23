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
]]--

-- AVL tree based on: http://www.geeksforgeeks.org/archives/17679
-- ==== AVL tree functions ====

local b = {}
b.__index = b

local newLeaf = function(a)
	return setmetatable({
	value	= a,
	isLeaf	= true,
	height	= 0, -- height of subtree starts at 0
	},b)
end

local getHeight = function(node)
	if node then return node.height else return -1 end
end

local getBalance = function(node) -- return balance factor, left heavy is negative
	return getHeight(node.right)-getHeight(node.left)
end

local rotateNode = function(root,rotation_side,opposite_side) -- rotate and return new root
	local pivot				= root[opposite_side]
	root[opposite_side]		= pivot[rotation_side] -- http://en.wikipedia.org/wiki/Tree_rotation
	pivot[rotation_side]	= root
	root,pivot				= pivot,root
	pivot.height	= math.max(getHeight(pivot.left),getHeight(pivot.right))+1 -- update pivot height FIRST to get correct root height
	root.height		= math.max(getHeight(root.left),getHeight(root.right))+1
	return root
end

local balanceNode = function(root) -- balance tree and return new root node
	local rotation_side,opposite_side,pivot,rotate_pivot
	local balance = getBalance(root)
	if balance > 1 then
		pivot = root.right
		local pBalance = getBalance(pivot)
		if pBalance < 0 then rotate_pivot = true end -- do double rotation
		rotation_side,opposite_side = 'left','right'
	elseif balance < -1 then
		pivot = root.left
		local pBalance = getBalance(pivot)
		if pBalance > 0 then rotate_pivot = true end
		rotation_side,opposite_side = 'right','left'
	end
	if rotation_side then
		if rotate_pivot then
			root[opposite_side] = rotateNode(pivot,opposite_side,rotation_side) 
		end
		root = rotateNode(root,rotation_side,opposite_side)
	end
	return root
end

local traverse
traverse = function(node,a,b) -- a and b determines order
	if node then
		if node.isLeaf then
			coroutine.yield(node.value)
		else
			traverse(node[a],a,b)
			coroutine.yield(node.value)
			traverse(node[b],a,b)
		end
	end
end

-- Insert given element
function b:insert(a)
	if not self then
		return newLeaf(a)
	else
		if a < self.value then
			self.left	= b.insert(self.left,a)
		else
			self.right	= b.insert(self.right,a)
		end
		self.isLeaf	= nil
		self.height	= math.max(getHeight(self.left),getHeight(self.right)) + 1 -- update height from insertion
		self		= balanceNode(self)
	end
	return self
end

b.iterate = function(self,mode)
	local a,b
	if not mode then a,b = 'left','right'
	else a,b = 'right','left' end
	return coroutine.wrap(function()
		traverse(self,a,b)
	end)
end

-- Find given element and return it
function b:find(a) 
	if self then
		local v = self.value
		if a == v then
			return a
		elseif not self.isLeaf then
			if a < v then
				return b.find(self.left,a)
			else
				return b.find(self.right,a)
			end
		end
	end
end

function b:delete(a)
	if self then
		local v = self.value
		if a == v then			
			if not self.left or not self.right then -- no successor
				return self.left or self.right
			else -- look for successor value
				local sNode = self.right
				while sNode.left do
					sNode = sNode.left
				end
				local _,v = b.delete(self,sNode.value) -- delete node with successor value
				self.value = v -- replace deleted node value with successor value
			end
		elseif not self.isLeaf then
			if a < v then
				self.left = b.delete(self.left,a)
			else
				self.right = b.delete(self.right,a)
			end
		end
		self.height	= math.max(getHeight(self.left),getHeight(self.right)) + 1
		return balanceNode(self),a
	end
end

-- ==== proxy functions ====

local proxyIterator = function(state)
	local root		= state.proxy.__index
	local iter		= b.iterate(root,state.mode) 
	local values	= state.proxy.values
	local key		= iter(root)
	while key do
		local key_table = values[key]
		for i = 1,#key_table do
			coroutine.yield(key,key_table[i])
		end
		key = iter()
	end
end

local proxy = {}

proxy.insert	= function(self,key,value) -- insert key value pair, value = key when no value
	value = value or key
	if not self.values[key] then 
		self.values[key] = {value}
		self.__index = b.insert(self.__index,key)
	else
		table.insert(self.values[key],value)
	end 
end
proxy.find		= function(self,key,value) -- return key value pair if exist, if no value, return list of values for that key
	local key_table = self.values[key]
	if key_table then
		if value then
			for i = 1,#key_table do
				if key_table[i] == value then
					return key,value
				end
			end
		else
			local list = {}
			for i = 1,#key_table do
				list[#list+1] = key_table[i]
			end
			return list
		end
	end
end
proxy.iterate	= function(self,mode) -- iterate over all key value pairs
	local state = {mode = mode,proxy = self}
	return coroutine.wrap(proxyIterator),state
end
proxy.delete	= function(self,key,value)
	if not value then -- delete key entirely
		self.values[key]	= nil
		self.__index	= b.delete(self.__index,key) 
	else -- delete key value pair
		local key_table = self.values[key]
		for i = #key_table,1,-1 do
			if key_table[i] == value then table.remove(key_table,i) end
		end
		if not next(key_table) then proxy.delete(self,key) end
	end
end

return {new = function() -- new list object
	local p	= {values = {}} -- proxy that wraps our binary tree
	return setmetatable(p,{__index = proxy})
end}