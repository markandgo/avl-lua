newlist = require'list'
list	= newlist()

function printList()
	for k in list:iterate() do print(k) end
	print('=======')
end

for i = 1,5 do
	list:add(i)
end

for i = 1,5 do
	list:add(i)
end

list:delete(3,1)

printList()

list:delete(4)

printList()

list:pop('left','dup')
list:pop('right')

printList()

print(list:peek'right')
print(list:get(2))