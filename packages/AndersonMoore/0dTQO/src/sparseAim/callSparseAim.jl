"""
    callSParseAim(hh, leads, lags)

Julia wrapper function that calls the c function callSparseAim.
"""
function callSparseAim( hh, leads, lags )

    # allocate space for the matrices and initialize inputs
    neq        = size(hh, 1)
    nstate     = 0
    hrows      = neq
    hcols      = size(hh, 2)
    qmax       = hrows*leads*(hrows*(lags+leads+1))
    retCodePtr = 0
    cofb       = zeros(neq, neq * lags)
    qmatrix    = zeros(neq*leads, hcols)

    # use the library libSPARSEAMA to call c function ...
    # libAndersonMoore is a shared library that combines sparseAMA
    # and LAPACK. LAPACK must be compiled with -fPIC.
    ccall(sym, Compat.Nothing,
          (  Ptr{Float64}, Int32, Int32, Int32, Int32,
          Int32, Int32, Int32,
          Ptr{Float64}, Ptr{Float64}, Ptr{Float64}  ),
          hh, hrows, hcols, neq, leads, lags, nstate,
          qmax, Ref{retCodePtr}[], cofb, qmatrix)
 
    return hh, cofb, qmatrix, retCodePtr
end
