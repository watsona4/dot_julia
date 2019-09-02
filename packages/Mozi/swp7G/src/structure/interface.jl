"""
    add_uniaxial_metal!(structure,id,E,ν,ρ,α,E₂,f,fᵤ)
向structure加入单轴金属材料
# Arguments
- `structure`: Structure类型实例
- `id`: 材料id
- `E::Integer`: 杨氏模量
- `ν::Integer`: 泊松比
- `ρ`: 质量密度
- `α`: 热膨胀系数
- `E₂`: 屈服后强化模量
- `f`: 屈服点
- `fᵤ`: 极限强度
"""
function add_uniaxial_metal!(structure::Structure,id,E=2e11,ν=0.3,ρ=7850,α=1e-7,E₂=1e11,f=0.345,fᵤ=0.420)::Int
    id=string(id)
    if id in keys(structure.materials)
        throw("material with id "*id*" already exists!")
    end
    hid=length(structure.materials)+1
    material=UniAxialMetal(id,hid,E,ν,ρ,α,E₂,f,fᵤ)
    structure.materials[id]=material
    return 0
end

"""
    add_beam_section!(structure,id,sec_type,size1 [,size2 [,size3 [,size4 [,size5 [,size6 [,size7 [,size8]]]]]]])
向structure加入常用beam截面
# Arguments
- `structure`: Structure类型实例
- `id`: 截面id
- `sec_type`: 截面类型，1-I形截面，2-H形截面，3-箱形截面，4-圆管，5-实心圆形，6-实心矩形
- `size1 ～ size8`: 截面尺寸
"""
function add_beam_section!(structure::Structure,id,sec_type,size1=0,size2=0,size3=0,size4=0,size5=0,size6=0,size7=0,size8=0)::Int
    id=string(id)
    if id in keys(structure.sections)
        throw("section with id "*id*" already exists!")
    end
    hid=length(structure.sections)+1
    if SectionType(sec_type)==Enums.GENERAL_SECTION
        h=float(size1)
        b=float(size2)
        structure.sections[id]=RectangleSection(id,hid,h,b)
    elseif SectionType(sec_type)==Enums.ISECTION
        h=float(size1)
        b1=float(size2)
        b2=float(size3)
        tw=float(size4)
        tf1=float(size5)
        tf2=float(size6)
        structure.sections[id]=ISection(id,hid,h,b1,b2,tw,tf1,tf2)
    elseif SectionType(sec_type)==Enums.HSECTION
        h=float(size1)
        b=float(size2)
        tw=float(size3)
        tf=float(size4)
        structure.sections[id]=HSection(id,hid,h,b,tw,tf)
    elseif SectionType(sec_type)==Enums.BOX
        h=float(size1)
        b=float(size2)
        tw=float(size3)
        tf=float(size4)
        structure.sections[id]=BoxSection(id,hid,h,b,tw,tf)
    elseif SectionType(sec_type)==Enums.PIPE
        d=float(size1)
        t=float(size2)
        structure.sections[id]=PipeSection(id,hid,d,t)
    elseif SectionType(sec_type)==Enums.CIRCLE
        d=float(size1)
        structure.sections[id]=CircleSection(id,hid,d)
    else
        throw("sec_type error!")
    end
    return 0
end

"""
    add_general_section!(structure,id,A,I₂,I₃,J,As₂,As₃,W₂,W₃)
向structure实例加入一般beam截面
# Arguments
- `structure`: Structure类型实例
- `id`: 截面id
- `A`: 截面面积
- `I₂`: 绕2轴惯性矩
- `I₃`: 绕3轴惯性矩
- `J`: 抗扭常数
- `As₂`: 2轴抗剪截面
- `As₃`: 3轴抗剪截面
- `W₂`: 2轴抗弯模量
- `W₃`: 3轴抗弯模量
"""
function add_general_section!(structure::Structure,id,A,I₂,I₃,J,As₂,As₃,W₂,W₃)::Int
    id=string(id)
    if id in keys(structure.sections)
        throw("section with id "*id*" already exists!")
    end
    hid=length(structure.sections)+1
    structure.sections[id]=BeamSection(id,hid,A,I₂,I₃,J,As₂,As₃,W₂,W₃)
    return 0
