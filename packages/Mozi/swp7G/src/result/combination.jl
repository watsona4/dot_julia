module Combination
using LinearAlgebra

export linear_add,SRSS,CQC,envelop

function linear_add(X)
    sum(X,dims=2)
end

function SRSS(X)
    sqrt.(sum(X.^2,dims=2))
end

function CQC(X)
    row,col=size(X)
    cqc=zeros(row)
    for i in 1:col
        for j in 1:col
            X[:,i].*X[:,j]
        end
    end
    sqrt.(cqc)
end

function envelop(X)
    maxX=maximum(X,dims=2)
    minX=mininum(X,dims=2)
    return maxX,minX
end

struct Comb()
    id::String
    hid::Int
    cases::Array
    factors::Array
    method::String
end

end
