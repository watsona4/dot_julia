using Test
using MiniLogging
using MiniLogging: @debug, @info, @warn, @error, @critical
using MiniLogging.Hierarchy
using MiniLogging.Hierarchy: Ancestors

@test collect(Ancestors("")) == []
@test collect(Ancestors("a")) == [""]
@test collect(Ancestors("a.bb.ccc")) == ["a.bb", "a", ""]
@test collect(Ancestors("❤.❤❤.❤❤❤")) == ["❤.❤❤", "❤" , ""]
@test_throws ErrorException collect(Ancestors(".a.bb.ccc"))
@test_throws ErrorException collect(Ancestors("a.b.cc."))
@test_throws ErrorException collect(Ancestors("a.b..cc"))


t = Tree()
push!(t, "a.b.c")
@test parent_node(t, "a.b.c") == ""
push!(t, "a.b.c")
@test parent_node(t, "a.b.c") == ""
push!(t, "a.b")
@test parent_node(t, "a.b") == ""
@test parent_node(t, "a.b.c") == "a.b"
push!(t, "a.b.c.d")
@test parent_node(t, "a.b.c.d") == "a.b.c"
push!(t, "a.b.c.d2")
@test parent_node(t, "a.b.c.d2") == "a.b.c"
push!(t, "a.b.c.d.❤")
@test parent_node(t, "a.b.c.d.❤") == "a.b.c.d"
push!(t, "a.b.❤.d")
@test parent_node(t, "a.b.❤.d") == "a.b"
push!(t, "a")
@test parent_node(t, "a") == ""
push!(t, "")
@test parent_node(t, "") == ""


open("stdout.out", "w") do f1
    open("stderr.out", "w") do f2
        redirect_stdout(f1) do
            redirect_stderr(f2) do
                include("test_log.jl")
            end
        end
    end
end

out1 = readlines("stdout.log")
err1 = readlines("stderr.log")
out2 = readlines("stdout.out")
err2 = readlines("stderr.out")

@test out1 == out2
@test err1 == err2
