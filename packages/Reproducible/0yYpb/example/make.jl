module DocMaker
import Reproducible, Random

Random.seed!(1234)

function Reproducible.render(o::Reproducible.CodeBlock, r::Val{:thing}; kw...)
    """
    ```
    The first line of your code was $(strip((o.rows[1].input)))
    ```
    ```
    The output of that line was $(o.rows[1].repldisplay)
    ```
    """
end

@info "building docs..."
Reproducible.build(joinpath(dirname(pathof(Reproducible)), "..", "example", "index.md"); toc=true)
end