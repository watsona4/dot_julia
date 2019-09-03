using SemiDiscretizationMethod
using Test

function createHayesProblem(a,b)
    AMx =  ProportionalMX(a*ones(1,1));
    τ1=1. 
    BMx1 = DelayMX(τ1,b*ones(1,1));
    cVec = Additive(ones(1))
    LDDEProblem(AMx,[BMx1],cVec)
end

function createMathieuProblem(δ,ε,b0,a1;T=2π)
    AMx =  ProportionalMX(t->@SMatrix [0. 1.; -δ-ε*cos(2π/T*t) -a1]);
    τ1=2π # if function is needed, the use τ1 = t->foo(t)
    BMx1 = DelayMX(τ1,t->@SMatrix [0. 0.; b0 0.]);
    cVec = Additive(t->@SVector [0.,sin(4π/T*t)])
    LDDEProblem(AMx,[BMx1],cVec)
end

function tests()
    @testset "Testing the SemiDiscretizationMethod package with the examples" begin
		#Hayes
        @test begin
            hayes_lddep=createHayesProblem(-1.,-1.); # LDDE problem for Hayes equation
			method=SemiDiscretization(1,0.1) # 3rd order semi discretization with Δt=0.1
			τmax=1. # the largest τ of the system
			mapping=DiscreteMapping(hayes_lddep,method,τmax,n_steps=1,calculate_additive=true); #The discrete mapping of the system
			spectralRadiusOfMapping(mapping)
			fixPointOfMapping(mapping)
            true
        end
		#Delay Mathieu
        @test begin
            τmax=2π # the largest τ of the system
			T=2π #Principle period of the system (sin(t)=sin(t+P)) 
			mathieu_lddep=createMathieuProblem(3.,2.,-0.15,0.1,T=T); # LDDE problem for Hayes equation
			method=SemiDiscretization(1,0.01) # 3rd order semi discretization with Δt=0.1
			# if P = τmax, then n_steps is automatically calculated
			mapping=DiscreteMapping(mathieu_lddep,method,τmax,
		    n_steps=Int((T+100eps(T))÷method.Δt),calculate_additive=true); #The discrete mapping of the system

			spectralRadiusOfMapping(mapping); # spectral radius ρ of the mapping matrix (ρ>1 unstable, ρ<1 stable)
			# spectralRadiusOfMapping(mapping) = 0.5131596340374617
			fp=fixPointOfMapping(mapping); # stationary solution of the hayes equation (equilibrium position)
			true
        end
    end
end
tests()