
"""
    DoNotCare{T}

A type that is equal to all things that are of type <:T.
For internal use.
Will interact weirdly with hash based dicts
"""
struct DoNotCare{T}
end

function Base.isequal(::DoNotCare{T}, ::A) where {T,A}
    A <: T
end

function Base.isequal(::DoNotCare{T1}, ::DoNotCare{T2}) where {T1,T2}
    T1 == T2
end


Base.isequal(a, d::DoNotCare)=isequal(d,a)
Base.:(==)(a, d::DoNotCare)=isequal(d,a)
Base.:(==)(d::DoNotCare, a)=isequal(d,a)
Base.:(==)(d::DoNotCare, a::DoNotCare)=isequal(d,a)

Base.isless(a, d::DoNotCare)=false
Base.isless(d::DoNotCare, a)=false
Base.isless(d::DoNotCare, a::DoNotCare)=false

