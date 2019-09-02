
function parse_add_node!(st::Structure,vals::Vector{String})
    id=vals[1]
    x,y,z=parse.(Float64,vals[2:4])
    add_node!(st,id,x,y,z)
end

function parse_add_quad!(st::Structure,vals::Vector{String})
    id=vals[1]
    n1,n2,n3,n4=vals[2:5]
    mat=vals[6]
    t=parse(Float64,vals[7])
    add_quad!(st,id,n1,n2,n3,n4,mat,t,elm_type="TMGQ")
end

function parse_add_tria!(st::Structure,vals::Vector{String})
    id=vals[1]
    n1,n2,n3=vals[2:4]
    mat=vals[5]
    t=parse(Float64,vals[6])
    add_tria!(st,id,n1,n2,n3,mat,t,elm_type="TMGT")
end

function parse_line!(st::Structure,lcset::LoadCaseSet,line::String)
    ss=split(line,",")
    key=lowercase(strip(ss[1]))
    vals=lowercase.(strip.(ss[2:end]))
    if key=="mat"
    elseif key=="sec"
    elseif key=="node"
        parse_add_node!(st,vals)
    elseif key=="beam"
    elseif key=="quad"
        parse_add_quad!(st,vals)
    elseif key=="tria"
        parse_add_tria!(st,vals)
    elseif key=="lc"
    elseif key=="beamload"
    elseif key=="quadload"
    end
end

function parse_block!(st,lcset,block)
    if length(block)==1
        parse_line!(st,lcset,block[1])
    end
end
