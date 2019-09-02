export latin, check_latin

function funky_mod(i::Int, n::Int)
    v = mod(i,n)
    return v==0 ? n : v
end


"""
`latin(n)` returns a simple `n`-by-`n` Latin square. More generally,
`latin(n,a,b)` generates a Latin square whose `i,j`-entry is
`a*(i-1) + b*(j-1) + 1` (wrapping around `n`, of course).

*Note*: If parameters `n,a,b` do not generate a legitimate Latin square
an error is thrown.
"""
function latin(n::Int, a::Int=1, b::Int=1)::Matrix{Int}
    A = zeros(Int,n,n)
    for i=1:n
        for j=1:n
            A[i,j] = funky_mod(a*(i-1) + b*(j-1) + 1, n)
        end
    end
    @assert check_latin(A) "Parameters n=$n, a=$a, and b=$b do not generate a Latin square"
    return A
end

"""
`check_latin(A)` checks if `A` is a Latin square.
(The entries must be chosen from `1:n` when `A` is an `n`-by-`n`
matrix).
"""
function check_latin(A::Matrix{Int})::Bool
    r,c = size(A)
    if r != c
        return false
    end

    vals = collect(1:r)

    # check rows
    for i=1:r
        if sort(A[:,i]) != vals
            return false
        end
    end

    # check cols
    for i=1:r
        if sort(A[i,:]) != vals
            return false
        end
    end

    return true
end
