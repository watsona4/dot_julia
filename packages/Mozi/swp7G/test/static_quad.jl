#
# include("../src/Mozi.jl")
# using Test
# using Logging
#
# using .Mozi
#
# const PATH=pwd()
# macro showbanner(word,total=99)
#     n=length(word)
#     m=(total-n)÷2
#     for i in 1:m
#         print("-")
#     end
#     print(word)
#     for i in 1:total-m-n
#         print("-")
#     end
#     println()
# end

@showbanner "Basic quad test"
st=Structure()

add_uniaxial_metal!(st,"steel",2e11,0.3,7849.0474)

add_node!(st,1,1,1,0)
add_node!(st,2,-1,1,0)
add_node!(st,3,-1,-1,0)
add_node!(st,4,1,-1,0)

add_quad!(st,1,4,1,2,3,"steel",1e-3)

set_nodal_restraint!(st,1,true,true,true,true,true,true)
set_nodal_restraint!(st,2,true,true,true,true,true,true)

lcset=LoadCaseSet()
add_static_case!(lcset,"MEMB",0)
add_static_case!(lcset,"BEND",0)
add_nodal_force!(lcset,"MEMB",4,0,-1e5,0,0,0,0)
add_nodal_force!(lcset,"BEND",4,0,0,-10,0,0,0)

assembly=assemble!(st,lcset,path=PATH)
solve(assembly)

r=result_nodal_displacement(assembly,"MEMB",4)
@show r
r=result_nodal_displacement(assembly,"BEND",4)
@show r
@test r≈[0.0, 0.0, -1.06318, 0.799041, 0.226482, 0.0] atol=1e-3

@showbanner "Isoparam quad test"
st=Structure()
add_uniaxial_metal!(st,"steel",2e11,0.3,7849.0474)

add_node!(st,1,7,3.5,0)
add_node!(st,2,5,3,0)
add_node!(st,3,5,1.5,0)
add_node!(st,4,6,2,0)
add_quad!(st,1,4,3,2,1,"steel",1e-3)

set_nodal_restraint!(st,1,true,true,true,true,true,true)
set_nodal_restraint!(st,2,true,true,true,true,true,true)
# for i in [3,4]
#     set_nodal_restraint!(st,i,false,false,false,false,false,true)
# end


lcset=LoadCaseSet()
add_static_case!(lcset,"MEMB",0)
add_static_case!(lcset,"BEND",0)
add_nodal_force!(lcset,"MEMB",4,0,-1e5,0,0,0,0)
add_nodal_force!(lcset,"BEND",4,0,0,-10,0,0,0)

assembly=assemble!(st,lcset,path=PATH)
solve(assembly)

r=result_nodal_displacement(assembly,"MEMB",4)
@show r
r=result_nodal_displacement(assembly,"BEND",4)
@test r≈[0.0, 0.0, -0.348873, 0.233849, 0.0296653, 0.0] atol=1e-3
#
# @showbanner "Quad cantilever test"
# st=Structure()
# lcset=LoadCaseSet()
# #
# add_uniaxial_metal!(st,"steel",2e11,0.3,7849.0474)
# add_node!(st,1,0,0,0)
# add_node!(st,2,1,0,0)
# add_node!(st,3,2,0,0)
# add_node!(st,4,3,0,0)
# add_node!(st,5,0,1,0)
# add_node!(st,6,1,1,0)
# add_node!(st,7,2,1,0)
# add_node!(st,8,3,1,0)
#
# add_quad!(st,1,1,2,6,5,"steel",1e-3)
# add_quad!(st,2,2,3,7,6,"steel",1e-3)
# add_quad!(st,3,3,4,8,7,"steel",1e-3)
# add_static_case!(lcset,"DL",0)
# add_nodal_force!(lcset,"DL",8,0,-1e5,0,0,0,0)
#
# set_nodal_restraint!(st,1,true,true,true,true,true,true)
# set_nodal_restraint!(st,5,true,true,true,true,true,true)
#
# assembly=assemble!(st,lcset,path=PATH)
# solve(assembly)
#
# r=result_nodal_displacement(assembly,"DL",8)
# @show r
