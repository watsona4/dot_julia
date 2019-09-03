
"""
    PODeigen(X)

Uses the eigenvalue method of snapshots to calculate the POD basis of X. Method of
snapshots is efficient when number of data points `n` > number of snapshots `m`.
"""
function PODeigen(X; subtractmean::Bool = false)

    Xcop = deepcopy(X)
    PODeigen!(Xcop, subtractmean = subtractmean)

end


"""
    PODeigen(X,W)

Same as `PODeigen(X)` but uses weights for each data point. The weights are equal to the
cell volume for a volume mesh.
"""
function PODeigen(X,W::AbstractVector; subtractmean::Bool = false)

    Xcop = deepcopy(X)
    PODeigen!(Xcop,W, subtractmean = subtractmean)

end

"""
    PODeigen!(X,W)

Same as `PODeigen!(X)` but uses weights for each data point. The weights are equal to the
cell volume for a volume mesh.
"""
function PODeigen!(X,W::AbstractVector; subtractmean::Bool = false)

    if subtractmean
        X .-= mean(X,dims=2)
    end

    # Number of snapshots
    m = size(X,2)

    # Correlation matrix for method of snapshots
    C = X'*Diagonal(W)*X

    # Eigen Decomposition
    E = eigen!(C)
    eigVals = E.values
    eigVects = E.vectors

    # Sort the eigen vectors
    sortInd = sortperm(abs.(eigVals)/m,rev=true)
    eigVects = eigVects[:,sortInd]
    eigVals = eigVals[sortInd]

    # Diagonal matrix containing the square roots of the eigenvalues
    S = sqrt.(abs.(eigVals))

    # Construct the modes and coefficients
    Φ = X*eigVects*Diagonal(1 ./S)
    a = Diagonal(S)*eigVects'

    POD = PODBasis(a, Φ)

    return POD, S

end


"""
    PODeigen!(X)

Same as `PODeigen(X)` but overwrites memory.
"""
function PODeigen!(X; subtractmean::Bool = false)

    if subtractmean
        X .-= mean(X,dims=2)
    end

    # Number of snapshots
    m = size(X,2)

    # Correlation matrix for method of snapshots
    C = X'*X

    # Eigen Decomposition
    E = eigen!(C)
    eigVals = E.values
    eigVects = E.vectors

    # Sort the eigen vectors
    sortInd = sortperm(abs.(eigVals)/m,rev=true)
    eigVects = eigVects[:,sortInd]
    eigVals = eigVals[sortInd]

    # Diagonal matrix containing the square roots of the eigenvalues
    S = sqrt.(abs.(eigVals))

    # Construct the modes and coefficients
    Φ = X*eigVects*Diagonal(1 ./S)
    a = Diagonal(S)*eigVects'

    POD = PODBasis(a, Φ)

    return POD, S

end
