using Test
using CMPFit

## testlinfit
x = [-1.7237128E+00,1.8712276E+00,-9.6608055E-01,
     -2.8394297E-01,1.3416969E+00,1.3757038E+00,
     -1.3703436E+00,4.2581975E-02,-1.4970151E-01,
     8.2065094E-01]

y = [1.9000429E-01,6.5807428E+00,1.4582725E+00,
     2.7270851E+00,5.5969253E+00,5.6249280E+00,
     0.787615,3.2599759E+00,2.9771762E+00,
     4.5936475E+00]

e = fill(0., size(y)) .+ 0.07
param = [1., 1.]

function linfunc(x::Vector{Float64}, p::Vector{Float64})
    return @. p[1] + p[2]*x
end

res = cmpfit(x, y, e, linfunc, param)

@test res.bestnorm ≈ 2.756285  rtol=1.e-5
@test res.status   == 1
@test res.npar     == 2
@test res.nfree    == 2
@test res.npegged  == 0
@test res.dof      == 8

zero = res.perror .- [0.0222102, 0.018938];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5

zero = res.param .- [3.209966, 1.770954];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5


## testquadfit
x = [-1.7237128E+00,1.8712276E+00,-9.6608055E-01,
	 -2.8394297E-01,1.3416969E+00,1.3757038E+00,
	 -1.3703436E+00,4.2581975E-02,-1.4970151E-01,
	 8.2065094E-01]
y = [2.3095947E+01,2.6449392E+01,1.0204468E+01,
	 5.40507,1.5787588E+01,1.6520903E+01,
	 1.5971818E+01,4.7668524E+00,4.9337711E+00,
	 8.7348375E+00]

e = fill(0., size(y)) .+ 0.2
param = [1., 1., 1.]

function quadfunc(x::Vector{Float64}, p::Vector{Float64})
    return @. p[1] + p[2]*x + p[3]*(x*x)
end

res = cmpfit(x, y, e, quadfunc, param)

@test res.bestnorm ≈ 5.679323  rtol=1.e-5
@test res.status   == 1
@test res.npar     == 3
@test res.nfree    == 3
@test res.npegged  == 0
@test res.dof      == 7

zero = res.perror .- [0.097512, 0.054802, 0.054433];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5

zero = res.param .- [4.703829, 0.062586, 6.163087];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5


## testquadfix
param = [1., 0., 1.]
pinfo = CMPFit.Parinfo(length(param))
pinfo[2].fixed = 1

res = cmpfit(x, y, e, quadfunc, param, parinfo=pinfo)

@test res.bestnorm ≈ 6.983588  rtol=1.e-5
@test res.status   == 1
@test res.npar     == 3
@test res.nfree    == 2
@test res.npegged  == 0
@test res.dof      == 8

zero = res.perror .- [0.097286, 0., 0.053743];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5

zero = res.param .- [4.696254, 0., 6.172954];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5


## testgaussfit
x = [-1.7237128E+00,1.8712276E+00,-9.6608055E-01,
	 -2.8394297E-01,1.3416969E+00,1.3757038E+00,
	 -1.3703436E+00,4.2581975E-02,-1.4970151E-01,
	 8.2065094E-01]
y = [-4.4494256E-02,8.7324673E-01,7.4443483E-01,
	 4.7631559E+00,1.7187297E-01,1.1639182E-01,
	 1.5646480E+00,5.2322268E+00,4.2543168E+00,
	 6.2792623E-01]

e = fill(0., size(y)) .+ 0.5
param = [0.0, 1.0, 1.0, 1.0]

function gaussfunc(x::Vector{Float64}, p::Vector{Float64})    
    sig2 = p[4] * p[4];
    xc = @. x - p[3];
    return @. p[2] * exp(-0.5 * xc *xc / sig2) + p[1]
end

res = cmpfit(x, y, e, gaussfunc, param)

@test res.bestnorm ≈ 10.350032  rtol=1.e-5
@test res.status   == 1
@test res.npar     == 4
@test res.nfree    == 4
@test res.npegged  == 0
@test res.dof      == 6

zero = res.perror .- [0.232234, 0.395434, 0.074715, 0.089997];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5

zero = res.param .- [0.480441, 4.550754, -0.062562, 0.397473];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5


## testgaussfix
param = [0.0, 1.0, 0.0, 0.1]
pinfo = CMPFit.Parinfo(length(param))
pinfo[1].fixed = 1
pinfo[3].fixed = 1

res = cmpfit(x, y, e, gaussfunc, param, parinfo=pinfo)

@test res.bestnorm ≈ 15.516134  rtol=1.e-5
@test res.status   == 1
@test res.npar     == 4
@test res.nfree    == 2
@test res.npegged  == 0
@test res.dof      == 8

zero = res.perror .- [0., 0.329307, 0., 0.053804];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5

zero = res.param .- [0., 5.059244, 0., 0.479746];
@test minimum(zero) ≈ 0 atol=1.e-5
@test maximum(zero) ≈ 0 atol=1.e-5

