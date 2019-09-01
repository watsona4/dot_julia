export matuscsirmaztetraproj, matuscsirmaztetra!

function matuscsirmaztetraproj(i, j, k, l)
    alpha = -4ingleton(i, j)
    beta1 = submodular(4, k, l, i)
    beta2 = submodular(4, k, l, j)
    beta  = beta1 + beta2
    gamma = 2submodular(4, i, j, k) + 2submodular(4, i, j, l)
    delta = submodular(4, j, l, k) + submodular(4, i, l, k) + submodular(4, j, k, l) + submodular(4, i, k, l)
    [alpha  beta  gamma  delta]'
end

function matuscsirmaztetra!(h::EntropyCone{15}, i, j, k, l, tetravertices::Matrix=[1 1 1;1 -1 -1; -1 1 -1; -1 -1 1]')
    tight!(h)
    intersect!(h, -ingleton(i, j))
    # er = getextremerays(h)
    # name = ["r_1", "br_ij", "r_1^jl", "r_1^j", "r_1^jk", "r_2^k", "r_2^l", "r_3", "r_1^i", "r_1^il", "r_1^ik"]
    # println(length(er))
    # for i in 1:length(er)
    #   println(name[i])
    #   println(er[i])
    # end
    # alpha = -4ingleton(i, j)
    # beta1 = submodular(4, k, l, i)
    # beta2 = submodular(4, k, l, j)
    # beta  = beta1 + beta2
    # gamma = 2submodular(4, i, j, k) + 2submodular(4, i, j, l)
    # delta = submodular(4, j, l, k) + submodular(4, i, l, k) + submodular(4, j, k, l) + submodular(4, i, k, l)
    removeredundantinequalities!(h.poly)
    #poly = [alpha  beta  gamma  delta]' * h.poly
    matuscsirmaztetra!(h.poly, i, j, k, l, tetravertices)
end

function matuscsirmaztetra!(poly::Polyhedron{15}, i, j, k, l, tetravertices::Matrix=[1 1 1;1 -1 -1; -1 1 -1; -1 -1 1]')
    poly = transformgenerators(poly, matuscsirmaztetraproj(i,j,k,l))
    poly = radialprojectoncut(poly, [1, 1, 1, 1], 1)
    removeredundantgenerators!(poly)
    #poly = tetravertices * poly
    poly = transformgenerators(poly, tetravertices)
    removeredundantgenerators!(poly)
    poly
end
