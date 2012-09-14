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

AVL tree based on: http://www.geeksforgeeks.org/archives/17679
]]--
local insert = table.insert
-- positive BF = right side heavy
-- negative BF = left side heavy
local MAX_BALANCE_FACTOR = 1
local MIN_BALANCE_FACTOR = -1

-- ================
-- PRIVATE
-- ================

local newLeaf = function(a)
	return {value = a, height = 0}
end

local getHeight = function(node)
	return node and node.height or -1
end

local setHeight = function(node)
	node.height = math.max(getHeight(node.left),getHeight(node.right))+1
end

local getBalance = function(node)
	return getHeight(node.right)-getHeight(node.left)
end

-- http://en.wikipedia.org/wiki/Tree_rotation
local rotateNode = function(root,rotation_side,opposite_side)
	local pivot           = root[opposite_side]
	root[opposite_side]   = pivot[rotation_side] 
	pivot[rotation_side]  = root
	root,pivot            = pivot,root
	setHeight(pivot);setHeight(root)
	return root
end

-- perform leaf check,height check,& rotation
local updateSubtree = function(root) 
	local oldHeight = root.height
	setHeight(root)
	local rotation_side,opposite_side,pivot,rotate_pivot
	local balance = getBalance(root)
	-- single rotation
	if balance > MAX_BALANCE_FACTOR then
		pivot = root.right
		-- double rotation
		if getBalance(pivot) < 0 then rotate_pivot = true end 
		rotation_side,opposite_side = 'left','right'
	elseif balance < MIN_BALANCE_FACTOR then
		pivot = root.left
		if getBalance(pivot) > 0 then rotate_pivot = true end
		rotation_side,opposite_side = 'right','left'
	end
	if rotation_side then
		if rotate_pivot then
			root[opposite_side] = rotateNode(pivot,opposite_side,rotation_side) 
		end
		root = rotateNode(root,rotation_side,opposite_side)
	end
	return root.height == oldHeight and false or true,root
end

-- check for the existence of the value and the path to the value
local getPath = function(a,node,side)
	local stack,side = {node},{side}
	-- get the path to the value or empty leaf
	while node do
		if a < node.value then
			node = node.left
			insert(stack,node);insert(side,'left')
		elseif a > node.value then
			node = node.right
			insert(stack,node);insert(side,'right')
		-- stop when the path is found
		else return a,stack,side end
	end
	-- else return path to empty leaf for value
	return nil,stack,side
end

local unwindPath = function(i,stack,side)
	local continue = true
	while i > 0 and continue do
		-- callback at each node when going back to root
		continue,stack[i]   = updateSubtree(stack[i])
		stack[i-1][side[i]] = stack[i]
		i = i - 1
	end
end

local traverse
traverse = function(node,a,b)
	if node then
		traverse(node[a],a,b)
		coroutine.yield(node.value)
		traverse(node[b],a,b)
	end
end

-- http://stackoverflow.com/questions/1733311/pretty-print-a-tree
local printTree
printTree = function(self,depth)
	depth = depth or 1
	if self then 
		printTree(self.right,depth+1)
		print(string.format("%s%d",string.rep("	",depth),self.value))
		printTree(self.left,depth+1)
	end	
end

-- ================
-- PUBLIC
-- ================

local b   = {}
b.__index = b

-- Insert given element, return it if successful
b.add = function(self,a)
	local exist,stack,side = getPath(a,self.root,'root')
	-- exit if the value is already added
	if exist then return end
	stack[0] = self
	-- create leaf node and insert value
	local leaf        = newLeaf(a)
	stack[#stack+1]   = leaf
	-- link leaf node to ancestor
	stack[#stack-1][side[#stack]] = leaf
	-- unwind stack and update ancestor nodes
	unwindPath(#stack-1,stack,side)
	return a
end

b.delete = function(self,a)
	local node = self.root
	local exist,stack,side = getPath(a,node,'root')
	-- exit if the value can't be found
	if not exist then return end
	stack[0]    = self
	local node  = stack[#stack]
	if not node.left or not node.right then
		-- if node to be deleted has one or less child...
		-- link child to parent
		stack[#stack-1][side[#stack]] = node.left or node.right
		unwindPath(#stack-1,stack,side)
	else
		-- else find successor node
		local sNode = node.right
		while sNode.left do
			sNode	    = sNode.left
		end
		-- get path to successor node
		local _,stack2,side2 = getPath(sNode.value,node.right,'right')
		stack2[0] = node
		-- delete successor node by linking it's parent to it's right child
		stack2[#stack2-1][side2[#stack2]] = sNode.right
		-- update path from node to sNode
		unwindPath(#stack2-1,stack2,side2)
		-- change deleted node value to successor's value
		node.value  = sNode.value
		-- update path from root to node
		unwindPath(#stack,stack,side)
	end
end

b.get = function(self,a)
	local exist = getPath(a,self.root,'root')
	return exist and a
end

b.pop = function(self,side)
	local node    = self.root
	local newNode = node
	while newNode do
		node    = newNode
		newNode = node[side]
	end
	if node then
		self:delete(node.value)
		return node.value
	end
end

b.peek = function(self,side)
	local node    = self.root
	local newNode = node
	while newNode do
		node    = newNode
		newNode = newNode[side]
	end
	return node and node.value or nil
end

b.iterate = function(self,mode)
	local a,b
	if not mode then 
		a,b = 'left','right'
	else 
		a,b = 'right','left' 
	end
	return coroutine.wrap(function()
		traverse(self.root,a,b)
	end)
end

b.printTree = function(self,depth)
	printTree(self.root,depth)
end

return setmetatable(b,{__call = 
	function()
		-- return setmetatable({root = newLeaf()},b)
		return setmetatable({},b)
	end
})