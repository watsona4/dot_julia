
## xdiff.jl - forward and reverse passes of symbolic differentiation

## utils

function extend_deriv!(dg::ExGraph, dzdx_v::Symbol, dzdx::Any)
    subderivs = find_related(dg, dzdx_v)
    pos = indexof(dg, dzdx_v)
    if isempty(subderivs)
        # first split
        dzdx_ex_1 = getexpr(dg[dzdx_v])
        dzdx_ex_2 = dzdx
        dzdx_v_1 = Symbol("$(dzdx_v)__1")
        dzdx_v_2 = Symbol("$(dzdx_v)__2")
        sub_dg = ExGraph(;ctx=copy(dg.ctx))
        parse!(sub_dg, :($dzdx_v_1 = $dzdx_ex_1))
        parse!(sub_dg, :($dzdx_v_2 = $dzdx_ex_2))
        parse!(sub_dg, :($dzdx_v = $dzdx_v_1 .+ $dzdx_v_2))
        sub_dg = fuse_assigned(sub_dg)
        new_nodes = sub_dg.tape
    else
        # dg already contains subderivatives for dzdx_v
        last_idx = parse(Int, split(subderivs[end] |> String, "__")[end])
        dzdx_v_last = Symbol("$(dzdx_v)__$(last_idx + 1)")
        prev_dzdx_ex = getexpr(dg[dzdx_v])
        sub_dg = ExGraph()
        parse!(sub_dg, :($dzdx_v_last = $dzdx))
        parse!(sub_dg, :($dzdx_v = $prev_dzdx_ex .+ $dzdx_v_last))
        sub_dg = fuse_assigned(sub_dg)
        new_nodes = sub_dg.tape
    end
    delete!(dg, pos)
    insert!(dg, pos, new_nodes)
    return dg
end


## forward pass

function forward_pass!(g::ExGraph)
    evaluate!(g) # to get types of all variables and find correct functions to inline
    known_funcs = Set(sanitize(rule[1].args[1]) for rule in DIFF_RULES)
    done = false
    while !done
        graph_funcs = Set(getexpr(nd).args[1] for nd in g
                          if isa(nd, ExNode{:call}) || isa(nd, ExNode{:bcast}))
        unknown_funcs = setdiff(graph_funcs, known_funcs)
        unknown_func_vars = Set(varname(nd) for nd in g
                                if (isa(nd, ExNode{:call}) || isa(nd, ExNode{:bcast}))
                                && getexpr(nd).args[1] in unknown_funcs)
        g = inline_nodes(g, unknown_func_vars)
        evaluate!(g; force=true)
        done = isempty(unknown_func_vars)
    end
    return g
end

## reverse pass

"""
Perform one step of reverse pass. Add derivatives of output variable w.r.t.
node's dependenices to derivative graph.
"""
function rev_step!(g::ExGraph, dg::ExGraph, nd::ExNode{:(=)})
    y = varname(nd)
    x = dependencies(nd)[1]
    dzdx_vname = deriv_name(z, x)
    # parse!(dg, :($))
    error("Not implemented yet")

end


function rev_step!(g::ExGraph, dg::ExGraph, nd::ExNode{:constant})
    # do nothing
end


function rev_step!(g::ExGraph, dg::ExGraph, nd::ExNode{:input})
    # do nothing
end


function rev_step!(g::ExGraph, dg::ExGraph, nd::ExNode{:field})
    ex = getexpr(nd)
    m_name = ex.args[1]
    fld_name = ex.args[2].value
    dzdx_v = deriv_name(g.ctx[:loss], m_name)
    if haskey(dg, dzdx_v)
        m_nd = dg[dzdx_v]
        kw = @get_or_create(m_nd.meta, :kw, Dict())
        dzdy_v = deriv_name(g.ctx[:loss], varname(nd))
        kw[fld_name] = dzdy_v
    else
        m_nd = ExNode{:ctor}(dzdx_v, :(__construct($m_name)))
        kw = @get_or_create(m_nd.meta, :kw, Dict())
        dzdy_v = deriv_name(g.ctx[:loss], varname(nd))
        kw[fld_name] = dzdy_v
        push!(dg, m_nd)
    end
end


