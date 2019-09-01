export zhangyeunginequality, matus41, matus42, matus51, matus52, matus53

function zhangyeunginequality(i::Signed, j::Signed, k::Signed, l::Signed)
    n = 4
    I = set(i)
    J = set(j)
    K = set(k)
    L = set(l)
    submodular(n, K, L, I) + submodular(n, K, L, J) + submodular(n, I, J) - submodular(n, K, L) +
    submodular(n, I, K, L) + submodular(n, I, L, K) + submodular(n, K, L, I)
end
zhangyeunginequality() = zhangyeunginequality(1, 2, 3, 4)

# function constraint41()
#   ingleton(1,2)
# end
# function constraint42()
#   submodular(4,2,3,4)
# end
# function constraint43()
#   submodular(4,2,4,3) + submodular(4, 3,4,2)
# end
function checkalldifferent(x)
    s = BitSet()
    for i in x
        push!(s, i)
    end
    if length(s) < length(x)
        error("Arguments must be all different")
    end
end
function matus41(s, i=1, j=2, k=3, l=4)
    checkalldifferent((i, j, k, l))
    2s*ingleton(i, j) + 2submodular(4,j,k,l) + s*(s+1)*(submodular(4,j,l,k) + submodular(4,k,l,j))
end
function matus42(s, i=1, j=2, k=3, l=4)
    checkalldifferent((i, j, k, l))
    (k, l) = getkl(i, j)
    2s*ingleton(i, j) + 2submodular(4,i,k,l) + 2s*(submodular(4,k,l,i)+submodular(4,i,l,k)) + s*(s-1)*(submodular(4,j,l,k)+submodular(4,k,l,j))
end

function matus5aux(s, ingli, inglj, inglk, ingll, i, j, k, l, m)
    2s*(ingleton(5,ingli,inglj,inglk,ingll)+submodular(5,k,l,m)+submodular(5,l,m,k)) + 2submodular(5,k,m,l) + s*(s-1)*(submodular(5,j,l,k)+submodular(5,k,l,j))
end

function matus51(s, i=1, j=2, k=3, l=4, m=5)
    checkalldifferent((i, j, k, l, m))
    matus5aux(s, i, j, k, l, i, j, k, l, m)
end
function matus52(s, i=1, j=2, k=3, l=4, m=5)
    checkalldifferent((i, j, k, l, m))
    matus5aux(s, i, k, j, l, i, j, k, l, m)
end
function matus53(s, i=1, j=2, k=3, l=4, m=5)
    checkalldifferent((i, j, k, l, m))
    matus5aux(s, i, l, j, k, i, j, k, l, m)
end
