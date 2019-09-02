function SteeringBVP(f::LinearDynamics{Dx,Du}, j::TimePlusQuadraticControl{Du};
                     compile::Union{Val{false},Val{true}}=Val(false)) where {Dx,Du}
    compile === Val(true) ? SteeringBVP(f, j, EmptySteeringConstraints(), LinearQuadraticHelpers(f.A, f.B, f.c, j.R)) :
                            SteeringBVP(f, j, EmptySteeringConstraints(), EmptySteeringCache())
end

struct LinearQuadraticHelpers{FGinv<:Function,
                              FexpAt<:Function,
                              Fcdrift<:Function,
                              Fcost<:Function,
                              Fdcost<:Function,
                              Fddcost<:Function,
                              Fx<:Function,
                              Fu<:Function} <: SteeringCache
    Ginv::FGinv
    expAt::FexpAt
    cdrift::Fcdrift
    cost::Fcost
    dcost::Fdcost
    ddcost::Fddcost
    x::Fx
    u::Fu
    symbolic_exprs::Dict{String,Union{SymPy.Sym,Vector{SymPy.Sym},Matrix{SymPy.Sym}}}
end

function (bvp::LinearQuadraticSteering{Dx,Du,<:LinearQuadraticHelpers})(x0::StaticVector{Dx}, xf::StaticVector{Dx},
                                                                        c_max::T=eltype(x0)(1e6)) where {Dx,Du,T<:Number}    # TODO: handle c_max == Inf
    x0 == xf && return (cost=T(0), controls=BVPControl(T(0), x0, xf, bvp.cache.x, bvp.cache.u))
    t = optimal_time(bvp, x0, xf, c_max)
    (cost=bvp.cache.cost(x0, xf, t), controls=BVPControl(t, x0, xf, bvp.cache.x, bvp.cache.u))
end

function LinearQuadraticHelpers(A_::AbstractMatrix, B_::AbstractMatrix, c_::AbstractVector, R_::AbstractMatrix)
    A, B, c, R = Array(A_), Array(B_), Vector(c_), Array(R_)
    Dx, Du = size(B)
    t, s = SymPy.symbols("t s", real=true)
    x = collect(SymPy.symbols(join(("x$i" for i in 1:Dx), " "), real=true))
    y = collect(SymPy.symbols(join(("y$i" for i in 1:Dx), " "), real=true))

    expAt = (A*t).exp()
    expAs = (A*s).exp()
    expAt_s = (A*(t - s)).exp()
    G = SymPy.integrate.(expAt*B*inv(R)*B'*expAt', t)
    Ginv = inv(G)
    cdrift = SymPy.integrate.(expAt, t)*c
    xbar = expAt*x + cdrift
    cost = t + (y - xbar)'*Ginv*(y - xbar)
    dcost = diff(cost, t)
    ddcost = diff(cost, t, 2)
    x_s = expAs*x + SymPy.integrate.(expAs, s)*c + SymPy.integrate.(expAs*B*inv(R)*B'*expAs', s)*expAt_s'*Ginv*(y-xbar)
    u_s = inv(R)*B'*expAt_s.transpose()*Ginv*(y-xbar)  # transpose needed here (and technically above) to avoid `Any`s

    symbolic_exprs = Dict{String,Union{SymPy.Sym,Vector{SymPy.Sym},Matrix{SymPy.Sym}}}(
        "Ginv" => Ginv,
        "expAt" => expAt,
        "cdrift" => cdrift,
        "cost" => cost,
        "dcost" => dcost,
        "ddcost" => ddcost,
        "x_s" => x_s,
        "u_s" => u_s,
        "t" => t,
        "s" => s,
        "x" => x,
        "y" => y
    )
    for (k, v) in symbolic_exprs
        symbolic_exprs[k] = SymPy.collect.(SymPy.expand.(v), t)
    end

    symbol_dict = merge(Dict(Symbol("x$i") => :(x[$i]) for i in 1:Dx),
                        Dict(Symbol("y$i") => :(y[$i]) for i in 1:Dx))
    sarray    = A_ isa StaticArray
    t_args    = :((t::T) where {T})
    xyt_args  = :((x::AbstractVector, y::AbstractVector, t::T) where {T})
    xyts_args = :((x::AbstractVector, y::AbstractVector, t::T, s) where {T})
    LinearQuadraticHelpers(
        code2func(sympy2code.(symbolic_exprs["Ginv"], Ref(symbol_dict)), t_args, sarray),
        code2func(sympy2code.(symbolic_exprs["expAt"], Ref(symbol_dict)), t_args, sarray),
        code2func(sympy2code.(symbolic_exprs["cdrift"], Ref(symbol_dict)), t_args, sarray),
        code2func(sympy2code.(symbolic_exprs["cost"], Ref(symbol_dict)), xyt_args, sarray),
        code2func(sympy2code.(symbolic_exprs["dcost"], Ref(symbol_dict)), xyt_args, sarray),
        code2func(sympy2code.(symbolic_exprs["ddcost"], Ref(symbol_dict)), xyt_args, sarray),
        code2func(sympy2code.(symbolic_exprs["x_s"], Ref(symbol_dict)), xyts_args, sarray),
        code2func(sympy2code.(symbolic_exprs["u_s"], Ref(symbol_dict)), xyts_args, sarray),
        symbolic_exprs
    )
end

function sympy2code(x, symbol_dict = Dict())
    code = foldl(replace, (".+" => " .+",
                           ".-" => " .-",
                           ".*" => " .*",
                           "./" => " ./",
                           ".^" => " .^"); init=SymPy.sympy.julia_code(x))
    expr = Meta.parse(code)
    MacroTools.postwalk(x -> x isa AbstractFloat ? :(T($x)) : get(symbol_dict, x, x), expr)
end

code2func(code, args, static_array = true) = eval(:($args -> $code))
function code2func(code::AbstractVector, args, static_array = true)
    N = length(code)
    if static_array
        body = :(SVector{$N}($(code...)))
    else
        body = :([$(code...)])
    end
    eval(:($args -> $body))
end
function code2func(code::AbstractMatrix, args, static_array = true)
    M,N = size(code)
    if static_array
        body = :(SMatrix{$M,$N}($(code...)))
    else
        body = Expr(:vcat, (Expr(:row, code[i,:]...) for i in 1:M)...)
    end
    eval(:($args -> $body))
end

function optimal_time(bvp::SteeringBVP{D,C,EmptySteeringConstraints,<:LinearQuadraticHelpers},
                      x0::StaticVector{Dx},
                      xf::StaticVector{Dx},
                      t_max::T) where {Dx,Du,T<:Number,D<:LinearDynamics{Dx,Du},C<:TimePlusQuadraticControl{Du}}
    cost   = (s -> (Base.@_inline_meta; bvp.cache.cost(x0, xf, s)))    # closures and optimizers below both @inline-d
    dcost  = (s -> (Base.@_inline_meta; bvp.cache.dcost(x0, xf, s)))
    ddcost = (s -> (Base.@_inline_meta; bvp.cache.ddcost(x0, xf, s)))
    t = (T === Float64 ? newton(dcost, ddcost, t_max/100, t_max) :
                         bisection(dcost, t_max/100, t_max))
    t !== nothing ? t : golden_section(cost, t_max/100, t_max)
end