function rev_step!(g::ExGraph, dg::ExGraph, nd::ExNode{:ref})
    ex = getexpr(nd)
    base_name = ex.args[1]
    base_val = getvalue(g[base_name])
    idx = ex.args[2]
    dzdx_v = deriv_name(g.ctx[:loss], base_name)
    if !haskey(dg, dzdx_v)
        if isa(base_val, Tuple)
            tuple_ex = Expr(:tuple, (:_ for i=1:length(base_val))...)
            push!(dg, :tuple, dzdx_v, tuple_ex)
        elseif isa(base_val, AbstractArray)
            # experimental: trying to support array literals by converting to tuples
            tuple_ex = Expr(:tuple, (:_ for i=1:length(base_val))...)
            push!(dg, :tuple, dzdx_v, tuple_ex)
        else
            error("Currently only indexing of tuples is supported, " *
                  "but got $(typeof(base_val))")
        end
    end
    dzdx_nd = dg[dzdx_v]
    dzdx_ex = getexpr(dzdx_nd)
    dzdy_v = deriv_name(g.ctx[:loss], varname(nd))
    dzdx_ex.args[idx] = dzdy_v
end


function rev_step!(g::ExGraph, dg::ExGraph, nd::ExNode{:tuple})
    z = g.ctx[:loss]
    dzdy_v = deriv_name(z, varname(nd))
    dzdy_nd = dg[dzdy_v]
    dzdy_ex = getexpr(dzdy_nd)
    for (i, x) in enumerate(dependencies(nd))
        # map x derivative directly to the component in a tuple
        # remove_unused() should then remove tuple altogether
        # alternative way would be to generate expression like :(dz!dx = dz!dt[i])
        dzdx_v = deriv_name(z, x)
        dzdx_ex = dzdy_ex.args[i]
        parse!(dg, :($dzdx_v = $dzdx_ex))
    end
end



function rev_step!(g::ExGraph, dg::ExGraph, nd::ExNode{:call})
    y = varname(nd)
    z = g.ctx[:loss]
    dzdy_v = deriv_name(z, y)
    cg = cat(g, dg)
    ex = getexpr_kw(nd)
    dep_vals = [x in g ? getvalue(g[x]) : Core.eval(g.ctx[:mod], x)
                for x in dependencies(nd)]
    for (i, x) in enumerate(dependencies(nd))
        if !in(x, g)
            # global constant
            continue
        end
        xnd = g[x]
        if isa(xnd, ExNode{:constant})
            # don't clog dg with unnesessary derivs
            continue
        end
        dydx = deriv(ex, dep_vals, i)
        dzdx = subs(dydx, Dict(:ds => dzdy_v))
        # dzdx = expand_const(cg, dzdx) |> simplify
        dzdx_v = deriv_name(z, x)
        if haskey(dg, dzdx_v)
            extend_deriv!(dg, dzdx_v, dzdx)
        else
            parse!(dg, :($dzdx_v = $dzdx))
        end
    end
end


function rev_step!(g::ExGraph, dg::ExGraph, nd::ExNode{:bcast})
    y = varname(nd)
    z = g.ctx[:loss]
    dzdy_v = deriv_name(z, y)
    cg = cat(g, dg)
    ex = bcast_to_call(getexpr_kw(nd))
    # assuming only array-like dependencies
    dep_vals = [x in g ? getvalue(g[x])[1] : Core.eval(g.ctx[:mod], x)[1]
                for x in dependencies(nd)]
    for (i, x) in enumerate(dependencies(nd))
        if !in(x, g)
            # global constant
            continue
        end
        xnd = g[x]
        if isa(xnd, ExNode{:constant})
            # don't clog dg with unnesessary derivs
            continue
        end
        dydx = deriv(ex, dep_vals, i)
        dzdx = subs(dydx, Dict(:ds => dzdy_v))
        dzdx = calls_to_bcast(dzdx)
        # dzdx = expand_const(cg, dzdx) |> simplify
        dzdx_v = deriv_name(z, x)
        if haskey(dg, dzdx_v)
            extend_deriv!(dg, dzdx_v, dzdx)
        else
            parse!(dg, :($dzdx_v = $dzdx))
        end
    end
end


function reverse_pass!(g::ExGraph)
    z = @get_or_create(g.ctx, :loss, varname(g.tape[end]))
    dzdz_var = deriv_name(z, z)
    seed = @get_or_create(g.ctx, :seed, 1.0)
    g.ctx[:method] = :parse  # forcing :parse method for derivative graph
    dg = ExGraph(:($dzdz_var = $seed); ctx=g.ctx)
    for nd in reverse(g.tape)
        rev_step!(g, dg, nd)
    end
    outvars = [deriv_name(z, varname(nd)) for nd in g.tape if isa(nd, ExNode{:input})]
    return fuse_assigned(dg; outvars=outvars)
end


