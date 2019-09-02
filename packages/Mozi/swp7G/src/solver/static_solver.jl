export solve_linear_static,solve_linear_eigen

function introduce_BC(K::SparseMatrixCSC{Float64},restrainedDOFs::Vector{Int})
    nDOF=size(K,1)
    mask=[(i in restrainedDOFs) ? false : true for i in 1:nDOF]
    return K[mask,mask]
end

function introduce_BC(K::Vector{Float64},restrainedDOFs::Vector{Int})
    nDOF=size(K,1)
    mask=[(i in restrainedDOFs) ? false : true for i in 1:nDOF]
    return K[mask]
end

function resolve_BC(d̄::Vector{Float64},restrainedDOFs::Vector{Int})
    rows=Array(1:length(d̄))
    cols=Array(1:length(d̄))
    vals=ones(length(d̄))
    for i in restrainedDOFs
        for j in 1:length(rows)
            if rows[j]>=i
                rows[j:end].+=1
                break
            end
        end
    end
    d̄=sparse(d̄)
    d=sparse(rows,cols,vals,length(restrainedDOFs)+length(d̄),length(d̄))*d̄
    return Array(d)
end

function K₂(structure::Structure,d₀::Vector{Float64})::SparseMatrixCSC{Float64}
    nDOF=length(structure.nodes)*6
    restrainedDOFs=[]
    K=spzeros(nDOF,nDOF)
    for elm in values(structure.beams)
        i = elm.node1.hid
        j = elm.node2.hid
        T=sparse(elm.T)

        I=collect(1:12)
        J=[6i-5:6i;6j-5:6j]
        G=sparse(I,J,1.0,12,nDOF)

        T=sparse(elm.T)
        dᵉ=T*[d₀[i*6-5:i*6];d₀[j*6-5:j*6]]
        # Kᵉ=integrateK!(elm)
        # σ=(Kᵉ*dᵉ)[1]
        Kᵢᵉ=elm.Kᵉ
        σ=(Kᵢᵉ*dᵉ)[1]
        Kᵉ=sparse(Kᵢᵉ)+integrateKσ(elm,σ)
        A=T*G
        rDOF=findall(x->x==true,elm.release)
        if length(rDOF)!=0
            K̄ᵉ,P̄ᵉ=FEStructure.FEBeam.static_condensation(Array(Kᵉ),zeros(12),rDOF)
            K+=A'*K̄ᵉ*A
        else
            K+=A'*Kᵉ*A
        end
    end
    return K
end

function solve_linear_static(structure::Structure,loadcase,restrainedDOFs::Vector{Int})
    @info "-------------------------- 求解一阶线性工况 ---------------------------" 工况=loadcase.id
    K̄=introduce_BC(structure.K,restrainedDOFs)
    P̄=introduce_BC(loadcase.P,restrainedDOFs)
    if USE_PARDISO
        ps=Pardiso.MKLPardisoSolver()
        Pardiso.set_matrixtype!(ps,1) #实对称矩阵
        ū=Pardiso.solve(ps,K̄,P̄)
    else
        ū=Symmetric(K̄) \ P̄
    end

    u=resolve_BC(ū,restrainedDOFs)

    P=structure.K*u
    @info "------------------------------ 求解完成 ------------------------------"
    return u,P
end

function solve_linear_buckling(structure::Structure,loadcase,restrainedDOFs::Vector{Int};path=pwd())
    @info "-------------------------- 求解屈曲模态特征值 --------------------------" 工况=loadcase.id 前一步基础工况=loadcase.plc
    K=structure.K
    P=loadcase.P
    u=zero(P)
    F₀=zero(P)
    if loadcase.plc!=""
        u=read_vector(joinpath(path,".analysis"),loadcase.plc*"_u.v")
        F₀=read_vector(joinpath(path,".analysis"),loadcase.plc*"_F.v")
        Kσ=calc_Kσ(structure,u)
        K=structure.K+Kσ #初始位移及初始刚度来自前一步结果
    end
    K̄=introduce_BC(K,restrainedDOFs)

    nev=min(loadcase.nev,size(K̄,1))
    tol=loadcase.tolev
    maxiter=loadcase.maxiterev
    ω²,ϕ=eigs(K̄,M̄,nev=nev,which=:SM,tol=tol,maxiter=maxiter)

    for i in 1:size(ϕ̄,2)
        println(resolve_BC(ϕ̄[:,i],restrainedDOFs))
    end
    @info "------------------------------ 求解完成 ------------------------------"
    return ω²,ϕ
end

function solve_2nd_static(structure::Structure,loadcase,restrainedDOFs::Vector{Int};conv_tol=1e-16,steps=10,max_iter=20,path=pwd())
    @info "------------------------ 求解二阶几何非线性工况 ------------------------" 工况=loadcase.id 前一步基础工况=loadcase.plc
    K=structure.K
    P=loadcase.P
    u=zero(P)
    F₀=zero(P)
    if loadcase.plc!=""
        u=read_vector(joinpath(path,".analysis"),loadcase.plc*"_u.v")
        F₀=read_vector(joinpath(path,".analysis"),loadcase.plc*"_F.v")
        K=K₂(structure,u)
    end
    K̄=introduce_BC(K,restrainedDOFs)
    P̄=introduce_BC(P,restrainedDOFs)
    ū=introduce_BC(u,restrainedDOFs)
    F=zero(P)
    F̄=zero(ū)
    # @info "initial" F[12]

    if USE_PARDISO
        ps=Pardiso.MKLPardisoSolver()
        Pardiso.set_matrixtype!(ps,1) #实对称矩阵
    end

    for step in 1:steps #等荷载增量
        Q̄=P̄*step/steps
        iter=0
        while true
            ΔQ̄=Q̄-F̄ #当前子步不平衡力
            if USE_PARDISO
                Δū=Pardiso.solve(ps,K̄,ΔQ̄)  #线性求解子步增量位移
            else
                Δū=Symmetric(K̄)\ΔQ̄
            end
            Δu=resolve_BC(Δū,restrainedDOFs)
            ū+=Δū
            u=resolve_BC(ū,restrainedDOFs) #T.L格式，相对零位形
            K=K₂(structure,u)#应力刚化/软化
            F+=K*Δu #计算非线性内力
            K̄=introduce_BC(K,restrainedDOFs)
            F̄=introduce_BC(F,restrainedDOFs)
            iter+=1

            error=maximum(abs.(Q̄-F̄))
            if error>conv_tol
                # @printf("Iteration %d, error=%f, tol=%4.3e\n",iter,error,conv_tol)
            else
                # @info "step "*string(step) F[12]
                # @info "Converged!"
                break
            end

            if iter >= max_iter
                @error "Max iteration reached, step not converged!"
                break
            end
        end
    end
    @info "------------------------------ 求解完成 ------------------------------"
    return u,F+F₀
end
