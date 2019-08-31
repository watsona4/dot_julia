
export @dropdims

using MacroTools

"""
    @dropdims sum(A; dims=1)

Macro which wraps such reductions in `dropdims(...; dims=1)`.
Allows `sum(A; dims=1) do x stuff end`,
and works on whole blocks of code like `@views`.
Does not handle other keywords, like `reduce(...; dims=..., init=...)`.
"""
macro dropdims(ex)
    _dropdims(ex)
end

function _dropdims(ex)
    out = MacroTools.postwalk(ex) do x
        if @capture(x, red_(args__, dims=d_)) || @capture(x, red_(args__; dims=d_))
            :( dropdims($x; dims=$d) )
        elseif @capture(x, dropdims(red_(args__, dims=d1_); dims=d2_) do z_ body_ end) ||
               @capture(x, dropdims(red_(args__; dims=d1_); dims=d2_) do z_ body_ end)
            :( dropdims($red($z -> $body, $(args...); dims=$d1); dims=$d2) )
        else
            x
        end
    end
    esc(out)
end
