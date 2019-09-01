import Base: show, sum, conj, adjoint, isequal, (+)

export IntegerPartition, Ferrers

"""
An `IntegerPartition` is a decreasing list of positive integers.
Construct in the following ways:
* `IntegerParition([a,b,c,...])`
* `IntegerPartition(a,b,c,...)`
"""
struct IntegerPartition
    parts::Vector{Int}
    val::Int

    function IntegerPartition()
        parts = Vector{Int}()
        val   = 0
        new(parts,val)
    end

    function IntegerPartition(pts::Vector{Int})
        if any(pts .<= 0)
            error("All parts of an IntegerPartition must be positive")
        end
        parts = sort(pts, rev=true)
        value = sum(parts)
        new(parts, value)
    end

    function IntegerPartition(pts...)
        return IntegerPartition(collect(pts))
    end

end

parts(P::IntegerPartition) = copy(P.parts)
num_parts(P::IntegerPartition) = length(P.parts)
sum(P::IntegerPartition) = P.val

function show(io::IO, P::IntegerPartition)
    str = "("
    np = num_parts(P)
    for k=1:np
        str *= string(P.parts[k])
        if k < np
            str *= "+"
        end
    end
    str *= ")"
    print(io, str)
end

"""
`Ferrers(P::IntegerParition)` prints a graphical representation of the
partition `P` in the form of a Ferrer's diagram.
"""
function Ferrers(P::IntegerPartition, sym::Char='*')
    np = num_parts(P)
    for i=1:np
        println(sym^P.parts[i])
    end
    nothing
end

"""
`conj(P::IntegerPartition)` returns the Ferrer's conjugate of `P`.
Also available as `P'`.
"""
function conj(P::IntegerPartition)::IntegerPartition
    np = num_parts(P)
    if np == 0
        return IntegerPartition()
    end
    big = P.parts[1]  # largest part

    new_parts = Array{Int,1}(undef,big)   # Vector{Int}(big)
    for k=1:big
        new_parts[k] = count(P.parts .>= k)
    end
    return IntegerPartition(new_parts)
end

adjoint(P::IntegerPartition) = conj(P)


"""
The sum of `IntegerPartition`s is their concatenation (multiset union).
"""
function (+)(P::IntegerPartition,Q::IntegerPartition)
    pts = [parts(P);parts(Q)]
    return IntegerPartition(pts)
end


isequal(P::IntegerPartition,Q::IntegerPartition) = isequal(P.parts,Q.parts)
==(P::IntegerPartition, Q::IntegerPartition) = isequal(P,Q)
