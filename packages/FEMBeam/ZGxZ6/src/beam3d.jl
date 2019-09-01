# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

"""
    Beam - Euler-Bernoulli beam for 3d problems

# Load types for distributed load
- P1 and P1 for loads in beam normal 1 and normal 2 direction
- PX, PY, PZ for loads in global coordinate system
"""
struct Beam <: FieldProblem end

FEMBase.get_unknown_field_name(::Problem{Beam}) = "displacement"

function FEMBase.get_integration_points(::Problem{Beam}, ::Element{Seg2})
    return FEMBase.get_quadrature_points(Val{:GLSEG3})
end

"""
    get_rotation_matrix(X1, X2, n_1)

Given element coordinates ``X_1``, ``X_2``  and the first beam section axis
``n1``, return rotation matrix ``R``, which can be used to define the
orientation of the beam cross-section.

The orientation of a beam cross-section is defined in terms of local,
right-handed ``(t, n_1, n_2)`` axis system, where ``t`` is the tangent to the
axis of the element, positive in the direction from the first to the second node
of the element, and ``n_1`` and ``n_2`` are basis vectors that define the local
1- and 2-directions of the cross section. ``n_1`` is referred to as the first
beam section axis, and ``n_2`` is referred to as the normal to the beam.

Notice that rotation matrix is made of three row vectors which must be linearly
independent. That is, if tangent vector ``t`` is parallel to ``n_1``, rotation
matrix cannot be defined because ``t × n_2 = 0``.

Connection to 2d-beams: for beams in a plane the `n_1`-direction is always
``(0.0, 0.0, -1.0)``, which is normal to the plane in which the motion occurs.
therefore, planar beams can bend only about the first beam section axis.
"""
function get_rotation_matrix(X1, X2, n1)
    t = X2-X1
    L = norm(t)
    a = L/2.0
    Pe = [2.0*a 0.0 0.0; 0.0 0.0 -2.0*a; 0.0 1.0 0.0]
    n2 = cross(t, n1)
    if iszero(n2)
        error("get_rotation_matrix(X1, X2, n1) = get_rotation_matrix($X1, $X2, $n1) ",
              "is failing because the first beam section axis n1 is parallel ",
              "to the tangent vector t. To fix this issue and construct an ",
              "orthonormal set of linearly independent basis vectors, choose ",
              "n1 such that cross-product t × n1 gives a non-zero answer. Now, ",
              "cross($t, $n1) = $n2.")
    end
    Pg = [t n1 n2]
    T = Pe*inv(Pg)
    return T
end