end

"""
    add_node!(structure,id,x,y,z)
向structure实例加入节点
# Arguments
- `structure`: Structure类型实例
- `id`: 节点id
- `x y z`: 节点坐标
"""
function add_node!(structure::Structure,id,x,y,z)::Int
    id=string(id)
    if id in keys(structure.nodes)
        throw("node id "*string(id)*" already existed")
    end
    hid=length(structure.nodes)+1
    node=Node(id,hid,Float64(x),Float64(y),Float64(z))
    structure.nodes[id]=node
    return 0
end

"""
    set_nodal_restraint!(structure,id,u1,u2,u3,r1,r2,r3)
设置节点约束
# Arguments
- `structure`: Structure类型实例
- `id`: 节点id
- `u1,u2,u3,r1,r2,r3::Bool`: 自由度约束，true为约束，false不约束
"""
function set_nodal_restraint!(structure::Structure,id,u1::Bool,u2::Bool,u3::Bool,r1::Bool,r2::Bool,r3::Bool)::Int
    id=string(id)
    if !(id in keys(structure.nodes))
        throw("node id "*string(id)*" does't existed")
    end
    structure.nodes[id].restraints=[u1,u2,u3,r1,r2,r3]
    return 0
end

"""
    set_nodal_spring!(structure,id,u1,u2,u3,r1,r2,r3)
设置节点弹簧
# Arguments
- `structure`: Structure类型实例
- `id`: 节点id
- `u1,u2,u3,r1,r2,r3`::Number`: 弹簧刚度
"""
function set_nodal_spring!(structure::Structure,id,u1,u2,u3,r1,r2,r3)::Int
    id=string(id)
    if !(id in keys(structure.nodes))
        throw("node id "*string(id)*" does't existed")
    end
    structure.nodes[id].spring=Float64.([u1,u2,u3,r1,r2,r3])
    return 0
end

"""
    set_nodal_mass!(structure,id,u1,u2,u3,r1,r2,r3)
设置节点附加质量
# Arguments
- `structure`: Structure类型实例
- `id`: 节点id
- `u1,u2,u3,r1,r2,r3`::Number`: 各自由度集中质量
"""
function set_nodal_mass!(structure::Structure,id,u1,u2,u3,r1,r2,r3)::Int
    id=string(id)
    if !(id in keys(structure.nodes))
        throw("node id "*string(id)*" does't existed")
    end
    structure.nodes[id].mass=Float64.([u1,u2,u3,r1,r2,r3])
    return 0
end

function add_link!(structure::Structure,id,i,j,E,A,ρ)
    hid=length(structure.links)+1
    node1=structure.nodes[findfirst(x->x.id==string(i),structure.nodes)]
    node2=structure.nodes[findfirst(x->x.id==string(j),structure.nodes)]
    link=Link(id,hid,node1,node2,Float64(E),Float64(A),Float64(ρ))
    push!(structure.links,link)
end

function add_cable!(structure::Structure,id,i,j,E,A,ρ)
    hid=length(structure.cables)+1
    node1=structure.nodes[findfirst(x->x.id==string(i),structure.nodes)]
    node2=structure.nodes[findfirst(x->x.id==string(j),structure.nodes)]
    cable=Cable(id,hid,node1,node2,E,A,ρ)
    push!(structure.cables,cable)
end

