export size_criterion, sqrt_criterion, change_criterion, log_criterion, epsilon_criterion


"""
Stops when the distance between far items achieves the given `e`
"""
function epsilon_criterion(e)
   (dmaxlist, database) -> dmaxlist[end] < e
end

"""
Stops when the number of far items are equal or larger than the given `maxsize`
"""
function size_criterion(maxsize)
   (dmaxlist, database) -> length(dmaxlist) >= maxsize
end

"""
Stops when the number of far items are equal or larger than the square root of the size of the database
"""
function sqrt_criterion()
   (dmaxlist, database) -> length(dmaxlist) >= Int(length(database) |> sqrt |> round)
end

"""
Stops when the number of far items are equal or larger than logarithm-2 of the size of the database
"""
function log_criterion()
   (dmaxlist, database) -> length(dmaxlist) >= Int(length(database) |> log2 |> round)
end

"""
Stops the process whenever the maximum distance converges, i.e., after `window` far items the maximum distance
change is below or equal to the allowed tolerance `tol`
"""
function change_criterion(tol=0.001, window=3)
    mlist = Float64[]
    count = 0.0
    function stop(dmaxlist, database)
        count += dmaxlist[end]
        
        if length(dmaxlist) % window != 1
            return false
        end
        push!(mlist, count)
        count = 0.0
        if length(dmaxlist) < 2
            return false
        end
        
        s = abs(mlist[end] - mlist[end-1])
        return s <= tol
    end
    
    return stop
end

"""
It nevers stops by side, it explores the entire dataset making a full farthest first traversal
"""
function salesman_criterion()
    function stop(dmaxlist, dataset)
        return false
    end
end