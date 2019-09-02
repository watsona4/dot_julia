@info "---------- Basic cantilever test ----------"
st=Structure()
lcset=LoadCaseSet()

add_uniaxial_metal!(st,"steel",2e11,0.2,7849.0474)
add_general_section!(st,"frame",4.26e-3,3.301e-6,6.572e-5,9.651e-8,1e-3,1e-3,0,0)

add_node!(st,1,0,0,0)
add_node!(st,2,18,12,12)
add_beam!(st,1,1,2,"steel","frame")

set_nodal_restraint!(st,1,true,true,true,true,true,true)

add_static_case!(lcset,"DL",1.1)

assembly=assemble!(st,lcset,path=PATH)

solve(assembly)

r=result_nodal_reaction(assembly,"DL",1)
@test r≈[-2.83076e-10,-9.04954e-10,8926.15,53556.9,-80335.3,-3.29473e-8] atol=1e-1
r=result_nodal_displacement(assembly,"DL",2)
@test r≈[0.454025, 0.302683, -0.98385, -0.0336002, 0.0504003, -5.77725e-13] atol=1e-3

@info "---------- Modal test ----------"
clear_result!(assembly)
lcset=LoadCaseSet()
add_static_case!(lcset,"DL",1.0)
add_modal_case!(lcset,"modal")
set_modal_params!(lcset,"modal",modal_type="eigen",n=4)
assembly=assemble!(st,lcset,path=PATH)
# set_mass_source!(assembly,"DL")
solve(assembly)
T=result_modal_period(assembly,"modal")
@info "To be examined" T=T

@info "----------Node spring test----------"
clear_result!(assembly)

set_nodal_restraint!(st,1,false,false,false,false,false,false)
set_nodal_spring!(st,1,1e3,2e3,3e3,4e3,5e3,6e3)

lcset=LoadCaseSet()
add_static_case!(lcset,"DL",1.1)

assembly=assemble!(st,lcset,path=PATH)
solve(assembly)
r=result_nodal_displacement(assembly,"DL",2)
@test r≈[193.258,160.973,-453.836,-13.4228,16.1175,3.14657e-9] atol=1e-2
