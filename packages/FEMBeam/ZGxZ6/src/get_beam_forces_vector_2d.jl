# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

"""
    get_beam_forces_vector_2d(X1, X2, qt, qn, f)

Function integrates forces vector for 6 DOF Euler-Bernoulli beam element in 2D.

X1 = beams left node coordinates
X2 = beams right node coordinates
qt = Tangential uniformly distributed load
qn = Normal uniformly distributed load
f = Point forces vector in global coordinates
"""
function get_beam_forces_vector_2d(X1, X2, qt, qn, f)
    le=norm(X2-X1)                      # Lenght of element
    a=atan((X2[2]-X1[2])/(X2[1]-X1[1])) # Rotation angle of the element
    nn=2                            # Number of nodes
    nd=3*1+3                           # Number of DOFs
    Gp=[-1/3*sqrt(5+2*sqrt(10/7)) -1/3*sqrt(5-2*sqrt(10/7)) 0 1/3*sqrt(5-2*sqrt(10/7)) 1/3*sqrt(5+2*sqrt(10/7))] # Five Gauss integration points
    w=[(322-13*sqrt(70))/900 (322+13*sqrt(70))/900 128/225 (322+13*sqrt(70))/900 (322-13*sqrt(70))/900] # Five Gauss integration weights
    # Rotation matrix
    B=[cos(a) sin(a) 0  0     0       0;
      -sin(a) cos(a) 0  0     0       0;
       0      0      1  0     0       0;
       0      0      0  cos(a) sin(a) 0;
       0      0      0 -sin(a) cos(a) 0;
       0      0      0  0      0      1]
    # Integration of the equivalent forces vector
    # For truss element tfq
    detJ=le/2
    function tfqint(wi::Float64, xi::Float64)
        N1s=1+(-1/2)*(1+xi)
        N2s=(1/2)*(1 + xi)
        Ns=[N1s N2s]
        return wi*Ns'
    end
    tfq=zeros(2,1)
    for i = 1:size(Gp,2)
        tfq +=tfqint(w[i],Gp[i])
    end
    tfq=qn*tfq*detJ
    # For 4 DOF beam element bfqe
    detJ=le/2
    function bfqint(wi::Float64, xi::Float64)
        N1=1/4*(1-xi)^2*(2+xi)
        N2=le/8*(1-xi)^2*(xi+1)
        N3=1/4*(1+xi)^2*(2-xi)
        N4=le/8*(1+xi)^2*(xi-1)
        N=[N1 N2 N3 N4]
        return wi*N'
    end
    bfq=zeros(4,1)
    for i = 1:size(Gp,2)
        bfq +=bfqint(w[i],Gp[i])
    end
    bfq=qt*bfq*detJ
    # Assembly of the 6 DOF beam element equivalent forces vector fqe
    fqe=zeros(6,1)
    fqe[1,1],fqe[4,1]=tfq[1,1],tfq[2,1]
    fqe[2,1],fqe[3,1],fqe[5,1],fqe[6,1]=bfq[1,1],bfq[2,1],bfq[3,1],bfq[4,1]
    # Rotation
    fqe=B'*fqe
    # Adding equivalent forces vector to point forces vector
    f +=fqe
    return f
end
