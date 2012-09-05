AVL tree implementation in Lua. Useful for maintaining a sorted list.

list.lua relies on avl.lua. list.lua allows duplicate values whereas avl.lua does not.

## Init ##

````lua
avl     = require 'avl'
newlist = require'list' (same folder as avl)
list    = avl() -- newlist()
````

## avl.lua ##

Values in the tree are added and sorted using > and < operations at each node. The operation will fail if either cases fail. You can add tables as values by defining a __lt metamethod for each one.

Functions:

````lua
_:add(value)

_:delete(value)

_:iterate(mode) 
-- if mode is specified then reverse order of traversal

_:get(value) 
-- return value if found

_:pop(side)
-- pop and return value on left or right side

_:peek(side)
-- return value on left or right side

_:printTree()
````


## list.lua ##

list.lua augments the AVL tree by storing a counter for each value in a hash table. This allows duplicate values. Values can only be added if they were successfully added to the tree.

Functions:

````lua
_:add(value,amount)

_:delete(value,amount) 
-- no amount specified: delete all copies

_:iterate(mode)

_:get(value) 
-- return the value and amount

_:pop(side,duplicate) 
-- pop and return a value and amount popped
-- if duplicate = 'dup' then pop all copies of a value

_:peek(side)

_:printTree()
````

See test.lua and output.txt for examples.