using Test
using BetweenFlags.FeaturedFuncs

@testset "Get flat" begin
  s_i1 = "Some text... {GRAB THIS}, some more text {GRAB THIS TOO}..."
  L_o1 = get_flat(s_i1, ["{"], ["}"])
  s_i2 = "Some text... {GRAB THIS}, some more text {GRAB THIS TOO}..."
  L_o2 = get_flat(s_i2, ["{"], ["}"], false)
  s_i3 = "Some text... {GRAB THIS), } some more text {GRAB THIS TOO}..."
  L_o3 = get_flat(s_i3, ["{"], ["}", ")"])
  s_i4 = "Some text... {GRAB THIS), } some more text {GRAB THIS TOO}..."
  L_o4 = get_flat(s_i4, ["{"], ["}", ")"], false)
  s_i5 = "Some text... GRAB NOTHING), some more text GRAB NOTHING..."
  L_o5 = get_flat(s_i5, ["{"], ["}", ")"], false)

  @test L_o1[1]=="{GRAB THIS}"
  @test L_o2[1]=="GRAB THIS"
  @test L_o3[1]=="{GRAB THIS)"
  @test L_o4[1]=="GRAB THIS"
  @test L_o1[2]=="{GRAB THIS TOO}"
  @test L_o2[2]=="GRAB THIS TOO"
  @test L_o3[2]=="{GRAB THIS TOO}"
  @test L_o4[2]=="GRAB THIS TOO"
  @test L_o5[1]==""
end

@testset "Get level flat" begin
  s_i1 = "Some text... {GRAB {THIS}}, some more text {GRAB THIS TOO}..."
  L_o1 = get_level_flat(s_i1, ["{"], ["}"])
  s_i2 = "Some text... {GRAB {THIS}}, some more text {GRAB THIS TOO}..."
  L_o2 = get_level_flat(s_i2, ["{"], ["}"], false)
  s_i3 = "Some text... {GRAB {THIS}), } some more text {GRAB THIS TOO}..."
  L_o3 = get_level_flat(s_i3, ["{"], ["}", ")"])
  s_i4 = "Some text... {GRAB {THIS}), } some more text {GRAB THIS TOO}..."
  L_o4 = get_level_flat(s_i4, ["{"], ["}", ")"], false)
  s_i5 = "Some text... GRAB {NOTHING),  some more text GRAB NOTHING..."
  L_o5 = get_level_flat(s_i5, ["{"], ["}"], false)

  @test L_o1[1]=="{GRAB {THIS}}"
  @test L_o2[1]=="GRAB {THIS}"
  @test L_o3[1]=="{GRAB {THIS})"
  @test L_o4[1]=="GRAB {THIS}"
  @test L_o1[2]=="{GRAB THIS TOO}"
  @test L_o2[2]=="GRAB THIS TOO"
  @test L_o3[2]=="{GRAB THIS TOO}"
  @test L_o4[2]=="GRAB THIS TOO"
  @test L_o5[1]==""
end

@testset "Get level flat practical" begin
  s_i = ""
  s_i = string(s_i, "\n", "Some text")
  s_i = string(s_i, "\n", "function myfunc()")
  s_i = string(s_i, "\n", "  more stuff")
  s_i = string(s_i, "\n", "  if something")
  s_i = string(s_i, "\n", "    print('something')")
  s_i = string(s_i, "\n", "  else")
  s_i = string(s_i, "\n", "    print('not something')")
  s_i = string(s_i, "\n", "  end")
  s_i = string(s_i, "\n", "  more stuff")
  s_i = string(s_i, "\n", "end")
  s_i = string(s_i, "\n", "more text")
  L_o = get_level_flat(s_i, ["function ", "if "], [" end", "\nend"])

  s_o = ""
  s_o = string(s_o,       "function myfunc()")
  s_o = string(s_o, "\n", "  more stuff")
  s_o = string(s_o, "\n", "  if something")
  s_o = string(s_o, "\n", "    print('something')")
  s_o = string(s_o, "\n", "  else")
  s_o = string(s_o, "\n", "    print('not something')")
  s_o = string(s_o, "\n", "  end")
  s_o = string(s_o, "\n", "  more stuff")
  s_o = string(s_o, "\n", "end")

  @test L_o[1]==s_o
end

