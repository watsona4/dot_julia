#Reference
#岑松, 龙志飞, 对转角场和剪应变场进行合理插值的厚板元[J]. 工程力学, 1998,15(3): 1―14.
function K_TMT(elm::Tria)::Matrix{Float64}
    E₀,ν₀=elm.material.E,elm.material.ν
    G₀=elm.material.G
    center=elm.center
    t=elm.t
    T=elm.T[1:3,1:3]
    x₁,y₁,z₁=T*(elm.node1.loc-center)
    x₂,y₂,z₂=T*(elm.node2.loc-center)
    x₃,y₃,z₃=T*(elm.node3.loc-center)
    K=Matrix{Float64}(undef,12,12)
    A=elm.A
    a₁,a₂,a₃=[xᵢ[j]*yᵢ[m]-xᵢ[m]*yᵢ[j] for (j,m) in zip([2,3,1],[3,1,2])]
    b₁,b₂,b₃=[yᵢ[j]-yᵢ[m] for (j,m) in zip([2,3,1],[3,1,2])]
    c₁,c₂,c₃=[-xᵢ[j]+xᵢ[m] for (j,m) in zip([2,3,1],[3,1,2])]
    l₁=norm(elm.node3.loc-elm.node2.loc)
    l₂=norm(elm.node1.loc-elm.node3.loc)
    l₃=norm(elm.node1.loc-elm.node2.loc)

    δ₁=(t/d₁)^2/(5/6*(1-ν₀)+2*(t/d₁)^2)
    δ₂=(t/d₂)^2/(5/6*(1-ν₀)+2*(t/d₂)^2)
    δ₃=(t/d₃)^2/(5/6*(1-ν₀)+2*(t/d₃)^2)



    F=-3/2/A*[c₁/l₁^2*(b₂*L₃+b₃*L₂) c₂/l₂^2*(b₃*L₁+b₁*L₃) c₃/l₃^2*(b₁*L₂+b₂*L₁);
             -b₁/l₁^2*(c₂*L₃+c₃*L₂) -b₂/l₂^2*(c₃*L₁+c₁*L₃) -b₃/l₃^2*(c₁*L₂+c₂*L₁);
             M₁ M₂ M₃]

    Δ=[1-2δ₁ 0 0;
       0 1-2δ₂ 0;
       0 0 1-2δ₃]

    G=[0 0 0 -2 -c₁ b₁ 2 -c₁ b₁;
       2 -c₂ b₂ 0 0 0 -2 -c₂ b₂;
       -2 -c₃ b₃ 2 -c₃ b₃ 0 0 0]

    Bb⁰=-1/2/A*[0 b₁ 0 0 b₂ 0 0 b₃ 0;
               0 0 c₁ 0 0 c₂ 0 0 c₃;
               0 c₁ b₁ 0 c₂ b₂ 0 c₃ b₃]

    FDG=F*Δ*G

    Bb=Bb⁰+FDG

    Δʼ=[δ₁ 0 0;
        0 δ₂ 0;
        0 0 δ₃]

    D₀=E₀*t^3/12/(1-ν₀^2)
    D=D₀*[1 ν₀ 0;
          ν₀ 1 0;
          0  0 (1-ν₀)/2]
    k=5/6

    function BtDB(x)
        x,y=x[1],x[2]
        L₁=1/2/A*(a₁+b₁*x+c₁*y)
        L₂=1/2/A*(a₂+b₂*x+c₂*y)
        L₃=1/2/A*(a₃+b₃*x+c₃*y)

        M₁=1/l₁^2*((c₁*c₂-b₁*b₂)*L₃+(c₃*c₁-b₃*b₁)*L₂)
        M₂=1/l₂^2*((c₂*c₃-b₂*b₃)*L₁+(c₁*c₂-b₁*b₂)*L₃)
        M₁=1/l₃^2*((c₃*c₁-b₃*b₁)*L₂+(c₂*c₃-b₂*b₃)*L₁)

        H=1/2/A*[b₃*L₂-b₂*L₃ b₁*L₃-b₃*L₁ b₂*L₁-b₁*L₂;
                 c₃*L₂-c₂*L₃ c₁*L₃-c₃*L₁ c₂*L₁-c₁*L₂]

        Bs=H*Δʼ*G

        C=k*G₀*t*[1 0;0 1]

        Kb=transpose(Bb)*D*Bb
        Ks=transpose(Bs)*C*Bs
        K=Kb+Ks
    end
    K=hcubature(BtDB,[-1,-1],[1,1])[1]
    # #left-hand system to right-hand system
    # I=1:9
    # J=[1,3,2,4,6,5,7,9,8,10,12,11]
    # L=sparse(I,J,1.,12,12)
    # for i in [1,3,4,6,7,9,10,12]
    #     for j in [2,5,8,11]
    #         K[i,j]=K[j,i]=-K[i,j]
    #     end
    # end
    # K=L'*sparse(K)*L
    #9x9 to 18x18
    I=1:9
    J=[3,4,5,9,10,11,15,16,17]
    L=sparse(I,J,1.,9,18)
    return L'*K*L
end
