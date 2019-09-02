

## using KronLinInv

###############################################

function test2D( )

    ## 2D problem, so set nx = 1
    nx = 1
    ny = 20
    nz = 30
    nxobs = 1
    nyobs = 18
    nzobs = 24
    sigmaobs  = [1.0, 0.1, 0.1]
    corlenobs = [0.0, 1.4, 1.4]
    sigmam    = [1.0, 0.8, 0.8]
    corlenm   = [0.0, 2.5, 2.5]
    
    # run test 
    result = test_mean_cov(nx,ny,nz,nxobs,nyobs,nzobs,
                           sigmaobs,corlenobs,sigmam,corlenm)

    return result
end

#########################################

function test3D( )

    ## 2D problem, so set nx = 1
    nx = 8
    ny = 9
    nz = 12
    nxobs = 6
    nyobs = 7
    nzobs = 11
    sigmaobs  = [0.1, 0.1, 0.1]
    corlenobs = [1.4, 1.4, 1.4]
    sigmam    = [0.8, 0.8, 0.8]
    corlenm   = [2.5, 2.5, 2.5]

    
    # run test 
    result = test_mean_cov(nx,ny,nz,nxobs,nyobs,nzobs,
                           sigmaobs,corlenobs,sigmam,corlenm)

    return result
end

########################################

function test_mean_cov(nx::Integer,ny::Integer,nz::Integer,
                       nxobs::Integer,nyobs::Integer,nzobs::Integer,
                       sigmaobs::Array{Float64,1},corlenobs::Array{Float64,1},
                       sigmam::Array{Float64,1},corlenm::Array{Float64,1})

    ##############################
    ## Setup the problem
    ##############################

    ## Covariance matrices
    # covariance on observed data
    Cd1,Cd2,Cd3 = mkCovSTAT(sigmaobs,nxobs,nyobs,nzobs,corlenobs,"gaussian")
    # covariance on model parameters
    Cm1,Cm2,Cm3 = mkCovSTAT(sigmam,nx,ny,nz,corlenm,"gaussian") 


    ## Create the covariance matrix structure
    Covs = CovMats(Cd1,Cd2,Cd3,Cm1,Cm2,Cm3)

    ## Forward model operator
    G1 = rand(nxobs,nx)
    G2 = rand(nyobs,ny)
    G3 = rand(nzobs,nz)

    ## Create the forward operator structure
    Gfwd = FwdOps(G1,G2,G3)


    ##############################
    ## Setup the synthetic test
    ##############################

    ## Create a reference model
    refmod = rand(nx*ny*nz)

    ## Create a reference model
    mprior = copy(refmod) #0.5 .* ones(nx*ny*nz)

    ## Create some "observed" data
    ##   (without noise because it's just a test of the algo)
    dobs = kron(G1,kron(G2,G3)) * refmod 


    ##############################
    ## Solve the inverse problem
    ##############################

    ## Calculate the required factors
    klifac = calcfactors(Gfwd,Covs)

    ## Calculate the posterior mean model
    postm = posteriormean(klifac,Gfwd,mprior,dobs)

    ## Calculate the posterior covariance
    npts = nx*ny*nz
    astart, aend = 1,div(npts,3)
    bstart, bend = 1,div(npts,3)
    postC = blockpostcov(klifac,astart,aend,bstart,bend)

    ##############################
    ## Check results
    ##############################

    if postm ≈ refmod
        return true
    end
    return false
end

###########################################################

function mkCovSTAT(sigma::Array{Float64,1},nx::Integer,ny::Integer,nz::Integer,
                   corrlength::Array{Float64,1},kind::String) 
    #
    #   Stationaly covariance model 
    #
    #println("Creating covariance matrix...")

    function cgaussian(dist,corrlength)
        if maximum(dist)==0.0
            return 1.0
        else
            @assert(corrlength>0.0)
            return exp.(-(dist./corrlength).^2)
        end
    end
    function cexponential(dist,corrlength)
        if maximum(dist)==0.0
            return 1.0
        else
            @assert(corrlength>0.0)
            return exp.(-(dist./corrlength))
        end
    end
    
    npts = nx*ny*nz
    x = [float(i) for i=1:nx]
    y = [float(i) for i=1:ny]
    z = [float(i) for i=1:nz]
    covmat_x = zeros(nx,nx)
    covmat_y = zeros(ny,ny)
    covmat_z = zeros(nz,nz)

    if kind=="gaussian" 
        calccovfun = cgaussian
    elseif kind=="exponential" 
        calccovfun = cexponential
    else 
        println("Error, no or wrong cov 'kind' specified")
        exit()
    end        

    for i=1:nx
        covmat_x[i,:] .= sigma[1]^2 .* 
            calccovfun(sqrt.((x.-x[i]).^2),corrlength[1])
    end
    for i=1:ny
        covmat_y[i,:] .= sigma[2]^2 .* 
            calccovfun(sqrt.(((y.-y[i])).^2),corrlength[2])
    end
    for i=1:nz
        covmat_z[i,:] .= sigma[3]^2 .* 
            calccovfun(sqrt.(((z.-z[i])).^2),corrlength[3])
    end
    
    return covmat_x,covmat_y,covmat_z
 end

##########################################################

