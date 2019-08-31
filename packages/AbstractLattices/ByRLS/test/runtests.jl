using Test
using AbstractLattices

function (∨)(a::Number,b::Number)
    return max(a,b)
end

function (∧)(a::Number,b::Number)
    return min(a,b)
end

@test 5 ∧ 10 == 5
@test 5 ∨ 10 == 10
