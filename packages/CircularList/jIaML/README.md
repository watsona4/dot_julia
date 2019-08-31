# CircularList

[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://tk3369.github.io/CircularList.jl/latest)
[![Build Status](https://travis-ci.org/tk3369/CircularList.jl.svg?branch=master)](https://travis-ci.com/tk3369/CircularList.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/tk3369/CircularList.jl?svg=true)](https://ci.appveyor.com/project/tk3369/CircularList-jl)
[![Codecov](https://codecov.io/gh/tk3369/CircularList.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tk3369/CircularList.jl)
[![Coveralls](https://coveralls.io/repos/github/tk3369/CircularList.jl/badge.svg?branch=master)](https://coveralls.io/github/tk3369/CircularList.jl?branch=master)

## Installation

```
]add CircularList
```

## Features

It is essentially a [doubly linked list](https://en.wikipedia.org/wiki/Doubly_linked_list).

- Adding a new node is _O(1)_
- Delete an existing node is _O(1)_
- Ability to handle millions of nodes

## How to use?

To construct a circular list, you must start with at least 1 datum element.
```
h = circularlist(0)      # CircularList.List(0)
h = circularlist([1,2])  # CircularList.List(1,2)
```

When inserting new data, the new node becomes the _head_.
```
h = circularlist(0)      # CircularList.List(0)
insert!(h, 1)            # CircularList.List(1,0)
insert!(h, 2)            # CircularList.List(2,0,1)
insert!(h, 3)            # CircularList.List(3,0,1,2)
```

When deleting the current node, the previous node becomes the _head_:
```
delete!(h)               # CircularList.List(2,0,1)
```

You can move the head pointer in any direction:
```
forward!(h)              # CircularList.List(0,1,2)
backward!(h)             # CircularList.List(2,0,1)
shift!(h, 2, :forward)   # CircularList.List(1,2,0)
shift!(h, 2, :backward)  # CircularList.List(2,0,1)
```

You can get the head and tail node:
```
head(h)                  # CircularList.Node(2)
tail(h)                  # CircularList.Node(1)
```

You can peek at the data of current, previous, or next nodes:
```
current(h)               # 2
previous(h)              # 1
next(h)                  # 0
```

Most methods returns `CircularList.List` so they are highly chainable:
```
julia> using Lazy

julia> @> h = circularlist(0) insert!(1) insert!(2) insert!(3) forward!
CircularList.List(0,1,2,3)
```

It is iteration friendly:
```
[x for x in h]           # Int[2,0,1]
sum(x for x in h)        # 3
```

## How does it perform?

Ingestion is fairly linear.

```
julia> @btime addmany(1000);
  24.908 μs (1003 allocations: 54.97 KiB)

julia> @btime addmany(10000);
  255.348 μs (10004 allocations: 547.11 KiB)

julia> @btime addmany(100000);
  2.852 ms (100004 allocations: 5.34 MiB)

julia> @btime addmany(1000000);
  31.802 ms (1000004 allocations: 53.41 MiB)
```
