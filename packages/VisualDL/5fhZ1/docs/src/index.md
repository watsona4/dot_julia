# VisualDL.jl

This package provides a julia wrapper for [VisualDL](https://github.com/PaddlePaddle/VisualDL), which is a deep learning visualization tool that can help design deep learning jobs.

Currently, the wrapper is written on top of the Python SDK of VisualDL by [PyCall](https://github.com/JuliaPy/PyCall.jl). I have tried to write the wrapper on top of the C++ SDK by leveraging [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl). But unluckily a strange error encountered. Hopefully I'll figured it out later and swap the backend into C++.


## Install

- First, install the Python client of VisualDL. Checkout [here](https://github.com/PaddlePaddle/VisualDL#install-with-virtualenv) for a detailed guide. 

- Then add this package as a dependent.

    `pkg> add https://github.com/findmyway/VisualDL.jl`

## Example

```@eval
    Markdown.parse("""
    ```julia
    $(read("example.jl", String))
    ```
    """)
```


## Reference


```@docs
VisualDLLogger
@log_scalar
add_component
as_mode
start_sampling
finish_sampling
set_caption
save
```