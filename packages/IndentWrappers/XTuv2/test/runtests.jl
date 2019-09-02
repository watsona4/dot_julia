using IndentWrappers, Test

@testset "indent" begin
    io = IOBuffer()
    print(io, "toplevel")
    let io = indent(io, 4)
        print(io, '\n', "- level1")
        let io = indent(io, 4)
            print(io, '\n', "- level 2")
            println(io)
            println(io, "test")
            print(io, "closing")
        end
    end
    buffer = String(take!(io))
    expected = "toplevel\n    - level1\n        - level 2\n        test\n        closing"
    @test buffer == expected
end

@testset "write count" begin
    str = "a fish"
    io = indent(IOBuffer(), 8)
    @test write(io, str) == length(str)
    @test write(io, '\n', str) == length(str) + 8 + 1
end

@testset "forwarding" begin
    io = IOContext(stdout, :foo => 42)
    iw = indent(io, 5)
    @test in(:foo => 42, iw)
    @test haskey(iw, :foo)
    @test !haskey(iw, :bar)
    @test iw[:foo] == io[:foo]
    @test displaysize(iw) == displaysize(stdout)
    @test get(iw, :foo, 9) == get(io, :foo, 9)
    @test get(iw, :bar, 9) == get(io, :bar, 9)
end

@testset "show" begin
    @test repr(indent(stdout, 4)) == repr(stdout) * " indented by 4 spaces"
end
