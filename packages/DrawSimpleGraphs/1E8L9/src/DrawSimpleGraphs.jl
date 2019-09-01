module DrawSimpleGraphs

using Plots, SimpleGraphs, SimpleDrawing

import SimpleDrawing: newdraw, finish
export newdraw, finish, draw
export draw_labels

function draw_one_edge(a,b,c,d,hue="black")
    draw_segment(a,b,c,d,color=hue)
end

function draw_edges(G::SimpleGraph)
    xy = getxy(G)
    hue = get_line_color(G)
    for ee in elist(G)
        u,v = ee
        draw_one_edge(xy[u][1], xy[u][2], xy[v][1], xy[v][2], hue)
    end
end

function draw_one_node(x,y,hue="black", fill="white", node_size=6)
    draw_point(x,y, markerstrokecolor=hue,
                    markercolor=fill,
                    marker=node_size,
                    markerstrokewidth=1)
end

function draw_nodes(G::SimpleGraph)
    hue = get_line_color(G)
    fill= get_vertex_color(G)
    node_size = get_vertex_size(G)
    xy = getxy(G)
    for v in vlist(G)
        x,y = xy[v]
        draw_one_node(x,y,hue,fill,node_size)
    end
end

"""
`draw(G::SimpleGraph)` draws `G` in its current embedding.
(If `G` does not have an embedding, then it is given a circular
embedding.)
"""
function SimpleDrawing.draw(G::SimpleGraph)
    if !has_embedding(G)
        embed(G)
    end
    newdraw()
    draw_edges(G)
    draw_nodes(G)
    finish()
end


function draw_labels(G::SimpleGraph, fontsize=8)
    if !has_embedding(G)
        embed(G)
    end
    xy = getxy(G)
    for v in G.V
        x,y = xy[v]
        annotate!(x,y,string(v),fontsize)
    end
    finish()
end




include("KnightTourDrawing.jl")

end  # end of module DrawSimpleGraphs
