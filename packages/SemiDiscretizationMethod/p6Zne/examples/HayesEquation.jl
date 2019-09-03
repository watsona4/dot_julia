using SemiDiscretizationMethod

function createHayesProblem(a,b)
    AMx =  ProportionalMX(a*ones(1,1));
    τ1=1. 
    BMx1 = DelayMX(τ1,b*ones(1,1));
    cVec = Additive(ones(1))
    LDDEProblem(AMx,[BMx1],cVec)
end

hayes_lddep=createHayesProblem(-1.,-1.); # LDDE problem for Hayes equation
method=SemiDiscretization(1,0.1) # 3rd order semi discretization with Δt=0.1
τmax=1. # the largest τ of the system
mapping=DiscreteMapping_1step(hayes_lddep,method,τmax,n_steps=1,calculate_additive=true); #The discrete mapping of the system

@show spectralRadiusOfMapping(mapping); # spectral radius ρ of the mapping matrix (ρ>1 unstable, ρ<1 stable)
@show fixPointOfMapping(mapping); # stationary solution of the hayes equation (equilibrium position)








using MDBM

using Plots
gr();
using LaTeXStrings

method=SemiDiscretization(4,0.1);
τmax=1.

foo(a,b) = log(spectralRadiusOfMapping(DiscreteMapping_1step(createHayesProblem(a,b),method,τmax,
    n_steps=1))); # No additive term calculated

axis=[Axis(-15.0:15.,:a),
    Axis(-15.0:15.,:b)]

iteration=3;
stab_border_points=getinterpolatedsolution(solve!(MDBM_Problem(foo,axis),iteration));

scatter(stab_border_points...,xlim=(-15.,15.),ylim=(-15.,15.),
    label="",title="Stability border of the Hayes equation",xlabel=L"a",ylabel=L"b",
    guidefontsize=14,tickfont = font(10),markersize=2,markerstrokewidth=0)
