
"""
```julia
three = 3
3
markable_three = Unmarked(three)
3
isunmarked(markable_three)
true
@mark!(markable_three)
3
ismarked(markable_three)
true
```
"""
macro mark!(x)
    quote
        $(esc(x)) = reinterpret(typeof($(esc(x))), lsbit(typeof($(esc(x)))) | ($(esc(x))))
    end
end


"""
```julia
three = 3
3
markable_three = Unmarked(three)
3
isunmarked(markable_three)
true
@mark!(markable_three)
3
ismarked(markable_three)
true
@unmark!(markable_three)
3
ismarked(markable_three)
false
```
"""
macro unmark!(x)
    quote
        $(esc(x)) = reinterpret(typeof($(esc(x))), msbitsof($(esc(x))))
    end
end

for (M,I) in ((:MarkInt128, :Int128), (:MarkInt64, :Int64), 
              (:MarkInt32, :Int32), (:MarkInt16, :Int16), (:MarkInt8, :Int8),
              (:MarkUInt128, :UInt128), (:MarkUInt64, :UInt64), 
              (:MarkUInt32, :UInt32), (:MarkUInt16, :UInt16), (:MarkUInt8, :UInt8))
  @eval begin
    @inline ismarked(x::$M) = isodd(reinterpret($I, x))
    @inline isunmarked(x::$M) = iseven(reinterpret($I, x))
    @inline ismarked(x::$I) = false
    @inline isunmarked(x::$I) = true

    @inline mtype(::Type{$I}) = $M
    @inline mtype(::Type{$M}) = $M
    @inline itype(::Type{$I}) = $I
    @inline itype(::Type{$M}) = $I
    @inline mtype(x::$I) = $M
    @inline mtype(x::$M) = $M
    @inline itype(x::$I) = $I
    @inline itype(x::$M) = $I
    @inline mtyped(x::$I) = reinterpret($M, x)
    @inline mtyped(x::$M) = x
    @inline ityped(x::$M) = reinterpret($I, x)
    @inline ityped(x::$I) = x
        

    @inline mark_unmarked(x::$M) = reinterpret($M, (reinterpret($I, x) | lsbit($I)))
    @inline unmark_marked(x::$M) = reinterpret($M, (msbitsof(reinterpret($I, x))))
    @inline mark(x::$M) = ismarked(x) ? x : mark_unmarked(x)
    @inline unmark(x::$M) = isunmarked(x) ? x : unmark_marked(x) 
  end
end

find_marked(x::Vector{T}) where {T<:MarkableInteger}  = findall(map(ismarked, x))
find_unmarked(x::Vector{T}) where {T<:MarkableInteger}  = findall(map(isunmarked, x))
all_marked(x::Vector{T}) where {T<:MarkableInteger} = x[find_marked(x)]
all_unmarked(x::Vector{T}) where {T<:MarkableInteger} = x[find_unmarked(x)]
