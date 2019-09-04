module XGrad

export
    xdiff,
    xgrad,
    kgrad,
    @diffrule,
    VectorCodeGen,
    BufCodeGen,
    CuCodeGen,
    # re-exports
    #  from Espresso
    Espresso,
    squeeze_sum,
    @get_or_create,    
    __construct,
    #  from LinearAlgebra
    mul!,
    # (other) helpers
    ungetindex,
    sum_grad


include("core.jl")

end # module
