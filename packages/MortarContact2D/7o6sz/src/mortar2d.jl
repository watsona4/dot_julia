# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2D.jl/blob/master/LICENSE

const MortarElements2D = Union{Seg2,Seg3}

mutable struct Mortar2D <: BoundaryProblem
    master_elements :: Vector{Element}
end

function Mortar2D()
    return Mortar2D([])
end

function FEMBase.add_elements!(::Problem{Mortar2D}, ::Union{Tuple, Vector})
    error("use `add_slave_elements!` and `add_master_elements!` to add " *
          "elements to the Mortar2D problem.")
end

function FEMBase.add_slave_elements!(problem::Problem{Mortar2D}, elements)
    for element in elements
        push!(problem.elements, element)
    end
end

function FEMBase.add_master_elements!(problem::Problem{Mortar2D}, elements)
    for element in elements
        push!(problem.properties.master_elements, element)
    end
end

function FEMBase.get_slave_elements(problem::Problem{Mortar2D})
    return problem.elements
end

function FEMBase.get_master_elements(problem::Problem{Mortar2D})
    return problem.properties.master_elements
end

function get_slave_dofs(problem::Problem{Mortar2D})
    dofs = Int64[]
    for element in get_slave_elements(problem)
        append!(dofs, get_gdofs(problem, element))
    end
    return sort(unique(dofs))
end

function get_master_dofs(problem::Problem{Mortar2D})
    dofs = Int64[]
    for element in get_master_elements(problem)
        append!(dofs, get_gdofs(problem, element))
    end
    return sort(unique(dofs))
end

function project_from_master_to_slave(slave_element::Element{E}, x2, time;
    tol=1.0e-9, max_iterations=5) where {E<:MortarElements2D}

    x1_ = slave_element("geometry", time)
    n1_ = slave_element("normal", time)
    cross2(a, b) = cross([a; 0.0], [b; 0.0])[3]
    x1(xi1) = interpolate(vec(get_basis(slave_element, [xi1], time)), x1_)
    dx1(xi1) = interpolate(vec(get_dbasis(slave_element, [xi1], time)), x1_)
    n1(xi1) = interpolate(vec(get_basis(slave_element, [xi1], time)), n1_)
    dn1(xi1) = interpolate(vec(get_dbasis(slave_element, [xi1], time)), n1_)
    R(xi1) = cross2(x1(xi1)-x2, n1(xi1))
    dR(xi1) = cross2(dx1(xi1), n1(xi1)) + cross2(x1(xi1)-x2, dn1(xi1))

    xi1 = 0.0
    dxi1 = 0.0
    for i=1:max_iterations
        dxi1 = -R(xi1)/dR(xi1)
        xi1 += dxi1
        if norm(dxi1) < tol
            return xi1
        end
    end

    len = norm(x1_[2] - x1_[1])
    midpnt = mean(x1_)
    dist = norm(midpnt - x2)
    distval = dist/len
    @info("Projection from the master element to the slave failed.")
    @info("Arguments:")
    @info("Time: $time")
    @info("Point to project to the slave element: (x2): $x2")
    @info("Slave element geometry (x1): $x1_")
    @info("Slave element normal direction (n1): $n1_")
    @info("Midpoint of slave element: $midpnt")
    @info("Length of slave element: $len")
    @info("Distance between midpoint of slave element and x2: $dist")
    @info("Distance/Lenght-ratio: $distval")
    @info("Number of iterations: $max_iterations")
    @info("Wanted convergence tolerance: $tol")
    @info("Achieved convergence tolerance: $(norm(dxi1))")
    error("Failed to project point to slave surface in $max_iterations.")
end

function project_from_slave_to_master(master_element::Element{E}, x1, n1, time;
    max_iterations=5, tol=1.0e-9) where {E<:MortarElements2D}
    x2_ = master_element("geometry", time)
    x2(xi2) = interpolate(vec(get_basis(master_element, [xi2], time)), x2_)
    dx2(xi2) = interpolate(vec(get_dbasis(master_element, [xi2], time)), x2_)
    cross2(a, b) = cross([a; 0], [b; 0])[3]
    R(xi2) = cross2(x2(xi2)-x1, n1)
    dR(xi2) = cross2(dx2(xi2), n1)
    xi2 = 0.0
    dxi2 = 0.0
    for i=1:max_iterations
        dxi2 = -R(xi2)/dR(xi2)
        xi2 += dxi2
        if norm(dxi2) < tol
            return xi2
        end
    end
    error("Failed to project point to master surface in $max_iterations iterations.")
end


