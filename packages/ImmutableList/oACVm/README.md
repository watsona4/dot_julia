# ImmutableList

**A single linked immutable list for Julia**

This package provides a singly linked immutable list. 
Along with common operations such as listHead and listRest
to get the head and the tail in constant time.

## List

`List` is a single linked immutable list.
* Usage:
```julia
a = List{Int}()    # Create a list of the given type.
b = list(1,2,3)    # Creates a list of 3 elements
c = 1 <| b         # Creates a new list C using the cons opertor <| with b as the tail.
```
* Utility functions:
```julia

""" (length(lst1)), O(1) if either list is empty """
listAppend

""" O(n) """
listLength

""" O(n) """
listMember

""" O(index) """
listGet

""" O(1) """
listRest

""" O(1) """
listHead

""" O(index) """
listDelete

""" O(1) """
listEmpty

```

Support for calling functions defined in the Julia core is also provided. 
Such as eltype and length.

