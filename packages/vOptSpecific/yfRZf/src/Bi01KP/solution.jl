# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
struct solution
    pb::problem #The problem for which it's a solution
    x::BitArray #Variable states
    obj_1::Int #Value on first objective
    obj_2::Int #Value on second objective
    weight::Int #Weight of the solution
end

#Constructor : empty solution
solution(p::problem) = solution(p, falses(size(p)), 0, 0, 0)

#Getters
obj_1(s::solution) = s.obj_1 + s.pb.min_profit_1
obj_2(s::solution) = s.obj_2 + s.pb.min_profit_2
obj(s::solution) = obj_1(s), obj_2(s)
weight(s::solution) = s.weight + s.pb.ω

full_variable_vector(s::solution) = begin
    res = zeros(Int,s.pb.psize)
    for i in s.pb.C1
        res[i] = 1
    end
    for i = 1:size(s.pb)
        if s.x[i] == true
            res[s.pb.variables[i]] = 1
        end
    end
    return res
end

print_vars(s::solution) = String([i==1 ? '1' : '0' for i in full_variable_vector(s)])

#Print function
Base.show(io::IO, s::solution) =
    # print(io, "sol(p1=$(obj_1(s)), p2=$(obj_2(s)), w=$(weight(s)))")
    print(io, "sol(p1=",obj_1(s),", p2=",obj_2(s),") w=",weight(s)," : " ,print_vars(s))

#Helper function to calculate an objective value or an accumulated weight
function dot(v::Vector{Int}, status::BitArray, indices::AbstractArray{Int,1})
    #@assert length(v) >= length(status) == length(indices)
    res = 0
    for i = 1:length(status)
        @inbounds res += status[i] * v[indices[i]]
    end
    res
end

#Relation operators
dominates(a1::Int,a2::Int,b1::Int,b2::Int) = (a1 > b1 && a2 >= b2) || (a1 >= b1 && a2 > b2)
dominates(yr::Tuple{Int,Int}, ys::Tuple{Int,Int}) = dominates(yr[1], yr[2], ys[1], ys[2])

ideal(yr::Tuple{Int,Int}, ys::Tuple{Int,Int}) = max(yr[1],ys[1]), max(yr[2],ys[2])
nadir(yr::Tuple{Int,Int}, ys::Tuple{Int,Int}) = min(yr[1],ys[1]), min(yr[2],ys[2])

import Base.==
==(a::solution, b::solution) = a.obj_1==b.obj_1 && a.obj_2==b.obj_2 && a.weight==b.weight && a.x==b.x
import Base.<
import Base.<=
<=(a::solution,b::solution) = dominates(obj(b),obj(a))
<=(a, b::solution) = dominates(obj(b), a)
<=(a::solution, b) = dominates(b, obj(a))

ideal(a::solution,b::solution) = max(obj_1(a), obj_1(b)) , max(obj_2(a), obj_2(b))
nadir(a::solution,b::solution) = nadir(obj(a), obj(b))