"""
    add_beam!(structure,id,i,j,mat_id,sec_id)
向structure实例加入beam单元
# Arguments
- `structure`: Structure类型实例
- `id`: 单元id
- `i,j`: 节点id
- `mat_id`: 材料id
- `sec_id`: 截面id
"""
function add_beam!(structure::Structure,id,i,j,mat_id,sec_id)::Int
    id=string(id)
    hid=length(structure.beams)+1
    if id in keys(structure.beams)
        throw("beam id "*string(id)*" already exists!")
    end
    i,j=string(i),string(j)
    if !(i in keys(structure.nodes))
        throw("node with id "*string(i)*" doesn't exist!")
    end
    if !(j in keys(structure.nodes))
        throw("node with id "*string(j)*" doesn't exist!")
    end
    if !(mat_id in keys(structure.materials))
        throw("material with id "*string(mat_id)*" doesn't exist!")
    end
    if !(sec_id in keys(structure.sections))
        throw("section with id "*string(sec_id)*" doesn't exist!")
    end
    node1=structure.nodes[i]
    node2=structure.nodes[j]
    material=structure.materials[mat_id]
    section=structure.sections[sec_id]
    beam=Beam(id,hid,node1,node2,material,section)
    structure.beams[id]=beam
    return 0
end

"""
    set_beam_orient!(structure,id,degree)
设置beam单元旋转指向
# Arguments
- `structure`: Structure类型实例
- `id`: 单元id
- `degree`: 绕单元1轴旋转角度
"""
function set_beam_orient!(structure::Structure,id,degree)::Int
    id=string(id)
    if !(id in keys(structure.beams))
        throw("beam id "*string(id)*" doesn't exists!")
    end
    rad=π/180*degree
    Rₓ=[1 0 0;
        0 cos(rad) -sin(rad);
        0 sin(rad) cos(rad)]
    structure.beams[id].T[1:3,1:3]*=Rₓ
    structure.beams[id].T[4:6,4:6]*=Rₓ
    structure.beams[id].T[7:9,7:9]*=Rₓ
    structure.beams[id].T[10:12,10:12]*=Rₓ
    return 0
end

"""
    set_beam_release!(structure,id,fᵢ₁,fᵢ₂,fᵢ₃,m₁₁,mᵢ₂,mᵢ₃,fⱼ₁,fⱼ₂,fⱼ₃,mⱼ₁,mⱼ₂,mⱼ₃)
设置beam单元自由度释放
# Arguments
- `structure`: Structure类型实例
- `id`: 单元id
- `fᵢ₁,fᵢ₂,fᵢ₃,m₁₁,mᵢ₂,mᵢ₃,fⱼ₁,fⱼ₂,fⱼ₃,mⱼ₁,mⱼ₂,mⱼ₃::Bool`: 释放自由度，true表示释放，false不释放
"""
function set_beam_release!(structure::Structure,id,fᵢ₁::Bool,fᵢ₂::Bool,fᵢ₃::Bool,m₁₁::Bool,mᵢ₂::Bool,mᵢ₃::Bool,fⱼ₁::Bool,fⱼ₂::Bool,fⱼ₃::Bool,mⱼ₁::Bool,mⱼ₂::Bool,mⱼ₃::Bool)::Int
    id=string(id)
    if !(id in keys(structure.beams))
        throw("beam id "*string(id)*" doesn't exists!")
    end
    structure.beams[id].release=[fᵢ₁,fᵢ₂,fᵢ₃,m₁₁,mᵢ₂,mᵢ₃,fⱼ₁,fⱼ₂,fⱼ₃,mⱼ₁,mⱼ₂,mⱼ₃]
    return 0
end

"""
    add_quad!(structure,id,i,j,k,l,mat_id,t)
向structure实例加入quad单元
# Arguments
- `structure`: Structure类型实例
- `id`: 单元id
- `i,j,k,l`: 节点id
- `mat_id`: 材料id
- `t`: 截面厚度
"""
function add_quad!(structure::Structure,id,i,j,k,l,mat_id,t;t2=0,t3=0,t4=0,elm_type="DKGQ",mass_type="concentrate")::Int
    id=string(id)
    hid=length(structure.quads)+1
    if id in keys(structure.quads)
        throw("quad id "*string(id)*" already exists!")
    end
    i,j,k,l=string(i),string(j),string(k),string(l)
    for n_i in (i,j,k,l)
        if !(n_i in keys(structure.nodes))
            throw("node with id "*n_i*" doesn't exist!")
        end
    end
    if !(string(mat_id) in keys(structure.materials))
        throw("material with id "*string(mat_id)*" doesn't exist!")
    end
    node1=structure.nodes[i]
    node2=structure.nodes[j]
    node3=structure.nodes[k]
    node4=structure.nodes[l]
    material=structure.materials[mat_id]
    quad=Quad(id,hid,node1,node2,node3,node4,material,t,t2,t3,t4,elm_type,mass_type)
    structure.quads[id]=quad
    return 0
