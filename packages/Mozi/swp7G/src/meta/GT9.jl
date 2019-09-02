using SymEngine
using HCubature
using LinearAlgebra

function L₂(X;x=symbols("x"),y=symbols("y"))
    res=Matrix{SymEngine.Basic}(undef,3,size(X,2))
    for i in 1:size(X,2)
        res[1,i]=diff(X[1,i],x)
        res[2,i]=diff(X[2,i],y)
        res[3,i]=diff(X[1,i],y)+diff(X[2,i],x)
    end
    return res
end

x,y=symbols("x,y")
xᵢ=symbols("x₁ x₂ x₃")
yᵢ=symbols("y₁ y₂ y₃")
#T9G9
A=symbols("A")

# aᵢ=[y[j]-y[m] for (j,m) in zip([2,3,1],[3,1,2])]
# bᵢ=[y[j]-y[m] for (j,m) in zip([2,3,1],[3,1,2])]
# cᵢ=[-x[j]+x[m] for (j,m) in zip([2,3,1],[3,1,2])]
aᵢ=symbols("a₁ a₂ a₃")
bᵢ=symbols("b₁ b₂ b₃")
cᵢ=symbols("c₁ c₂ c₃")
Lᵢ=1/2/A .*(aᵢ .+bᵢ .*x .+cᵢ .*y)
Nᵤᵨᵢ=[0.5*Lᵢ[i]*(bᵢ[m]*Lᵢ[j]-bᵢ[j]*Lᵢ[m]) for (i,j,m) in zip([1,2,3],[2,3,1],[3,1,2])]
Nᵥᵨᵢ=[0.5*Lᵢ[i]*(cᵢ[m]*Lᵢ[j]-cᵢ[j]*Lᵢ[m]) for (i,j,m) in zip([1,2,3],[2,3,1],[3,1,2])]

Nᵢ=Array{Basic}(undef,2,9)
for i in 1:3
    Nᵢ[:,3i-2:3i]=[Lᵢ[i] 0 Nᵤᵨᵢ[i];
                   0 Lᵢ[i] Nᵥᵨᵢ[i]]
end
B=L₂(Nᵢ)
D₀=E₀/(1-ν₀^2)
D=D₀*[1 ν₀ 0;
      ν₀ 1 0;
      0  0 (1-ν₀)/2]

K=transpose(B)*D*B
open("./k_GT9.jl","w+") do f
    for i in 1:size(K,1)
        for j in 1:size(K,2)
            write(f,"K["*string(i)*","*string(j)*"]="*string(K[i,j])*"\n")
        end
    end
end
