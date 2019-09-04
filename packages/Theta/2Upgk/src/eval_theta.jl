""" 
    theta(z, R, char=[], derivs=[], derivs_t=[])

Compute the Riemann theta function of the matrix in R at z, with optional characteristics or derivatives.

The input derivatives must be unit vectors, and the input z must be of the form ``z = a + τb, b∈[0,1)^g, a∈ \\mathbb{R}^g``.

# Arguments
- `z::Array{<:Number}`: Array of size g, each entry is a complex number.
- `R::RiemannMatrix`: RiemannMatrix type containing matrix.
- `char::Array{}=[]`: 2-element array containing 2 arrays of size g, where entries are either 0 or 1.
- `derivs::Array{}=[]`: N-element array specifying the derivative to the N-th order with respect to z, where each element is an array representing a unit vector in the direction of the derivative.
- `derivs_t::Array{}=[]`: M-element array specifying the derivative to the M-th order with respect to τ, where each element is an array of size 2 whose entries are the index in τ.

# Examples
```julia
julia> theta([0,0], RiemannMatrix([1+im -1; -1 1+im]), char=[[1,0],[1,1]], derivs=[[1,0]], derivs_t=[[2,1]])
```
"""
function theta(z::Array{<:Number}, R::RiemannMatrix; char::Array{}=[], derivs::Array{}=[], derivs_t::Array{}=[])
    # compute theta function with characteristics
    shift_x = zeros(R.g); # shift z by characteristic
    shift_n = zeros(R.g); # shift points in ellipsoid by characteristic
    if length(char) > 0
        shift_x = 0.5*char[2];
        shift_n = 0.5*char[1];
    end
    # compute derivatives with respect to τ by converting to derivatives with respect to z using the heat equation
    deriv_t_factor = 1; # multiply result by this factor
    for d in derivs_t
        if d[1] == d[2]
            deriv_t_factor *= 1/(4*π*im);
        else
            deriv_t_factor *= 1/(2*π*im);
        end
        deriv = [zeros(R.g), zeros(R.g)];
        deriv[1][d[1]] = 1;
        deriv[2][d[2]] = 1;
        derivs = vcat(derivs, deriv);
    end
    # compute theta function
    x = real(z) + shift_x; # shift z by characteristic
    y = convert(Array{Float64}, imag(z));
    y0 = (R.g > 1 ?  inv(R.Y)*y : inv.(R.Y).*y); # Y⁻¹y
    exp_part = exp((π*transpose(y)*y0)[1]); # exponential part of theta function
    osc_part = oscillatory_part(R, x, y0, shift_n, derivs); # oscillatory part of theta function
    return deriv_t_factor*exp_part*osc_part;
end


"""
    oscillatory_part(R, x, y0, shift_n, derivs=[])

Compute the oscillatory part of the Riemann theta function. Helper function to [`theta`](@ref).
"""
function oscillatory_part(R::RiemannMatrix, x::Array{<:Real}, y0::Array{<:Real}, shift_n::Array{<:Real}, derivs::Array{}=[])
    nderivs = size(derivs)[1];
    E = [n + shift_n for n in R.ellipsoid[nderivs + 1]]; # shift points in ellipsoid for computing theta function with characteristics
    w = round.(y0);
    w0 = y0 - w;
    s = (2*π*im)^(nderivs) * sum([
(nderivs > 0 ? prod(transpose(d)*(p-w) for d in derivs) : 1) * exp(2*π*im*((0.5*(transpose(p-w)*R.X*(p-w))[1] + transpose(p-w)*x)[1]) - π*(transpose(p+w0)*R.Y*(p+w0))[1]) for p in E]); # compute sum over points in ellipsoid
    return s;
end








