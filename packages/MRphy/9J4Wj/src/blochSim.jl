
#= 𝐵-effective =#
# Methods for getting 𝐵-effective
export rfgr2B
"""
    B = rfgr2B(rf, gr, loc; Δf, b1Map, γ)
Turn rf, `rf`, and gradient, `gr`, into 𝐵-effective magnetic field.

*INPUTS*:
- `rf::TypeND(RF0D, [1,2])` (nT, (nCoil))
- `gr::TypeND(GR0D, [2])`   (nT, 3)
- `loc::TypeND(L0D, [2])`   (1,3) or (nM, 3), locations.
*KEYWORDS*:
- `Δf::TypeND(F0D, [0,1,2])` (1,)  or (nM,), off-resonance.
- `b1Map::TypeND(Union{Real,Complex},[0,1,2])` (1,) or (nM,(nCoils)),
   transmit sensitivity.
- `γ::TypeND(Γ0D, [0,1])` (1,)  or (nM,), gyro-ratio
*OUTPUS*:
- `B`, generator of `TypeND(B0D, [2])` (1,1,nT), 𝐵 field.

# TODO:
Support `loc`, `Δf`, and `b1Map` being `Base.Generators`.
"""
function rfgr2B(rf   ::TypeND(RF0D, [1,2]),
                gr   ::TypeND(GR0D, [2]),
                loc  ::TypeND(L0D,  [2]) = [0 0 0]u"cm";
                Δf   ::TypeND(F0D,  [0,1]) = 0u"Hz",
                b1Map::TypeND(Union{Real,Complex}, [0,1,2,3]) = 1,
                γ    ::TypeND(Γ0D,  [0,1]) = γ¹H)

  nM = maximum(map(x->size(x,1), (loc, Δf, b1Map, γ)))

  Bxy_gen = b1Map==1 ?
    @inbounds(view(rf,t,:)       |> x->repeat([real(x) imag(x)], nM)
              for t in axes(rf,1)) :
    @inbounds(b1Map*view(rf,t,:) |> x->       [real(x) imag(x)]
              for t in axes(rf,1))

  Bz_gen = Δf==0u"Hz" ?
    @inbounds(loc*view(gr,t,:)          for t in axes(gr,1)) :
    @inbounds(loc*view(gr,t,:).+(Δf./γ) for t in axes(gr,1))

  B_gen = @inbounds([bxy bz] for (bxy, bz) in zip(Bxy_gen, Bz_gen))
  return B_gen
end

#= rotation axis/angle, U/Φ =#
export B2UΦ
"""
    B2UΦ(B::TypeND(B0D,[2,3]); γ::TypeND(Γ0D,[0,1]), dt::T0D=4e-6u"s")
Given 𝐵-effective, `B`, compute rotation axis/angle, `U`/`Φ`.

*INPUTS*:
- `B::TypeND(B0D, [2,3])` (1,3,nT) or (nM, 3, nT), 𝐵 field.
*KEYWORDS*:
- `γ::TypeND(Γ0D, [0,1])`: Global, (1,); Spin-wise, (nM, 1). gyro ratio
- `dt::T0D` (1,), simulation temporal step size, i.e., dwell time.
*OUTPUTS*:
- `U::TypeND(Real, [2,3])` (1,3,(nT)) or (nM,3,(nT)), axis.
- `Φ::TypeND(Real, [2,3])` (1,1,(nT)) or (nM,1,(nT)), angle.

# Notes:
Somehow, in-place version, `B2UΦ!(B,U,Φ; γ,dt)`, provokes more allocs in julia.
"""
@inline function B2UΦ(B::TypeND(B0D, [2,3]);
                      γ::TypeND(Γ0D, [0,1]), dt::T0D=4e-6u"s")
  X = γ*dt
  U = ustrip.(Float64, unit.(X).^-1, B)
  Φ = sqrt.(sum(U.*U, dims=2))
  U .= U./Φ .|> x->isnan(x) ? 0 : -x # negate to make: 𝐵×𝑀 → 𝑀×𝐵
  Φ .*= ustrip.(X).*2π
  return (U=U, Φ=Φ)
end

@inline function B2UΦ!(B::TypeND(B0D, [2,3]),
                       U::TypeND(AbstractFloat, [2,3]),
                       Φ::TypeND(AbstractFloat, [2,3]);
                       γ::TypeND(Γ0D, [0,1]), dt::T0D=4e-6u"s")
  X = γ*dt
  U .= ustrip.(Float64, unit.(X).^-1, B)
  Φ .= sqrt.(sum(U.*U, dims=2))
  U .= U./Φ .|> x->isnan(x) ? 0 : -x # negate to make: 𝐵×𝑀 → 𝑀×𝐵
  Φ .*= ustrip.(X).*2π
  return (U=U, Φ=Φ)