@testset "Get level complex" begin
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

  s_o = ""
  s_o = string(s_o,       " function myfunc()") # The extra space is due to the left word boundary of the function...
  s_o = string(s_o, "\n", "    more stuff")
  s_o = string(s_o, "\n", "    if something")
  s_o = string(s_o, "\n", "      print('something')")
  s_o = string(s_o, "\n", "    else")
  s_o = string(s_o, "\n", "      print('not something')")
  s_o = string(s_o, "\n", "    end")
  s_o = string(s_o, "\n", "    for something")
  s_o = string(s_o, "\n", "      print('something')")
  s_o = string(s_o, "\n", "    else")
  s_o = string(s_o, "\n", "      print('not something')")
  s_o = string(s_o, "\n", "    end")
  s_o = string(s_o, "\n", "    more stuff")
  s_o = string(s_o, "\n", "  end\n") # The \n is due to the right word boundary of the "end"

  @test L_o[1]==s_o

  # Edge case (no flags in string):
  s_i = ""
  s_i = string(s_i, "\n", "Some text")
  s_i = string(s_i, "\n", "more text")
  L_o = get_level(s_i, FS_outer, FS_inner)
  s_o = ""
  @test L_o[1]==s_o
end

@testset "Remove flat" begin
  s_i1 = "Here is some text, and {THIS SHOULD BE REMOVED}, FeaturedFuncs offers a simple interface..."
  s_o1 = remove_flat(s_i1, ["{"], ["}"])
  s_i2 = "Here is some text, and {THIS SHOULD BE REMOVED}, FeaturedFuncs offers a simple interface..."
  s_o2 = remove_flat(s_i2, ["{"], ["}"], false)
  s_i3 = "Here is some text, and {THIS SHOULD BE REMOVED), FeaturedFuncs} offers a simple interface..."
  s_o3 = remove_flat(s_i3, ["{"], ["}", ")"])
  s_i4 = "Here is some text, and {THIS SHOULD BE REMOVED), FeaturedFuncs} offers a simple interface..."
  s_o4 = remove_flat(s_i4, ["{"], ["}", ")"], false)
  s_i5 = "Here is some text, and THIS SHOULD REMAIN, FeaturedFuncs} offers a simple interface..."
  s_o5 = remove_flat(s_i5, ["{"], ["}"], false)
  s_i6 = "Here is some text, and THIS SHOULD REMAIN, FeaturedFuncs| offers a simple interface..."
  s_o6 = remove_flat(s_i6, ["|"], ["|"], false)
  s_i7 = "Here is some text, and |THIS SHOULD BE REMOVED|, FeaturedFuncs offers a simple interface..."
  s_o7 = remove_flat(s_i7, ["|"], ["|"], false)
  s_doc = "\"\"\""
  s_i8 = "Here is some text-"*s_doc*" docs... "*s_doc*", and-"*s_doc*"more docs"*s_doc*", FeaturedFuncs offers a simple interface..."
  s_o8 = remove_flat(s_i8, [s_doc], [s_doc], true)
  s_doc = "\"\"\""
  s_i9 = "Here is some text-"*s_doc*" docs... "*s_doc*", and-"*s_doc*"more docs"*s_doc*", and "*s_doc*"more docs"*s_doc*", FeaturedFuncs offers a simple interface..."
  s_o9 = remove_flat(s_i9, [s_doc], [s_doc], true)

  @test s_o1=="Here is some text, and , FeaturedFuncs offers a simple interface..."
  @test s_o2=="Here is some text, and {}, FeaturedFuncs offers a simple interface..."
  @test s_o3=="Here is some text, and , FeaturedFuncs} offers a simple interface..."
  @test s_o4=="Here is some text, and {), FeaturedFuncs} offers a simple interface..."
  @test s_o5=="Here is some text, and THIS SHOULD REMAIN, FeaturedFuncs} offers a simple interface..."
  @test s_o6=="Here is some text, and THIS SHOULD REMAIN, FeaturedFuncs| offers a simple interface..."
  @test s_o7=="Here is some text, and ||, FeaturedFuncs offers a simple interface..."
  @test s_o8=="Here is some text-, and-, FeaturedFuncs offers a simple interface..."
  @test s_o9=="Here is some text-, and-, and , FeaturedFuncs offers a simple interface..."
end
