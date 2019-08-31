using AssociativeArrays, Test

# zero-dimensional gauntlet; integer indexing
function zero_dimensional_gauntlet(a)
    @test a[] == 1
    @test a[1] == 1
    @test a[1, 1] == 1
    @test a[[1], 1] == [1]
    @test a[1, [1]] == [1]
    @test a[reshape([1], 1, 1, 1)] == reshape([1], 1, 1, 1)
    @test a[:] == [1]
    @test a[:, :] == reshape([1], 1, 1)
    @test a[CartesianIndex(1)] == 1
    @test a[CartesianIndex(1, 1, 1)] == 1
    @test a[[]] == Int[]
    @test a[[1, 1]] == [1, 1]
    @test a[[true]] == [1]
    @test a[[false]] == Int[]
    @test_throws BoundsError a[[true, true]]
    @test_throws BoundsError a[[false, true]]
    @test_throws BoundsError a[[0, 1]]
end

i = 0
# zero-dimensional-specific tests
let a = Assoc(fill(1))
    @test a[fill(1), named=true] == a
    @test a[named=true] == a
    @test a[1, named=true] == a
    @test a[1,1,1,named=true] == a
end

zero_dimensional_gauntlet(fill(1))
zero_dimensional_gauntlet(Assoc(fill(1)))
zero_dimensional_gauntlet(Assoc([1], ["a"]))

function one_dimensional_gauntlet(a)
    @test a[fill(1), named=true] == a
    @test a[named=true] == a
    @test a[1, named=true] == a
    @test a[1,1,1,named=true] == a
    @test a[] == a[named=false] == 1
    @test a["a"] == a
    @test a["a", 1] == a
    @test_throws BoundsError a["a", [1]]
    @test_throws BoundsError a["a", 1, [1]]
    @test_throws BoundsError a["a", [1], 1]
    @test_throws BoundsError a["a", 0]
    @test_throws BoundsError a["a", 3]
    @test_throws BoundsError a["a", :]
    @test size(a["b"]) == (0,)
    @test_throws BoundsError a["b", "c"]
    @test a[["a"]] == a
    @test a[["a", "b", "c"]] == a
    @test a[1, named=true] == a
    @test a[1, named=false] == 1
    @test a[named=true] == a
    # This should really throw a better error about mixed indexing being disallowed:
    @test_throws ArgumentError a[["a", 1]]
end

one_dimensional_gauntlet(Assoc([1], ["a"]))

#= Future Tests

Should be a bug:

julia> td = Assoc(reshape([1 2 3], 1, 3, 1), [:x], ["a", "b", "c"], [:e])
julia> td[named=true]
1×1×1 Assoc{Int64,3,Array{Int64,3}}:
[:, :, 1] =
 1

And now is. An Assertion, at least.

--

Should be a bug:

using Serialization
dogs = deserialize("2012.ser")
dogs[[:name => "bailey", :name => "pugsley"]]

---

bug in Julia base:
a[[true, false], [false, true], named=true] # => ​
getindex not defined for Base.LogicalIndex{Int64,Array{Bool,1}}

---

another one?
nzrange(sparse(rand(2,2)), 2) # Bug? Returned range is out of bounds.

---

test that Symbol names are disallowed

---

d = Assoc(reshape([1, 2], 2, 1), ['a', 'x'], ['b'])
d[fill(1), named=true]

---

test each of the argchecks in the assoc constructor
=#


