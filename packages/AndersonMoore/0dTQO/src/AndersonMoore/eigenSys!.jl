"""
    eigenSys!(h, qcols, neq)

Compute the roots and the left eigenvectors of the companion
matrix, sort the roots from large-to-small, and sort the
eigenvectors conformably.  Map the eigenvectors into the real
domain. Count the roots bigger than uprbnd.
"""
function eigenSys!(aa::Array{Float64,2}, upperbound::Float64, rowsLeft::Int64)

    roots = Array{Complex{Float64},1}(eigvals(copy(transpose(aa))))
    ww = eigvecs(copy(transpose(aa)))

    # sort eigenvalues in descending order of magnitude
    magnitudes = abs.(roots)
    highestToLowestMag = sortperm(magnitudes, rev = true) # reverse order
    roots = roots[highestToLowestMag]

    # sort eigenvecs in order found above
    ww = ww[:, highestToLowestMag]
    
    #  Given a complex conjugate pair of vectors W = [w1,w2], there is a
    #  nonsingular matrix D such that W*D = real(W) + imag(W).  That is to
    #  say, W and real(W)+imag(W) span the same subspace, which is all
    #  that AMA cares about. 

    ww = ( real(ww) + imag(ww) )

    # count how many roots are above the upperbound threshold
    lgroots = mapreduce((mag->mag > upperbound ? 1 : 0), +, magnitudes)
    
    return (ww, roots, lgroots)

end # eigenSys!
