
using ZygoteRules
using ZygoteRules: @adjoint

# From the flux file, this one replaces
# @grad -> @adjoint
# .data ->
# ::TrackedArray -> ::AbstractArray
# Delete every line containing track(
# Delete all docstrings -- @adjoint dislikes them
# Delete inv!! whatever that was.


@adjoint function exp_(A::AbstractArray)
    expA = exp_(A)
    expA_copy = copy(expA) # ensures that mutating output won't damage the gradient
    expA, Δ -> ( scale!(expA_copy, Δ) ,) # and we can then mutate the copy here... for 1st deriv?
end
@adjoint function exp!(A::AbstractArray)
    expA = exp!(A)
    expA_copy = copy(expA)
    expA, Δ -> ( scale!(expA_copy, Δ) ,)
end
@adjoint function exp!!(A::AbstractArray)
    expA = exp!(A)
    expA, Δ -> ( scale!(Δ, expA) ,)
end

@adjoint function exp_(name::Symbol, A::AbstractArray)
    expA = exp_(name, A)
    expA_copy = copy_(:exp_copy, expA) # opts in but has a distinct name? NOT safe
    expA, Δ -> (nothing, scale!(expA_copy, Δ) ,)
end


@adjoint log_(A::AbstractArray) =
    log_(A), Δ -> ( iscale_(Δ, A) ,)
@adjoint function log!(A::AbstractArray)
    invA = inv_(A)
    log!(A), Δ -> ( scale!(invA, Δ) ,)
end
@adjoint function log!!(A::AbstractArray)
    invA = inv_(A)
    logA = log!(A)
    logA, Δ -> ( scale!(Δ, invA) ,)
end

@adjoint function log_(name::Symbol, A::AbstractArray)
    invA = inv_(:log_copy, A)
    logA = log_(name, A)
    logA, Δ -> (nothing, scale!(invA, Δ) ,)
end


@adjoint scale_(A::AbstractArray, b::Number) = scale_(A, b), Δ -> (scale_(Δ, b), nothing)
@adjoint scale!(A::AbstractArray, b::Number) = scale!(A, b), Δ -> (scale_(Δ, b), nothing)
@adjoint scale!!(A::AbstractArray, b::Number) = scale!(A, b), Δ -> (scale!(Δ, b), nothing)

# @adjoint scale_(A::AbstractArray, b::TrackedReal) = scale_(A, b), Δ -> (scale_(Δ, b), dot(A,Δ))
# @adjoint scale!(A::AbstractArray, b::TrackedReal) = @error "hmm"

@adjoint scale_(A::AbstractArray, B::Union{Array, RVector}) = scale_(A, B), Δ -> (scale_(Δ, B), nothing)
@adjoint scale!(A::AbstractArray, B::Union{Array, RVector}) = scale!(A, B), Δ -> (scale_(Δ, B), nothing)
@adjoint scale!!(A::AbstractArray, B::Union{Array, RVector}) = scale!(A, B), Δ -> (scale!(Δ, B), nothing)

@adjoint  scale_(A::AbstractArray, B::AbstractArray) =
    scale_(A, B), Δ ->  (scale_(Δ, B), sum!(similar(B), scale_(Δ,A)) )
@adjoint function scale!(A::AbstractArray, B::AbstractArray)
    Ac = copy(A)
    scale!(A, B), Δ -> (scale_(Δ, B), sum!(similar(B), scale!(Ac,Δ)) )
end
@adjoint function scale!!(A::AbstractArray, B::AbstractArray)
    Ac = copy(A)
    scale!(A, B), function(Δ)
        ∇B = sum!(similar(B), scale!(Ac,Δ))
        (scale!(Δ, B),  ∇B)
    end
end

@adjoint  scale_(A::Array, B::AbstractArray) =
    scale_(A, B), Δ ->  (nothing, sum!(similar(B), scale_(Δ,A)) )
@adjoint function scale!(A::Array, B::AbstractArray)
    Ac = copy(A)
    scale!(A, B), Δ -> (nothing, sum!(similar(B), scale!(Ac,Δ)) )
end

@adjoint iscale_(A::AbstractArray, b::Number) = iscale_(A, b), Δ -> (iscale_(Δ, b), nothing)
@adjoint iscale!(A::AbstractArray, b::Number) = iscale!(A, b), Δ -> (iscale!(Δ, b), nothing)

# @adjoint iscale_(A::AbstractArray, b::TrackedReal) = iscale_(A, b), Δ -> (iscale_(Δ, b), nothing)
# @adjoint iscale!(A::AbstractArray, b::TrackedReal) = iscale!(A, b), Δ -> (iscale!(Δ, b), nothing)

@adjoint iscale_(A::AbstractArray, B::Union{Array, RVector}) = iscale_(A, B), Δ -> (iscale_(Δ, B), nothing)
@adjoint iscale!(A::AbstractArray, B::Union{Array, RVector}) = iscale!(A, B), Δ -> (iscale!(Δ, B), nothing)
@adjoint iscale!!(A::AbstractArray, B::Union{Array, RVector}) = scale!(A, inv!(B)), Δ -> (scale!(Δ, B), nothing)

@adjoint iscale_(A::AbstractArray, B::AbstractArray) = iscale_(A, B), Δ -> (iscale_(Δ, B), sum!(similar(B), -1 .* Δ .* A ./ B .^2))
# @adjoint function iscale!(A::AbstractArray, B::AbstractArray)
#     Ac = copy(A)
#     iscale!(A, B), Δ -> (scale(Δ, B), sum!(similar(B), scale!(Ac,Δ)) )
# end

@adjoint iscale_(A::Array, B::AbstractArray) = iscale_(A, B), Δ -> (nothing, sum!(similar(B), -1 .* Δ .* A ./ B .^2))


# @adjoint inv!(A::AbstractArray, b::Number=1) = inv_(A, b), Δ -> (-1 .* Δ .* b .* A .^ (-2) , nothing) # one copy
@adjoint function inv_(A::AbstractArray, b=1)
    invA = inv_(A, b)
    invA_copy = copy(invA) # don't invert twice?
    invA, Δ -> (invA_copy .= -1 .* Δ .* b .* invA_copy .^ 2 , nothing) # total one copy
end
# @adjoint inv!(A::AbstractArray, b::Number=1) = inv!(A, b), Δ -> (-1 .* Δ .* b .* A .^ 2 , nothing) # one copy
@adjoint function inv!(A::AbstractArray, b=1)
    invA = inv!(A, b)
    invA_copy = copy(invA) # keep gradient calc safe from downstream mutations
    invA, Δ -> (invA_copy .= -1 .* Δ .* b .* invA_copy .^ 2 , nothing) # total one copy
end


using FillArrays

@adjoint function sum_(A::AbstractArray)
    sum(A), Δ -> (Ones(A) ,)
end
