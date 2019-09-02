export tesselation

"""
`expander(P::HPolygon)` returns a list of polygons formed by reflecting `P`
across each of its sides.
"""
function expander(P::HPolygon)
    slist = sides(P)
    return [ reflect_across(P,S) for S in slist ]
end



"""
`tesselation(n,k,deep)`: Tesselate the hyperbolic plane by regular `n`-gons in which
each vertex is a corner of `k` polygons. `deep` controls how many layers.
The center of the first `k`-gon is placed at the origin.

May also be called `tesselation(n,k,deep,true)` in which case
a vertex of the first `k`-gon is placed at the origin and the tesselation
is seeded by copies of this first polygon around the origin.
"""
function tesselation(n::Int, k::Int, deep::Int=2,  vertex_centered::Bool=false)
    theta = 2pi/k
    P = equiangular(n,theta)
    outlist = HContainer()
    todo = HContainer()

    if vertex_centered
        v = P.plist[1]
        f = move2zero(v)
        P = f(P)
        r = rotation(theta)
        for j=1:k
            add_object!(todo,P)
            add_object!(outlist,P)
            P = r(P)
        end
    else
        add_object!(todo, P)
        add_object!(outlist,P)
    end

    for j=1:deep
        new_todo = HContainer()
        for X in todo.objs
            add_object!(outlist,X)
            for Y in expander(X)
                if !in(Y,outlist)
                    add_object!(new_todo,Y)
                end
            end
        end
        todo = new_todo
    end

    return outlist
end
