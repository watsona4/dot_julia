export result_quad_force,result_quad_displacement

"""
    result_quad_force(assembly,lc_id,elm_id)
读取已求解的assembly实例的单个quad单元内力
# Arguments
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `elm_id`: 单元id
# 返回
- 包含梁单元坐标系下的12个节点力向量
"""
function result_quad_force(assembly,lc_id,elm_id)
    path=assembly.working_path
    elm_id=string(elm_id)
    if !(id in keys(assembly.structure.quads))
        throw("quad id "*string(quad_id)*" doesn't exists!")
    end
    lc_id=string(lc_id)
    if !(lc_id in keys(assembly.lcset.cases))
        throw("loadcase with id "*lc_id*" doesn't exist!")
    end
    elm=assembly.structure.quads[quad_ids]
    i=elm.node1.hid
    j=elm.node2.hid
    k=elm.node3.hid
    l=elm.node4.hid
    iDOFs=6*i-5:6*i
    jDOFs=6*j-5:6*j
    kDOFs=6*k-5:6*k
    lDOFs=6*l-5:6*l
    u=read_vector(path*"/.analysis",lc_id*"_u.v")
    T=elm.T
    uᵉ=T*[u[iDOFs];u[jDOFs];u[kDOFs];u[lDOFs]]
    Kᵉ=elm.Kᵉ
    return Kᵉ*uᵉ
end

"""
    result_quad_displacement(assembly,lc_id,elm_id)
读取已求解的assembly实例的单个quad单元节点位移
# 参数
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `elm_id`: 单元id
# 返回
- 包含quad单元坐标系下的12个节点位移向量
"""
function result_quad_displacement(assembly,lc_id,elm_id)
    path=assembly.working_path
    elm_id=string(elm_id)
    if !(id in keys(assembly.structure.quads))
        throw("quad id "*string(quad_id)*" doesn't exists!")
    end
    lc_id=string(lc_id)
    if !(lc_id in keys(assembly.lcset.cases))
        throw("loadcase with id "*lc_id*" doesn't exist!")
    end
    loadcase=assembly.lcset.cases[lc_id]
    u=read_vector(path*"/.analysis",lc_id*"_u.v")
    elm=assembly.structure.quads[quad_id]
    i=elm.node1.hid
    j=elm.node2.hid
    k=elm.node3.hid
    l=elm.node4.hid
    iDOFs=6*i-5:6*i
    jDOFs=6*j-5:6*j
    kDOFs=6*k-5:6*k
    lDOFs=6*l-5:6*l
    T=elm.T
    uᵉ=T*[u[iDOFs];u[jDOFs];u[kDOFs];u[lDOFs]]
    return ūᵉ
end

function result_element()
    Δdᵉ=(elm.T)'*[Δd[6*hid1-5:6*hid1];Δd[6*hid2-5:6*hid2]]
    Δϵᵉ=Bᵉ*Δdᵉ
    Δσᵉ=∫D*Δϵᵉ
    σᵉ+=Δσᵉ
end
