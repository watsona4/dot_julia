# Memoisation for Approximate Computation
#
# #######################################

function ApproximateHashingMemoise(fn, hashmap, hashfn, inputs...)
    hashid = hashfn(fn, inputs...)
    if( haskey(hashmap, hashid))
       return hashmap[hashid]
    else
        res = fn(inputs...)
        hashmap[hashid] = res
        return res
    end
end

function TrendingMemoisation(fn, hashfn, hasharray, limit, inputs...)
    index = hashfn(fn, inputs...)

    # Training is complete
    if(hasharray[index][1] > limit)
        return hasharray[index][3]
    end
    
    # Continue Training
    res = fn(inputs...)
    hasharray[index][1] += 1
    hasharray[index][2] += res

    if(hasharray[index][1] > limit)
        hasharray[index][3] = hasharray[index][2]/Float64.(hasharray[index][1])
        return hasharray[index][3]
    end
    
    return res
end