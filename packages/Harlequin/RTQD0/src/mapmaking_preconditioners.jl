abstract type Preconditioner end

struct IdentityPreconditioner <: Preconditioner
end

struct JacobiPreconditioner{T <: Number} <: Preconditioner
    diagonal_list::Array{Array{T, 1}, 1}
end

function apply!(precond::IdentityPreconditioner, baselines) where {T <: Number}
    # Do nothing
end

function apply!(precond::JacobiPreconditioner{T}, baselines) where {T <: Number}
    @assert length(baselines) == length(precond.diagonal_list)
    
    for idx in eachindex(baselines)
        baselines[idx] .*= precond.diagonal_list[idx]
    end
end

function jacobi_preconditioner(baseline_length_list, T)
    # TODO: once we specify a mask or flags, we need to take them into account here!
    diagonals = [Array{T}(undef, length(x)) for x in baseline_length_list]

    for cur_diag_idx in eachindex(diagonals)
        diagonals[cur_diag_idx] .= 1 ./ baseline_length_list[cur_diag_idx]
    end
    
    JacobiPreconditioner{T}(diagonals)
end
