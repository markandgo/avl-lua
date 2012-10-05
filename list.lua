local path  = (...):match('^.*[%.%/]') or ''
local avl   = require (path .. 'avl')

local iterator = function(state)
	local root    = state.list.root
	local iter    = root:iterate(state.mode) 
	local vc      = state.list.value_counter
	local value   = iter(root)
	while value do
		for i = 1,vc[value] do
			coroutine.yield(value)
		end
		value = iter()
	end
end

local list    = {}
-- insert value
list.add = function(self,value,amt) 
	if self.root:add(value) then 
		self.value_counter[value] = amt or 1
	else
		self.value_counter[value] = self.value_counter[value] + (amt or 1)
	end 
end
-- return value and amount
list.get = function(self,value) 
	local vc = self.value_counter
	if vc[value] then
		return value,vc[value]
	end
end
-- iterate over all key value pairs
list.iterate = function(self,mode) 
	local state = {mode = mode,list = self}
	return coroutine.wrap(iterator),state
end

list.delete = function(self,value,amt)
	local vc  = self.value_counter
	vc[value] = vc[value] - (amt or math.huge)
	if vc[value] < 1 then
		self.root:delete(value)
		vc[value] = nil
	end
end

list.pop = function(self,side,dup)
	if dup == 'dup' then
		local value = self.root:pop(side)
		local amt   = self.value_counter[value]
		self.value_counter[value] = nil
		return value,amt
	else
		local value = self.root:peek(side)
		local vc    = self.value_counter
		local c     = vc[value] - 1
		vc[value]   = c
		if c < 1 then
			list.pop(self,side,'dup')
		end
		return value,1
	end
end

return function()
	local root  = avl()
	local vc    = setmetatable({},{__mode = 'k'})
	return setmetatable({
	value_counter = vc,
	root          = root,
	},{__index = function(t,k)
		return list[k] or t.root[k]
	end})
end