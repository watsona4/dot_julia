# Level-based functions
  The level-based version of BetweenFlags is needed for things
  like finding functions, where then "end" of a `function` cannot
  be confused with the "end" of an `if` statement inside the
  function. Therefore, the "level" corresponding to that function
  should be zero both on the opening and closing of the function.

##  Examples:

Consider trying to grab all functions defined in a file.

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
