# Utility
@inline function _map(f::F, a::Tuple{Vararg{Any, N}}) where {F, N}
    ntuple(Val(N)) do i
        f(a[i])
    end
end

@inline function _map(f::F, a::Tuple{Vararg{Any, N}}, b::Tuple{Vararg{Any, N}}) where {F, N}
    ntuple(Val(N)) do i
        f(a[i], b[i])
    end
end
