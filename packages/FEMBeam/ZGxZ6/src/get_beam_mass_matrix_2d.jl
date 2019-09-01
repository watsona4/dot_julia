# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

"""
    get_beam_mass_matrix_2d(X1, X2, A, ro)

Function integrates mass matrix for 6 DOF Euler-Bernoulli beam element in 2d.

X1 = beams left node coordinates
X2 = beams right node coordinates
A = Cross section area
ro = Density
"""
function get_beam_mass_matrix_2d(X1,X2,A,ro)
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
    # Integration of the truss mass matrix tm
    detJ=le/2
    function tmint(wi::Float64, xi::Float64)
        N1s=1+(-1/2)*(1+xi)
        N2s=(1/2)*(1 + xi)
        Ns=[N1s N2s]
        return wi*Ns'*Ns
    end
    tm=zeros(2,2)
    for i = 1:size(Gp,2)
        tm +=tmint(w[i],Gp[i])
    end
    tm=ro*A*tm*detJ
    # Integration of the beam mass matrix bm
    detJ=(le/2)
    function bmint(wi::Float64, xi::Float64)
        N1=1/4*(1-xi)^2*(2+xi)
        N2=le/8*(1-xi)^2*(xi+1)
        N3=1/4*(1+xi)^2*(2-xi)
        N4=le/8*(1+xi)^2*(xi-1)
        N=[N1 N2 N3 N4]
        return wi*N'*N
    end
    bm=zeros(4,4)
    for i = 1:size(Gp,2)
        bm +=bmint(w[i],Gp[i])
    end
    bm=ro*A*bm*detJ
    # Assembly of the 6 DOF truss-beam mass matrix m
    m=zeros(6,6)
    m[1,1]=tm[1,1];m[1,4]=tm[1,2];m[4,1]=tm[2,1];m[4,4]=tm[2,2]
    m[2,2]=bm[1,1];m[2,3]=bm[1,2];m[2,5]=bm[1,3];m[2,6]=bm[1,4]
    m[3,2]=bm[2,1];m[3,3]=bm[2,2];m[3,5]=bm[2,3];m[3,6]=bm[2,4]
    m[5,2]=bm[3,1];m[5,3]=bm[3,2];m[5,5]=bm[3,3];m[5,6]=bm[3,4]
    m[6,2]=bm[4,1];m[6,3]=bm[4,2];m[6,5]=bm[4,3];m[6,6]=bm[4,4]
    # Rotation
    m=B'*m*B
    return m
end
