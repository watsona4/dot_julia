IVERBOSE && @info "ArrayAllez loaded in-place code for Tracker"

using .Tracker
using .Tracker: track, TrackedArray, TrackedReal, @grad, data, nobacksies # also for prod....jl

"""
It is safe to mutate the forward output of `exp!` and `exp_`,
as they keep a copy for backwards use.

    exp!!(A::TrackedArray)
The gradient function of `exp!!` mutates its backward `Δ`, no copies.
Whether or not this is safe is for you to decide.
It tends to lead to Inf problems when used inside `@btime`.
"""
exp!(A::TrackedArray) = track(exp!, A)
exp!!(A::TrackedArray) = track(exp!!, A)
exp_(A::TrackedArray) = track(exp_, A)

exp0(A::TrackedArray) = exp.(A)

@grad function exp_(A::TrackedArray)
    expA = exp_(A.data)
    expA_copy = copy(expA) # ensures that mutating output won't damage the gradient
    expA, Δ -> ( scale!(expA_copy, Δ) ,) # and we can then mutate the copy here... for 1st deriv?
end
@grad function exp!(A::TrackedArray)
    expA = exp!(A.data)
    expA_copy = copy(expA)
    expA, Δ -> ( scale!(expA_copy, Δ) ,)
end
@grad function exp!!(A::TrackedArray)
    expA = exp!(A.data)
    expA, Δ -> ( scale!(Δ, expA) ,)
end

exp_(name::Symbol, A::TrackedArray) = track(exp_, name, A)
@grad function exp_(name::Symbol, A::TrackedArray)
    expA = exp_(name, A.data)
    expA_copy = copy_(:exp_copy, expA) # opts in but has a distinct name? NOT safe
    expA, Δ -> (nothing, scale!(expA_copy, Δ) ,)
end


"""
For `log!` it is safe to mutate both the input and the forward output,
as the `inv_(A)` needed for the gradient is computed ahead of time.
For `log_` it is safe to mutate the output but not its input.

    log!!(A::TrackedArray)
Note that the gradient function of `log!!` mutates its backward `Δ`.
Even less of a good idea than `exp!!` as we must copy `inv_(A)` anyway.
"""
log!(A::TrackedArray) = track(log!, A)
log!!(A::TrackedArray) = track(log!!, A)
log_(A::TrackedArray) = track(log_, A)

log0(A::TrackedArray) = log.(A)

@grad log_(A::TrackedArray) =
    log_(A.data), Δ -> ( iscale_(Δ, A.data) ,)
@grad function log!(A::TrackedArray)
    invA = inv_(A.data)
    log!(A.data), Δ -> ( scale!(invA, Δ) ,)
end
@grad function log!!(A::TrackedArray)
    invA = inv_(A.data)
    logA = log!(A.data)
    logA, Δ -> ( scale!(Δ, invA) ,)
end

log_(name::Symbol, A::TrackedArray) = track(log_, name, A)
@grad function log_(name::Symbol, A::TrackedArray)
    invA = inv_(:log_copy, A.data)
    logA = log_(name, A.data)
    logA, Δ -> (nothing, scale!(invA, Δ) ,)
end


"""
    scale!!(A::TrackedArray, b)
This may mutate its backward `Δ`, watch out.
"""
scale!(A::TrackedArray, b) = track(scale!, A, b)
scale!(A::TrackedArray, b::Number) = track(scale!, A, b) # just to avoid ambiguty
scale!(A::Array, b::TrackedArray) = track(scale!, A, b)

scale_(A::TrackedArray, b) = track(scale_, A, b)
scale_(A::TrackedArray, b::AbstractArray) = track(scale_, A, b) # avoid an ambiguty?
scale0(A::TrackedArray, b) = A .* b

@grad scale_(A::TrackedArray, b::Number) = scale_(A.data, b), Δ -> (scale_(Δ, b), nothing)
@grad scale!(A::TrackedArray, b::Number) = scale!(A.data, b), Δ -> (scale_(Δ, b), nothing)
@grad scale!!(A::TrackedArray, b::Number) = scale!(A.data, b), Δ -> (scale!(Δ, b), nothing)

# @grad scale_(A::TrackedArray, b::TrackedReal) = scale_(A.data, b), Δ -> (scale_(Δ, b), dot(A,Δ))
# @grad scale!(A::TrackedArray, b::TrackedReal) = @error "hmm"

@grad scale_(A::TrackedArray, B::Union{Array, RVector}) = scale_(A.data, B), Δ -> (scale_(Δ, B), nothing)
@grad scale!(A::TrackedArray, B::Union{Array, RVector}) = scale!(A.data, B), Δ -> (scale_(Δ, B), nothing)
@grad scale!!(A::TrackedArray, B::Union{Array, RVector}) = scale!(A.data, B), Δ -> (scale!(Δ, B), nothing)

