# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
mutable struct Triangle
    xr::solution
    xs::solution
    XΔ::Vector{solution}
    λ::Tuple{Int,Int} 
    ub::Int
    lb::Int
    pending::Bool
end

Triangle(xr::solution,xs::solution) = begin 
    λ1,λ2 = obj_2(xr) - obj_2(xs), obj_1(xs) - obj_1(xr)
    Triangle(xr,xs,solution[xr,xs],(λ1,λ2),λ1*obj_1(xr) + λ2*obj_2(xr),λ1*obj_1(xr) + λ2*obj_2(xs), true)
end

const PartitionHeap = BinaryHeap{Partition, DataStructures.GreaterThan}

#Returns the partition p in τ maximizing p.zλ
function parent_partition!(τ::PartitionHeap)
    pop!(τ)
end

function clean!(τ::PartitionHeap, lb::Int)
    deleteat!(τ.valtree, findall(elt -> elt.zλ < lb, τ.valtree))
    heapify!(τ.valtree, Base.Order.Reverse)
    # @assert all(top(τ).zλ .>= zλ.(τ.valtree[2:end]))
end

#constructs the optimal path for a partition p=<v, U>
#new partitions are added to τ if their value for zλ is >= lb
function const_Path_New_Partition(p::Partition, τ::PartitionHeap, lb::Int, mono_pb::mono_problem)::BitArray
    t = p.v #The vertex from which we're constructing the path
    U = p.arcs #The imposed arcs
    U_prime = reverse(U)
    ϕ = falses(size(mono_pb)) #The path that will be returned

    while t.layer != 1
        if !isempty(U_prime) && last(head(U_prime)) == t #if an arc (s=>t) is imposed
            s = first(head(U_prime))
            U_prime = tail(U_prime)
        elseif inner_degree(t) == 1 #elseif the vertex only has one parent
            s = parent(t)
        else
            s1,s2 = parents(t)

            #(s => t) is the optimal arc, (s' => t) is the secondary arc, not imposed yet
            if s2.zλ + zλ(s2, t, mono_pb) == t.zλ
                s = s2
                s_prime = s1
            else
                s = s1
                s_prime = s2
            end

            if isempty(U_prime) #Create a partition imposing the secondary arc (s' => t)
                ϕ_zλ = zλ(p) - zλ(t) + zλ(s_prime) + zλ(s_prime, t, mono_pb)
                if ϕ_zλ >= lb #Add it only if it's interesting
                    ϕ_z1 = z1(p) - z1(t) + z1(s_prime) + z1(s_prime, t, mono_pb)
                    ϕ_z2 = z2(p) - z2(t) + z2(s_prime) + z2(s_prime, t, mono_pb)
                    #@assert ϕ_zλ <= p.zλ
                    ♇ = Partition(p.v, List(s_prime=>t, U), p.nbArcs+1, ϕ_zλ, ϕ_z1, ϕ_z2 )
                    push!(τ,♇)
                end
            end
        end
        #If the weight of the arc isn't 0 (-> if we picked the item)
        if weight(s, t) != 0
            ϕ[s.layer] = true #We add s.i to the list of items picked
        end
        t = s
    end
    ϕ
end



in_triangle(y::Tuple{Int,Int}, yr::Tuple{Int,Int}, ys::Tuple{Int,Int}) = yr[1] <= y[1] <= ys[1] && ys[2] <= y[2] <= yr[2]
in_triangle(y::Tuple{Int,Int}, xr::solution, xs::solution) = in_triangle(y, obj(xr), obj(xs))
in_triangle(xt::solution, xr::solution, xs::solution) = in_triangle(obj(xt), obj(xr), obj(xs))
in_triangle(y::solution, Δ::Triangle) = in_triangle(y, Δ.XΔ[1], Δ.XΔ[end])
in_triangle(y::Tuple{Int,Int}, Δ::Triangle) = in_triangle(y, Δ.XΔ[1], Δ.XΔ[end])


