function smallF(anF, bigPhi, nn)
    
    (fRows, fCols) = size(anF)
    lilFL = anF[(nn + 1):fRows, (nn + 1):fRows]
    uu = nullspace(lilFL)
    theNull = size(uu, 2)
    #eOpts.disp = 0;
    lilFU = anF[1:nn, (nn + 1):fRows]
    onLeft = lilFU
    onRight = bigPhi[(nn + 1):fRows, :]
    inMiddle = lilFL

    return onLeft, inMiddle, onRight
    
end # function
