function setEu(aimCode)
        
    euVal = zeros(2, 1)
    if aimCode == 1
        euVal[1, 1] = 1
        euVal[2, 1] = 1
    elseif aimCode == 2
        euVal[1, 1] = -2
        euVal[2, 1] = -2
    elseif aimCode == 3
        euVal[1, 1] = 0
        euVal[2, 1] = 0
    elseif aimCode == 4
        euVal[1, 1] = 1
        euVal[2, 1] = 0
    elseif aimCode == 5
        euVal[1, 1] = -5
        euVal[2, 1] = -5
    end
    
    return euVal
end
