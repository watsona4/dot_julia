export Beam

mutable struct Beam <: AbstractElement
    id::String
    hid::Int
    node1::Node
    node2::Node
    material::Material
    section::BeamSection

    release::Vector{Bool}

    elm_type::String
    mass_type::String

    center::Vector{Float64}
    l::Float64
    T::Matrix{Float64} #transform_matrix
end

function Beam(id,hid,node1,node2,material,section;elm_type="eular_shear",mass_type="concentrate")
    tol=1e-6
    o=node1.loc
    pt1=node2.loc
    pt2=node1.loc
    if abs(pt2[1]-pt1[1])<tol && abs(pt2[2]-pt1[2])<tol
        pt2=pt2.+[1,0,0]
    else
        pt2=pt2.+[0,0,1]
    end
    csys=CSys(o,pt1,pt2)
    T=zeros(12,12)
    T[1:3,1:3]=T[4:6,4:6]=T[7:9,7:9]=T[10:12,10:12]=csys.T
    l=norm(node1.loc-node2.loc)
    release=Bool.(zeros(12))
    Beam(string(id),hid,node1,node2,material,section,release,elm_type,mass_type,(pt1+pt2)/2,l,T)
end

for (root,dirs,files) in walkdir(joinpath(@__DIR__,"beams"))
    for file in files
        if file[end-2:end]==".jl"
            include(joinpath(@__DIR__,"beams",file))
        end
    end
end

function integrateK(beam::Beam)::Matrix{Float64}
    if beam.elm_type=="eular_shear"
        return K_eular_shear(beam::Beam)
    end
end

function integrateKσ(beam::Beam,σ::Vector{Float64})::Matrix{Float64}
    if beam.elm_type=="eular_shear"
        return K2_eular_shear(beam::Beam)
    end
end

function static_condensation(K,P,rDOF::Vector{Int})
    if isempty(rDOF)
        return K,P
    end
    i=[!(x in rDOF) for x in 1:12]
    j=[(x in rDOF) for x in 1:12]
    Kᵢᵢ=K[i,i]
    Kᵢⱼ=K[i,j]
    Kⱼᵢ=K[j,i]
    Kⱼⱼ=K[j,j]
    Kⱼⱼ⁻¹=inv(Kⱼⱼ)
    Pⱼ=P[j]
    Pᵢ=P[i]
    Kᶜ=zero(K)
    Pᶜ=zero(P)
    Kᶜ[i,i]=Kᵢᵢ-Kᵢⱼ*Kⱼⱼ⁻¹*Kⱼᵢ
    Pᶜ[i]=Pᵢ-Kᵢⱼ*Kⱼⱼ⁻¹*Pⱼ
    return Kᶜ,Pᶜ
end

function integrateM(beam::Beam)::Matrix{Float64}
    E,ν=beam.material.E,beam.material.ν
    A,I₂,I₃,J,l=beam.section.A,beam.section.I₂,beam.section.I₃,beam.section.J,beam.l
    ρ=beam.material.ρ
    if beam.mass_type=="concentrate"
        return Matrix(I,12,12)*12*ρ*A*l/2
    elseif beam.mass_type=="coordinate"
        return Matrix(I,12,12)*12*ρ*A*l/2
    end
end

function calc_force(beam,beamforce)
    f₁,f₂=beamforce.f[1:6],beamforce.f[7:12]
    l=beam.l
    fi,v2i,v3i,ti,m2i,m3i,fj,v2j,v3j,tj,m2j,m3j=beamforce.f
    Nᵀf(x)=[
          0;
    (1 - 3*x^2 + 2*x^3)*(v2i + x*(-v2i + v2j));
    (1 - 3*x^2 + 2*x^3)*(v3i + x*(-v3i + v3j));
          0;
    l*(x - 2*x^2 + x^3)*(v3i + x*(-v3i + v3j));
    l*(x - 2*x^2 + x^3)*(v2i + x*(-v2i + v2j));
          0;
        (3*x^2 - 2*x^3)*(v2i + x*(-v2i + v2j));
        (3*x^2 - 2*x^3)*(v3i + x*(-v3i + v3j));
         0;
         l*(-x^2 + x^3)*(v3i + x*(-v3i + v3j));
         l*(-x^2 + x^3)*(v2i + x*(-v2i + v2j));
   ]*l

   Nᵀf2(x)=[
         -0.5*(-1 + x)*(fi + (1+x)/2*(-fi + fj));0;0;
         -0.5*(-1 + x)*(ti + (1+x)/2*(-ti + tj));0;0;
           0.5*(1 + x)*(fi + (1+x)/2*(-fi + fj));0;0;
           0.5*(1 + x)*(ti + (1+x)/2*(-ti + tj));0;0
  ]*l/2

    Pᵉ_f=hquadrature(Nᵀf,0,1)[1]+hquadrature(Nᵀf2,-1,1)[1]#Pᵉf=∫NᵀfdV #体积力

    Pᵉ_s=beamforce.s# Pᵉs=∫NᵀTdS #边界力

    f₁,f₂=beamforce.σ₀[1],beamforce.σ₀[2]
    Bᵀσ₀(x)=[-0.5*(f₁+0.5*(x+1)*(-f₁+f₂));
              0.5*(f₁+0.5*(x+1)*(-f₁+f₂))]*beam.l/2
    a,b=hquadrature(Bᵀσ₀,-1,1)[1]# Pᵉσ₀=-∫Bᵀσ₀dV #初应力
    Pᵉ_σ₀=[a,0,0,0,0,0,b,0,0,0,0,0]

    f₁,f₂=beamforce.ϵ₀[1],beamforce.ϵ₀[2]
    BᵀDϵ₀(x)=[-0.5*(f₁+0.5*(x+1)*(-f₁+f₂));
               0.5*(f₁+0.5*(x+1)*(-f₁+f₂))]*beam.l/2
    a,b=hquadrature(BᵀDϵ₀,-1,1)[1]*beam.material.E*beam.section.A# Pᵉϵ₀=∫BᵀDϵ₀dV #初应变
    Pᵉ_ϵ₀=[a,0,0,0,0,0,b,0,0,0,0,0]
    return Pᵉ_f,Pᵉ_s,Pᵉ_σ₀,Pᵉ_ϵ₀
end

function integrateP(beam::Beam,beam_force)::Vector{Float64}
    Pfᵉ,Psᵉ,Pσ₀ᵉ,Pϵ₀ᵉ=calc_force(beam,beam_force) #Pᵉ=Pᵉf+Pᵉs+Pᵉσ₀+Pᵉϵ₀
    return reshape(Pfᵉ+Psᵉ+Pσ₀ᵉ+Pϵ₀ᵉ,12)
end

# end
