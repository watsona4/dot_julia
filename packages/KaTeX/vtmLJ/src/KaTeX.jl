module KaTeX

const assetsdir = joinpath(@__DIR__, "..", "assets")
const assets = ["auto-render.min.js", "katex.min.css", "katex.min.js"]
const fontsdir = joinpath(assetsdir, "fonts")

using WebIO: Scope, onimport, onjs, node
using JSExpr: @js
using AssetRegistry: register
using Observables: AbstractObservable, Observable

const katex_min_css = joinpath(KaTeX.assetsdir, "katex.min.css")
const katex_min_js = joinpath(KaTeX.assetsdir, "katex.min.js")

"""
`latex(txt)`

Render `txt` in LaTeX using KaTeX. Backslashes need to be escaped:
`latex("\\\\sum_{i=1}^{\\\\infty} e^i")`
"""
function latex(txt)
    (txt isa AbstractObservable) || (txt = Observable(txt))
    register(assetsdir)
    w = Scope(imports=[
        katex_min_js,
        katex_min_css
    ])

    w["value"] = txt

    onimport(w, @js function (k)
        this.k = k
        this.container = this.dom.childNodes[0]
        k.render($(txt[]), this.container)
    end)

    onjs(w["value"], @js (txt) -> this.k.render(txt, this.container))

    w.dom = node(:div)
    w
end

end # module
