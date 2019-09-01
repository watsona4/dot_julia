# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

"""
    get_beam_stiffness_matrix_2d(X1, X2, E, I, A)

Function integrates stiffness matrix for 6 DOF Euler-Bernoulli beam element.

X1 = beams left node coordinates
X2 = beams right node coordinates
E = Young's modulus
I = Moment of inertia
A = Cross section area
"""
function get_beam_stiffness_matrix_2d(X1,X2,E,I,A)
    le=norm(X2-X1)                      # Lenght of element
    a=atan((X2[2]-X1[2])/(X2[1]-X1[1])) # Rotation angle of the element
    nn=2                                # Number of nodes
    nd=3*1+3                            # Number of DOFs
    Gp=[-1/3*sqrt(5+2*sqrt(10/7)) -1/3*sqrt(5-2*sqrt(10/7)) 0 1/3*sqrt(5-2*sqrt(10/7)) 1/3*sqrt(5+2*sqrt(10/7))] # Five Gauss integration points
    w=[(322-13*sqrt(70))/900 (322+13*sqrt(70))/900 128/225 (322+13*sqrt(70))/900 (322-13*sqrt(70))/900] # Five Gauss integration weights
    # Rotation matrix
    B=[cos(a) sin(a) 0  0     0       0;
      -sin(a) cos(a) 0  0     0       0;
       0      0      1  0     0       0;
       0      0      0  cos(a) sin(a) 0;
       0      0      0 -sin(a) cos(a) 0;
       0      0      0  0      0      1]
    # Integration of the truss elements stiffness matrix
    detJ=2/le
    function tkint(wi::Float64, ::Float64)
        dN1=-1/2
        dN2=1/2
        dN=[dN1 dN2]
        return wi*dN'*dN
    end
    tk=zeros(2,2)
    for i = 1:size(Gp,2)
        tk +=tkint(w[i],Gp[i])
    end
    tk=detJ*A*E*tk
    # Integration of the 4 DOF beam elments stiffness matrix
    detJ=(2/le)^3
    function bkint(wi::Float64, xi::Float64)
        d2N1=(-1.0)*(1 - xi) + 0.5*(2 + xi)
        d2N2=(-1/2)*le*(1 - xi) + (1/4)*le*(1 + xi)
        d2N3=(-1.0)*(1 + xi) + 0.5*(2 - xi)
        d2N4=(1/4)*le*(-1 + xi) + (1/2)*le*(1 + xi)
        d2N=[d2N1 d2N2 d2N3 d2N4]
        return wi*d2N'*d2N
    end
    bk=zeros(4,4)
    for i = 1:size(Gp,2)
        bk +=bkint(w[i],Gp[i])
    end
    bk=E*I*detJ*bk
    # Assembly of 6 DOF truss-beam stiffness matrix k
    k=zeros(6,6)
    k[1,1]=tk[1,1]; k[1,4]=tk[1,2]; k[4,1]=tk[2,1]; k[4,4]=tk[2,2]
    k[2,2]=bk[1,1];k[2,3]=bk[1,2];k[2,5]=bk[1,3];k[2,6]=bk[1,4]
    k[3,2]=bk[2,1];k[3,3]=bk[2,2];k[3,5]=bk[2,3];k[3,6]=bk[2,4]
    k[5,2]=bk[3,1];k[5,3]=bk[3,2];k[5,5]=bk[3,3];k[5,6]=bk[3,4]
    k[6,2]=bk[4,1];k[6,3]=bk[4,2];k[6,5]=bk[4,3];k[6,6]=bk[4,4]
    # Rotation
    k=B'*k*B
    return k
end