end

export UΦRot!, UΦRot
"""
    UΦRot!(U, Φ, V, R)
Apply axis-angle, `U`-`Φ` based rotation on `V`. Rotation is broadcasted on `V`
along its 3rd dimension. Results will overwrite into `R`.

*INPUTS*:
- `U::TypeND(AbstractFloat,[2])` (nM, 3), rotation axes in 3D, assumed unitary;
- `Φ::TypeND(AbstractFloat,[1])` (nM,), rotation angles;
- `V::TypeND(AbstractFloat,[2,3])` (nM, 3, (3)), vectors to be rotated;
- `R::TypeND(AbstractFloat,[2,3])` (nM, 3, (3)), vectors rotated, i.e., results;
*OUTPUTS*:
- `R` the input container `R` is also returned for convenience.
"""
@inline function UΦRot!(U::TypeND(AbstractFloat,[2]),
                        Φ::TypeND(AbstractFloat,[1]),
                        V::TypeND(AbstractFloat,[2,3]),
                        R::TypeND(AbstractFloat,[2,3]))
  # en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_and_angle
  # 𝑅 = 𝑐𝑜𝑠𝜃⋅𝐼 - (𝑐𝑜𝑠𝜃-1)⋅(𝐮𝐮ᵀ) + 𝑠𝑖𝑛𝜃⋅[𝐮]ₓ; 𝜃/𝐮, rotation angle/axis
  cΦ, sΦ = cos.(Φ), sin.(Φ)
  (Vx,Vy,Vz) = map(x->size(V,3)==1 ? view(V,:,[x]) : view(V,:,[x],:), (1,2,3))
  (Ux,Uy,Uz) = map(x->view(U,:,x), (1,2,3))

  R .= cΦ.*V .+ (1 .- cΦ).*sum(U.*V,dims=2).*U .+
       sΦ.*hcat(-Uz.*Vy.+Uy.*Vz, Uz.*Vx.-Ux.*Vz, -Uy.*Vx.+Ux.*Vy)
  return R
end

"""
    UΦRot(U, Φ, V)
Same as `UΦRot!(U, Φ, V, R)`, except not in-place.
"""
@inline UΦRot(U, Φ, V) = UΦRot!(U, Φ, V, copy(V))

#= 𝐴, 𝐵 =#
export B2AB
"""
    B2AB(B; T1, T2, γ, dt)
Turn B-effective into Hargreave's 𝐴/𝐵, mat/vec, see: doi:10.1002/mrm.1170.

*INPUTS*:
- `B::Union{TypeND(B0D, [2,3]), Base.Generator}`:
  Global, (nT,xyz); Spin-wise, (nM,xyz,nT).
*KEYWORDS*:
- `T1 & T2 ::TypeND(T0D, [0,1])`: Global, (1,); Spin-wise, (nM,1).
- `γ::TypeND(Γ0D, [0,1])`: Global, (1,); Spin-wise, (nM, 1). gyro ratio
- `dt::T0D` (1,), simulation temporal step size, i.e., dwell time.
*OUTPUTS*:
- `A::TypeND(AbstractFloat,[3])` (nM, 3,3), `A[iM,:,:]` is the `iM`-th 𝐴.
- `B::TypeND(AbstractFloat,[2])` (nM, 3), `B[iM,:]` is the `iM`-th 𝐵.
"""
function B2AB(B ::Base.Generator;
              T1::TypeND(T0D, [0,1])=(Inf)u"s",
              T2::TypeND(T0D, [0,1])=(Inf)u"s",
              γ ::TypeND(Γ0D, [0,1])=γ¹H,
              dt::T0D=(4e-6)u"s")

  nM = maximum([size(x,1) for x in (T1,T2,γ,first(B))])
  AB = reshape([ones(nM) zeros(nM,3) ones(nM) zeros(nM,3) ones(nM) zeros(nM,3)],
               (nM,3,4)) # as if cat(A,B;dims=3), avoid constructing U, Φ twice.
  AB1 = similar(AB)

  # in unit, convert relaxations into losses/recovery per step
  E1 = exp.(-dt./T1) |> x->isa(x[1], Real) ? x : uconvert.(NoUnits, x)
  E2 = exp.(-dt./T2) |> x->isa(x[1], Real) ? x : uconvert.(NoUnits, x)
  E1₋₁ = E1 .- 1

  # u, ϕ = Array{Float64}(undef, nM, 3), Array{Float64}(undef, nM, 1)

  for b in B
    u, ϕ = B2UΦ(b; γ=γ, dt=dt)
    # B2UΦ!(b, u, ϕ; γ=γ, dt=dt)
    any(ϕ.!=0) && @inbounds(UΦRot!(u, view(ϕ,:,1), AB, AB1))
    AB1[:,1:2,:] .*= E2
    AB1[:,3,:]   .*= E1
    AB1[:,3,4]   .-= E1₋₁
    AB, AB1 = AB1, AB
  end

  return (A=AB[:,:,1:3], B=AB[:,:,4]) # Can one avoid the array copies here?