function calculate_normals(elements::Vector{Element{Seg2}}, time; rotate_normals=false)

    normals = Dict{Int64, Vector{Float64}}()

    for element in elements
        X1, X2 = element("geometry", time)
        t1, t2 = (X2-X1)/norm(X2-X1)
        normal = [-t2, t1]
        for j in get_connectivity(element)
            normals[j] = get(normals, j, zeros(2)) + normal
        end
    end

    s = rotate_normals ? -1.0 : 1.0
    for j in keys(normals)
        normals[j] = s*normals[j]/norm(normals[j])
    end

    return normals
end


function FEMBase.assemble_elements!(problem::Problem{Mortar2D}, assembly::Assembly,
                                    elements::Vector{Element{Seg2}}, time::Float64)

    slave_elements = get_slave_elements(problem)

    props = problem.properties
    field_dim = get_unknown_field_dimension(problem)
    field_name = get_parent_field_name(problem)

    # 1. calculate nodal normals for slave element nodes j ∈ S
    normals = calculate_normals([slave_elements...], time)
    update!(slave_elements, "normal", time => normals)

    # 2. loop all slave elements
    for slave_element in slave_elements

        nsl = length(slave_element)
        X1 = slave_element("geometry", time)
        n1 = slave_element("normal", time)

        # 3. loop all master elements
        for master_element in get_master_elements(problem)

            nm = length(master_element)
            X2 = master_element("geometry", time)

            # 3.1 calculate segmentation
            xi1a = project_from_master_to_slave(slave_element, X2[1], time)
            xi1b = project_from_master_to_slave(slave_element, X2[2], time)
            xi1 = clamp.([xi1a; xi1b], -1.0, 1.0)
            l = 1/2*abs(xi1[2]-xi1[1])
            isapprox(l, 0.0) && continue # no contribution in this master element

            # 3.3. loop integration points of one integration segment and calculate
            # local mortar matrices
            De = zeros(nsl, nsl)
            Me = zeros(nsl, nm)
            fill!(De, 0.0)
            fill!(Me, 0.0)
            for ip in get_integration_points(slave_element, 2)
                detJ = slave_element(ip, time, Val{:detJ})
                w = ip.weight*detJ*l
                xi = ip.coords[1]
                xi_s = dot([1/2*(1-xi); 1/2*(1+xi)], xi1)
                N1 = vec(get_basis(slave_element, xi_s, time))
                Phi = N1
                # project gauss point from slave element to master element in direction n_s
                X_s = interpolate(N1, X1) # coordinate in gauss point
                n_s = interpolate(N1, n1) # normal direction in gauss point
                xi_m = project_from_slave_to_master(master_element, X_s, n_s, time)
                N2 = vec(get_basis(master_element, xi_m, time))
                X_m = interpolate(N2, X2)
                De += w*Phi*N1'
                Me += w*Phi*N2'
            end

            sdofs = get_gdofs(problem, slave_element)
            mdofs = get_gdofs(problem, master_element)

            # add contribution to contact virtual work and constraint matrix
            for i=1:field_dim
                lsdofs = sdofs[i:field_dim:end]
                lmdofs = mdofs[i:field_dim:end]
                add!(problem.assembly.C1, lsdofs, lsdofs, De)
                add!(problem.assembly.C1, lsdofs, lmdofs, -Me)
                add!(problem.assembly.C2, lsdofs, lsdofs, De)
                add!(problem.assembly.C2, lsdofs, lmdofs, -Me)
            end

        end # master elements done

    end # slave elements done, contact virtual work ready

    return nothing

end

function get_mortar_matrix_D(problem::Problem{Mortar2D})
    s = get_slave_dofs(problem)
    C2 = sparse(problem.assembly.C2)
    return sparse(problem.assembly.C2)[s,s]
end

function get_mortar_matrix_M(problem::Problem{Mortar2D})
    m = get_master_dofs(problem)
    s = get_slave_dofs(problem)
    C2 = sparse(problem.assembly.C2)
    return -C2[s,m]
end

function get_mortar_matrix_P(problem::Problem{Mortar2D})
    m = get_master_dofs(problem)
    s = get_slave_dofs(problem)
    C2 = sparse(problem.assembly.C2)
    D_ = C2[s,s]
    M_ = -C2[s,m]
    P = cholesky(1/2*(D_ + D_')) \ M_
    return P
end

""" Eliminate mesh tie constraints from matrices K, M, f. """
function FEMBase.eliminate_boundary_conditions!(problem::Problem{Mortar2D}, K, M, f)

    m = get_master_dofs(problem)
    s = get_slave_dofs(problem)
    P = get_mortar_matrix_P(problem)
    ndim = size(K, 1)
    Id = ones(ndim)
    Id[s] .= 0.0
    Q = sparse(Diagonal(Id))
    Q[m,s] .+= P'
    K[:,:] .= Q*K*Q'
    M[:,:] .= Q*M*Q'
    f[:] .= Q*f

    return true
end