function update_lb!(Δ::Triangle)
    # @assert issorted(Δ.XΔ, by = x -> obj_1(x))
    
    XΔ = Δ.XΔ
    λ1, λ2 = Δ.λ

    lb = λ1*obj_1(XΔ[1]) + λ2*obj_2(XΔ[1])
    
    for i = 2:length(XΔ)
        zλ = λ1*obj_1(XΔ[i]) + λ2*obj_2(XΔ[i])
        lb = min(lb,zλ)
    end

    for i = 1:length(XΔ)-1
        xr = XΔ[i]
        xs = XΔ[i+1]
        zλ = λ1*(obj_1(xr)+1) + λ2*(obj_2(xs)+1)
        lb = min(lb,zλ)
    end
    Δ.lb = lb
end

function explore_triangle(Δ::Triangle, output::Bool)
    Δ.pending = false
    XΔ = Δ.XΔ
    OΔ = solution[] #Nondominated points located outside of Δ(yr, ys)

    GKP = build_graph(Δ, output)

    isempty(GKP) && return OΔ
    mono_pb = GKP.mono_pb
    
    τ = binary_maxheap([Partition(v) for v in GKP.layer])
    Tk = parent_partition!(τ)
    while Tk.zλ >= Δ.lb

        ϕk = const_Path_New_Partition(Tk, τ, Δ.lb, mono_pb)

        let yk = (Tk.z1, Tk.z2)

            if in_triangle(yk, Δ)#If the solution is in the triangle
                if !any(x -> dominates(obj(x), yk), XΔ) #and no other solution in the triangle dominates it
                    s = solution(ϕk, GKP.pb, GKP.mono_pb) #Create the solution( O(n) )
                    deleteat!(XΔ, findall(x -> s>=x, XΔ))#Delete solutions dominated by this one

                    #Add the solution to the list
                    indinsert = searchsortedfirst(XΔ, s, by = obj_1)
                    insert!(XΔ, indinsert, s)

                    if Δ.lb != update_lb!(Δ)#And update the lower bound
                        clean!(τ, Δ.lb) #If the lower bound has been updated, we can remove some partitions from τ
                    end
                end
            else
                if !any(y -> dominates(obj(y), yk), OΔ)#If the solution isn't in the triangle and isn't dominated by any other in OΔ
                    deleteat!(OΔ, findall(y -> dominates(yk, obj(y)), OΔ))#Delete solutions dominated by this one
                    push!(OΔ, solution(ϕk, GKP.pb, GKP.mono_pb))#push it in OΔ
                end
            end
        end

        length(τ)==0 && break #If there are no more partitions to explore, stop
        Tk = parent_partition!(τ)#Else, pick the one with the better zλ
    end
    OΔ 
end

function second_phase(XSE::Vector{solution}, output::Bool)

    res = solution[]

    Δlist = [Triangle(XSE[i], XSE[i+1]) for i = 1:length(XSE)-1]

    for i = 1:length(Δlist)

        Δ = select_triangle(Δlist)
        output && println("exploring triangle $i/$(length(Δlist)) : Δ$(obj(Δ.xr))$(obj(Δ.xs)) ($((Δ.ub-Δ.lb)/2))")
        # output && plot_triangle(Δ)

        OΔ = explore_triangle(Δ, output)
        append!(res, Δ.XΔ)

        for sol in OΔ
            for j = 1:length(Δlist)
                Δj = Δlist[j]
                if in_triangle(sol,Δj)
                    let sol=sol #15938
                        !(Δj.pending) && break
                        any(x -> x>=sol, Δj.XΔ) && break

                        deleteat!(Δj.XΔ, findall(x -> sol>=x, Δj.XΔ))

                        indinsert = searchsortedfirst(Δj.XΔ, sol, by = obj_1)
                        insert!(Δj.XΔ, indinsert, sol)
                    end

                    update_lb!(Δj)
                    break
                end
            end
        end

    end
    sort!(res, by = obj_1, alg=QuickSort)
    return unique(elt -> elt.x, res)
end

function select_triangle(Δlist::Vector{Triangle})
    res = Δlist[findfirst(x->x.pending, Δlist)]
    val_min = res.ub - res.lb
    for i in findall(x -> x.pending, Δlist)
        val = Δlist[i].ub - Δlist[i].lb
        if val < val_min
            val_min = val
            res = Δlist[i]
        end
    end
    return res
end