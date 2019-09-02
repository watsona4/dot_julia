
#= General =#
export CartesianLocations
"""
    CartesianLocations(dim::Dims, doShift::Bool=true)

Retuns a `(prod(dim),length(dim))` array of grid locations. `doShift` shifts the
locations to be consistent with `fftshift`.

# Examples
```julia-repl
julia> loc = [CartesianLocations((2,2)), CartesianLocations((2,2),false)]
2-element Array{Array{Int64,2},1}:
 [-1 -1; 0 -1; -1 0; 0 0]
 [1 1; 2 1; 1 2; 2 2]
```
"""
CartesianLocations(dim::Dims, doShift::Bool=true) = doShift ?
  Array(hcat(collect.(Tuple.(CartesianIndices(dim).-ctrSub(dim)))...)') :
  Array(hcat(collect.(Tuple.(CartesianIndices(dim)))...)')

export ctrSub
"""
    ctrSub(dim::Dims) = CartesianIndex(dim .÷ 2 .+ 1)

As a separate fn, ensure consistent behaviour of getting ::CartesianIndex to the
center of a Nd-Array of size `dim`.
This `center` should match `fftshift`'s `center`.

See also: `ctrInd`
"""
ctrSub(dim::Dims) = CartesianIndex(dim .÷ 2 .+ 1)

export ctrInd
"""
    ctrInd(dim::Dims) = sum((dim.÷2) .* [1; cumprod([dim[1:end-1]...])])+1

As a separate fn, ensure consistent behariour of getting the linear index to the
center of a Nd-array of size `dim`.
This `center` should match `fftshift`'s `center`.

See also: `ctrSub`
"""
ctrInd(dim::Dims) = sum((dim.÷2) .* [1; cumprod([dim[1:end-1]...])])+1

#= MR =#
export k2g
"""
    k2g(k::TypeND(K0D,:), isTx::Bool=false; dt::T0D=4e-6u"s", γ::Γ0D=γ¹H)
Gradient, `g`, of the `TxRx` k-space, (trasmit/receive, excitation/imaging).

# Usage
*INPUTS*:
- `k::TypeND(K0D, :)` (nSteps, Nd...), Tx or Rx k-space, w/ unit u"cm^-1".
- `isTx::Bool`, if `true`, compute transmit k-space, `k`, ends at the origin.
*KEYWORDS*:
- `dt::T0D` (1,), gradient temporal step size, i.e., dwell time.
- `γ::Γ0D` (1,), gyro-ratio.
*OUTPUTS*:
- `g::TypeND(GR0D, :)` (nSteps, Nd...), gradient

# Note
The function asserts if `k` ends at the origin for `isTx==true`.

See also: `g2k`
"""
k2g(k::TypeND(K0D,:), isTx::Bool=false; dt::T0D=4e-6u"s", γ::Γ0D=γ¹H) =
  (isTx&&any(ustrip.(selectdim(k,1,size(k,1))) .!=0)) ?
    error("Tx `k` must end at 0") : [selectdim(k,1,1:1); diff(k,dims=1)]/(γ*dt)

export g2k
"""
    g2k(g::TypeND(GR0D,:); isTx::Bool=false, dt::T0D=4e-6u"s", γ::Γ0D=γ¹H)
Compute k-space from gradient.

# Usage
*INPUTS*:
- `g::TypeND(GR0D, :)` (nSteps, Nd...), gradient
- `isTx::Bool`, if `true`, compute transmit k-space, `k`, ends at the origin.
*KEYWORDS*:
- `dt::T0D` (1,), gradient temporal step size, i.e., dwell time.
- `γ::Γ0D` (1,), gyro-ratio.
*OUTPUTS*:
- `k::TypeND(K0D, :)` (nSteps, Nd...), k-space, w/ unit u"cm^-1".

See also: `k2g`
"""
g2k(g::TypeND(GR0D,:), isTx::Bool=false; dt::T0D=4e-6u"s", γ::Γ0D=γ¹H) =
  γ*dt*cumsum(g,dims=1) |> k->isTx ? k.-selectdim(k,1,size(k,1):size(k,1)) : k

export g2s
"""
    g2s(g::TypeND(GR0D,:); dt::T0D=4e-6u"s")
Slew rate `sl`, of the gradient, `g`.

# Usage
*INPUTS*:
- `g::TypeND(GR0D, :)` (nSteps, Nd...)
*KEYWORDS*:
- `dt::T0D` (1,), gradient temporal step size, i.e., dwell time.
*OUTPUTS*:
- `sl::TypeND(Quantity{<:Real, 𝐁/𝐋/𝐓, :)` (nSteps, Nd...), slew rate

# Note
No `s2g` is provided for the moment.
"""
g2s(g::TypeND(GR0D,:);dt::T0D=4e-6u"s") = [selectdim(g,1,1:1);diff(g,dims=1)]/dt

