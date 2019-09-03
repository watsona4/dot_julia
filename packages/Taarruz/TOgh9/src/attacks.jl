"""
    ∇xJ(f, args...)

Returns gradients of the loss function (f) w.r.t. your parameters (args).
"""
function ∇xJ(f, args...)
    args = collect(args)
    args = map(a->isa(a, FloatArray) ? param(a) : a, args)
    J = @diff f(args...)
    ∇ = map(arg->grad(J, arg), args)
    ∇ = filter(i->isa(i, FloatArray), ∇)
end


"""
This function implements FGSM (Fast Gradient Sign Method)
 (arxiv.org/abs/1412.6572). FGSM is a white-box attack which means the attacker
 has full access to the model  including its parameters. In this attack, we
 simply take advantage of the  gradients of the loss with respect to input data.
 We first apply sign function to the input gradients, scale it, and then add
 those gradients to the input  data to get the perturbed data which will
 maximize the loss value. See lenet-fgsm notebook for example usage.

    FGSM(x::FloatArray, ∇x::FloatArray, ϵ; minval=0.0, maxval=1.0)

Applies FGSM for given input array (x), the gradient of your model's loss w.r.t. input array (∇x) and ϵ. minval and maxval stands for clipping.

    FGSM(f, ϵ, args...; minval=0.0, maxval=1.0)

Applies FGSM for given loss function (f), ϵ and arguments for the loss function.
 minval and maxval stands for clipping.
"""
function FGSM(x::FloatArray, ∇x::FloatArray, ϵ; minval=0.0, maxval=1.0)
    T = eltype(x)
    sgn∇x = sign.(∇x)
    x̂ = x + T(ϵ) * sgn∇x
    x̂ = min.(T(maxval), x̂)
    x̂ = max.(T(minval), x̂)
    return x̂
end


function FGSM(f, ϵ, args...; minval=0.0, maxval=1.0)
    args = collect(args)
    ∇x  = ∇xJ(f, args...)
    x = filter(i->isa(i, FloatArray), args)
    x̂ = [FGSM(xi, ∇xi, ϵ) for (xi, ∇xi) in zip(x, ∇x)]
end
