
## debug.jl - developer utilities, not exported to users

function find_bad(g)
    for i=1:length(g.tape)
        println("Evaliating $(i)th node $(g[i])")
        evaluate!(g, g[i])
    end
end


function load_espresso()
    for n in Base.names(Espresso, true) @eval import Espresso: $n end
end
