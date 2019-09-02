export result_modal_period,result_eigen_value,result_eigen_vector

"""
    result_modal_period(assembly,lc_id,node_id)
读取已求解的assembly实例的模态周期
# Arguments
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `order`: 模态阶数，默认为全部结果
"""
function result_modal_period(assembly,lc_id,order="all")
    path=assembly.working_path
    lc=string(lc_id)
    if !(lc in keys(assembly.lcset.modals))
        throw("loadcase with id "*string(lc_id)*" doesn't exist!")
    end
    ω²=read_vector(path*"/.analysis",lc*"_o.v")
    if order=="all"
        return 2π./sqrt.(ω²)
    else
        return 2π/sqrt(ω²[order])
    end
end

"""
    result_modal_period(assembly,lc_id,node_id)
读取已求解的assembly实例的模态特征值
# Arguments
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `order`: 模态阶数，默认为全部结果
"""
function result_eigen_value(assembly,lc_id;order="all")
    path=assembly.working_path
    d=read_vector(path*"/.analysis",lc_id*"_o.v")
    if order=="all"
        return d
    else
        return d[order]
    end
end

"""
    result_modal_period(assembly,lc_id,node_id)
读取已求解的assembly实例的模态特征向量
# Arguments
- `assembly`: Assembly类型实例
- `lc_id`: 工况id
- `order`: 模态阶数，默认为全部结果
"""
function result_eigen_vector(assembly,lc_id;order="all")
    path=assembly.working_path
    ϕ=read_matrix(path*"/.analysis",lc_id*"_p.m")
    if order=="all"
        return ϕ
    else
        return ϕ[:,order]
    end
end

# """
#     result_modal_period(assembly,lc_id,node_id)
# 读取已求解的assembly实例的模态周期
# # Arguments
# - `assembly`: Assembly类型实例
# - `lc_id`: 工况id
# - `order`: 模态阶数，默认为全部结果
# """
# function result_modal_mass_paticipation(assembly,lc_id,node_id)
#     path=assembly.working_path
#     node_idx=findfirst(x->x.id==string(node_id),assembly.structure.nodes)
#     if node_idx isa Nothing
#         throw("node with id "*string(node_id)*" doesn't exist!")
#     end
#     lc_idx=findfirst(x->x.id==string(lc_id),assembly.lcset.cases)
#     if lc_idx isa Nothing
#         throw("loadcase with id "*string(lc_id)*" doesn't exist!")
#     end
#     d=read_vector(path*"/.analysis",lc_id*".v")
#     hid=assembly.structure.nodes[node_idx].hid
#     DOFs=6*hid-5:6*hid
#     R=assembly.structure.K*d-assembly.loadcases[lc_idx].P
#     return R[DOFs]
# end
