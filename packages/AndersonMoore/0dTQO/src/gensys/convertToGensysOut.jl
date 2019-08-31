function convertToGensysOut(bb, phi, theF, cc, g0, g1, psi, ncpi)
    
    (nr, nc) = size(g1)
    (nrpsi,ncpsi) = size(psi)
    stateDim = size(bb, 2) - ncpi
    G1 = bb[1:nr, 1:nc]

    ststate = (g0 - g1) \ cc
    CC = (Compat.Matrix(I, nr, nr) - G1) * ststate

    thePsi = vcat(psi, zeros(ncpi, ncpsi))
    aa = phi * thePsi
    impact = aa[1:nr, :]

    # no unique way to represent these components
    (ywt, fmat, fwt) = smallF(theF, aa, stateDim)
    
    return CC, G1, impact, ywt, fmat, fwt

end # function


