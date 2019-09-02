module LoadCase

include("./Load.jl")

using SparseArrays

using ..Enums
using .Load

export LoadCaseSet,AbstractLoadCase

# export StaticCase,ModalCase,BucklingCase,TimeHistoryCase,ResponseSpectrumCase

export add_static_case!, add_modal_case!, add_buckling_case!, add_time_history_case!

export add_nodal_disp!,add_nodal_force!,
add_cable_distributed!,add_cable_strain!,add_cable_stress!,
add_link_distributed!,add_link_strain!,add_link_stress!,
add_beam_distributed!,add_beam_strain!
export set_modal_params!,set_buckling_params!,set_time_history_params!
export is_static, is_modal, is_buckling, is_time_history, is_response_spectrum, get_all_id

abstract type AbstractLoadCase end

mutable struct StaticCase <: AbstractLoadCase
    id::String
    hid::Int

    nl_type::String
    plc::String

    gfactor::Float64
    nodal_forces::Dict{String,NodalForce}
    nodal_disps::Dict{String,NodalDisp}
    beam_forces::Dict{String,BeamForce}
    quad_forces::Dict{String,QuadForce}

    P::Vector
    P̄::Vector

    StaticCase(id,hid,nl_type="1st",plc="",gfactor=0.)=new(
        string(id),
        hid,
        nl_type,
        plc,
        gfactor,
        Dict{String,NodalForce}(),
        Dict{String,NodalDisp}(),
        Dict{String,BeamForce}(),
        Dict{String,QuadForce}(),
        zeros(1),
        zeros(1))
end

mutable struct ModalCase <: AbstractLoadCase
    id::String
    hid::Int

    modal_type::String
    plc::String

    nev::Int
    tolev::Number
    maxiterev::Int

    P::Vector
    P̄::Vector

    ModalCase(id,hid,modal_type,plc="")=new(
        string(id),
        hid,
        modal_type,
        plc,
        6,
        1e-9,
        100,
        zeros(1),
        zeros(1))
end

mutable struct BucklingCase <: AbstractLoadCase
    id::String
    hid::Int

    plc::String

    gfactor::Float64
    nodal_forces::Dict{String,NodalForce}
    nodal_disps::Dict{String,NodalDisp}
    beam_forces::Dict{String,BeamForce}
    quad_forces::Dict{String,QuadForce}

    shift::Float64
    positive_only::Bool

    nev::Int
    tolev::Number
    maxiterev::Int

    P::Vector
    P̄::Vector

    BucklingCase(id,hid,nl_type="1st",plc="",gfactor=0.)=new(
        string(id),
        hid,
        plc,
        gfactor,
        Dict{String,NodalForce}(),
        Dict{String,NodalDisp}(),
        Dict{String,BeamForce}(),
        Dict{String,QuadForce}(),
        0.,
        false,
        6,
        1e-12,
        100,
        zeros(1),
        zeros(1))
end

mutable struct TimeHistoryCase <: AbstractLoadCase
    id::String
    hid::Int

    t::Array{Float64}
    f::Array{Float64}

    plc::String

    nodal_forces::Dict{String,NodalForce}
    nodal_disps::Dict{String,NodalDisp}
    beam_forces::Dict{String,BeamForce}
    quad_forces::Dict{String,QuadForce}

    algorithm::String
    α::Float64
    β::Float64
    γ::Float64
    θ::Float64
    modal_case::String

    P::Vector
    P̄::Vector
    TimeHistoryCase(id,hid,t,f,plc="")=new(
        string(id),
        hid,
        t,f,
        plc,
        Dict{String,NodalForce}(),
        Dict{String,NodalDisp}(),
        Dict{String,BeamForce}(),
        Dict{String,QuadForce}(),
        "newmark",
        0.85,
        0.25,
        0.5,
        1.4,
        "",
        zeros(1),
        zeros(1))
end

mutable struct ResponseSpectrumCase <: AbstractLoadCase
    id::String
    hid::Int

    t::Array{Float64}
    α::Array{Float64}

    modal_case::String

    plc::String

    dirfactors::Array{Float64}
