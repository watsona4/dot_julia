function reorder(t,s, strat::CommonVertex)

    # Find the permutation P of t and s that make
    # Pt = [P, A1, A2]
    # Ps = [P, B1, B2]
    I = zeros(Int,1)
    J = zeros(Int,1)
    e = 1
    for i in 1:3
        v = t[i]
        for j in 1:3
            w = s[j]
            if norm(w-v) < eps(eltype(v)) * 1.0e3
                I[e] = i
                J[e] = j
                e += 1
                break
            end
        end
        e == 2 && break
    end

    append!(I, setdiff([1,2,3], I))
    append!(J, setdiff([1,2,3], J))

    # # inverse permutations
    # K = indexin([1,2,3], I)
    # L = indexin([1,2,3], J)

    K = zeros(Int,3)
    for i in 1:3
        for j in 1:3
            if I[j] == i
                K[i] = j
                break
            end
        end
    end

    L = zeros(Int,3)
    for i in 1:3
        for j in 1:3
            if J[j] == i
                L[i] = j
                break
            end
        end
    end

    return I, J, K, L
end


function reorder(t, s, strat::CommonEdge)

    I = zeros(Int,3)
    J = zeros(Int,3)
    e = 1
    for i in 1:3
        v = t[i]
        for j in 1:3
            w = s[j]
            if norm(w-v) < eps(eltype(v)) * 1.0e3
                I[e] = i
                J[e] = j
                e += 1
                break
            end
        end
    end
    I[3] = setdiff([1,2,3], I[1:2])[1]
    J[3] = setdiff([1,2,3], J[1:2])[1]

    I = circshift(I,-1)
    J = circshift(J,-1)

    # # inverse permutations
    # K = indexin([1,2,3], I)
    # L = indexin([1,2,3], J)

    K = zeros(Int,3)
    for i in 1:3
        for j in 1:3
            if I[j] == i
                K[i] = j
                break
            end
        end
    end

    L = zeros(Int,3)
    for i in 1:3
        for j in 1:3
            if J[j] == i
                L[i] = j
                break
            end
        end
    end

    return I, J, K, L
end


function reorder(t, s, strat::CommonFace)

    I = [1,2,3]
    J = [1,2,3]
    K = [1,2,3]
    L = [1,2,3]

    return I, J, K, L
end
