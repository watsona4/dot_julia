
# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
const Arc = Pair{vertex,vertex}

struct List{T}
   head::T
   tail::List{T}

   List{T}() where T = new{T}()
   List(a, l::List{T}) where T = new{T}(a, l)
end

List(T) = List{T}()
List() = List(Any)

Base.isempty(x::List) = !isdefined(x,2)

head(a::List) = a.head
tail(a::List) = a.tail

@static if VERSION > v"0.7-"
	function Base.iterate(l::List, state::List = l)
		isempty(state) && return nothing
	    state.head, state.tail
	end
end

@static if VERSION < v"0.7-"
	Base.start(l::List) = l
	Base.done(l::List, state::List) = isempty(state)
	Base.next(l::List, state::List) = (state.head, state.tail)
end

function reverse(l::List{T}) where T
    l2 = List(T)
    for h in l
        l2 = List(h, l2)
    end
    l2
end

struct Partition
    v::vertex
    arcs::List{Arc}
    nbArcs::UInt16
    zλ::Int
    z1::Int
    z2::Int
end
<(a::Partition, b::Partition) = a.zλ < b.zλ || a.zλ == b.zλ && a.nbArcs < b.nbArcs #Used to sort the binary heap of Partitions
Base.isless(a::Partition, b::Partition) = a.zλ < b.zλ || a.zλ == b.zλ && a.nbArcs < b.nbArcs #Used to sort the binary heap of Partitions
# Base.isless(a::Partition, b::Partition) = a.zλ < b.zλ || (a.zλ == b.zλ && a.z1 <= b.z1 && a.z2 <= b.z2) #Used to sort the binary heap of Partitions
# <(a::Partition, b::Partition) = a.zλ < b.zλ || (a.zλ == b.zλ && a.z1 <= b.z1 && a.z2 <= b.z2) #Used to sort the binary heap of Partitions
zλ(p::Partition) = p.zλ
z1(p::Partition) = p.z1
z2(p::Partition) = p.z2

Partition(v::vertex) = Partition(v, List(Arc), 0, v.zλ, v.z1, v.z2)

#Reconstruct a solution from a Partition

function solution(l, pb::problem, mono_pb::mono_problem) 
    vars = falses(size(pb))
    obj1, obj2, w = mono_pb.min_profit_1, mono_pb.min_profit_2, mono_pb.ω

    #TODO :
    #variables in l are sorted by decreasing profit of the mono_problem,
    #the first pass should be doable in O(n) instead of O(n^2)
    #Variables in C1 could be sorted after the reduction to make the second pass in O(n) too

    for i = 1:length(l)
        if l[i]
            ind_var = mono_pb.variables[i]
            vars[findfirst(isequal(ind_var), pb.variables)] = true
            obj1 += pb.p1[ind_var]
            obj2 += pb.p2[ind_var]
            w += pb.w[ind_var]
        end
    end

    for v in mono_pb.C1
        vars[findfirst(isequal(v), pb.variables)] = true
    end

    res = solution(pb, vars, obj1 - pb.min_profit_1, obj2 - pb.min_profit_2, w - pb.ω)
    # @assert dot(pb.p1, res.x, pb.variables) + pb.min_profit_1 == obj_1(res)
    # @assert dot(pb.p2, res.x, pb.variables) + pb.min_profit_2 == obj_2(res)
    return res
end


zλ(s, t, mpb) = s.w == t.w ? 0 : mpb.p[s.i]
z1(s, t, pb) = s.w == t.w ? 0 : pb.p1[s.i]
z2(s, t, pb) = s.w == t.w ? 0 : pb.p2[s.i]
weight(s, t) = t.w - s.w
