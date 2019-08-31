"""
    buildA(hh, qcols, neq)

Build the companion matrix, deleting inessential lags.
Solve for x_{t+nlead} in terms of x_{t+nlag},...,x_{t+nlead-1}.

"""
function buildA!(hh::Array{Float64,2}, qcols::Int64, neq::Int64) 

    left  = 1:qcols
    right = (qcols + 1):(qcols + neq)

    tmp = similar(hh)
    tmp[:, left] =  \(-hh[:, right], hh[:, left])

    #  Build the big transition matrix.
    aa = zeros(qcols, qcols)

    if(qcols > neq)
        eyerows = 1:(qcols - neq)
        eyecols = (neq + 1):qcols
        # aa[eyerows, eyecols] = eye(qcols - neq)
	aa[eyerows, eyecols] = Compat.Matrix(I, qcols - neq, qcols - neq) 
    end
    hrows      = (qcols - neq + 1):qcols
    aa[hrows, :] =  tmp[:, left]

    #  Delete inessential lags and build index array js.  js indexes the
    #  columns in the big transition matrix that correspond to the
    #  essential lags in the model.  They are the columns of q that will
    #  get the unstable left eigenvectors. 

    js       = Array{Int64}(undef, 1, qcols)
    for ii in 1 : qcols
        js[1, ii] = ii
    end
    
    zerocols = Compat.sum(abs.(aa); dims=1)
    zerocols = LinearIndices(zerocols)[findall(col->(col == 0), zerocols)]


     while length(zerocols) != 0
        # aa = filter!(x->(x !in zerocols), aa)       
        aa = deleteCols(aa, zerocols)        
        aa = deleteRows(aa, zerocols)
        js = deleteCols(js, zerocols)
        
        zerocols = Compat.sum(abs.(aa); dims=1)  
        zerocols = LinearIndices(zerocols)[findall(col->(col == 0), zerocols)]

    end
    ia = length(js)
    
    return (aa::Array{Float64,2}, ia::Int64, Int64.(js)::Array{Int64,2})
    
end # buildA
