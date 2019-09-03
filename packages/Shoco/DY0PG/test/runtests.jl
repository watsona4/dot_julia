using Shoco
using Test

s = "What's up, doc?"
c = compress(s)
@test 0 < sizeof(c) < sizeof(s)
@test decompress(c) == s

@test compress("") == ""
@test decompress("") == ""

s = "؉'s ⎨<g"
d = decompress(s)
@test sizeof(d) > sizeof(s)
