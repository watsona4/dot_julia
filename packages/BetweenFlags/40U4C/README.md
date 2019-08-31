# BetweenFlags.jl

A set of string processing utility functions that finds/removes text between given flags.

| **Documentation**                             | **Build Status**                                                                                                     |
|:--------------------------------------------- |:---------------------------------------------------------------------------------------------------------------------|
| [![latest][docs-latest-img]][docs-latest-url] | [![travis][travis-img]][travis-url] [![appveyor][appveyor-img]][appveyor-url] [![codecov][codecov-img]][codecov-url] |

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://charleskawczynski.github.io/BetweenFlags.jl/latest/

[travis-img]: https://travis-ci.org/charleskawczynski/BetweenFlags.jl.svg?branch=master
[travis-url]: https://travis-ci.org/charleskawczynski/BetweenFlags.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/ca6lgtt9f8e42o4f?svg=true
[appveyor-url]: https://ci.appveyor.com/project/charleskawczynski/betweenflags-jl

[codecov-img]: https://codecov.io/gh/charleskawczynski/BetweenFlags.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/charleskawczynski/BetweenFlags.jl

# Installation

To install, use

`julia ] add BetweenFlags`

# Featured functions

## Greedy functions
  The greedy `BetweenFlags` functions are similar to regex pattern matching, and
  are useful for processing strings to, for example, remove comments, where after opening
  a comment the first instance of closing the comment must be recognized.

```
BetweenFlags.get_flat(s::String,
                       flags_start::Vector{String},
                       flags_stop::Vector{String})
```

### Examples

```
  using BetweenFlags
  s = "Here is some text, and {THIS SHOULD BE GRABBED}, BetweenFlags offers a simple interface..."
  s = get_flat(s, ["{"], ["}"])
  print(s)
{THIS SHOULD BE GRABBED}

  s = "Here is some text, and {THIS SHOULD BE GRABBED), BetweenFlags} offers a simple interface..."
  s = get_flat(s, ["{"], ["}", ")"])
  print(s)
{THIS SHOULD BE GRABBED)
```

### Note
These functions are effectively replaceable by regex. They do, however,
provide a nice interface. The level-based functions are not, in general,
replaceable by regex.

## Level-based functions
  The level-based version of BetweenFlags is needed for things
  like finding functions, where the "end" of a `function` cannot
  be confused with the "end" of an `if` statement inside the
  function. Therefore, the "level" corresponding to that function
  should be zero both on the opening and closing of the function.

###  Examples:

```
  s_i = ""
  s_i = string(s_i, "\n", "Some text")
  s_i = string(s_i, "\n", "if something")
  s_i = string(s_i, "\n", "  function myfunc()")
  s_i = string(s_i, "\n", "    more stuff")
  s_i = string(s_i, "\n", "    if something")
  s_i = string(s_i, "\n", "      print('something')")
  s_i = string(s_i, "\n", "    else")
  s_i = string(s_i, "\n", "      print('not something')")
  s_i = string(s_i, "\n", "    end")
  s_i = string(s_i, "\n", "    for something")
  s_i = string(s_i, "\n", "      print('something')")
  s_i = string(s_i, "\n", "    else")
  s_i = string(s_i, "\n", "      print('not something')")
  s_i = string(s_i, "\n", "    end")
  s_i = string(s_i, "\n", "    more stuff")
  s_i = string(s_i, "\n", "  end")
  s_i = string(s_i, "\n", "end")
  s_i = string(s_i, "\n", "more text")

  word_boundaries_left = ["\n", " ", ";"]
  word_boundaries_right = ["\n", " ", ";"]
  word_boundaries_right_if = [" ", ";"]

  FS_outer = FlagSet(
    Flag("function", word_boundaries_left, word_boundaries_right),
    Flag("end",      word_boundaries_left, word_boundaries_right)
  )

  FS_inner = [
  FlagSet(
    Flag("if",       word_boundaries_left, word_boundaries_right_if),
    Flag("end",      word_boundaries_left, word_boundaries_right)
  ),
  FlagSet(
    Flag("for",      word_boundaries_left, word_boundaries_right),
    Flag("end",      word_boundaries_left, word_boundaries_right)
  )]

  L_o = get_level(s_i, FS_outer, FS_inner)
  print("\n -------------- results from complex example: \n")
  print(L_o[1])
  print("\n --------------\n")

 -------------- results from complex example:
 function myfunc()
    more stuff
    if something
      print('something')
    else
      print('not something')
    end
    for something
      print('something')
    else
      print('not something')
    end
    more stuff
  end

 --------------

```