end

mutable struct LoadCaseSet
    statics::Dict{String,StaticCase}
    modals::Dict{String,ModalCase}
    bucklings::Dict{String,BucklingCase}
    time_histories::Dict{String,TimeHistoryCase}
    response_spectrums::Dict{String,ResponseSpectrumCase}

    lc_tree::Array
    LoadCaseSet()=new(Dict{String,StaticCase}(),
    Dict{String,ModalCase}(),
    Dict{String,BucklingCase}(),
    Dict{String,TimeHistoryCase}(),
    Dict{String,ResponseSpectrumCase}(),
    [])
end

get_all_id(lcset::LoadCaseSet)=union(keys(lcset.statics),keys(lcset.modals),keys(lcset.bucklings),keys(lcset.time_histories),keys(lcset.response_spectrums))

"""
    add_static_case!(lcset,id,gfactor,lc_type,plc)
向lcset加入新静力工况
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `gfactor`: 自重乘数
- `nl_type`: 非线性类型，应为1st、2nd、3rd中之一
- `plc`: nl_type为2nd、3rd时可选的提供初始刚度的前一步工况
"""
function add_static_case!(lcset::LoadCaseSet,id,gfactor=0.;nl_type="1st",plc="")
    all_ids=get_all_id(lcset)
    if id in all_ids
        throw("load case with id "*string(id)*" already exists!")
    end
    if plc!="" && !(plc in keys(lcset.statics))
        throw("previous load case with id "*string(plc)*" doe not exists!")
    end
    hid=length(lcset.statics)+1
    lcset.statics[id]=StaticCase(id,hid,nl_type,plc,gfactor)
end

"""
    add_modal_case!(lcset,id,gfactor,lc_type,plc)
向lcset加入新模态工况
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `modal_type`: 工况类型，应为eigen、ritz中之一
- `plc`: 可选的提供初始刚度的前一步静力工况
"""
function add_modal_case!(lcset::LoadCaseSet,id;modal_type="eigen",plc="")
    all_ids=get_all_id(lcset)
    id=string(id)
    if id in all_ids
        throw("load case with id "*id*" already exists!")
    end
    if plc!="" && !(plc in keys(lcset.statics))
        throw("previous load case with id "*string(plc)*" doe not exists!")
    end
    hid=length(keys(lcset.modals))+1
    lcset.modals[id]=ModalCase(id,hid,modal_type,plc)
end

"""
    set_modal_params!(lcset::LoadCaseSet,lc;n=12,tol=1e-12,maxiter=300,method="eigen")
设置模态工况分析参数
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `n`: 模态阶数
- `tol`: 迭代收敛容差
- `maxiter`: 最大迭代数
- `method`: 求解模态方法，应为`eigen`或`ritz`之一
"""
function set_modal_params!(lcset::LoadCaseSet,lc;n=12,tol=1e-12,maxiter=300,modal_type="eigen")
    lc=string(lc)
    if !(lc in keys(lcset.modals))
        throw("Modal case with id "*lc*" doe not exists!")
    end
    lcset.modals[lc].nev=n
    lcset.modals[lc].tolev=tol
    lcset.modals[lc].maxiterev=maxiter
    lcset.modals[lc].modal_type=modal_type
end

"""
    add_buckling_case!(lcset,id,gfactor,lc_type,plc)
向lcset加入新屈曲工况
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `plc`: 可选的提供初始刚度的前一步静力工况
"""
function add_buckling_case!(lcset::LoadCaseSet,id;plc="")
    all_ids=get_all_id(lcset)
    if id in all_ids
        throw("load case with id "*string(id)*" already exists!")
    end
    if plc!="" && !(plc in keys(lcset.statics))
        throw("previous load case with id "*string(plc)*" doe not exists!")
    end
    hid=length(keys(lcset.modals))+1
    lcset.bucklings[id]=Buckling(id,hid,modal_type,plc)
end

