export result_beam_force,result_beam_displacement

"""
    result_beam_force(assembly,lc_id,beam_id)
读取已求解的assembly实例的单个beam单元内力
# Arguments
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `beam_id`: 单元id
# 返回
- 包含梁单元坐标系下的12个节点力向量
"""
function result_beam_force(assembly,lc_id,beam_id)
    path=assembly.working_path
    beam_id=string(beam_id)
    if !(id in keys(assembly.structure.beams))
        throw("beam id "*string(beam_id)*" doesn't exists!")
    end
    lc_id=string(lc_id)
    if !(lc_id in keys(assembly.lcset.cases))
        throw("loadcase with id "*lc_id*" doesn't exist!")
    end
    elm=assembly.structure.beams[beam_id]
    i=elm.node1.hid
    j=elm.node2.hid
    iDOFs=6*i-5:6*i
    jDOFs=6*j-5:6*j
    u=read_vector(path*"/.analysis",lc_id*"_u.v")
    T=elm.T
    uᵉ=T*[d[iDOFs];u[jDOFs]]

    rDOF=findall(x->x==true,elm.release)
    Kᵉ=integrateK(elm)
    K̃ᵉ,P̃ᵉ=static_condensation(K̃ᵉ,zeros(12),rDOF)
    return K̃ᵉ*uᵉ
end

"""
    result_beam_displacement(assembly,lc_id,beam_id)
读取已求解的assembly实例的单个beam单元两端节点位移
# 参数
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `beam_id`: 单元id
# 返回
- 包含梁单元坐标系下的12个节点位移向量
"""
function result_beam_displacement(assembly,lc_id,beam_id)
    path=assembly.working_path
    beam_id=string(beam_id)
    if !(id in keys(assembl.structure.beams))
        throw("beam id "*string(beam_id)*" doesn't exists!")
    end
    lc_id=string(lc_id)
    if !(lc_id in keys(assembly.lcset.cases))
        throw("loadcase with id "*lc_id*" doesn't exist!")
    end
    loadcase=assembly.lcset.cases[lc_id]
    u=read_vector(path*"/.analysis",lc_id*"_u.v")
    elm=assembly.structure.beams[beam_id]
    i=elm.node1.hid
    j=elm.node2.hid
    iDOFs=6*i-5:6*i
    jDOFs=6*j-5:6*j
    if beam_id in keys(loadcase.beam_forces)
        Pᵉ=zeros(12)
    else
        force=loadcase.beam_forces[beam_id]
        Pᵉ=FEBeam.integrateP!(elm,force)
    end
    T=elm.T
    uᵉ=T*[u[iDOFs];u[jDOFs]]
    K̄ᵉ=integrateK(elm)
    i=.!elm.release
    j=elm.release
    Kᵢᵢ=K̄ᵉ[i,i]
    Kᵢⱼ=K̄ᵉ[i,j]
    Kⱼᵢ=K̄ᵉ[j,i]
    Kⱼⱼ=K̄ᵉ[j,j]
    Pⱼ=Pᵉ[j]
    ūᵉ=zeros(12)
    ūᵉ[i]=uᵉ[i]
    ūᵉ[j]=inv(Kⱼⱼ)*(Pⱼ-Kⱼᵢ*uᵉ[i])
    return ūᵉ
end

"""
    result_beam_displacement(assembly,lc_id)
读取已求解的assembly实例的所有beam单元两端节点位移
# 参数
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
# 返回
- 所有梁在单元坐标系下的12个节点位移向量
"""
function result_beam_displacement(assembly,lc_id)
    path=assembly.working_path
    lc_id=string(lc_id)
    if !(lc_id in keys(assembly.lcset.cases))
        throw("loadcase with id "*lc_id*" doesn't exist!")
    end
    loadcase=assembly.lcset.cases[lc_id]
    u=read_vector(path*"/.analysis",lc_id*"_u.v")
    res=Dict{String,Array{Float64}}()
    for elm in values(assembly.structure.beams)
        i=elm.node1.hid
        j=elm.node2.hid
        iDOFs=6*i-5:6*i
        jDOFs=6*j-5:6*j
        if !(elm.id in keys(loadcase.beam_forces))
            Pᵉ=zeros(12)
        else
            force=loadcase.beam_forces[elm.id]
            Pᵉ=BeamModule.integrateP!(elm,force)
        end
        T=elm.T
        uᵉ=T*[u[iDOFs];u[jDOFs]]
        K̄ᵉ=integrateK(elm)
        i=.!elm.release
        j=elm.release
        Kᵢᵢ=K̄ᵉ[i,i]
        Kᵢⱼ=K̄ᵉ[i,j]
        Kⱼᵢ=K̄ᵉ[j,i]
        Kⱼⱼ=K̄ᵉ[j,j]
        Pⱼ=Pᵉ[j]
        ūᵉ=zeros(12)
        ūᵉ[i]=uᵉ[i]
        ūᵉ[j]=inv(Kⱼⱼ)*(Pⱼ-Kⱼᵢ*uᵉ[i])
        res[elm.id]=ūᵉ
    end
    return res
end

function result_element()
    Δdᵉ=(elm.T)'*[Δd[6*hid1-5:6*hid1];Δd[6*hid2-5:6*hid2]]
    Δϵᵉ=Bᵉ*Δdᵉ
    Δσᵉ=∫D*Δϵᵉ
    σᵉ+=Δσᵉ
end