end

function B2AB(B ::TypeND(B0D, [2,3]); kw...)
  if size(B,3) == 1 && size(B,1) != size(M,1)
    B = permutedims(B[:,:,:], [3,2,1])  # best practice?
    println("B not being spin-specific, assuming global")
  end
  return B2AB(@inbounds(view(B,:,:,t) for t in axes(B,3)); kw...)
end

#= blochSim =#
export blochSim!, blochSim
"""
    blochSim!(M, B; T1, T2, γ, dt, doHist)
Old school 𝐵-effective magnetic field, `B`, based bloch simulation. Globally or
spin-wisely apply `B` over spins, `M`. `M` will be updated by the results.

*INPUTS*:
- `M::TypeND(Real, [2])` (nM, xyz): input spins' magnetizations.
- `B::Union{TypeND(B0D, [2,3]), Base.Generator}`:
  Global, (nT,xyz); Spin-wise, (nM,xyz,nT).
*KEYWORDS*:
- `T1 & T2 ::TypeND(T0D, [0,1])`: Global, (1,); Spin-wise, (nM,1).
- `γ::TypeND(Γ0D, [0,1])`: Global, (1,); Spin-wise, (nM, 1). gyro ratio
- `dt::T0D` (1,), simulation temporal step size, i.e., dwell time.
- `doHist::Bool`, whether to output spin history through out `B`.
*OUTPUTS*:
- `M::TypeND(Real, [2])` (nM, xyz): spins after applying `B`.
- `Mhst::TypeND(Real, [3])` (nM, xyz, nT): spins history during `B`.

# Notes:
1. Not much sanity check inside this function, user is responsible for
   matching up the dimensions.
2. Put relax at the end of each time step may still be inaccurate, since
   physically spins relax continuously, this noise/nuance may worth study
   for applications like fingerprinting simulations, etc.
"""
function blochSim!(M ::TypeND(AbstractFloat, [2]),
                   B ::Base.Generator;
                   T1::TypeND(T0D, [0,1])=(Inf)u"s",
                   T2::TypeND(T0D, [0,1])=(Inf)u"s",
                   γ ::TypeND(Γ0D, [0,1])=γ¹H,
                   dt::T0D=(4e-6)u"s", doHist=false)

  # in unit, convert relaxations into losses/recovery per step
  E1 = exp.(-dt./T1) |> x->isa(x[1], Real) ? x : uconvert.(NoUnits, x)
  E2 = exp.(-dt./T2) |> x->isa(x[1], Real) ? x : uconvert.(NoUnits, x)
  E1₋₁ = E1 .- 1

  nM = maximum([size(x,1) for x in (T1,T2,γ,first(B))])
  size(M,1) == 1 && (M = repeat(M, nM))

  Mhst = doHist ? zeros(size(M,1), 3, length(B)) : nothing
  Mi, M1 = M, similar(M) # Mi refers to the original array `M` in memory.

  # u, ϕ = Array{Float64}(undef, nM, 3), Array{Float64}(undef, nM, 1)

  if doHist
    for (t, b) in enumerate(B)
      u, ϕ = B2UΦ(b; γ=γ, dt=dt)
      # B2UΦ!(b, u, ϕ; γ=γ, dt=dt)
      any(ϕ.!=0) && @inbounds(UΦRot!(u, view(ϕ,:,1), M, M1))
      # relaxation
      M1[:,1:2] .*= E2
      M1[:,3]   .*= E1
      M1[:,3]   .-= E1₋₁
      @inbounds(Mhst[:,:,t] = M1)
      M, M1 = M1, M
    end
  else
    for b in B
      u, ϕ = B2UΦ(b; γ=γ, dt=dt)
      # B2UΦ!(b, u, ϕ; γ=γ, dt=dt)
      any(ϕ.!=0) && @inbounds(UΦRot!(u, view(ϕ,:,1), M, M1))
      # relaxation
      M1[:,1:2] .*= E2
      M1[:,3]   .*= E1
      M1[:,3]   .-= E1₋₁
      M, M1 = M1, M
    end
  end
  M === Mi || (Mi .= M) # if `M` doesn't point to the input array, update.

  return (M=M, Mhst=Mhst)
