mutable struct drake_signal_t <: LCMType
    dim::Int32
    val::Vector{Float64}
    coord::Vector{String}
    timestamp::Int64
end

@lcmtypesetup(drake_signal_t,
    val => (dim,),
    coord => (dim,),
)
