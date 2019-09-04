# TwentyFour


[![Build Status](https://travis-ci.org/scheinerman/TwentyFour.jl.svg?branch=master)](https://travis-ci.org/scheinerman/TwentyFour.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/TwentyFour.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/TwentyFour.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/TwentyFour.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/TwentyFour.jl?branch=master)



[Twenty Four](https://www.24game.com/) is a number game. The player is presented with a card
containing four numbers. The object is to use those four numbers to make
the value 24 using the four standard arithmetic operations
(plus, minus, times, divide). This Julia module provide solves these
puzzles.

## Usage

Use the `solve` function to find solutions to *Twenty Four* puzzles.
Simply provide two or more values (either integers or rationals).


```julia
julia> solve(3,4,5,8)
"(4*8)-(3+5)"

julia> solve(5,5,5,1)
"5*(5-(1/5))"

julia> solve(5,5,5,2)
"No solution"

julia> solve(1//2, 1//3, 7, 3)
"(7-3)/(1/2-1/3)"
```


## To do list

* Permit alternative goals besides 24.
* Our code might give a solution in which some of the intermediate
values are negative. One can prove this can always be avoided
(assuming the given numbers are all positive). Modify the code
so all intermediate values are nonnegative.
