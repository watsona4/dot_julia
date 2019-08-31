function simMats(newfmat, fmat)
    tol = 1e-8
    evA = eig(full(newfmat))
    evB = eig(full(fmat))
    aNz = find(abs(evA) > tol)
    bNz = find(abs(evB) > tol)
    diffLen = length(aNz) - length(bNz)

    if diffLen < 0
        res = norm(sort(real(evB(bNz))) - (sort(real([evA(aNz);zeros(-diffLen,1)]))))
    elseif diffLen == 0
        res = norm(sort(real(evB(bNz))) - (sort(real(evA(aNz)))));
    elseif diffLen > 0
        res = norm(sort(real([evB(bNz);zeros(diffLen,1)]))-sort(real(evA(aNz))))
    end
    
    return res
end