function FEMBase.assemble_elements!(problem::Problem{Beam}, assembly::Assembly,
                                    elements::Vector{Element{Seg2}}, time::Float64)

    B = zeros(4, 12)
    N = zeros(6, 12)
    D = zeros(4, 4)
    Ke = zeros(12, 12)
    Me = zeros(12, 12)
    fe = zeros(12)
    b_loc = zeros(6)
    b_glob = zeros(6)
    Rho = zeros(6,6)

    for element in elements
        fill!(Ke, 0.0)
        fill!(Me, 0.0)
        fill!(fe, 0.0)

        for (w, xi) in get_integration_points(problem, element)

            X1, X2 = element("geometry", time)
            L = norm(X2-X1)

            if haskey(element, "orientation")
                T = element("orientation", xi, time)
            elseif haskey(element, "normal")
                n1 = element("normal", xi, time)
                T = get_rotation_matrix(X1, X2, n1)
            end

            Z = zeros(3,3)
            Rd = [T Z Z Z; Z T Z Z; Z Z T Z; Z Z Z T]
            Rf = [T Z; Z T]
            detJ = L/2.0
            s = 2.0/L

            fill!(B, 0.0)
            fill!(b_loc, 0.0)
            fill!(b_glob, 0.0)
            fill!(N, 0.0)
            fill!(D, 0.0)
            fill!(Rho, 0.0)

            N1 = -xi/2 + 1/2
            N2 =  xi/2 + 1/2
            dN1 = -1/2*s
            dN2 =  1/2*s

            M1 = xi^3/4 - 3*xi/4 + 1/2
            M2 = -xi^3/4 + 3*xi/4 + 1/2
            dM1 =  (3*xi^2/4 - 3/4)*s
            dM2 = (-3*xi^2/4 + 3/4)*s
            d2M1 = 3*xi/2*s^2
            d2M2 = -3*xi/2*s^2

            L1 = (xi^3/4 - xi^2/4 - xi/4 + 1/4)/s
            L2 = (xi^3/4 + xi^2/4 - xi/4 - 1/4)/s
            dL1 = (3*xi^2/4 - xi/2 - 1/4)
            dL2 = (3*xi^2/4 + xi/2 - 1/4)
            d2L1 = (3*xi - 1)/2*s
            d2L2 = (3*xi + 1)/2*s

            # Shape functions N

            # for node 1
            N[1,1] =  N1
            N[2,2] =  M1
            N[6,2] =  dM1
            N[3,3] =  M1
            N[5,3] =  dM1
            N[4,4] =  N1
            N[3,5] = -L1
            N[5,5] = -dL1
            N[2,6] =  L1
            N[6,6] =  dL1

            # for node 2
            N[1,7]  =  N2
            N[2,8]  =  M2
            N[6,8]  =  dM2
            N[3,9]  =  M2
            N[5,9]  = -dM2
            N[4,10] =  N2
            N[3,11] = -L2
            N[5,11] = -dL2
            N[2,12] =  L2
            N[6,12] =  dL2

            # Kinematic matrix B

            # for node 1
            B[1,1] = dN1
            B[2,2] = -d2M1
            B[2,6] = -d2L1
            B[3,3] = -d2M1
            B[3,5] = d2L1
            B[4,4] = dN1

            # for node 2
            B[1,7] = dN2
            B[2,8] = -d2M2
            B[2,12] = -d2L2
            B[3,9] = -d2M2
            B[3,11] = d2L2
            B[4,10] = dN2

            # Material matrix D

            E = element("youngs modulus", xi, time)
            A = element("cross-section area", xi, time)
            I1 = element("torsional moment of inertia 1", xi, time)
            I2 = element("torsional moment of inertia 2", xi, time)
            G = element("shear modulus", xi, time)
            J = element("polar moment of inertia", xi, time)
            D[1,1] = E*A
            D[2,2] = E*I1
            D[3,3] = E*I2
            D[4,4] = G*J

            # Assemble stiffness matrix

            Ke += w * Rd'*(B'*D*B)*Rd * detJ

            # Assemble mass matrix (if density is defined)

            if haskey(element, "density")
                rho = element("density", xi, time)
                Rho[1,1] = rho*A
                Rho[2,2] = rho*A
                Rho[3,3] = rho*A
                Rho[4,4] = rho*J
                #Rho[5,5] = I1 # Looks these have only a very small influence to
                #Rho[6,6] = I2 # result and are neglected in ABAQUS
                Me += w * Rd'*(N'*Rho*N)*Rd * detJ
            end

            # Assemble distributed loads / moments
            if haskey(element, "distributed load 1")
                b_loc[3] = element("distributed load 1", xi, time)
            end
            if haskey(element, "distributed load 2")
                b_loc[2] = element("distributed load 2", xi, time)
            end
            if haskey(element, "distributed load x")
                b_glob[1] = element("distributed load x", xi, time)
            end
            if haskey(element, "distributed load y")
                b_glob[2] = element("distributed load y", xi, time)
            end
            if haskey(element, "distributed load z")
                b_glob[3] = element("distributed load z", xi, time)
            end

            fe += w * Rd'*N'*Rf*b_loc * detJ
            fe += w * N'*b_glob * detJ
        end
        gdofs = get_gdofs(problem, element)
        add!(assembly.K, gdofs, gdofs, Ke)
        add!(assembly.M, gdofs, gdofs, Me)
        add!(assembly.f, gdofs, fe)
    end

    return nothing

end

function FEMBase.assemble_elements!(problem::Problem{Beam}, assembly::Assembly,
                                    elements::Vector{Element{Poi1}}, time::Float64)

    for element in elements
        gdofs = get_gdofs(problem, element)
        for i=1:3
            if haskey(element, "point force $i")
                P = element("point force $i", time)
                add!(assembly.f, gdofs[i], P)
            end
            if haskey(element, "point moment $i")
                P = element("point moment $i", time)
                add!(assembly.f, gdofs[3+i], P)
            end
            if haskey(element, "fixed displacement $i")
                g = element("fixed displacement $i", time)
                add!(assembly.C1, gdofs[i], gdofs[i], 1.0)
                add!(assembly.C2, gdofs[i], gdofs[i], 1.0)
                add!(assembly.g, gdofs[i], g)
            end
            if haskey(element, "fixed rotation $i")
                g = element("fixed rotation $i", time)
                add!(assembly.C1, gdofs[3+i], gdofs[3+i], 1.0)
                add!(assembly.C2, gdofs[3+i], gdofs[3+i], 1.0)
                add!(assembly.g, gdofs[3+i], g)
            end
        end
    end

    return nothing

end
