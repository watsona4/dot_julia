export result_nodal_reaction,result_nodal_displacement,result_nodal_time_history

"""
   result_nodal_displacement(assembly,lc_id,node_id)
获取已求解的assembly实例的单个节点位移
# Arguments
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `node_id`: 节点id
"""
function result_nodal_displacement(assembly,lc_id,node_id;substep=0)
    path=assembly.working_path
    node_id=string(node_id)
    if !(node_id in keys(assembly.structure.nodes))
        throw("node with id "*string(node_id)*" doesn't exist!")
    end
    lc_id=string(lc_id)
    if !(lc_id in get_all_id(assembly.lcset))
        throw("loadcase with id "*lc_id*" doesn't exist!")
    end
    hid=assembly.structure.nodes[node_id].hid
    DOFs=6*hid-5:6*hid
    if lc_id in keys(assembly.lcset.statics)
        u=read_vector(path*"/.analysis",lc_id*"_u.v")
        return u[DOFs]
    else
        u=read_matrix(path*"/.analysis",lc_id*"_u.m")
        if substep==0
            return u[DOFs,:]
        elseif substep<=size(u,2)
            return u[DOFs,substep]
        else
            throw("substep not exists!")
        end
    end
end

"""
   result_nodal_displacement(assembly,lc_id)
获取已求解的assembly实例的所有节点位移
# 参数
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `node_id`: 节点id
# 返回
- id=>位移字典
"""
function result_nodal_displacement(assembly,lc_id)
    path=assembly.working_path
    lc_id=string(lc_id)
    if !(lc_id in get_all_id(assembly.lcset))
        throw("loadcase with id "*string(lc_id)*" doesn't exist!")
    end
    u=read_vector(path*"/.analysis",lc_id*"_u.v")
    res=Dict{String,Array{Float64}}
    for node in values(assembly.structure.nodes)
        hid=node.hid
        DOFs=6*hid-5:6*hid
        res[node.id]=u[DOFs]
    end
    return res
end

"""
   result_nodal_reaction(assembly,lc_id,node_id)
获取已求解的assembly实例的单个节点反力
# Arguments
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `node_id`: 节点id
"""
function result_nodal_reaction(assembly,lc_id,node_id)
    path=assembly.working_path
    node_id=string(node_id)
    if !(node_id in keys(assembly.structure.nodes))
        throw("node with id "*string(node_id)*" doesn't exist!")
    end
    lc_id=string(lc_id)
    if !(lc_id in get_all_id(assembly.lcset))
        throw("loadcase with id "*lc_id*" doesn't exist!")
    end
    u=read_vector(path*"/.analysis",lc_id*"_u.v")
    F=read_vector(path*"/.analysis",lc_id*"_F.v")
    F₀=zero(F)
    hid=assembly.structure.nodes[node_id].hid
    DOFs=6*hid-5:6*hid
    R=F-recursive_P(assembly,lc_id)
    return R[DOFs]
end

function recursive_P(assembly,lc_id)
    lc_id=string(lc_id)
    lc=assembly.lcset.statics[lc_id]
    if lc.plc==""
        return lc.P
    else
        return lc.P+recursive_P(assembly,lc.plc)
    end
end

"""
   result_nodal_time_history(assembly,lc_id,node_id)
获取已求解的assembly实例的单个节点响应时程
# Arguments
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `node_id`: 节点id
- `value`:值，0-位移；1-速度；2-加速度
- `dir`:方向，1-1方向，2-2方向，3-3方向，4-绕1轴转动方向，5-绕2轴转动方向，6-绕3轴转动方向
"""
function result_nodal_time_history(assembly,lc_id,node_id,value=0,dir=1)
    path=assembly.working_path
    node_id=string(node_id)
    if !(node_id in keys(assembly.structure.nodes))
        throw("node with id "*string(node_id)*" doesn't exist!")
    end
    lc_id=string(lc_id)
    if !(lc_id in keys(assembly.lcset.time_histories))
        throw("loadcase with id "*lc_id*" doesn't exist!")
    end
    hid=assembly.structure.nodes[node_id].hid
    DOFs=6*hid-5:6*hid
    if value==0
        u=read_matrix(path*"/.analysis",lc_id*"_u.m")
    elseif value==1
        u=read_matrix(path*"/.analysis",lc_id*"_v.m")
    elseif value==2
        u=read_matrix(path*"/.analysis",lc_id*"_a.m")
    end
    u[6*hid-6+dir,:]
end
