
for F in (:typemax, :typemin, :zero, :one)
  @eval begin
    @pure function $F(::Type{M}) where {M<:MarkableInteger}
        Unmarked($F(itype(M)))
    end
    @pure function $F(x::M) where {M<:MarkableInteger}
        Unmarked($F(itype(M)))
    end
  end
end

for F in (:iszero, :isone, :iseven, :isodd)
  @eval begin
    function $F(x::M) where {M<:MarkableInteger}
        xx = itype(x)
        return $F(xx)
    end
  end
end


for F in (:leading_zeros, :leading_ones, :trailing_zeros, :trailing_ones,
          :count_zeros, :count_ones, :abs, :(-))
  @eval begin
    function $F(x::M) where {M<:MarkableInteger}
        xx = itype(x) >> 1
        zz = $F(xx)
        z = Unmarked(zz)
        z |= any_lsbits(x)
        return z
    end
  end
end

for F in (:(|), :(&), :(⊻))
  @eval begin
    function $F(x::M, y::M) where {M<:MarkableInteger}
        xx = ityped(x) >> 1
        yy = ityped(y) >> 1
        zz = $F(xx, yy)
        z = zz << 1
        !(zz === z >> 1) && throw(DomainError("$x, $y"))
        z |= any_lsbits(x, y)
        return reinterpret(M, z)
    end
    $F(x::M1, y::M2) where {M1<:MarkableInteger, M2<:MarkableInteger} =
         $F(promote(x,y)...,)
    $F(x::M, y::I) where {M<:MarkableInteger, I<:Union{Signed,Unsigned}} =
         $F(promote(x,y)...,)
    $F(x::I, y::M) where {M<:MarkableInteger, I<:Union{Signed,Unsigned}} =
         $F(promote(x,y)...,)
  end
end

for F in(:flipsign, :copysign,
         :(+), :(-), :(*), :(^), :div, :cld, :fld, :rem, :mod,
         :checked_add, :checked_cld, :checked_div, :checked_fld,
         :checked_mod, :checked_mul, :checked_rem, :checked_sub)
  @eval begin
    function $F(x::M, y::M) where {M<:MarkableInteger}
        xx = ityped(x) >> 1
        yy = ityped(y) >> 1
        zz = $F(xx, yy)
        z = zz << 1
        !(zz === z >> 1) && throw(DomainError("$x, $y"))
        z |= any_lsbits(x, y)
        return reinterpret(M, z)
    end
    $F(x::M1, y::M2) where {M1<:MarkableInteger, M2<:MarkableInteger} =
         $F(promote(x,y)...,)
    $F(x::M, y::I) where {M<:MarkableInteger, I<:Union{Signed,Unsigned}} =
         $F(promote(x,y)...,)
    $F(x::I, y::M) where {M<:MarkableInteger, I<:Union{Signed,Unsigned}} =
         $F(promote(x,y)...,)
  end
end


string(x::T) where {T<:MarkableSigned} = string(ityped(x) >> 1)
string(x::T) where {T<:MarkableUnsigned} = string(ityped(x) >> 1)

show(io::IO, x::T) where {T<:MarkableInteger} = print(io, string(x))
show(x::T) where {T<:MarkableInteger} = show(StdOut, x)
