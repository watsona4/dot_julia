using Pkg; Pkg.activate(".")
using BKTrees
using Random
using StringDistances

lev(x::S,y::S) where S<:AbstractString = evaluate(Levenshtein(), x, y)
dictionary = [randstring(10) for _ in 1:10_000]
bkt = BKTree(lev, sort(dictionary))

target = randstring(10)

found = find(bkt, "bbb", 10, k=3)
@time found=find(bkt, target, 10, k=3)
@show target, found
