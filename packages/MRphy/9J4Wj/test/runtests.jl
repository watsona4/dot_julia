using Test
using Unitful, UnitfulMR

using MRphy

@time begin

@testset "utils tests" for _ = [1]
  dim, k = (2,2), [1,2,3,4,0]u"cm^-1"
  gT, gR = k2g(k, true), k2g(k, false)
  @test CartesianLocations(dim) ==
        CartesianLocations(dim,false) .- collect(Tuple(ctrSub(dim)))' ==
        [-1 -1; 0 -1; -1 0; 0 0];
  @test ctrSub((1,2,3,4,5,6)) == CartesianIndex(1,2,2,3,3,4)
  @test ctrInd.([(3,4), (4,3)]) == [8, 7] # center index of fftshift
  @test g2k(gT, true) ≈ k && k2g(k, false) ≈ gR # `≈` in case of numeric errors
  @test g2s(gT, dt=1u"s") ≈ [gT[1]; diff(gT, dims=1)]/1u"s"
end

#= Core Features Tests =#
M0, nt = [1. 0. 0.; 0. 1. 0.; 0. 0. 1.], 512
nM_spa, t = size(M0,1), 0:nt-1
fov = Quantity.((3,3,1), u"cm")
γ = γ¹H
γ_unitless = ustrip(Float64, u"Hz/Gauss",γ)

rf = (10*(cos.(t/nt*2π) + sin.(t/nt*2π)im))u"Gauss"
gr = [ones(nt) zeros(nt) (10*atan.(t.-round(nt/2))/π)]u"Gauss/cm"
dt, des = 4e-6u"s", "test pulse"

p    = Pulse(rf; dt=dt, des=des)
p.gr = gr; # split here to hit `setproperty!` for coverage
spa  = mSpinArray(trues((nM_spa,1)); γ=γ, M=M0)
cube = mSpinCube(trues((3,3,1)), fov)

@testset "mObjects tests" for _ = [1] # setting _ = [1] shuts down this testset

  @testset "`AbstractPulse` constructor" for _ = [1]
    @test isequal(p, Pulse(p.rf, p.gr; dt=dt,des=des))
    @test p != Pulse(p.rf, p.gr; dt=dt,des=des)
  end

  @testset "`AbstractSpinArray` constructor" for _ = [1]
    @test isequal(spa, mSpinArray(spa.mask; M=spa.M))
    @test isequal(spa, mSpinArray(size(spa); M=spa.M))
  end

  @testset "`AbstractSpnCube` constructor" for _ = [1]
    @test isequal(cube, mSpinCube(cube.mask, fov))
    @test isequal(cube, mSpinCube(cube.dim, fov))
  end

end

spa.T1, spa.T2 = 1u"s", 4e-2u"s"

b1Map = 1

loc_x = collect(range(-1., 1.; length=nM_spa))u"cm"
loc_y, loc_z = zeros(3)u"cm", ones(3)u"cm"

loc = [loc_x loc_y loc_z]

Δf = -(ustrip.(loc_x))u"Hz" .* γ_unitless # w/ gr_x==1u"Gauss/cm", cancels Δf
t_fp = (1/4/γ_unitless)u"s"

@testset "blochSim tests" for _ = [1] # setting _ = [] shuts down this testset
  Mo, _ = applyPulse(spa, p, loc; Δf=Δf, b1Map=b1Map, doHist=false)

  Beff = cat(Pulse2B(p, loc; Δf=Δf, b1Map=b1Map, γ=spa.γ)...; dims=3)
  @test Beff == cat(rfgr2B(p.rf, p.gr, loc; Δf=Δf, b1Map=b1Map, γ=spa.γ)...;
                    dims=3)

  A, B = B2AB(Beff; T1=spa.T1, T2=spa.T2, γ=spa.γ, dt=p.dt)

  _, Mhst = blochSim(M0,Beff; T1=spa.T1,T2=spa.T2,γ=spa.γ,dt=p.dt,doHist=true);
  X = copy(M0)
  blochSim!(X, Beff; T1=spa.T1,T2=spa.T2,γ=spa.γ,dt=p.dt,doHist=true);

  MoAB = blochSim(M0, A, B)

  @test Mo ≈ Mhst[:,:,end] ≈ MoAB ≈ X ≈
        [ 0.559535641648385  0.663342640621335  0.416341441715101;
          0.391994737048090  0.210182892388552 -0.860954821972489;
         -0.677062008711222  0.673391604920576 -0.143262993311057]

  E1, E2, eΔθ = exp.(-t_fp./spa.T1), exp.(-t_fp./spa.T2), exp.(-1im*2π*Δf*t_fp)
  M0f = copy(M0)
  M0f[:,1:2] .*= E2
  M0f[:,3]   .*= E1
  M0f[:,3]   .+= (1-E1)

  M0f[:,1:2] .= eΔθ.*(M0f[:,1]+1im*M0f[:,2]) |> x->[real(x) imag(x)]

  @test freePrec(spa, t_fp; Δf=Δf) ≈ M0f

end

end

