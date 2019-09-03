using PyRhodium
using Roots
using Distributions
using DataFrames
using Random

function lake_problem(;pollution_limit=nothing,
         b = 0.42,       # decay rate for P in lake (0.42 = irreversible)
         q = 2.0,        # recycling exponent
         μ = 0.02,       # mean of natural inflows
         σ = 0.001,      # standard deviation of natural inflows
         α = 0.4,        # utility from pollution
         δ = 0.98,       # future utility discount rate
         nsamples = 100) # monte carlo sampling of natural inflows)

    Pcrit = fzero(x -> x^q/(1+x^q) - b*x, 0.01, 1.5)
    nvars = length(pollution_limit)
    X = zeros(nvars)
    average_daily_P = zeros(nvars)
    reliability = 0.0

    d = LogNormal(log(μ^2 / sqrt(σ^2 + μ^2)),sqrt(log(1.0 + σ^2 / μ^2)))
    
    natural_inflows = zeros(nvars)
    
    for i in 1:nsamples
        X[1] = 0.0        
        
        rand!(d, natural_inflows)
        
        for t in 2:nvars
            X[t] = (1-b)*X[t-1] + X[t-1]^q/(1+X[t-1]^q) + pollution_limit[t] + natural_inflows[t]
            average_daily_P[t] += X[t]/nsamples
        end
    
        reliability += sum(X .< Pcrit)/(nsamples*nvars)
    end
      
    max_P = maximum(average_daily_P)
    utility = sum(α.*pollution_limit.*δ.^collect(1:nvars))
    intertia = sum(diff(pollution_limit) .> -0.02)/(nvars-1)
    
    return max_P, utility, intertia, reliability
end

m = Model(lake_problem)

set_parameters!(m, [Parameter("pollution_limit"),
                    Parameter("b"),
                    Parameter("q"),
                    Parameter("mean"),
                    Parameter("stdev"),
                    Parameter("delta")])

set_responses!(m, [Response("max_P", :MINIMIZE),
                   Response("utility", :MAXIMIZE),
                   Response("inertia", :MAXIMIZE),
                   Response("reliability", :MAXIMIZE)])

set_levers!(m, [RealLever("pollution_limit", 0.0, 0.1, length=100)])

#output = optimize(m, "NSGAII", 1000)
output = optimize(m, "NSGAII", 100)

println("Found $(length(output)) optimal policies!")

# fig = scatter2d(output)

policy = output[5]
policy = findmax(output, :reliability)
policies = find(output, "utility > 0.5");

policy = named_tuple(findmax(output, :reliability))

println("Max Phosphorus in Lake: ", policy.max_P)
println("Utility:                ", policy.utility)
println("Inertia:                ", policy.inertia)
println("Reliability:            ", policy.reliability)

df = DataFrame(output)
arr = collect(output);