end

function blochSim!(M::TypeND(AbstractFloat, [2]), B::TypeND(B0D, [2,3]); kw...)
  if size(B,3) == 1 && size(B,1) != size(M,1)
    B = permutedims(B[:,:,:], [3,2,1])  # best practice?
    println("B not being spin-specific, assuming global")
  end
  return blochSim!(M, @inbounds(view(B,:,:,t) for t in axes(B,3)); kw...)
end

"""
    blochSim!(M, A, B)
Hargreave's 𝐴/𝐵, mat/vec, based bloch simulation. Globally or spin-wisely apply
matrix `A` and vector `B` over spins, `M`, described in doi:10.1002/mrm.1170

*INPUTS*:
- `M::TypeND(Real, [2])` (nM, xyz): input spins' magnetizations.
- `A::TypeND(AbstractFloat,[3])` (nM, 3,3), `A[iM,:,:]` is the `iM`-th 𝐴.
- `B::TypeND(AbstractFloat,[2])` (nM, 3), `B[iM,:]` is the `iM`-th 𝐵.
*OUTPUTS*:
- `M::TypeND(Real, [2])` (nM, xyz): spins after applying `B`.
"""
blochSim!(M, A, B) = M .= blochSim(M, A, B)

"""
    blochSim(M, B; T1, T2, γ, dt, doHist)
Same as `blochSim!(M, B; T1,T2,γ,dt,doHist)`, `M` will not be updated.
"""
blochSim(M, B; kw...) = blochSim!(copy(M), B; kw...)

"""
    blochSim(M, A, B)
Same as `blochSim(M, A, B)`, `M` will not be updated.
"""
blochSim(M::TypeND(AbstractFloat,[2]),
         A::TypeND(AbstractFloat,[3]),
         B::TypeND(AbstractFloat,[2])) =
  sum(A.*permutedims(M[:,:,:],(1,3,2));dims=3) .+ B

# No inplace operation for `M::TypeND(Integer,[2])`.
blochSim(M::TypeND(Integer,[2]), a...; kw...) = blochSim(float(M), a...; kw...)

#= freePrec =#
export freePrec!, freePrec
"""
    freePrec!(M, t; Δf, T1, T2)
Spins, `M`, free precess by time `t`. `M` will be updated by the results.

*INPUTS*:
- `M::TypeND(Real, [2])` (nM, xyz): input spins' magnetizations.
- `t::T0D` (1,): duration of free precession.
*KEYWORDS*:
- `T1 & T2 ::TypeND(T0D, [0,1])`: Global, (1,); Spin-wise, (nM,1).
*OUTPUTS*:
- `M::TypeND(Real, [2])` (nM, xyz): output spins' magnetizations.
"""
function freePrec!(M ::TypeND(AbstractFloat,[2]),
                   t ::T0D;
                   Δf::TypeND(F0D,[0,1])=0u"Hz",
                   T1::TypeND(T0D,[0,1])=(Inf)u"s",
                   T2::TypeND(T0D,[0,1])=(Inf)u"s")

  E1 = exp.(-t./T1) |> x->isa(x[1], Real) ? x : uconvert.(NoUnits, x)
  E2 = exp.(-t./T2) |> x->isa(x[1], Real) ? x : uconvert.(NoUnits, x)

  M[:,1:2] .*= E2
  M[:,3]   .*= E1
  M[:,3]   .+= 1 .- E1

  eΔθ = exp.(-1im*2π*Δf*t) |> x->isa(x[1], Complex) ? x : uconvert.(NoUnits, x)

  M[:,1:2] .= ((view(M,:,1)+1im*view(M,:,2)).*eΔθ |> x->[real(x) imag(x)])

  return M
end

"""
    freePrec(M, t; Δf, T1, T2)
Same as `freePrec!(M, t; Δf, T1, T2)`, `M` will not be updated.
"""
freePrec(M, t; kw...) = freePrec!(copy(M), t; kw...)

