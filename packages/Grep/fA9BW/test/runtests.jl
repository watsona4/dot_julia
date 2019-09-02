module TestGrep

using Grep
using Test

@test grep("1", 1:11) == [1, 10, 11]
@test grep(1, 1:11) == [1]
@test 1:1000 |> grep(r"^1.*0$") == [10, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 1000]
@test grep(isodd, 1:3) == [1, 3]


end # module