"""
    set_buckling_params!(lcset::LoadCaseSet,lc;n=12,tol=1e-12,maxiter=300)
设定屈曲工况分析参数
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `n`: 模态阶数
- `tol`: 迭代收敛容差
- `maxiter`: 最大迭代数
"""
function set_buckling_params!(lcset::LoadCaseSet,lc;n=12,tol=1e-12,maxiter=300)
    lc=string(lc)
    if !lc in lcset.modals
        throw("Buckling case with id "*lc*" doe not exists!")
    end
    lcset.bucklings[lc].nev=n
    lcset.bucklings[lc].tolev=tol
    lcset.bucklings[lc].maxiterev=maxiter
    lcset.bucklings[lc].modal_method=method
end

"""
    add_time_history_case!(lcset::LoadCaseSet,id,t,f;plc="")
向lcset加入新时程工况
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `id`: 工况id
- `t`: 时间值
- `f`: 函数值
- `plc`: 可选的提供初始刚度的前一步静力工况
"""
function add_time_history_case!(lcset::LoadCaseSet,id,t,f;plc="")
    all_ids=get_all_id(lcset)
    id=string(id)
    plc=string(plc)
    if id in all_ids
        throw("Load case with id "*id*" already exists!")
    end
    if plc!="" && !(plc in keys(lcset.statics))
        throw("Previous load case with id "*plc*" doe not exists!")
    end
    hid=length(keys(lcset.modals))+1
    lcset.time_histories[id]=TimeHistoryCase(id,hid,t,f,plc)
end

"""
    set_time_history_params!(lcset::LoadCaseSet,lc,algorithm;α=0.85,β=0.25,γ=0.5,θ=1.4)
设定时程工况分析参数
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `algorithm`: 0-中心差分法； 1-Newmark-β法； 2-Wilson-Θ法；3-振型分解法
- `α`: 对HHT法的可选参数
- `β`: 对Newmark、Wilson法的可选参数
- `γ`: 对Newmark、Wilson法的可选参数
- `θ`: 对Wilson法的可选参数
- `modal_case`: 对振型分解法要求的模态工况
"""
function set_time_history_params!(lcset::LoadCaseSet,lc,algorithm;α=0.85,β=0.25,γ=0.5,θ=1.4,modal_case="")
    lc=string(lc)
    if !(lc in keys(lcset.time_histories))
        throw("Time history case with id "*lc*" doe not exists!")
    end
    if algorithm==0
        algor="central_diff"
    elseif algorithm==1
        algor="newmark"
    elseif algorithm==2
        algor="wilson"
    elseif algorithm==3
        algor="modal_decomp"
    else
        throw("算法不存在")
    end
    lcset.time_histories[lc].algorithm=algor
    lcset.time_histories[lc].α=α
    lcset.time_histories[lc].β=β
    lcset.time_histories[lc].γ=γ
    lcset.time_histories[lc].θ=θ
    lcset.time_histories[lc].modal_case=modal_case
end

"""
    add_nodal_disp!(lcset,lc,id,u1,u2,u3,r1,r2,r3;csys)
向lcset加入节点强制位移
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `id`: 节点id/组id
- `u1,u2,u3,r1,r2,r3`: 各自由度位移
# 可选参数
- `csys`: 参考坐标系，应为"global"或"local"
"""
function add_nodal_disp!(lcset::LoadCaseSet,lc,id,u1,u2,u3,r1,r2,r3;csys="global")
    lc=string(lc)
    if !(lc in keys(lcset.static))
        throw("Static case with id "*lc*" doesn't exists!")
    end
    disp=[u1,u2,u3,r1,r2,r3]
    nodal_disp=NodeDisp(id,disp,csys)
    lcset.statics[lc].nodal_disps[string(id)]=nodal_disp
end

