newlist = require'list'
list	= newlist()

function printList(mode)
	print('=======')
	for k in list:iterate(mode) do print(k) end
	print('=======')
end

for i = 1,5 do
	list:add(i,2)
end

list:delete(3,1)

printList()

list:delete(4)

printList('reverse')

print(list:pop('left','dup'))
print(list:pop('right'))

printList()

print(list:peek'right')
print(list:get(2))

for i = 6,20 do
	list:add(i)
end

list:printTree()