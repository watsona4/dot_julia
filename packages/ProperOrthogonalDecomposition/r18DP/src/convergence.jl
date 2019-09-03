
"""
    function modeConvergence(X::AbstractArray, PODfun, stops::AbstractArray{<: AbstractRange}, numModes::Int)
Modal convergence check based on l2-norm of modes. The array `stops` contains
the ranges to investigate where `stops[end]` is used as the reference modes. The `numModes`
largest modes are compared to reduce the computational time. The function used to
POD the data is supplied through `PODfun`
"""
function modeConvergence(X::AbstractArray, PODfun, stops::AbstractArray{<: AbstractRange}, numModes::Int)

    
    # The full POD which the subsets are compared to
    maxPOD = PODfun(X[:,stops[end]])[1].modes[:,1:numModes]

    numPODs = size(stops,1)
    output = zeros(eltype(X), numModes, numPODs) # Allocate output

    for i = 1:numPODs-1

        podRes = PODfun(X[:,stops[i]])[1].modes[:,1:numModes]
        
        # Compare the first numModes modes.
        for j = 1:numModes

            # normalize the mode before comparing
            maxPODnorm = norm(maxPOD[:,j])
            podResnorm = norm(podRes[:,j])
            maxComp = maxPOD[:,j]/maxPODnorm
            podComp = podRes[:,j]/podResnorm

            # modes do not have a specific sign, compare the positive and negative
            # to find minimum.
            l2norm1 = norm(maxComp - podComp)
            l2norm2 = norm(maxComp + podComp)
            l2norm = minimum([l2norm1, l2norm2])
            output[j,i] = l2norm
        end

    end

    return output
end







"""
    function modeConvergence!(loadFun, PODfun, stops::AbstractArray{<: AbstractRange}, numModes::Int)
Same as `modeConvergence(X::AbstractArray, PODfun, stops::AbstractArray{<: AbstractRange}, numModes::Int)` 
but here the data is reloaded for each comparision so that an inplace POD method can be used to reduce
maximum memory usage.
"""
function modeConvergence!(loadFun, PODfun, stops::AbstractArray{<: AbstractRange}, numModes::Int)

    X = loadFun()

    # The full POD which the subsets are compared to
    maxPOD = PODfun(X[:,stops[end]])[1].modes[:,1:numModes]

    numPODs = size(stops,1)
    output = zeros(eltype(X), numModes, numPODs) # Allocate output

    for i = 1:numPODs-1

        X = loadFun()

        podRes = PODfun(X[:,stops[i]])[1].modes[:,1:numModes]
        
        # Compare the first numModes modes.
        for j = 1:numModes

            # normalize the mode before comparing
            maxPODnorm = norm(maxPOD[:,j])
            podResnorm = norm(podRes[:,j])
            maxComp = maxPOD[:,j]/maxPODnorm
            podComp = podRes[:,j]/podResnorm

            # modes do not have a specific sign, compare the positive and negative
            # to find minimum.
            l2norm1 = norm(maxComp - podComp)
            l2norm2 = norm(maxComp + podComp)
            l2norm = minimum([l2norm1, l2norm2])
            output[j,i] = l2norm
        end

    end

    return output
end