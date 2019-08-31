module BigCombinatorics

using Combinatorics

export Fibonacci
export Factorial, DoubleFactorial, FallingFactorial, RisingFactorial
export Binomial, Catalan
export Derangements, MultiChoose, Multinomial
export Bell, Stirling1, Stirling2
export IntPartitions, IntPartitionsDistinct
export Euler, PowerSum

_master_table = Dict{Function,Dict}()

function _save(f::Function, x, val::BigInt)
    d = _master_table[f]
    d[x] = val
    nothing
end

function _has(f::Function, x)::Bool
    d = _master_table[f]
    return haskey(d,x)
end

function _get(f::Function, x)::BigInt
    d = _master_table[f]
    return d[x]
end

function _make(f::Function, T::Type)
    _master_table[f] = Dict{T,BigInt}()
    nothing
end

"""
`BigCombinatorics.cache_report()` reports how many
entries are saved for each function in the `BigCombinatorics`
module.
"""
function cache_report()
    total = 0
    for func in keys(_master_table)
        parse_func = split(string(func),".")
        func_name = parse_func[2]
        sz = length(_master_table[func])
        total += sz
        println("$sz\t$func_name")
    end
    println()
    println("$total\tTotal entries")
    nothing
end


"""
`BigCombinatorics.cache_clear(f)` clears the cached values for
the function `f`. Returns `false` if `f` values are not cached.

`BigCombinatorics.cache_clear()` clears all cached values.
"""
function cache_clear(f::Function)::Bool
    if !haskey(_master_table,f)
        return false
    end
    tab = _master_table[f]
    for k in keys(tab)
        delete!(tab,k)
    end
    return true
end

function cache_clear()
    for f in keys(_master_table)
        cache_clear(f)
    end
    true
end

"""
`Fibonacci(n)` returns the `n`-th Fibonacci number.
We begin with `Fibonacci(0)==0` and `Fibonacci(1)==1`.
"""
function Fibonacci(n::Integer)::BigInt
  if n<0
    throw(DomainError(n,"argument must be nonngative"))
  end
  if n==0
    return big(0)
  end
  if n==1
    return big(1)
  end
  if _has(Fibonacci,n)
      return _get(Fibonacci,n)
  end
  val = Fibonacci(n-1)+Fibonacci(n-2)
  _save(Fibonacci,n,val)
  return val
end


_make(Fibonacci,Integer)

"""
`Factorial(n)` returns `n!` for nonnegative integers `n`.
`Factorial(n,k)` returns `n!/k!` (to be consistent with Julia's
`factorial`.) Requires `0 <= k <= n`.

See also `FallingFactorial` and `RisingFactorial`.
"""
function Factorial(n::Integer)::BigInt
    if n < 0
        throw(DomainError(n,"argument must be nonngative"))
    end
    if n <= 1
        return big(1)
    end
    if _has(Factorial,n)
        return _get(Factorial,n)
    end
    val = big(n) * Factorial(n-1)
    _save(Factorial,n,val)
    return val
end

function Factorial(n::Integer,k::Integer)::BigInt
    if k>n
        throw(DomainError((n,k),"$k cannot exceed $n"))
    end
    return div(Factorial(n),Factorial(k))
end
_make(Factorial,Integer)

"""
`FallingFactorial(n,k)` returns `n*(n-1)*(n-2)*...*(n-k+1)`
(with a total of `k` factors). Requires `n,k >= 0`.
If `k>n` then `0` is returned.
"""
function FallingFactorial(n::Integer, k::Integer)::BigInt
  if n<0 || k<0
    throw(DomainError((n,k)," arguments must be nonnegative"))
  end
  if k>n
    return big(0)
  end
  return Factorial(n,n-k)
end


"""
`RisingFactorial(n,k)` returns `n*(n+1)*(n+2)*...*(n+k-1)`
(with a total of `k` factors). Requires `n,k >= 0`.
"""
function RisingFactorial(n::Integer,k::Integer)::BigInt
  if n<0 || k<0
    throw(DomainError((n,k),"arguments must be nonnegative"))
  end
  if k==0
    return big(1)
  end
  if n==0
    return big(0)
  end

  return FallingFactorial(n+k-1,k)
end


