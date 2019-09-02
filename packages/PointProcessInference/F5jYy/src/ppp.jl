
inference(data_choice::AbstractString) = inference(loadexample(data_choice)[1:2]...)


################ Generate or read data
function inference(observations;
    title = "Poisson process", # optional caption for mcmc run
    summaryfile = nothing, # path to summaryfile or nothing
    T0 = 0.0, # start time
    T = maximum(observations), # end time
    n = 1, # number of aggregated samples in `observations`
    N = min(length(observations)÷4, 50), # number of bins
    samples = 1:1:30000, # (sub-)samples to save
    α1 = 0.1, β1 = 0.1, # parameters for Gamma Markov chain
    Π = Exponential(10), # prior on alpha
    τ = 0.7, # Set scale for random walk update on log(α)
    αind = 0.1, βind = 0.1, # parameters for the independence prior
    emp_bayes = false, # estimate βind using empirical Bayes
    verbose = true
)

    ################ Data processing

    breaks = range(T0, stop=T, length=N+1) # linspace(0,T,N+1)
    Δ = diff(breaks)

    # if the observations are sorted, the bin counts can be computed faster
    if issorted(observations)
        sorted = true
        H = counts_sorted(observations, breaks)    # extract vector H
    else
        sorted = false
        H = counts(observations, breaks)           # extract vector H
    end

    if emp_bayes == true
        βind = ebβ(αind, H, Δ, n, N)
    end


    ################## Specification number of bins N

    # option 1a: maximise marginal log-likelihood with independence prior
    Nmax = length(observations)÷2
    Nvals, mll = marginal_loglikelihood(Nmax, observations, T0, T, n, αind, βind)
    Nopt = Nvals[argmax(mll)]


    ################### Initialisation of algorithms
    first(samples) < 1 && throw(ArgumentError("first(samples) < 1)"))
    SUBIT = length(samples)
    IT = last(samples)

    # nr of iterations
    ψ = zeros(SUBIT, N)  # each row is a (sub-) iteration
    ζ = zeros(SUBIT - 1, N-1)
    α = zeros(IT)
    αc = 1.0
    α[1] = αc  # initial value for α
    acc = zeros(Bool, IT - 1)  # keep track of MH acceptance

    # Initialise, by drawing under independence prior
    post_ind = zeros(N, 2)
    ψc = zeros(N)
    ζc = zeros(N-1)

    for k in 1:N
    	post_ind[k,1] = αind + H[k]
        post_ind[k,2] = βind + n*Δ[k]  # note that second parameter is the rate
    	ψc[k] = rand(Gamma(post_ind[k,1], 1.0/(post_ind[k,2])))
    end


    ss = 1 # keep track of subsample number
    if 1 in samples
        ψ[ss, :] = ψc
        ss += 1
    end

    # Gibbs sampler
    tt = @elapsed for i in 2:IT
        αψ = αζ = αc
        updateζ!(ζc, ψc, αψ, αζ)
        updateψ!(ψc, H, Δ, n, ζc, αψ, αζ, α1, β1)
        α[i], acc[i-1] = updateα(αc, ψc, ζc, τ, Π)
        αc = α[i]
        if i in samples
            ψ[ss,:] = ψc
            ζ[ss - 1,:] = ζc
            ss += 1
        end
    end

    if verbose
        println("Running time: $(round(tt, digits=2)) s")
        println("")
        println("Average acceptance probability for updating: ",
            round(mean(acc); digits=3),"\n")
    end

    if summaryfile != nothing
        facc = open(summaryfile, "w")
        write(facc, "Data: ", string(title), "\n")
        write(facc, "Average acceptance probability: ", string(round(mean(acc); digits=3)), "\n")
        write(facc, "[T0, T, n, N] = ", string([T0, T, n, N]), "\n")
        write(facc, "Total number of events: ", string(sum(H)), "\n")
        write(facc, "tau = ", string(τ),"\n\n")
        write(facc, "Prior specification:", "\n")
        write(facc, "\talpha_ind = ", string(αind), "\n")
        write(facc, "\tbeta_ind = ", string(βind, "\n"))
        write(facc, "\talpha1 = ", string(α1), "\n")
        write(facc, "\tbeta1 = ", string(β1), "\n")
        write(facc, "\tPi = ", string(Π), "\n")
        close(facc)
    end

    return (title=title, observations = observations, ψ = ψ, N = N, T0 = T0, T = T, breaks = breaks, acc = acc)
end
