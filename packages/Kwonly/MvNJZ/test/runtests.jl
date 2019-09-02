try
    using Test
catch
    using Base.Test
end

let in_code = false, code = []
    for line in readlines(joinpath(@__DIR__, "..", "README.md"))
        if line == "```julia"
            in_code = true
        elseif line == "```"
            in_code = false
        elseif in_code
            push!(code, line)
        end
    end
    write(joinpath(@__DIR__, "README.jl"), join(code, "\n"))
end

@testset "$file" for file in [
        "test_add_kwonly.jl",
        "README.jl",
        ]
    @time include(file)
end