function _xdiff(g::AbstractExGraph)
    g = forward_pass!(g)
    dg = reverse_pass!(g)
    return g, dg
end


"""
    xdiff(ex; ctx=Dict(), inputs...)

Differentiate scalar-valued expression w.r.t. its inputs,
return expression for the derivatives.

    ex = :(sum(w * x .- y))
    dex = xdiff(ex; w=rand(2,3), x=rand(3,4), y=rand(2))

`xdiff()` also accepts a context `ctx::Dict{Any,Any}` which can be used to pass options
and extract additional information. Some options include:

 * `codegen::Espresso.CodeGen` - code generator used for derivative expression;
                                 valid values include `VecotorCodeGen()`, `BufCodeGen()`
                                 and `CuCodeGen()`
"""
function xdiff(ex; ctx=Dict(), inputs...)
    ctx = to_context(ctx)
    codegen = @get_or_create(ctx, :codegen, autoselect_codegen(inputs))
    ctx[:bitness] = sizeof(codegen.eltyp) * 8
    # inputs = unconvert_cuarrays(inputs)
    g = ExGraph(ex; ctx=ctx, inputs...)
    g, dg = _xdiff(g)
    rg = cat(g, dg)
    outvars = [deriv_name(g.ctx[:loss], var) for (var, _) in inputs]
    outvars = pushfirst!(outvars, varname(g[end]))
    push!(rg, :tuple, Espresso.genname(), Expr(:tuple, outvars...))
    rg = topsort(rg)
    infer_deriv_size!(rg) # do we still need this? can we replace rsizes with actual sizes?
    evaluate!(rg)
    return generate_code(codegen, rg)
end


function xdiff_track(f::Function; ctx=Dict(), inputs...)
    ctx = to_context(ctx)
    codegen = @get_or_create(ctx, :codegen, autoselect_codegen(inputs))
    ctx[:bitness] = sizeof(codegen.eltyp) * 8
    g = ExGraph(; ctx=ctx, inputs...)
    og = swap_default_graph!(g)
    tracked_vals = [tracked_val(g, var, val) for (var, val) in inputs]
    f(tracked_vals...)
    swap_default_graph!(og)
    g, dg = _xdiff(g)
    rg = cat(g, dg)
    outvars = pushfirst!([deriv_name(g.ctx[:loss], var) for (var, _) in inputs], varname(g[end]))
    push!(rg, :tuple, Espresso.genname(), Expr(:tuple, outvars...))
    rg = topsort(rg)
    infer_deriv_size!(rg) # do we still need this? can we replace rsizes with actual sizes?
    evaluate!(rg)
    return generate_code(codegen, rg)
end


function xdiff_parse(f::Function; ctx=Dict(), inputs...)
    ctx = to_context(ctx)
    types = ([typeof(val) for (name, val) in inputs]...,)
    args, ex = funexpr(f, types)
    ex = sanitize(ex)
    ctx[:mod] = Espresso.func_mod(f)
    return xdiff(ex; ctx=ctx, inputs...)
end


"""
    df = xdiff(f; ctx=Dict(), inputs...)

Differentiate scalar-valued function w.r.t. its inputs, return derivative function.

    loss(w, x, y) = sum(w * x .- y)
    w = rand(2,3); x = rand(3,4); y = rand(2)
    dloss = xdiff(loss; w=w, x=x, y=y)
    val, dw, dx, dy = dloss(w, x, y)

See also `xgrad()` for a more dynamic API.
"""
function xdiff(f::Function; ctx=Dict(), inputs...)
    ctx = to_context(ctx)
    method = get(ctx, :method, :parse)
    if method == :track
        dex = xdiff_track(f; ctx=ctx, inputs...)
    elseif method == :parse
        dex = xdiff_parse(f; ctx=ctx, inputs...)
    else
        error("Method $method is not supported")
    end
    ctx[:dex] = dex
    mod = get(ctx, :mod, @__MODULE__)
    name = Espresso.genname("$(func_name(f))_deriv_")
    types = ([typeof(val) for (_, val) in inputs]...,)
    args = get_or_generate_argnames(f, types)
    typed_args = [:($a::$t) for (a, t) in zip(args, map(top_type, types))]
    # function with additional argument `mem`
    fn_ex_mem = make_func_expr(name, [typed_args; :mem], [], dex)
    fn = Core.eval(mod, fn_ex_mem)
    # function with kw argument `mem=Dict()`
    fn_ex_mem_kw = make_func_expr(name, typed_args, [:mem => :(Dict{Any,Any}())], dex)
    Core.eval(mod, fn_ex_mem_kw)
    return fn
end
