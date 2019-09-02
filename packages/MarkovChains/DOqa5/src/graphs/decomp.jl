struct SccNodeData
    depth::Int
    lowlink::Int
    onstack::Bool
end

struct StronglyConnectedComponent
    members::Vector{Int}
    is_bottom::Bool
end

export strongly_connected_components, StronglyConnectedComponent

function update_link(node_info::Vector{SccNodeData}, node::Int, new_node::Int)
    if node_info[node].lowlink > node_info[new_node].lowlink
        node_info[node] = SccNodeData(node_info[node].depth, node_info[new_node].lowlink, node_info[node].onstack)
    end
end





function strongly_connected_components(dg::Digraph)::Vector{StronglyConnectedComponent}
    components = Vector{StronglyConnectedComponent}()
    node_info = fill(SccNodeData(0, 0, false), node_count(dg))
    node_stack = Vector{Int}()
    depth = Int(1)
    function scc_recur(src::Int)
        node_info[src] = SccNodeData(depth, depth, true)
        depth += 1
        push!(node_stack, src)
        is_bottom = true
        for edge ∈ out_edges(dg, src)
            dst = dst_node(dg, edge)
            if  dst != src
                if node_info[dst].depth == 0
                    if !scc_recur(dst)
                        is_bottom = false
                    end
                    update_link(node_info, src, dst)
                elseif node_info[dst].onstack
                    update_link(node_info, src, dst)
                else
                    is_bottom = false
                end
            end
        end
        if node_info[src].lowlink == node_info[src].depth
            mem = Vector{Int}()
            local top_node::Int
            while true
                top_node = pop!(node_stack)
                push!(mem, top_node)
                node_info[top_node] = SccNodeData(node_info[top_node].depth, node_info[top_node].lowlink, false)
                if top_node == src
                    break
                end
            end
            push!(components, StronglyConnectedComponent(mem, is_bottom))
            return false
        else
            return is_bottom
        end
    end
    for n in nodes(dg)
        if node_info[n].depth == 0
            scc_recur(n)
        end
    end
    return components
end
