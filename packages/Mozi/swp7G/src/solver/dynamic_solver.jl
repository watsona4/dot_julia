include("../util/numeric.jl")

function solve_modal_eigen(structure,loadcase,restrainedDOFs::Vector{Int};path=pwd())
    @info "-------------------------- 求解自振模态特征值 --------------------------" 工况=loadcase.id 前一步基础工况=loadcase.plc
    K=structure.K
    P=loadcase.P
    u=zero(P)
    F₀=zero(P)
    if loadcase.plc!=""
        u=read_vector(path*"/.analysis",loadcase.plc*"_u.v")
        F₀=read_vector(path*"/.analysis",loadcase.plc*"_F.v")
        Kσ=calc_Kσ(structure,u)
        K=structure.K+Kσ #初始位移及初始刚度来自前一步结果
    end
    K̄=introduce_BC(K,restrainedDOFs)
    M̄=introduce_BC(structure.M,restrainedDOFs)

    nev=min(loadcase.nev,size(M̄,1))
    tol=loadcase.tolev
    maxiter=loadcase.maxiterev

    if size(K̄,1)>512
        ω²,ϕ=eigs(K̄,M̄,nev=nev,which=:SM,tol=tol,maxiter=maxiter)
    else
        eig=eigen(Array(K̄),Array(M̄))
        idx=collect(1:length(eig.values))
        sort!(idx,by=x->eig.values[x])
        ω²=zero(eig.values)
        ϕ=zero(eig.vectors)
        for i in 1:length(idx)
            ω²[i]=eig.values[idx[i]]
            ϕ[:,i]=eig.vectors[:,idx[i]]
        end
        ω²,ϕ=ω²[1:nev],ϕ[:,1:nev]
    end

    @info "------------------------------ 求解完成 ------------------------------"
    return ω²,ϕ
end

