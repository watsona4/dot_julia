st=Structure()
lcset=LoadCaseSet()
add_uniaxial_metal!(st,"q345",2e11,0.3,7850,1.17e-7)

open(joinpath(@__DIR__,"nodes.mz")) do f
    line=readline(f)
    while line!=""
        parse_block!(st,lcset,[line])
        line=readline(f)
    end
end

open(joinpath(@__DIR__,"trias.mz")) do f
    line=readline(f)
    while line!=""
        parse_block!(st,lcset,[line])
        line=readline(f)
    end
end

for node in values(st.nodes)
    if abs(node.loc[2])<1e-6 || abs(node.loc[2]-7.62)<1e-6
        set_nodal_restraint!(st,node.id,true,true,true,false,false,false)
    end
end

add_static_case!(lcset,"DL",1.0)

@time begin
assembly=assemble!(st,lcset)
end

solve(assembly)

for node in values(st.nodes)
    if abs(node.loc[2]-3.81)<1e-3 && abs(node.loc[3]-3.81)<1e-3
        r=result_nodal_displacement(assembly,"DL",node.id)
        @show r
    end
end
