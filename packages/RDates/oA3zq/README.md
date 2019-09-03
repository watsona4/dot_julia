# RDates

[![Build Status](https://travis-ci.com/InfiniteChai/RDates.jl.svg?branch=master)](https://travis-ci.com/InfiniteChai/RDates.jl)
[![Coverage Status](https://coveralls.io/repos/github/InfiniteChai/RDates.jl/badge.svg)](https://coveralls.io/github/InfiniteChai/RDates.jl)

Relative date library for Julia, built around the Dates package. Aims to provide a generic, extendable algebra for relative date operations and aiming for long term support of holiday calendar systems as well.

## Basic Usage

Let's start with some basic usage to add one day to the date. We'll use the macro `rd` but you can also use the function `rdate`.

```julia
julia> using RDates
julia> using Dates
julia> rd"1d" + Date(2019,4,17)
2019-04-18
```

We can also do other standard relative date calculations such as weeks, months and years
```julia
julia> rd"1w" + Date(2019,4,17)
2019-04-24
julia> rd"-1m" + Date(2019,4,17)
2019-03-17
julia> rd"3y" + Date(2019,4,17)
2022-04-17
```

### Months and Years

In cases when the increment of the months would not fall on a real date, it will fall back to the last day of the month

```julia
julia> rd"1m" + Date(2012,1,31)
2012-02-29
```

Similarly, if we increment from the 29th of February by a year, we'll fall back to the last day of the month

```julia
julia> rd"1y" + Date(2012,2,29)
2013-02-28
```

### Weekdays

The relative date supports the ability to find the nth weekday from the current day. If we want to know the next Saturday then we can do the following

```julia
julia> rd"1SAT" + Date(2017,10,25)
2017-10-28
```

To know the last Tuesday from a given date, then we can use a negative value

```julia
julia> rd"-1TUE" + Date(2017,10,25)
2017-10-24
```

### Nth Weekdays

Find the nth weekday in the given month of the date passed in. If the date doesn't exist, then an exception will be thrown

```julia
julia> rd"1st THU" + Date(2017,10,25)
2017-10-05
julia> rd"3rd MON" + Date(2017,10,25)
2017-10-16
julia> rd"5th FRI" + Date(2017,10,25)
ERROR: ArgumentError: Day: 34 out of range (1:31)
```

You can also ask for the nth last weekday as well, if you need to manipulate dates in that fashion

```julia
julia> rd"Last THU" + Date(2017,10,25)
2017-10-26
julia> rd"2nd Last FRI" + Date(2017,10,25)
2017-10-20
```

### First and Last Days of the Month

Given a date, this will give you back the first and last dates for the given month

```julia
julia> rd"FDOM" + Date(2017,10,25)
2017-10-01
julia> rd"LDOM" + Date(2017,10,25)
2017-10-31
```

### Easter Sunday

Mainly defined to support integration with holiday calendars, but you can find out the relative Easter Sunday from a given date. Note, `rd"1E"` refers to the Easter Sunday of next year and not necessarily the next Easter Sunday. You can use `rd"0E"` to get this year's Easter Sunday.

```julia
julia> rd"0E" + Date(2017,10,25)
2017-04-16
julia> rd"1E" + Date(2017,10,25)
2018-04-01
```

### Relative Date Algebraic Operations

The relative date library also supports addition, subtraction (where appropriate) and constant multiplication operations.

You can add two rdates together using the + symbol, which will be equivalent of applying the left then the right sequentially.

```julia
julia> rd"1d+2d" + Date(2017,10,25)
2017-10-28
julia> rd"3rd WED+1d" + Date(2017,10,25)
2017-10-19
```

Where the rdate on the right supports negation, then you can subtract two rdates using the - symbol. This is equivalent of applying the left then the negation of the right sequentially.

It's worth noting that in most cases, this is just syntax sugar of an addition and wrapping the negated right rdate in brackets.

```julia
julia> rd"1d-2d" + Date(2017,10,25)
2017-10-24
julia> rd"3rd WED-1d" + Date(2017,10,25)
2017-10-17
julia> rd"1d+(-2d)" + Date(2017,10,25)
2017-10-24
```

Finally we also support multiplication of an rdate with a positive integer n using the * symbol. This is equivalent to repeating the rdate operation n times.

```julia
julia> rd"3*2d" + Date(2017,10,25)
2017-10-31
julia> rd"2d*3" + Date(2017,10,25)
2017-10-31
```

As with standard arithmetic, the multiplication takes prescedence over addition or subtraction, but can be overruled using brackets.

```julia
julia> rd"3*2d+1d" + Date(2017,10,25)
2017-11-01
julia> rd"3*(2d+1d)" + Date(2017,10,25)
2017-11-03
```

## Ranges

As well as performing relative date operations, you can also get a range of dates that follow a given period. For example, if we want the next three days incremented, including the start date, then

```julia
julia> collect(Iterators.take(range(Date(2019,4,17), rd"1d"),3))
3-element Array{Date,1}:
 2017-01-25
 2017-01-26
 2017-01-27
julia> collect(range(Date(2019,4,17), Date(2019,4,21), rd"2d"))
3-element Array{Date,1}:
 2019-04-17
 2019-04-19
 2019-04-21
julia> collect(range(Date(2019,4,17), Date(2019,4,21), rd"1d", inc_from=false, inc_to=false))
3-element Array{Date,1}:
 2019-04-18
 2019-04-19
 2019-04-20
```

This should give the basic building blocks to come up with as complex a set of functionality as you require. For example, to get the next 3 future IMM dates we could use the following

```julia
julia> today = Date(2017,10,27)
julia> start = rd"1MAR+3rd WED" + today
julia> immdates = Iterators.take(Iterators.filter(x -> x >= today, range(start, rd"3m+3rd WED")), 3)
julia> collect(immdates)
3-element Array{Date,1}:
 2017-12-20
 2018-03-21
 2018-06-20
```
