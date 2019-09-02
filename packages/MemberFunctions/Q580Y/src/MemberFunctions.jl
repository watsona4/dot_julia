module MemberFunctions

using MacroTools

export @member

function prepostwalk(pre, post, expr)
  MacroTools.walk(pre(expr), x -> prepostwalk(pre, post, x), post)
end

macro member(expr)
  @capture(expr, (f_(obj_::type_, args__) = body_) | (function f_(obj_::type_, args__) body_ end))
  type = getfield(__module__, type)
  let fieldnames = fieldnames(type)
    skipped_vars_stack=[]
    function pre(expr)
      skipped_vars=[]
      if isa(expr, Expr) && expr.head == :let
        assdeclstms = (isa(expr.args[1], Symbol) || expr.args[1].head == :(=)) ? [expr.args[1]] : expr.args[1].args
        for subexpr in assdeclstms
          if isa(subexpr, Symbol)
            push!(skipped_vars, subexpr)
          else
            @capture(subexpr, var_ = val_)
            push!(skipped_vars, var)
          end
        end
      end
      push!(skipped_vars_stack, skipped_vars)
      expr
    end

    function post(expr)
      if isa(expr, Symbol) && expr ∈ fieldnames && !(expr ∈ reduce(vcat, skipped_vars_stack))
        expr = :($(obj).$(expr))
      end
      pop!(skipped_vars_stack)
      expr
    end

    esc(prepostwalk(pre, post, expr))
  end
end

end # module
