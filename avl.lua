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
local b   = {}
b.__index = b

local newLeaf = function(a)
	return setmetatable({
	value   = a,
	height  = 0,
	},b)
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
	setHeight(root)
	local rotation_side,opposite_side,pivot,rotate_pivot
	local balance = getBalance(root)
	if balance > 1 then
		pivot = root.right
		if getBalance(pivot) < 0 then rotate_pivot = true end 
		rotation_side,opposite_side = 'left','right'
	elseif balance < -1 then
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
	return root
end

local add -- Insert given element, return it if successful
add = function(self,a)
	if not self or not self.value then
		return a,newLeaf(a)
	else
		if a < self.value then
			a,self.left   = add(self.left,a)
		elseif a > self.value then
			a,self.right  = add(self.right,a)
		else a = nil end
		return a,updateSubtree(self)
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
-- tree traversal is in order by default (left,root,right)
local iterate = function(self,mode)
	local a,b
	if not mode then 
		a,b = 'left','right'
	else 
		a,b = 'right','left' 
	end
	return coroutine.wrap(function()
		traverse(self,a,b)
	end)
end
-- Find given element and return it
local get 
get = function(self,a) 
	if self then
		if a == self.value then
			return a
		elseif a < self.value then
			return get(self.left,a)
		else
			return get(self.right,a)
		end
	end
end

local delete
delete = function(self,a)
	if self then 
		local v = self.value
		if a == v then 
			if not self.left or not self.right then
				return self.left or self.right
			else 
				local sNode = self.right
				while sNode.left do
					sNode	    = sNode.left
				end
				self        = delete(self,sNode.value)
				self.value  = sNode.value
				return self
			end
		else
			if a < v then
				self.left   = delete(self.left,a)
			else
				self.right  = delete(self.right,a)
			end
		end
		return updateSubtree(self)
	end
end

local pop
pop = function(self,side)
	local v
	if not self[side] then
		return self.value,self.left or self.right
	else
		v,self[side] = pop(self[side],side)
	end
	return v,updateSubtree(self)
end

local peek
peek = function(self,side)
	if not self[side] then
		return self.value
	else
		return peek(self[side],side)
	end
end
-- http://stackoverflow.com/questions/1733311/pretty-print-a-tree
local printTree
printTree = function(self,depth)
	depth = depth or 1
	if self then 
		printTree(self.right,depth+1)
		print(string.format("%s%d",string.rep("  ",depth), self.value))
		printTree(self.left,depth+1)
	end	
end

b.add       = add
b.delete    = delete
b.pop       = pop
b.peek      = peek
b.get       = get
b.iterate   = iterate
b.printTree = printTree

return function()
	return setmetatable({ -- proxy table for tree
		root  = newLeaf(),
		add   = function(self,a)
			a,self.root = self.root:add(a)
			return a
		end,
		delete = function(self,a)
			self.root = self.root:delete(a) or newLeaf()
		end,
		pop = function(self,side)
			assert(side,'No side specified!')
			a,self.root = self.root:pop(side)
			return a
		end,
	},
	{__index = function(t,k)
		local root = t.root
		if type(root[k]) == 'function' then 
			return function(...)
				return root[k](root,select(2,...))
			end
		end
		return root[k]
	end})
end