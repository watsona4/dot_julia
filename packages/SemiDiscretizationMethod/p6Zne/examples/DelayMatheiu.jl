using SemiDiscretizationMethod

function createMathieuProblem(δ,ε,b0,a1;T=2π)
    AMx =  ProportionalMX(t->@SMatrix [0. 1.; -δ-ε*cos(2π/T*t) -a1]);
    τ1=2π # if function is needed, the use τ1 = t->foo(t)
    BMx1 = DelayMX(τ1,t->@SMatrix [0. 0.; b0 0.]);
    cVec = Additive(t->@SVector [0.,sin(4π/T*t)])
    LDDEProblem(AMx,[BMx1],cVec)
end;

τmax=2π # the largest τ of the system
T=2π #Principle period of the system (sin(t)=sin(t+P)) 
mathieu_lddep=createMathieuProblem(3.,2.,-0.15,0.1,T=T); # LDDE problem for Hayes equation
method=SemiDiscretization(1,0.01) # 3rd order semi discretization with Δt=0.1
# if P = τmax, then n_steps is automatically calculated
mapping=DiscreteMapping_1step(mathieu_lddep,method,τmax,
    n_steps=Int((T+100eps(T))÷method.Δt),calculate_additive=true); #The discrete mapping of the system

@show spectralRadiusOfMapping(mapping); # spectral radius ρ of the mapping matrix (ρ>1 unstable, ρ<1 stable)
fp=fixPointOfMapping(mapping); # stationary solution of the hayes equation (equilibrium position)


plot(0.0:method.Δt:P,fp[1:2:end],
    xlabel=L"-s",title=L"t \in [nP,(n+1)P],\quad n \to \infty",guidefontsize=14,linewidth=3,
    label=L"x(t-s)",legendfontsize=11,tickfont = font(10))

plot!(0.0:method.Δt:P,fp[2:2:end],
    xlabel=L"-s",linewidth=3,
    label=L"\dot{x}(t-s)")

plot!(0.0:method.Δt:P,sin.(2*(0.0:method.Δt:P)),linewidth=3,label=L"\sin(2t)")







using MDBM

using Plots
gr();
using LaTeXStrings

a1=0.1;
ε=1;
τmax=2π;
T=1π;
method=SemiDiscretization(2,T/40);

foo(δ,b0) = log(spectralRadiusOfMapping(DiscreteMapping_1step(createMathieuProblem(δ,ε,b0,a1,T=T),method,τmax,
    n_steps=Int((T+100eps(T))÷method.Δt)))); # No additive term calculated

axis=[Axis(-1:0.2:5.,:δ),
    Axis(-2:0.2:1.5,:b0)]

iteration=3;
stab_border_points=getinterpolatedsolution(solve!(MDBM_Problem(foo,axis),iteration));

scatter(stab_border_points...,xlim=(-1.,5),ylim=(-2.,1.5),
    label="",title="Stability border of the delay Mathieu equation",xlabel=L"\delta",ylabel=L"b_0",
    guidefontsize=14,tickfont = font(10),markersize=2,markerstrokewidth=0)


