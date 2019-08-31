export Eulerian
"""
`Eulerian(n,k)` returns the number of permutations of `{1,2,...,n}`
with `k` ascents.
"""
function Eulerian(n::Integer, k::Integer)::BigInt
    @assert (n>=0 && k>=0) "$n,$k must both be nonnegative"

    if n==0
        return big(0)
    end

    if k>n || k==0
        return big(0)
    end

    if n < 2
        return big(1)
    end

    if k==n      # includes the case n=k=0
        return big(1)
    end

    if k==1
        return big(1)
    end

    if _has(Eulerian,(n,k))
        return _get(Eulerian,(n,k))
    end

    val = (n-k+1)*Eulerian(n-1,k-1) + k*Eulerian(n-1,k)
    _save(Eulerian,(n,k),val)
    return val
end


_make(Eulerian,Tuple{Integer,Integer})
