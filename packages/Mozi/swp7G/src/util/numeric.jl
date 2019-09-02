function linear_interp(a,x,y)
    for i in 2:length(x)
        if x[i-1]<a<x[i] || x[i-1]>a>x[i]
            return y[i-1]+(x[i]-a)/(x[i]-x[i-1])*(y[i]-y[i-1])
        end
    end
end

# using SparseArrays
# using LinearAlgebra
#
# @time begin
#
# for i in 1:100
#     G=zeros(12,200000)
#     i=20
#     j=300
#     G[1:6,6i-5:6i]=Matrix(1.0I,6,6)
#     G[7:12,6j-5:6j]=Matrix(1.0I,6,6)
#     G=sparse(G)
# end
# end
#
# @time begin
#
# for i in 1:100
#     G=spzeros(12,200000)
#     i=20
#     j=300
#     G[1:6,6i-5:6i]=sparse(1.0I,6,6)
#     G[7:12,6j-5:6j]=sparse(1.0I,6,6)
# end
# end
#
# @time begin
#
# for i in 1:100
#     i=20
#     j=300
#     I=collect(1:12)
#     J=[6i-5:6i;6j-5:6j]
#     G=sparse(I,J,1.0,12,200000)
# end
# end
