# BracedErrors.jl

This package helps to automate the printing of values with errors in brackets.

[![Build Status](https://travis-ci.org/stakaz/BracedErrors.jl.svg?branch=master)](https://travis-ci.org/stakaz/BracedErrors.jl)

## Getting Started

This is a very simple but yet useful package which helps to generate strings with values and their corresponding error followed in brackets, e. g., `23.56(12)(30)` stands for `23.56 ± 0.12 ± 0.30`.

This is common notation in science and this package provides a function to generate these strings.
The reading is the following: the error denoted with $N$ digits describes the error in the last $N$ shown digits of the value. E. g., `0.345(56) = 0.345 ± 0.56` or `1234567890(123) = 1234567890 ± 123`.

## Rounding

The errors are always rounded with `ceil` while the value is rounded with `round`. This rule is a usual conservative case for rounding errors.

By default the errors will have 2 digits in the brackets. See next section for more explanations.

## Accepted values

This function is mainly written for float-like types as `Float64`.

## Usage

There is only one function exported: `bracederror`.
The usage is explained in its docstring.

### Basic Usage

```julia
julia> bracederror(123.456, 0.123)
"123.46(13)"

julia> bracederror(123.456, 0.00123)
"123.4560(13)"

julia> bracederror(123.456, 123456)
"123(130000)"
```

### Two errors
You can provide two or more errors.
```julia
julia> bracederror(123.456, 123456, 0.0034)
"123.4560(1300000000)(34)"

julia> bracederror(123.456, 0.123456, 0.0034)
"123.4560(1300)(34)"

julia> bracederror(1.23456, 0.1, 0.23, 0.45, 0.56)
"1.23(10)(23)(45)(57)"
```

## Customize Output

With some keywords you can customize the output.

- `dec::Int = 2`: number of decimals to round the errors to
- `suff::NTuple{String} = ("", ...)`: optional suffix after the brackets (Tuple can be omitted when using with only one error)
- `bracket::NTuple{Symbol} = (:r, ...)`: type of the brackets (Tuple can be omitted when using with only one error)

`bracket` can take the values: `[:a, :l, :s, :r, :c, :_, :^]` (angular, line, square, round, curly, subscript, superscript) which correspond to `["<>", "||", "[]", "()", "{}", "_{}", "^{}"]`.
The last two are useful for LaTeX output.
However, note that this is **not** a common way of printing the errors.
In such cases one usually prints the real error like in this example:
$$0.1234 \pm 0.056 \pm 0.12 = 1.234(56)(12) = 1.234_{\pm 0.056}^{\pm 0.012}$$
and **not** $1.234_{56}^{12}$.
But feel free to use it and annotate how to read it (it is the shortest one ;)).
It is also possible that you use it for lower and upper error bound, where it makes much more sense and is common notation.

$$ 0.1234 +0.056 -0.012 = 0.1234_{56}^{12}$$

```julia
julia> bracederror(123.456, 0.123456, 0.0034; bracket=:s)
"123.4560[1300](34)"

julia> bracederror(123.456, 0.123456, 0.0034; suff2="_\\inf")
"123.4560(1300)(34)_\\inf"

julia> bracederror(123.456, 0.123456, 0.0034; dec=1)"123.456(200)(4)"
```

## Unexported $±$ Infix Operator

Due to the fact that $\pm$ is often used as an operator `BracedErrors` by default does not export it. It is however defined and can be used by importing it like this:

```julia
julia> import BracedErrors: ±
julia>0.234 ± 0.00056
	"0.23400(56)"
julia>0.234 ± (0.00056, 0.45)
	"0.23400(56)(45000)"
julia>±(0.234, 0.00056, 0.45; bracket =(:r,:s))
	"0.23400(56)[45000]"
```

By using this infix operator you gain even more convenience in error printing in strings like `"$(val ± err)"` and so on.

## Remarks

I have written this package during the hackathon at juliacon 2018 and this is the first official package.
I have tried to test it on different cases but it is still very early stage. Please use it with care and any help is welcome.