"""
`DoubleFactorial(n)` returns `n!!`, i.e.,
`n*(n-2)*...` with `(-1)!! == 0!! == 1!! == 1`.
"""
function DoubleFactorial(n::Integer)::BigInt
  if n<-1
    throw(DomainError(n,"argument must be at least -1"))
  end
  if n<2
    return big(1)
  end
  if _has(DoubleFactorial,n)
      return _get(DoubleFactorial,n)
  end
  val = n * DoubleFactorial(n-2)
  _save(DoubleFactorial,n,val)
  return val
end
_make(DoubleFactorial,Integer)


"""
`Binomial(n,k)` returns the binomial coefficient `n`-choose-`k`.
This is the number of `k`-element subsets of an `n`-element set.
"""
Binomial(n::Integer, k::Integer) = binomial(big(n),big(k))::BigInt


"""
`Multinomial(vec)` returns the multinomial coefficient whose
top index is the sum of `vec` (an array of `Int`s) and whose
bottom indices are given by `vec`.

This may also be called with a common-separated list of arguments,
that is, either of `Multinomial([1,2,3])` or `Multinomial(1,2,3)`.
The result is `60` in both cases as these equal `6!/(1! 2! 3!)`.

**Warning**: This is not the same as `MultiChoose`.
"""
function Multinomial(v...)::BigInt
  nv = length(v)
  for i=1:nv
    typeof(v[i])<:Integer || throw(DomainError(v,"arguments must be integers"))
    v[i]>=0 || throw(DomainError(v,"arguments must be nonngative"))
  end
  vals = [t for t in v]
  return Multinomial(vals)
end

Multinomial() = big(1)::BigInt

function Multinomial(vals::Vector{T})::BigInt where T<:Integer
  if any([t<0 for t in vals])
    throw(DomainError(vals,"arguments must be nonnegative"))
  end

  nv = length(vals)
  n  = sum(vals)
  # base cases
  if nv<=1 || n==0
    return big(1)
  end
  # reduce
  return Binomial(n,vals[end]) * Multinomial(vals[1:nv-1])
end


"""
`MultiChoose(n,k)` returns the number of `k`-element
*multisets* that can be formed using the elements of an
`n`-element set.

**Warning**: This is not the same as `Multinomial`.
"""
function MultiChoose(n::Integer,k::Integer)::BigInt
  return Binomial(n+k-1,k)
end

"""
`Catalan(n)` returns the `n`-th Catalan number.
"""
function Catalan(n::Integer)::BigInt
  n >= 0 || throw(DomainError(n,"argument must be nonnegative"))
  return div(Binomial(2n,n),n+1)
end


"""
`Derangements(n)` returns the number of permutations of
an `n`-set that have no fixed point.
"""
function Derangements(n::Integer)::BigInt
  if n<0
    throw(DomainError(n,"argument must be nonnegative"))
  end
  if n==0
    return big(1)
  end
  if n==1
    return big(0)
  end
  if _has(Derangements,n)
      return _get(Derangements,n)
  end

  val = (n-1)*(Derangements(n-1)+Derangements(n-2))
  _save(Derangements,n,val)
  return val
end

_make(Derangements,Integer)

"""
`Bell(n)` gives the `n`-th Bell number, that is,
the number of partitions of an `n`-element set.
"""
function Bell(n::Integer)::BigInt
  if n<0
    throw(DomainError(n,"argument must be nonnegative"))
  end
  if n==1 || n==0
    return big(1)
  end
  if _has(Bell,n)
      return _get(Bell,n)
  end
  N1 = n-1
  result = big(0)
  for k=0:n-1
    result += Binomial(n-1,k) * Bell(k)
  end
  _save(Bell,n,result)
  return result
end
_make(Bell,Integer)


"""
`Stirling2(n,k)` gives the Stirling number of the second kind,
that is, the number of paritions of an `n`-set into `k`-parts."
"""
function Stirling2(n::Integer,k::Integer)::BigInt
  # special cases
  if k<0 || n<0
    throw(DomainError((n,k),"arguments must be nonnegative"))
  end

  if k>n
    return big(0)
  end

  if n==0  # and by logic, k==0
    return big(1)
  end

  if k==0
    return big(0)
  end

  if n==k
    return big(1)
  end
  # END OF SPECIAL CASES, invoke recursion
  if _has(Stirling2,(n,k))
      return _get(Stirling2,(n,k))
  end

  val = Stirling2(n-1,k-1) + Stirling2(n-1,k)*k
  _save(Stirling2,(n,k),val)
  return val
end
_make(Stirling2,Tuple{Integer,Integer})


