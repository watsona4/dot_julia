# Example 2

using Base.Iterators
using Arbitrary

# Define your own type
struct Point{T}
    x::T
    y::T
end

# Define a method for Arbitrary.arbitrary
function Arbitrary.arbitrary(::Type{Point{T}}, ast::ArbState) where {T}
    xs = Iterators.Stateful(arbitrary(T, ast))
    flatten([Point{T}[Point(T(0), T(0)),
                      Point(T(0), T(1)),
                      Point(T(1), T(0)),
                      Point(T(-1), T(-1))],
             Generate{Point{T}}(
                 () -> Point(popfirst!(xs), popfirst!(xs)))])
end

collect(take(arbitrary(Point{Int}), 20))
