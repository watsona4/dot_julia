function convertFromGensysIn(g0,g1,pi)

    gDim  = size(g0, 1)
    piCol = size(pi, 2)
    
    theHM = hcat(-g1, zeros(gDim, piCol))
    theHM = vcat(theHM, zeros(piCol, gDim + piCol))
    
    theH0 = hcat(g0, -pi)
    theH0 = vcat(theH0, zeros(piCol, gDim + piCol))
    #theH0=sparse([...
    #              g0,-pi;...
    #              zeros(piCol,gDim+piCol)]);

    matrix = Compat.Matrix(I, piCol, piCol)
    theHP = hcat(zeros(piCol, gDim), matrix)
    theHP = vcat(zeros(gDim, gDim + piCol), theHP)
    #theHP=sparse([...
    #             zeros(gDim,gDim+piCol);...
    #              zeros(piCol,gDim),eye(piCol)]);

    return theHM, theH0, theHP
    
end # function