"""
`Stirling1(n,k)` gives the (signed) Stirling number
of the first kind, that is, the coefficient of `x^k`
in the poynomial `x(x-1)(x-2)...(x-n+1)`.
"""
function Stirling1(n::Integer,k::Integer)::BigInt
  # special cases
  if k<0 || n<0
    throw(DomainError((n,k),"arguments must be nonnegative"))
  end

  if k>n
    return big(0)
  end

  if n==0  # and, by logic, k==0
    return big(1)
  end

  if k==0  # and, by logic, n>0
    return big(0)
  end

  if _has(Stirling1,(n,k))
      return _get(Stirling1,(n,k))
  end

  # end of special cases, invoke recursion

  val = Stirling1(n-1,k-1) - (n-1)*Stirling1(n-1,k)
  _save(Stirling1,(n,k),val)
  return val
end

_make(Stirling1,Tuple{Integer,Integer})



"""
`IntPartitions(n)` is the number of partitions of the integer `n`.

`IntPartitions(n,k)` is the number of partitions of the integer
`n` with exactly `k` (nonzero) parts.
"""
function IntPartitions(n::Integer,k::Integer)::BigInt
  if n<0 || k<0
    throw(DomainError((n,k),"arguments must be nonnegative"))
  end
  # lots of special cases
  if k>n
    return big(0)
  end
  if n==0
    return big(1)
  end
  if k==0
    return big(0)
  end
  if k==n || k==1
    return big(1)
  end
  if _has(IntPartitions,(n,k))
      return _get(IntPartitions,(n,k))
  end

  val =  sum([IntPartitions(n-k,i) for i=0:k])
  _save(IntPartitions,(n,k),val)
  return val
end

function IntPartitions(n::Integer)::BigInt
    if n<0
        throw(DomainError(n,"argument must be nonnegative"))
    end
    if _has(IntPartitions,n)
        return _get(IntPartitions,n)
    end
    val = sum([IntPartitions(n,k) for k=0:n])
    _save(IntPartitions,n,val)
    return val
end

_make(IntPartitions,Union{Tuple{Integer,Integer},Integer})

"""
`IntPartitionsDistinct(n,k)` is the number of partitions of
the integer `n` into exactly `k` *distinct* parts.

`IntPartitionsDistinct(n)` is the number of partitions of `n`
into *distinct* parts.
"""
function IntPartitionsDistinct(n::Integer,k::Integer)::BigInt
  if n<0 || k<0
    throw(DomainError((n,k),"arguments must be nonnegative"))
  end
  Ck2 = div(k*(k-1),2)
  if n < Ck2
    return big(0)
  end
  return IntPartitions(n-Ck2,k)
end

function IntPartitionsDistinct(n::Integer)::BigInt
  if n<0
    throw(DomainError(n,"argument must be nonngative"))
  end
  result = big(0)
  for k=1:n
    s = IntPartitionsDistinct(n,k)
    if s==0
      break
    end
    result += s
  end
  return result
end

"""
`Euler(n)` returns the `n`-th Euler number. Starting with `n=0`
this is the sequence
1, 0, -1, 0, 5, 0, -61, 0, 1385 and so on.
"""
function Euler(n::Integer)::BigInt
  n>=0 || throw(DomainError(n,"argument must be nonngative"))
  if n%2 == 1
    return big(0)
  end
  if n==0
    return big(1)
  end
  if _has(Euler,n)
      return _get(Euler,n)
  end


  last = div(n,2)-1
  val =  -sum([ Binomial(n,2k)*Euler(2k) for k=0:last])
  _save(Euler,n,val)
  return val
end
_make(Euler,Integer)


"""
`PowerSum(n,k)` returns the sum of the `k`-th powers of the
integers `1` through `n`, i.e.,
`1^k + 2^k + 3^k + ... + n^k`.
"""
function PowerSum(n::Integer, k::Integer)::BigInt
  (n>=0 && k>=0) || throw(DomainError((n,k),"arguments must be nonngative"))
  # Base and special cases
  if n==0
    return big(0)
  end
  if k==0
    return big(n)
  end
  if k==1
    return Binomial(n,2)
  end
  if _has(PowerSum,(n,k))
      return _get(PowerSum,(n,k))
  end

  val =  big(n)^k + PowerSum(n-1,k)
  _save(PowerSum,(n,k),val)
  return val
end
_make(PowerSum,Tuple{Integer,Integer})


include("eulerian.jl")

end  #end of module