@grad  scale_(A::TrackedArray, B::TrackedArray) =
    scale_(A.data, B.data), Δ ->  (scale_(Δ, B), sum!(similar(B), scale_(Δ,A)) )
@grad function scale!(A::TrackedArray, B::TrackedArray)
    Ac = copy(A.data)
    scale!(A.data, B.data), Δ -> (scale_(Δ, B), sum!(similar(B), scale!(Ac,Δ)) )
end
@grad function scale!!(A::TrackedArray, B::TrackedArray)
    Ac = copy(A.data)
    scale!(A.data, B.data), function(Δ)
        ∇B = sum!(similar(B), scale!(Ac,Δ))
        (scale!(Δ, B),  ∇B)
    end
end

@grad  scale_(A::Array, B::TrackedArray) =
    scale_(A, B.data), Δ ->  (nothing, sum!(similar(B), scale_(Δ,A)) )
@grad function scale!(A::Array, B::TrackedArray)
    Ac = copy(A)
    scale!(A, B.data), Δ -> (nothing, sum!(similar(B), scale!(Ac,Δ)) )
end

iscale!(A::TrackedArray, b) = track(iscale!, A, b)
iscale_(A::TrackedArray, b) = track(iscale_, A, b)
iscale0(A::TrackedArray, b) = A ./ b

@grad iscale_(A::TrackedArray, b::Number) = iscale_(A.data, b), Δ -> (iscale_(Δ, b), nothing)
@grad iscale!(A::TrackedArray, b::Number) = iscale!(A.data, b), Δ -> (iscale!(Δ, b), nothing)

# @grad iscale_(A::TrackedArray, b::TrackedReal) = iscale_(A.data, b.data), Δ -> (iscale_(Δ, b), nothing)
# @grad iscale!(A::TrackedArray, b::TrackedReal) = iscale!(A.data, b.data), Δ -> (iscale!(Δ, b), nothing)

@grad iscale_(A::TrackedArray, B::Union{Array, RVector}) = iscale_(A.data, B), Δ -> (iscale_(Δ, B), nothing)
@grad iscale!(A::TrackedArray, B::Union{Array, RVector}) = iscale!(A.data, B), Δ -> (iscale!(Δ, B), nothing)
@grad iscale!!(A::TrackedArray, B::Union{Array, RVector}) = scale!(A.data, inv!(B)), Δ -> (scale!(Δ, B), nothing)

@grad iscale_(A::TrackedArray, B::TrackedArray) = iscale_(A.data, B.data), Δ -> (iscale_(Δ, B), sum!(similar(B), -1 .* Δ .* A ./ B .^2))
# @grad function iscale!(A::TrackedArray, B::TrackedArray)
#     Ac = copy(A.data)
#     iscale!(A.data, B.data), Δ -> (scale(Δ, B.data), sum!(similar(B), scale!(Ac,Δ)) )
# end

@grad iscale_(A::Array, B::TrackedArray) = iscale_(A, B.data), Δ -> (nothing, sum!(similar(B), -1 .* Δ .* A ./ B .^2))


"""
    inv!!(A::TrackedArray)
This may mutate its backward `Δ`, watch out.
"""
inv!(A::TrackedArray, b::Number=1) = track(inv!, A, b)
inv_(A::TrackedArray, b::Number=1) = track(inv_, A, b)
inv!!(A::TrackedArray, b::Number=1) = track(inv!!, A, b)

inv0(A::TrackedArray, b) = 1 ./ A

# @grad inv!(A::TrackedArray, b::Number=1) = inv_(A.data, b), Δ -> (-1 .* Δ .* b .* A.data .^ (-2) , nothing) # one copy
@grad function inv_(A::TrackedArray, b=1)
    invA = inv_(A.data, b)
    invA_copy = copy(invA) # don't invert twice?
    invA, Δ -> (invA_copy .= -1 .* Δ .* b .* invA_copy .^ 2 , nothing) # total one copy
end
# @grad inv!(A::TrackedArray, b::Number=1) = inv!(A.data, b), Δ -> (-1 .* Δ .* b .* A.data .^ 2 , nothing) # one copy
@grad function inv!(A::TrackedArray, b=1)
    invA = inv!(A.data, b)
    invA_copy = copy(invA) # keep gradient calc safe from downstream mutations
    invA, Δ -> (invA_copy .= -1 .* Δ .* b .* invA_copy .^ 2 , nothing) # total one copy
end
@grad inv!!(A::TrackedArray, b::Number=1) = inv!(A.data, b), Δ -> (scale!(Δ,A,A,-b), nothing)


using FillArrays
"""
    sum_(A)
Like `sum(A)`, but with a `FilledArray.Ones` when going backwards.
"""
sum_(A::TrackedArray) = track(sum_, A)

@grad function sum_(A::TrackedArray)
    sum(A.data), Δ -> (Ones(A.data) ,)
end

