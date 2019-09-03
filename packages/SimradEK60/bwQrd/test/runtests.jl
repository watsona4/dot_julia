#!/usr/bin/env julia

using SimradEK60
using SimradEK60TestData
using Test

# Basic tests

@test octet2deg(-128) == -180

@test power2db(25.6f0) == log10(2f0)

# SONAR equation for EK60

α = 0.009841439f0
Pt = 1000.0f0
c = 1448.2969f0
G = 25.92f0


λ = 0.038113076f0

Ψ = -20.7f0
τ = 0.001024f0
Pr = -111.22823f0
_R = [18.1677435f0]
Sa = -0.49f0

_Sv = Sv(Pr,  λ, G, Ψ, c, α, Pt, τ, Sa,
       _R)

@test typeof(_Sv[1]) == Float32
@test _Sv[1] ≈ -94.1832

# All pings

ps =collect(pings(EK60_SAMPLE));
@test length(ps) == 1716

# 38 kHz pings

ps38 = [p for p in ps if p.frequency == 38000];

@test length(ps38) == 572

# 70 kHz pings

ps70 = [p for p in ps if p.frequency == 70000];

@test length(ps70) == 0

# 120 kHz pings

ps120 = [p for p in ps if p.frequency == 120000];

@test length(ps120) == 572

# 200 kHz pings

ps200 = [p for p in ps if p.frequency == 200000];

@test length(ps200) == 572

# 38 kHz volume backscatter

Sv38 = Sv(ps38);

m, n = size(Sv38)
@test m == 3782
@test n == 572

@test typeof(Sv38[1,1]) == Float32

# Power

p38 = power(ps38)
m, n = size(p38)
@test m == 3782
@test n == 572
@test typeof(p38[1,1]) == Int16

pdb38 = powerdb(ps38)
m, n = size(pdb38)
@test m == 3782
@test n == 572

@test typeof(pdb38[1,1]) == Float32

pdb120 = powerdb(ps120)
pdb200 = powerdb(ps200)

# Volume backscatter

Sv120 = Sv(ps120)
Sv200 = Sv(ps200)

m, n = size(Sv200)
@test m == 3782
@test n == 572

# Athwartships

at38 = athwartshipangle(ps38);
at120 = athwartshipangle(ps120);
at200 = athwartshipangle(ps200);

m, n = size(at38)
@test m == 3782
@test n == 572

# Alongships

al38 = alongshipangle(ps38);
al120 = alongshipangle(ps120);
al200 = alongshipangle(ps200);

m, n = size(al38)
@test m == 3782
@test n == 572

# Range

_R = R(ps38[1])
@test typeof(_R[1]) == Float32
@test _R[1] == 0
@test _R[end] == 699.4475f0
_R = R(ps38)
@test _R[1] == 0
@test _R[end] == 699.4475f0



function rmse(A, B)
    a = A .- B
    a = a.^2
    return sqrt(maximum(a))
end

function compare(A, B)
    x = rmse(A, B)
    x < 1e-4
end


function load_echoview_matrix(filename)

    # This is a crappy but fast CSV reader. I tried CSV.jl but it
    # segfaults. I tried CSVFiles but it takes (literally) minutes to
    # run.
    
    a = []
    open(filename) do file
        for ln in eachline(file)
            s = split(ln, ",")
            s = s[14:end]
            s = map(x->parse(Float64,x), s)
            push!(a,s)
        end
    end

    hcat(a[2:end]...)
    
end


filename = joinpath(EK60_DATA, "JR230-D20091215-T121917.raw")

ps = collect(pings(filename))
ps38 = [p for p in ps if p.frequency == 38000]
ps120 = [p for p in ps if p.frequency == 120000]
ps200 = [p for p in ps if p.frequency == 200000]

# N.B. Echoview drops the first sample, so we'll do the same for
# comparison purposes.

Sv38 = Sv(ps38)[2:end,:]
Sv120 = Sv(ps120)[2:end,:]
Sv200 = Sv(ps200)[2:end,:]

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-38-uncal.sv.csv")
A = load_echoview_matrix(filename)

@test compare(A, Sv38)

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-120-uncal.sv.csv")
A = load_echoview_matrix(filename)
@test compare(A, Sv120)


filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-200-uncal.sv.csv")
A = load_echoview_matrix(filename)
@test compare(A, Sv200)

TS38 = TS(ps38)[2:end,:]
TS120 = TS(ps120)[2:end,:]
TS200 = TS(ps200)[2:end,:]

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-38-uncal.ts.csv")
A = load_echoview_matrix(filename)
@test compare(A, TS38)

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-120-uncal.ts.csv")
A = load_echoview_matrix(filename)
@test compare(A, TS120)

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-200-uncal.ts.csv")
A = load_echoview_matrix(filename)
@test compare(A, TS200)

# Calibration values from JR230.ecs Beware that Echoview
# measures pulse length in mS not seconds!

Sv38cal = Sv(ps38;
             frequency=38000,
             gain=25.9400,
             equivalentbeamangle=-20.700001,
             soundvelocity=1462.0,
             absorptioncoefficient=0.001014,
             transmitpower=2000.00000,
             pulselength=0.001024,
             sacorrection=0.12)[2:end,:]

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-38-cal.sv.csv")
A = load_echoview_matrix(filename)
@test compare(A, Sv38cal)

Sv120cal = Sv(ps120;
              frequency=120000,
              gain=21.950,
              equivalentbeamangle=-20.700001,
              soundvelocity=1462.0,
              absorptioncoefficient=0.02683,
              transmitpower=500.00000,
              pulselength=0.001024,
              sacorrection=-0.05)[2:end,:]

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-120-cal.sv.csv")
A = load_echoview_matrix(filename)
@test compare(A, Sv120cal)

Sv200cal = Sv(ps200;
              frequency=200000,
              gain=23.9900,
              equivalentbeamangle=-19.600000,
              soundvelocity=1462.0,
              absorptioncoefficient=0.04023,
              transmitpower=300.00000,
              pulselength=0.001024,
              sacorrection=0.080)[2:end,:]

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-200-cal.sv.csv")
A = load_echoview_matrix(filename)
@test compare(A, Sv200cal)

TS38cal = TS(ps38;
             frequency=38000,
             gain=25.9400,
             soundvelocity=1462.0,
             absorptioncoefficient=0.001014,
             transmitpower=2000.000002)[2:end,:]

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-38-cal.ts.csv")
A = load_echoview_matrix(filename)
@test compare(A, TS38cal)

TS120cal = TS(ps120;
              frequency=120000,
              gain=21.950,
              soundvelocity=1462.0,
              absorptioncoefficient=0.02683,
              transmitpower=500.00000)[2:end,:]

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-120-cal.ts.csv")
A = load_echoview_matrix(filename)
@test compare(A, TS120cal)

TS200cal = TS(ps200;
              frequency=200000,
              gain=23.9900,
              soundvelocity=1462.0,
              absorptioncoefficient=0.04023,
              transmitpower=300.00000)[2:end,:]

filename = joinpath(EK60_DATA, "JR230-D20091215-T121917-200-cal.ts.csv")
A = load_echoview_matrix(filename)
@test compare(A, TS200cal)

# Test range for unequal ping lengths

filename = joinpath(EK60_DATA, "JR245-D20110116-T182142.raw")

ps = pings(filename) # Get the pings
ps38 = [p for p in ps if p.frequency == 38000] # Just 38 kHz pings

m, n = size(R(ps38))
@test m == 5355 # not 5100 !
@test n == 412


#