"""
    add_nodal_force!(lcset,lc,id,f1,f2,f3,m1,m2,m3;csys)
向lcset加入节点集中力
# 参数
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `id`: 节点id
- `f1,f2,f3,m1,m2,m3`: 各自由度集中力
# 可选参数
- `csys`: 参考坐标系，应为"global"或"local"
"""
function add_nodal_force!(lcset::LoadCaseSet,lc,id,f1,f2,f3,m1,m2,m3;csys="global")
    lc=string(lc)
    cases=merge(lcset.statics,lcset.bucklings,lcset.time_histories)
    if !(lc in keys(cases))
        throw("Load case with id "*lc*" doesn't exists!")
    end
    id=string(id)
    force=Float64.([f1,f2,f3,m1,m2,m3])
    nodal_force=NodalForce(id,force,csys)
    cases[lc].nodal_forces[id]=nodal_force
end

function add_cable_distributed!(lcset::LoadCaseSet,lc,id,fi1,fi2,fi3,fj1,fj2,fj3;csys="local")
    lc=string(lc)
    if !(lc in keys(lcset.static))
        throw("static case with id "*lc*" doesn't exists!")
    end
    id=string(id)
    force=Float64.([fi1,fi2,fi3,fj1,fj2,fj3])
    idx=findfirst(x->x.id==id,loadcase.cable_forces)
    if csys=="local"
        if idx isa Nothing
            cable_force=LinkForce(id)
            cable_force.f=force
            push!(lcset.statics[hid].cable_forces,cable_force)
        else
            lcset.statics[hid].cable_force[idx].f+=force
        end
    else
        #pass
    end
end

"""
    add_beam_distributed!(lcset::LoadCaseSet,lc,id,fi1,fi2,fi3,mi1,mi2,mi3,fj1,fj2,fj3,mj1,mj2,mj3;csys)
向lcset加入beam单元分布力
# Arguments
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `id`: 单元id
- `fi1,fi2,fi3,mi1,mi2,mi3,fj1,fj2,fj3,mj1,mj2,mj3`: i,j端的分布力集度
# 可选参数
- `csys`: 参考坐标系，应为"global"或"local"
"""
function add_beam_distributed!(lcset::LoadCaseSet,lc,id,fi1,fi2,fi3,mi1,mi2,mi3,fj1,fj2,fj3,mj1,mj2,mj3;csys="local")
    lc=string(lc)
    if !(lc in keys(lcset.statics))
        throw("static case with id "*lc*" doesn't exists!")
    end
    id=string(id)
    force=Float64.([fi1,fi2,fi3,mi1,mi2,mi3,fj1,fj2,fj3,mj1,mj2,mj3])
    if csys=="local"
        if !(id in keys(lcset.statics[lc].beam_forces))
            beam_force=BeamForce(id)
            beam_force.f=force
            lcset.statics[lc].beam_forces[id]=beam_force
        else
            lcset.statics[lc].beam_forces[id].f+=force
        end
    else
        #pass
    end
end

"""
    add_beam_strain!(lcset,lc,val)
向lcset加入beam单元初应变
# Arguments
- `lcset::LoadCaseSet`: LoadCaseSet实例
- `lc`: 工况id
- `id`: 单元id
- `val`: 应变值
"""
function add_beam_strain!(lcset::LoadCaseSet,lc,id,val)
    lc=string(lc)
    if !(lc in keys(lcset.statics))
        throw("load case with id "*lc*" doesn't exists!")
    end
    if !(id in keys(lcset.statics[lc].beam_forces))
        beam_force=BeamForce(id)
        beam_force.s[1]=val
        beam_force.s[7]=val
        lcset.statics[lc].beam_forces[id]=beam_force
    else
        lcset.statics[lc].beam_forces[id].s[1]+=val
        lcset.statics[lc].beam_forces[id].s[7]+=val
    end
end

function add_link_stress!(lcset::LoadCaseSet)
end
is_static(loadcase)=loadcase isa StaticCase
is_modal(loadcase)=loadcase isa ModalCase
is_buckling(loadcase)=loadcase isa BucklingCase
is_time_history(loadcase)=loadcase isa TimeHistoryCase
is_response_spectrum(loadcase)=loadcase isa ResponseSpectrumCase

end
