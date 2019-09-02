using .Graphs

export inftime_solve, Reorder, InftimeStateResult, state_cumtime, state_prob, mean_time_to_absorption
struct Reorder
    mat2chain::Vector{Int}
    chain2mat::Vector{Int}
    ntransients::Int
    recur_comp_member_count::Vector{Int}
end

function extend!(dst_array, new_array)
    push!(dst_array, new_array...)
end
"""
reorder states into transient states, recurrent components.
"""
function reorder_states(chain::ContMarkovChain)::Reorder
    comps = strongly_connected_components(chain.state_graph)
    mat2chain = Vector{Int}()
    ntrans = 0
    for comp in filter(comp -> !comp.is_bottom, comps)
        extend!(mat2chain, comp.members)
        ntrans += length(comp.members)
    end
    recur_comp_member_count = Vector{Int}()
    for comp in filter(comp -> comp.is_bottom, comps)
        extend!(mat2chain, comp.members)
        push!(recur_comp_member_count, length(comp.members))
    end
    chain2mat = Vector{Int}(undef, length(mat2chain))
    for i in 1:length(mat2chain)
        chain2mat[mat2chain[i]] = i
    end
    return Reorder(mat2chain, chain2mat, ntrans, recur_comp_member_count)
end

"""
    tt_rate_matrix(chain, mat2chain, chain2mat, ntrans)

create transition rate matrix (to-from order) between transient states.
"""
function tt_rate_matrix(chain, order)
    rows = Vector{Int}()
    cols = Vector{Int}()
    vals = Vector{Float64}()
    for src_mat in 1:order.ntransients
        src_chn = order.mat2chain[src_mat]
        for edge in out_edges(chain.state_graph, src_chn)
            dst_chn = dst_node(chain.state_graph, edge)
            dst_mat = order.chain2mat[dst_chn]
            rate = chain.trans_rates[edge]
            if dst_mat <= order.ntransients
                push!(rows, dst_mat)
                push!(cols, src_mat)
                push!(vals, rate)
            end
            push!(rows, src_mat)
            push!(cols, src_mat)
            push!(vals, -rate)
        end
    end
    sparse(rows, cols, vals, order.ntransients, order.ntransients)
end
"""
    ta_rate_matrix(chain, order, abs_start, nabs)

create transition rate matrix (to-from order) from transient states to
recurrent states within range abs_start, abs_start + abs
"""
function ta_rate_matrix(chain, order, abs_start, abs_end)
    rows = Vector{Int}()
    cols = Vector{Int}()
    vals = Vector{Float64}()
    for src_mat in 1:order.ntransients
        src_chn = order.mat2chain[src_mat]
        for edge in out_edges(chain.state_graph, src_chn)
            dst_chn = dst_node(chain.state_graph, edge)
            dst_mat = order.chain2mat[dst_chn]
            rate = chain.trans_rates[edge]
            if dst_mat >= abs_start && dst_mat <= abs_end
                push!(rows, dst_mat - abs_start + 1)
                push!(cols, src_mat)
                push!(vals, rate)
            end
        end
    end
    sparse(rows, cols, vals, abs_end - abs_start + 1, order.ntransients)
end

"""
    aa_rate_matrix(chain, order, abs_start, nabs)

create transition rate matrix (to-from order) from between
recurrent states within range abs_start, abs_start + abs
"""
function aa_rate_matrix(chain, order, abs_start, abs_end)
    rows = Vector{Int}()
    cols = Vector{Int}()
    vals = Vector{Float64}()
    for src_mat in abs_start:abs_end
        src_chn = order.mat2chain[src_mat]
        total_rate = 0.0
        for edge in out_edges(chain.state_graph, src_chn)
            dst_chn = dst_node(chain.state_graph, edge)
            dst_mat = order.chain2mat[dst_chn]
            rate = chain.trans_rates[edge]
            total_rate += rate
            if dst_mat != abs_end
                push!(rows, dst_mat - abs_start + 1)
                push!(cols, src_mat - abs_start + 1)
                push!(vals, rate)
            end
        end
        if src_mat != abs_end
            push!(rows, src_mat - abs_start + 1)
            push!(cols, src_mat - abs_start + 1)
            push!(vals, -total_rate)
        end
        push!(rows, abs_end - abs_start + 1)
        push!(cols, src_mat - abs_start + 1)
        push!(vals, 1.0)
    end
    sparse(rows, cols, vals, abs_end - abs_start + 1, abs_end - abs_start + 1)
end

struct InftimeStateResult
    reorder::Reorder
    solution::Vector{Float64}
end

"""
    state_prob(result, state)

used to retrieve state probablity from result.
"""
function state_prob(res::InftimeStateResult, state)
    state_mat = res.reorder.chain2mat[state]
    if state_mat <= res.reorder.ntransients
        0.0
    else
        res.solution[state_mat]
    end
end

"""
    state_cumtime(result, state)

used to retrieve state cumulative time from result.
"""
function state_cumtime(res::InftimeStateResult, state)
    state_mat = res.reorder.chain2mat[state]
    if state_mat <= res.reorder.ntransients
        res.solution[state_mat]
    else
        Inf
    end
end
"""
    inftime_state(chain, init_prob; spsolve)

compute state cumulative times/probabilites of the markov chain at time infinity.
`state_prob` and `state_cumtime` can be used to retrieve times/probs from the return value.
"""
function inftime_solve(chain::ContMarkovChain, init_prob; spsolve=Base.:\)
    order = reorder_states(chain)
    sol::Vector{Float64} = fill(0.0, state_count(chain))
    for idx in eachindex(init_prob)
        val = init_prob[idx]
        mat_idx = order.chain2mat[idx]
        if mat_idx <= order.ntransients
            sol[mat_idx] = -val
        else
            sol[mat_idx] = val
        end
    end

    #solve Qₜₜ . τ = -π(0)
    if order.ntransients > 0
        QTT = tt_rate_matrix(chain, order)
        sol[1:order.ntransients] = spsolve(QTT, sol[1:order.ntransients])
    end

    abs_start = order.ntransients + 1
    for nabs in order.recur_comp_member_count
        abs_end = abs_start + nabs - 1
        if order.ntransients > 0
            QTA = ta_rate_matrix(chain, order, abs_start, abs_end)
            sol[abs_start:abs_end] += QTA * sol[1:order.ntransients]
        end
        total_prob = sum(sol[abs_start:abs_end])
        QAA = aa_rate_matrix(chain, order, abs_start, abs_end)
        b = fill(0.0, nabs)
        b[nabs] = total_prob
        sol[abs_start:abs_end] = spsolve(QAA, b)
        abs_start = abs_end + 1
    end
    return InftimeStateResult(order, sol)
end


function mean_time_to_absorption(sol::InftimeStateResult)
    g_start = sol.reorder.ntransients + 1
    for g in sol.reorder.recur_comp_member_count
        if g > 1
            for mat_idx in 1:g
                if sol.solution[mat_idx] > 0
                    return Inf
                end
            end
        end
    end
    sum(sol.solution[1:sol.reorder.ntransients])
end

function mean_time_to_absorption(chain::ContMarkovChain, init_prob)
    sol = inftime_solve(chain::ContMarkovChain, init_prob)
    mean_time_to_absorption(sol)
end
