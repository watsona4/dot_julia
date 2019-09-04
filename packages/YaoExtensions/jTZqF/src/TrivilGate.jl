export TrivilGate, Wait

abstract type TrivilGate{N} <: PrimitiveBlock{N} end

mat(d::TrivilGate{N}) where N = IMatrix{1<<N}()
apply!(reg::DefaultRegister, d::TrivilGate) = reg
Base.adjoint(g::TrivilGate) = g

"""
    Wait{N, T} <: TrivilGate{N}
    Wait{N}(t)

Wait the experimental signals for time `t` (empty run).
"""
struct Wait{N, T} <: TrivilGate{N}
    t::T
    Wait{N}(t::T) where {N,T} = new{N, T}(t)
end
YaoBlocks.print_block(io::IO, d::Wait) = print(io, "Wait → $(d.t)")
