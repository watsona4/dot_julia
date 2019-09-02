@info "---------- Modal test ----------"
st=Structure()
lcset=LoadCaseSet()

add_uniaxial_metal!(st,"steel",2e11,0.2,7849.0474)
add_general_section!(st,"frame",4.26e-3,3.301e-6,6.572e-5,9.651e-8,1e-3,1e-3,0,0)

add_node!(st,1,0,0,0)
add_node!(st,2,18,18,0)
add_beam!(st,1,1,2,"steel","frame")

set_nodal_restraint!(st,1,true,true,true,true,true,true)

add_modal_case!(lcset,"MODAL")
set_modal_params!(lcset,"MODAL",modal_type="eigen")

@info "---------- Time history test ----------"

t=0:1/64:20
f=sin.(t)

add_static_case!(lcset,"STATIC")
add_nodal_force!(lcset,"STATIC",2,0,0,-1,0,0,0)

add_time_history_case!(lcset,"DIFF",t,f)
set_time_history_params!(lcset,"DIFF",0)
add_nodal_force!(lcset,"DIFF",2,0,0,-1,0,0,0)

add_time_history_case!(lcset,"NEWMARK",t,f)
add_nodal_force!(lcset,"NEWMARK",2,0,0,-1,0,0,0)
add_nodal_force!(lcset,"NEWMARK",2,0,0,-1,0,0,0)

add_time_history_case!(lcset,"WILSON",t,f)
set_time_history_params!(lcset,"WILSON",2)
add_nodal_force!(lcset,"WILSON",2,0,0,-1,0,0,0)

add_time_history_case!(lcset,"MODALDECOMP",t,f)
set_time_history_params!(lcset,"MODALDECOMP",3,modal_case="MODAL")
add_nodal_force!(lcset,"MODALDECOMP",2,0,0,-1,0,0,0)

assembly=assemble!(st,lcset,path=PATH)
solve(assembly)

T=result_modal_period(assembly,"MODAL")
@show T
# u=result_nodal_time_history(assembly,"NEWMARK",2,0,3)
r=result_nodal_time_history(assembly,"MODALDECOMP",2,0,3)
