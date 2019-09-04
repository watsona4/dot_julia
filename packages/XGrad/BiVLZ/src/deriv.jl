
## deriv.jl - derivative of a single ExNode

const DIFF_PHS = Set([:w, :x, :y, :z, :i, :j, :k,])

isparameters(a) = isa(a, Expr) && a.head == :parameters

function without_types(pat)
    rpat = copy(pat)
    for i=2:length(rpat.args)
        a = rpat.args[i]
        if !isparameters(a)  # parameters aren't modified
            rpat.args[i] = isa(a, Expr) ? a.args[1] : a
        end
    end
    return rpat
end


function get_arg_names(pat)
    return [isa(a, Expr) ? a.args[1] : a for a in pat.args[2:end] if !isparameters(a)]
end

function get_arg_types(pat)
    return [isa(a, Expr) ? Core.eval(Base, a.args[2]) : Any
            for a in pat.args[2:end] if !isparameters(a)]
end


function match_rule(rule, ex, dep_vals, idx)
    tpat, (vname, rpat) = rule
    vidx = findfirst(isequal(vname), get_arg_names(tpat))
    if idx != vidx
        return nothing
    end
    dep_types = get_arg_types(tpat)
    if length(dep_vals) != length(dep_types) ||
        !all(isa(v, t) for (v, t) in zip(dep_vals, dep_types))
        return nothing
    end
    pat = without_types(tpat)
    ex_ = without_keywords(ex)
    if !matchingex(pat, ex_; phs=DIFF_PHS)
        return nothing
    else
        return pat => rpat
    end
end


function rewrite_with_keywords(ex, pat, rpat)
    if rpat isa Expr && rpat.head == :call
        op, args, kw_args = parse_call_expr(ex)
        ex_no_kw = make_call_expr(op, args)
        rex_no_kw = rewrite(ex_no_kw, pat, rpat; phs=DIFF_PHS)
        rex = with_keywords(rex_no_kw, kw_args)
    else
        rex = rewrite(ex, pat, rpat; phs=DIFF_PHS)
    end
    return rex
end


function deriv(ex, dep_vals, idx::Int)
    rex = nothing
    for rule in DIFF_RULES
        m = match_rule(rule, ex, dep_vals, idx)
        if m != nothing
            pat, rpat = m
            rex = rewrite_with_keywords(ex, pat, rpat)
            break
        end
    end
    if rex == nothing
        error("Can't find differentiation rule for $ex at $idx " *
              "with types $(map(typeof, dep_vals))")
    end
    return rex
end


"""
Internal function for finding rule by function name
"""
function find_rules_for(fun)
    return [r for r in DIFF_RULES if r[1].args[1] == fun]
end