end

"""
    set_quad_rotation!(structure,id,degree)
设置单元局部坐标系转角
# Arguments
- `structure`: Structure类型实例
- `id`: 单元id
- `degree`: 旋转角度（ᵒ）
"""
function set_quad_rotation!(structure::Structure,id,degree)::Int
    id=string(id)
    if !(id in keys(structure.quads))
        throw("quad id "*string(id)*" doesn't exists!")
    end
    rad=π/180*degree
    Rₓ=[cos(rad) -sin(rad) 0;
        sin(rad) cos(rad) 0;
        0 0 1]
    for i in 1:4
        structure.quads[id].T[6i-5:6i-3,6i-5:6i-3]*=Rₓ
        structure.quads[id].T[6i-2:6i,6i-2:6i]*=Rₓ
    end
    return 0
end

"""
    add_tria!(structure,id,i,j,k,mat_id,t)
向structure实例加入Tria单元
# Arguments
- `structure`: Structure类型实例
- `id`: 单元id
- `i,j,k`: 节点id
- `mat_id`: 材料id
- `t`: 截面厚度
"""
function add_tria!(structure::Structure,id,i,j,k,mat_id,t;t2=0,t3=0,t4=0,elm_type="DKGQ",mass_type="concentrate")::Int
    id=string(id)
    hid=length(structure.trias)+1
    if id in keys(structure.trias)
        throw("tria id "*string(id)*" already exists!")
    end
    i,j,k=string(i),string(j),string(k)
    for n_i in (i,j,k)
        if !(n_i in keys(structure.nodes))
            throw("node with id "*n_i*" doesn't exist!")
        end
    end
    if !(mat_id in keys(structure.materials))
        throw("material with id "*string(j)*" doesn't exist!")
    end
    node1=structure.nodes[i]
    node2=structure.nodes[j]
    node3=structure.nodes[k]
    material=structure.materials[mat_id]
    tria=Tria(id,hid,node1,node2,node3,material,t,t2,t3,elm_type,mass_type)
    structure.trias[id]=tria
    return 0
end

"""
    set_tria_rotation!(structure,id,degree)
设置三角单元局部坐标系转角
# Arguments
- `structure`: Structure类型实例
- `id`: 单元id
- `degree`: 旋转角度（ᵒ）
"""
function set_tria_rotation!(structure::Structure,id,degree)::Int
    id=string(id)
    if !(id in keys(structure.trias))
        throw("tria id "*string(id)*" doesn't exists!")
    end
    rad=π/180*degree
    Rₓ=[cos(rad) -sin(rad) 0;
        sin(rad) cos(rad) 0;
        0 0 1]
    for i in 1:3
        structure.quads[id].T[6i-5:6i-3,6i-5:6i-3]*=Rₓ
        structure.quads[id].T[6i-2:6i,6i-2:6i]*=Rₓ
    end
    return 0
end

"""
    set_damp_constant!(structure,ζ)
设置structure实例阻尼矩阵为常数阻尼
# Arguments
- `structure`: Structure类型实例
- `ζ`: 阻尼比
"""
function set_damp_constant!(structure::Structure,ζ)::Int
    structure.damp="constant"
    structure.ζ₁=ζ
    return 0
end

"""
    set_damp_Rayleigh!(structure,α,β)
设置structure实例的阻尼矩阵为Rayleigh阻尼
# Arguments
- `structure`: Structure类型实例
- `α`: 刚度矩阵系数
- `β`: 质量矩阵系数
"""
function set_damp_Rayleigh!(structure::Structure,α,β)::Int
    structure.damp="rayleigh"
    structure.ζ₁=α
    structure.ζ₂=β
    return 0
end
