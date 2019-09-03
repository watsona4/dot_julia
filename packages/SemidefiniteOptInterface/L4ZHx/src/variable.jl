const VIS = Union{VI, Vector{VI}}

function newblock(m::SOItoMOIBridge, n)
    push!(m.blockdims, n)
    m.nblocks += 1
end

isfree(m, v::VI) = v.value in m.free
function unfree(m, v)
    @assert isfree(m, v)
    delete!(m.free, v.value)
end

function _constraintvariable!(m::SOItoMOIBridge{T}, vs::VIS, s::ZS) where T
    blk = newblock(m, -_length(vs))
    for (i, v) in _enumerate(vs)
        setvarmap!(m, v, (blk, i, i, one(T), _getconstant(m, s)))
        unfree(m, v)
    end
    blk
end
vscaling(::Type{<:NS}) = 1.
vscaling(::Type{<:PS}) = -1.
_length(vi::VI) = 1
_length(vi::Vector{VI}) = length(vi)
_enumerate(vi::VI) = enumerate((vi,))
_enumerate(vi::Vector{VI}) = enumerate(vi)
function _constraintvariable!(m::SOItoMOIBridge, vs::VIS, s::S) where S<:Union{NS, PS}
    blk = newblock(m, -_length(vs))
    cst = _getconstant(m, s)
    m.blkconstant[blk] = cst
    for (i, v) in _enumerate(vs)
        setvarmap!(m, v, (blk, i, i, vscaling(S), cst))
        unfree(m, v)
    end
    blk
end
function getmatdim(k::Integer)
    # n*(n+1)/2 = k
    # n^2+n-2k = 0
    # (-1 + sqrt(1 + 8k))/2
    n = div(isqrt(1 + 8k) - 1, 2)
    if n * (n+1) != 2*k
        error("sd dim not consistent")
    end
    n
end
function _constraintvariable!(m::SOItoMOIBridge{T}, vs::VIS, ::DS) where T
    d = getmatdim(length(vs))
    k = 0
    blk = newblock(m, d)
    for i in 1:d
        for j in 1:i
            k += 1
            setvarmap!(m, vs[k], (blk, i, j, i == j ? one(T) : one(T)/2, zero(T)))
            unfree(m, vs[k])
        end
    end
    blk
end
_var(f::SVF) = f.variable
_var(f::VVF) = f.variables
function _throw_error_if_unfree(m, vi::MOI.VariableIndex)
    if !isfree(m, vi)
        error("A variable cannot be constrained by multiple ",
              "`MOI.SingleVariable` or `MOI.VectorOfVariables` constraints.")
    end
end
function _throw_error_if_unfree(m, vis::MOI.Vector)
    for vi in vis
        _throw_error_if_unfree(m, vi)
    end
end
function MOIU.allocate_constraint(m::SOItoMOIBridge{T}, f::VF, s::SupportedSets) where T
    vis = _var(f)
    _throw_error_if_unfree(m, vis)
    blk = _constraintvariable!(m, vis, s)
    if isa(s, ZS)
        ci = _allocate_constraint(m, f, s)
        m.zeroblock[ci] = blk
        return ci
    else
        return CI{typeof(f), typeof(s)}(-blk)
    end
end

_getconstant(m::SOItoMOIBridge, s::MOI.AbstractScalarSet) = MOIU.getconstant(s)
_getconstant(m::SOItoMOIBridge{T}, s::MOI.AbstractSet) where T = zero(T)

_var(f::SVF, j) = f.variable
_var(f::VVF, j) = f.variables[j]
function MOIU.load_constraint(m::SOItoMOIBridge, ci::CI, f::VF, s::SupportedSets)
    if ci.value >= 0 # i.e. s is ZS or _var(f) wasn't free at allocate_constraint
        setconstant!(m, ci, s)
        cs = m.constrmap[ci]
        @assert !isempty(cs)
        for k in 1:length(cs)
            vm = varmap(m, _var(f, k))
            # For free variables, the length of vm is 2, clearly not the case here
            @assert length(vm) == 1
            (blk, i, j, coef, shift) = first(vm)
            c = cs[k]
            setconstraintcoefficient!(m.sdoptimizer, coef, c, blk, i, j)
            setconstraintconstant!(m.sdoptimizer,  _getconstant(m, s) - coef * shift, c)
        end
    end
end

function loadfreevariables!(m::SOItoMOIBridge{T}) where T
    for vi in m.free
        blk = newblock(m, -2)
        # x free transformed into x = y - z with y, z >= 0
        setvarmap!(m, VI(vi), [(blk, 1, 1, one(T), zero(T)), (blk, 2, 2, -one(T), zero(T))])
    end
end
