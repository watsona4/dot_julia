# A collection of extensions to the DomainSets package.

using DomainSets: inverse_map, forward_map

###########################
# Applying broadcast to in
###########################

# Intercept a broadcasted call to indomain. We assume that the user wants evaluation
# in a set of points (which we call a grid), rather than in a single point.
# TODO: the user may want to evaluate a single point in a sequence of domains...
broadcast(::typeof(in), grid, d::Domain) = indomain_broadcast(grid, d)

# # Default methods for evaluation on a grid: the default is to call eval on the domain with
# # points as arguments. Domains that have faster grid evaluation routines may define their own version.
indomain_broadcast(grid, d::Domain) = indomain_broadcast!(BitArray(undef, size(grid)), grid, d)
# TODO: use BitArray here

function indomain_broadcast!(result, grid::AbstractGrid, domain::Domain)
    for (i,x) in enumerate(grid)
        result[i] = DomainSets.in(x, domain)
    end
    result
end

function indomain_broadcast(grid::AbstractGrid, d::UnionDomain)
    z = indomain_broadcast(grid, element(d,1))
    for i in 2:numelements(d)
        z = z .| indomain_broadcast(grid, element(d,i))
    end
    z
end

function indomain_broadcast(grid::AbstractGrid, d::IntersectionDomain)
    z = indomain_broadcast(grid, element(d,1))
    for i in 2:numelements(d)
        z = z .& indomain_broadcast(grid, element(d,i))
    end
    z
end

function indomain_broadcast(grid::AbstractGrid, d::DifferenceDomain)
    z1 = indomain_broadcast(grid, d.d1)
    z2 = indomain_broadcast(grid, d.d2)
    z1 .& (.~z2)
end