function solve_modal_Ritz(structure,loadcase,restrainedDOFs::Vector{Int};path=pwd())
    @info "-------------------------- 求解自振模态Ritz值 -------------------------" 工况=loadcase.id 前一步基础工况=loadcase.plc
    K=structure.K
    P=loadcase.P
    u=zero(P)
    F₀=zero(P)
    if loadcase.plc!=""
        u=read_vector(path*"/.analysis",loadcase.plc*"_u.v")
        F₀=read_vector(path*"/.analysis",loadcase.plc*"_F.v")
        Kσ=calc_Kσ(structure,u)
        K=structure.K+Kσ #初始位移及初始刚度来自前一步结果
    end
    K̄=introduce_BC(K,restrainedDOFs)
    F̄=introduce_BC(P,restrainedDOFs)
    M̄=introduce_BC(structure.M,restrainedDOFs)

    if F̄==zero(F̄)
        F̄.=1
    end

    nev=min(loadcase.nev,length(F̄))
    tol=loadcase.tolev
    maxiter=loadcase.maxiterev

    X=zeros(length(F̄),nev)
    if USE_PARDISO
        ps=Pardiso.MKLPardisoSolver()
        Pardiso.set_matrixtype!(ps,1) #实对称矩阵
        x̂=Pardiso.solve(ps,K̄,F̄)
        x̂=Pardiso.solve(ps,K̄,F̄)
    else
        x̂=Symmetric(K̄) \ F̄
    end
    β=sqrt(x̂'*M̄*x̂)
    X[:,1]=x̂/β
    for i in 2:nev
        if USE_PARDISO
            x̃=Pardiso.solve(ps,K̄,Array(M̄*X[:,i-1]))
        else
            x̃=Symmetric(K̄) \ Array(M̄*X[:,i-1])
        end
        x̂=copy(x̃)
        for j in 1:i-1
            α=x̃'*M̄*X[:,j]
            x̂-=α*X[:,j]
        end
        β=sqrt(x̂'*M̄*x̂)
        X[:,i]=x̂/β
    end
    ω²,ϕ=eigs(X'*K̄*X,X'*M̄*X,nev=nev,which=:SM,tol=tol,maxiter=maxiter) #X'*M̄*X=I?
    @info "------------------------------ 求解完成 ------------------------------"
    return ω²,ϕ
end

function solve_newmark_beta(structure,loadcase,restrainedDOFs::Vector{Int};path=pwd())
    T=loadcase.t
    Δt=(T[end]-T[1])/(length(T)-1)

    β=loadcase.β
    γ=loadcase.γ
    @info "----------------------- 求解Newmark-β法逐步积分 -----------------------" Δt=Δt β=β γ=γ
    K̄=introduce_BC(structure.K,restrainedDOFs)
    M̄=introduce_BC(structure.M,restrainedDOFs)
    C̄=introduce_BC(structure.C,restrainedDOFs)
    P̄=introduce_BC(loadcase.P,restrainedDOFs)
    Q̄=loadcase.f'.*P̄
    u₀=zeros(size(K̄,1))
    v₀=zeros(size(K̄,1))

    if !(β>=0.25*(0.5+γ)^2 && γ>=0.5)
        @warn "算法可能不稳定"
    end
    c₀=1/(β*Δt^2)
    c₁=γ/(β*Δt)
    c₂=1/(β*Δt)
    c₃=1/(2*β)-1
    c₄=γ/β-1
    c₅=Δt/2*(γ/β-2)
    c₆=Δt*(1-γ)
    c₇=γ*Δt

    K̂=K̄+c₀*M̄+c₁*C̄
    LDLᵀ=ldlt(Symmetric(K̂))

    ū=Array{Float64,2}(undef,length(u₀),length(T))
    v̄=Array{Float64,2}(undef,length(v₀),length(T))
    ā=Array{Float64,2}(undef,length(v₀),length(T))
    ū[:,1]=u₀
    v̄[:,1]=v₀
    if USE_PARDISO
        ps=Pardiso.MKLPardisoSolver()
        Pardiso.set_matrixtype!(ps,1)
        a₀=Pardiso.solve(ps,M̄,(Q̄[:,1]-C̄*v₀-K̄*u₀)[:,1])
    else
        a₀=Symmetric(M̄) \ (Q̄[:,1]-C̄*v₀-K̄*u₀)[:,1]
    end

    ā[:,1]=a₀
    for t in 1:length(T)-1
        Q̂=Q̄[:,t+1]+M̄*(c₀*ū[:,t]+c₂*v̄[:,t]+c₃*ā[:,t])+C̄*(c₁*ū[:,t]+c₄*v̄[:,t]+c₅*ā[:,t])
        Q̂=reshape(Q̂,length(Q̂))
        if USE_PARDISO
            ū[:,t+1]=Pardiso.solve(ps,K̂,Q̂) #May LDLT here
        else
            ū[:,t+1]=Symmetric(K̂) \ Q̂
        end
        ā[:,t+1]=c₀*(ū[:,t+1]-ū[:,t])-c₂*v̄[:,t]-c₃*ā[:,t]
        v̄[:,t+1]=v̄[:,t]+c₆*ā[:,t]+c₇*ā[:,t+1]
    end
    @info "------------------------------ 求解完成 ------------------------------"

    u=zeros(size(structure.K,1),length(T))
    v=zeros(size(structure.K,1),length(T))
    a=zeros(size(structure.K,1),length(T))
    for t in 1:length(T)
        u[:,t]=resolve_BC(ū[:,t],restrainedDOFs)
        v[:,t]=resolve_BC(v̄[:,t],restrainedDOFs)
        a[:,t]=resolve_BC(ā[:,t],restrainedDOFs)
    end
    return u,v,a
end

function solve_wilson_theta(structure,loadcase,restrainedDOFs::Vector{Int};path=pwd())
    @info "----------------------- 求解Wilson-θ法逐步积分 -----------------------"
    T=loadcase.t
    Δt=(T[end]-T[1])/(length(T)-1)

    β=loadcase.β
    γ=loadcase.γ
    θ=loadcase.θ

    if !(θ<1.37)
        @warn "算法可能不稳定"
    end

    K̄=introduce_BC(structure.K,restrainedDOFs)
    M̄=introduce_BC(structure.M,restrainedDOFs)
    C̄=introduce_BC(structure.C,restrainedDOFs)
    P̄=introduce_BC(loadcase.P,restrainedDOFs)
    Q̄=loadcase.f'.*P̄
    u₀=zeros(size(K̄,1))
    v₀=zeros(size(K̄,1))

    Δt̄=θ*Δt
    b₁=1/(β*Δt^2)
    b₂=-1/(β*Δt̄)
    b₃=(1/2-β)/β
    b₄=γ*Δt̄*b₁
    b₅=1+γ*Δt̄*b₂
    b₆=Δt̄*(1+γ*b₃-γ)

    K̂=K̄+b₁*M̄+b₄*C̄
    LDLᵀ=ldlt(Symmetric(K̂))

    ū=Array{Float64,2}(undef,length(u₀),length(T))
    v̄=Array{Float64,2}(undef,length(v₀),length(T))
    ā=Array{Float64,2}(undef,length(v₀),length(T))
    ū[:,1]=u₀
    v̄[:,1]=v₀

    if USE_PARDISO
        ps=Pardiso.MKLPardisoSolver()
        Pardiso.set_matrixtype!(ps,1)
        a₀=Pardiso.solve(ps,M̄,(Q̄[:,1]-C̄*v₀-K̄*u₀)[:,1])
    else
        a₀=Symmetric(M̄) \ (Q̄[:,1]-C̄*v₀-K̄*u₀)[:,1]
    end

    ā[:,1]=a₀
    for t in 1:length(T)-1
        Q̂=Q̄[:,t+1]+M̄*(b₁*ū[:,t]+b₂*v̄[:,t]+b₃*ā[:,t])+C̄*(b₄*ū[:,t]+b₅*v̄[:,t]+b₆*ā[:,t])
        Q̂=reshape(Q̂,length(Q̂))
        if USE_PARDISO
            ū[:,t+1]=Pardiso.solve(ps,K̂,Q̂) #May LDLT here
        else
            ū[:,t+1]=Symmetric(K̂) \ Q̂
        end
        v̄[:,t+1]=b₄*(ū[:,t+1]-ū[:,t])+b₅*v̄[:,t]+b₆*ā[:,t]
        ā[:,t+1]=b₁*(ū[:,t+1]-ū[:,t])+b₂*v̄[:,t]+b₃*ā[:,t]

        ā[:,t+1]=ā[:,t]+1/θ*(ā[:,t+1]-ā[:,t])
        v̄[:,t+1]=v̄[:,t]+((1-γ)*ā[:,t]+γ*ā[:,t+1])*Δt
        ū[:,t+1]=ū[:,t]+v̄[:,t]*Δt
    end
    @info "------------------------------ 求解完成 ------------------------------"

    u=zeros(size(structure.K,1),length(T))
    v=zeros(size(structure.K,1),length(T))
    a=zeros(size(structure.K,1),length(T))
    for t in 1:length(T)
        u[:,t]=resolve_BC(ū[:,t],restrainedDOFs)
        v[:,t]=resolve_BC(v̄[:,t],restrainedDOFs)
        a[:,t]=resolve_BC(ā[:,t],restrainedDOFs)
    end
    return u,v,a
end

#not finished

function solve_HHT_alpha(structure,loadcase,restrainedDOFs::Vector{Int};path=pwd())
    T=loadcase.t
    Δt=(T[end]-T[1])/(length(T)-1)
    α=loadcase.α
    β=(2-α^2)/4
    γ=1.5-α
    @info "----------------------- 求解Hilber-Hughes-Taylor法逐步积分 -----------------------"
    K̄=introduce_BC(structure.K,restrainedDOFs)
    M̄=introduce_BC(structure.M,restrainedDOFs)
    C̄=introduce_BC(structure.C,restrainedDOFs)
    P̄=introduce_BC(loadcase.P,restrainedDOFs)
    Q̄=loadcase.f'.*P̄
    u₀=zeros(size(K̄,1))
    v₀=zeros(size(K̄,1))

    if !(0.5<α<1.0)
        @warn "算法可能不精确"
    end
    c₀=1/(β*Δt^2)
    c₁=α*γ/(β*Δt)
    c₂=1/(β*Δt)
    c₃=1/(2*β)-1
    c₄=γ/β-1
    c₅=Δt/2*(γ/β-2)
    c₆=Δt*(1-γ)
    c₇=γ*Δt

    K̂=α*K̄+c₀*M̄+c₁*C̄

    LDLᵀ=ldlt(Symmetric(K̂))

    ū=Array{Float64,2}(undef,length(u₀),length(T))
    v̄=Array{Float64,2}(undef,length(v₀),length(T))
    ā=Array{Float64,2}(undef,length(v₀),length(T))
    ū[:,1]=u₀
    v̄[:,1]=v₀
    if USE_PARDISO
        ps=Pardiso.MKLPardisoSolver()
        Pardiso.set_matrixtype!(ps,1)
        a₀=Pardiso.solve(ps,M̄,(Q̄[:,1]-C̄*v₀-K̄*u₀)[:,1])
    else
        a₀=Symmetric(M̄) \ (Q̄[:,1]-C̄*v₀-K̄*u₀)[:,1]
    end

    ā[:,1]=a₀
    for t in 1:length(T)-1
        Q̂=Q̄[:,t+1]+M̄*(c₀*ū[:,t]+c₂*v̄[:,t]+c₃*ā[:,t])+C̄*(c₁*ū[:,t]+c₄*v̄[:,t]+c₅*ā[:,t])

        Q̂=reshape(Q̂,length(Q̂))
        if USE_PARDISO
            ū[:,t+1]=Pardiso.solve(ps,K̂,Q̂) #May LDLT here
        else
            ū[:,t+1]=Symmetric(K̂) \ Q̂
        end
        ā[:,t+1]=c₀*(ū[:,t+1]-ū[:,t])-c₂*v̄[:,t]-c₃*ā[:,t]
        v̄[:,t+1]=v̄[:,t]+c₆*ā[:,t]+c₇*ā[:,t+1]
    end
    @info "------------------------------ 求解完成 ------------------------------"

    u=zeros(size(structure.K,1),length(T))
    v=zeros(size(structure.K,1),length(T))
    a=zeros(size(structure.K,1),length(T))
    for t in 1:length(T)
        u[:,t]=resolve_BC(ū[:,t],restrainedDOFs)
        v[:,t]=resolve_BC(v̄[:,t],restrainedDOFs)
        a[:,t]=resolve_BC(ā[:,t],restrainedDOFs)
    end
    return u,v,a
end

function duhamel(ω,ζ,t,p)
    dt=(t[end]-t[1])/(length(t)-1)
    N=length(t)
    ω̄=ω*sqrt(1-ζ^2)
    q=exp.(-ζ*ω*t).*sin.(ω*t)
    d=(1/ω)*conv(p,q)[1:N]*dt
end

#差分代微分
function diffasdiff(x₀,y₀)
    d=diff(y₀,dims=2)./diff(x₀)'
    dydx=zero(y₀)
    dydx[:,1:end-1]=d
    dydx[:,2:end]+=d
    dydx[:,1]+=d[:,1]
    dydx[:,end]+=d[:,end]
    dydx./2
end

function solve_modal_decomposition(structure,loadcase,restrainedDOFs::Vector{Int};path=pwd())
    modal_case=loadcase.modal_case
    ω²=read_vector(path*"/.analysis",modal_case*"_o.v")
    ϕ=read_matrix(path*"/.analysis",modal_case*"_p.m")

    @info "------------------------ 求解振型分解法频域积分 ------------------------" 模态工况=modal_case 模态数量=length(ω²)

    K̄=introduce_BC(structure.K,restrainedDOFs)
    M̄=introduce_BC(structure.M,restrainedDOFs)
    C̄=introduce_BC(structure.C,restrainedDOFs)
    P̄=introduce_BC(loadcase.P,restrainedDOFs)
    T=loadcase.t #should be a nx1 vector
    P̄=loadcase.f'.*P̄ #should be a nfDOF*nt matrix
    ω̂=sqrt.(ω²)
    K̂=diag(ϕ'*K̄*ϕ)
    M̂=diag(ϕ'*M̄*ϕ)
    Ĉ=diag(ϕ'*C̄*ϕ)
    P̂=[(ϕ'*P̄)[i,:] for i in 1:size(ϕ,2)]
    X=zeros(length(ω²),length(loadcase.f))
    for i in 1:length(ω²)
        ζ=Ĉ[i]/(2*sqrt(M̂[i]*K̂[i]))
        X[i,:]=duhamel(ω̂[i],ζ,T,P̂[i])
    end
    ū=ϕ*X
    v̄=diffasdiff(T,ū)
    ā=diffasdiff(T,v̄)
    @info "------------------------------ 求解完成 ------------------------------"
    u=zeros(size(structure.K,1),length(T))
    v=zeros(size(structure.K,1),length(T))
    a=zeros(size(structure.K,1),length(T))
    for t in 1:length(T)
        u[:,t]=resolve_BC(ū[:,t],restrainedDOFs)
        v[:,t]=resolve_BC(v̄[:,t],restrainedDOFs)
        a[:,t]=resolve_BC(ā[:,t],restrainedDOFs)
    end
    return u,v,a
end

function solve_central_diff(structure,loadcase,restrainedDOFs::Vector{Int};path=pwd(),Δtcr=0)
    T=loadcase.t
    Δt=(T[end]-T[1])/(length(T)-1)
    @info "----------------------- 求解中心差分法逐步积分 -----------------------" Δt=Δt
    if Δtcr==0
        @warn "未考虑临界Δt，算法可能不稳定"
    end
    c₀=1/Δt^2
    c₁=1/2Δt
    c₂=2c₀
    c₃=1/c₂

    K̄=introduce_BC(structure.K,restrainedDOFs)
    M̄=introduce_BC(structure.M,restrainedDOFs)
    C̄=introduce_BC(structure.C,restrainedDOFs)
    P̄=introduce_BC(loadcase.P,restrainedDOFs)
    Q̄=loadcase.f'.*P̄

    u₀=zeros(size(K̄,1))
    v₀=zeros(size(K̄,1))
    a₀=zeros(size(K̄,1))

    ū=Array{Float64,2}(undef,length(u₀),length(T)+1)
    v̄=Array{Float64,2}(undef,length(v₀),length(T)+1)
    ā=Array{Float64,2}(undef,length(v₀),length(T)+1)

    ū[:,2]=u₀
    v̄[:,2]=v₀
    ā[:,2]=a₀

    ū[:,1]=u₀-Δt*v₀+c₃*a₀
    M̂=c₀*M̄+c₁*C̄

    LDLᵀ=ldlt(Symmetric(M̂))
    if USE_PARDISO
        ps=Pardiso.MKLPardisoSolver()
        Pardiso.set_matrixtype!(ps,1)
    end
    for t in 2:length(T)
        Q̂=Q̄[:,t]-(K̄-c₂*M̄)*ū[:,t]-(c₀*M̄-c₁*C̄)*ū[:,t-1]
        if USE_PARDISO
            ū[:,t+1]=Pardiso.solve(ps,M̂,Q̂)
        else
            ū[:,t+1]=Symmetric(M̂) \ Q̂
        end
        v̄[:,t]=c₁*(-ū[:,t-1]+ū[:,t+1])
        ā[:,t]=c₀*(ū[:,t-1]-2*ū[:,t]+ū[:,t+1])
    end
    @info "------------------------------ 求解完成 ------------------------------"

    u=zeros(size(structure.K,1),length(T))
    v=zeros(size(structure.K,1),length(T))
    a=zeros(size(structure.K,1),length(T))
    for t in 1:length(T)
        u[:,t]=resolve_BC(ū[:,t+1],restrainedDOFs)
        v[:,t]=resolve_BC(v̄[:,t+1],restrainedDOFs)
        a[:,t]=resolve_BC(ā[:,t+1],restrainedDOFs)
    end
    return u,v,a
end

function solve_response_spectrum(structure,loadcase,restrainedDOFs::Vector{Int};path=pwd())
    modal_case=loadcase.modal_case
    ω²=read_vector(path*"/.analysis",modal_case*"_o.v")
    ϕ=read_matrix(path*"/.analysis",modal_case*"_p.m")

    K̄=introduce_BC(structure.K,restrainedDOFs)
    M̄=introduce_BC(structure.M,restrainedDOFs)
    C̄=introduce_BC(structure.C,restrainedDOFs)
    P̄=introduce_BC(loadcase.P,restrainedDOFs)
    T=loadcase.t #should be a nx1 vector
    P̄=loadcase.f'.*P̄ #should be a nfDOF*nt matrix
    ω̂=sqrt.(ω²)
    K̂=diag(ϕ'*K̄*ϕ)
    M̂=diag(ϕ'*M̄*ϕ)
    Ĉ=diag(ϕ'*C̄*ϕ)
    P̂=[(ϕ'*P̄)[i,:] for i in 1:size(ϕ,2)]
    X=zeros(length(ω²),length(loadcase.f))
    for i in 1:length(ω²)
        ζ=Ĉ[i]/(2*sqrt(M̂[i]*K̂[i]))
        X[i,:]=duhamel(ω̂[i],ζ,T,P̂[i])
    end
    ū=ϕ*X
    v̄=ū
    ā=ū
    @info "------------------------------ 求解完成 ------------------------------"
    u=zeros(size(structure.K,1),length(T))
    v=zeros(size(structure.K,1),length(T))
    a=zeros(size(structure.K,1),length(T))
    for t in 1:length(T)
        u[:,t]=resolve_BC(ū[:,t],restrainedDOFs)
        v[:,t]=resolve_BC(v̄[:,t],restrainedDOFs)
        a[:,t]=resolve_BC(ā[:,t],restrainedDOFs)
    end
    return u,v,a
end

#
# """
# spec: a {'T':period,'a':acceleration} dictionary of spectrum\n
# mdd: a list of modal damping ratio\n
# comb: combination method, 'CQC' or 'SRSS'
# """
# function solve_response_spectrum(assembly:assembly,T::Vector,α::Vector,n=60,comb='CQC'):
#     K=assembly.K̄
#     M=assembly.M̄
#     DOF=size(K̄)[1]
#     w,f,T,mode=eigen_mode(assembly,DOF)
#     mode=mode[:,1:n]#use n modes only.
#     M̂=ϕ'*M*ϕ#generalized mass
#     K̂=ϕ'*K*ϕ#generalized stiffness
#     L̂=M*ϕ
#     px=[]
#     Vx=[]
#     Xm=[]
#     γ=[]
#     mx=diag(M)
#     for i in range(len(mode)):
#         #mass participate factor
#         push!(px,-(ϕ[:,i])'*mx)
#         push!(Vx,px[end]^2)
#         push!(Xm,Vx[end]/3/m)
#         #modal participate factor
#         push!(γ,L̂[i]/M̂[i,i])
#     end
#     S=zeros(DOF,n)
#
#     for i in 1:n:
#         ξ=assembly.C̄[i]
#         y=linear_interp(T[i],T,α)
#         y/=ω²[i]
#         S[:,i]=γ[i]*y*mode[:,i]
#     end
#
#     if comb=='CQC':
#         cqc=0
#         rho=Matrix(,n,n)
#         for i in range(mode.shape[1]):
#             for j in range(mode.shape[1]):
#                 if i!=j:
#                     r=T[i]/T[j]
#                     rho[i,j]=8*xi^2*(1+r)*r^1.5/((1-r^2)^2+4*xi^2*r*(1+r)^2)
#                 end
#                 cqc+=rho[i,j]*S[:,i]*S[:,j]
#             end
#         end
#         cqc=sqrt(cqc)
#         print(cqc)
#     elseif comb=='SRSS':
#         SRSS(S)
#     end
# end
#
#
