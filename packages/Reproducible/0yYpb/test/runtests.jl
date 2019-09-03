using Reproducible, Test

import Reproducible: CodeBlock

module TestMod
end

@testset "CodeBlock" begin
    cb = CodeBlock("x = 1\ny = 2", TestMod)
    @test strip(cb[1].input) == "x = 1"
    @test strip(cb[2].input) == "y = 2"
    @test cb[1].output == 1
    @test cb[2].output == 2
end

