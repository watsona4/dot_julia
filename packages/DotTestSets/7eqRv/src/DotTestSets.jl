module DotTestSets

using Printf
using Test: AbstractTestSet, Result, Pass, Fail, Error, Broken,
    get_testset_depth, get_testset

import Test: record, finish
export DotTestSet

const WIDTH = 70
const column = Ref(0)

mutable struct DotTestSet <: AbstractTestSet
    desc::AbstractString
    passes::Vector
    fails::Vector
    errors::Vector
    starttime::Float64
    opts
end
DotTestSet(desc::AbstractString; opts...) =
    DotTestSet(desc, [], [], [], time_ns(), opts)

function log(ts::DotTestSet, str::AbstractString; err=false, fail=false)
    w = textwidth(str)
    column[] = column[] + w
    column[] > WIDTH && (println(); column[] = w)
    (err || fail) ? printstyled(str, color=:red, bold=true) : print(str)
end

record(ts::DotTestSet, res::Pass) = (log(ts, "."); push!(ts.passes, res))

record(ts::DotTestSet, res::Fail) =
    (log(ts, "F", fail=true); push!(ts.fails, res))

record(ts::DotTestSet, res::Error) =
    (log(ts, "E", err=true); push!(ts.errors, res))

record(ts::DotTestSet, res::Broken) =
    (log(ts, "B"); push!(ts.passes, res))

function record(ts::DotTestSet, kid::DotTestSet)
    append!(ts.passes, kid.passes)
    append!(ts.fails, kid.fails)
    append!(ts.errors, kid.errors)
end

function finish(ts::DotTestSet)
    sep() = println("-"^WIDTH)
    if get_testset_depth() == 0
        column[] = 0
        println()
        for err in ts.errors
            sep()
            println(err)
        end
        for fail in ts.fails
            sep()
            println(fail)
        end
        sep()
        n = length(ts.passes) + length(ts.fails) + length(ts.errors)
        s = (time_ns() - ts.starttime)/1e9
        @printf("Ran %i tests in %.3f s\n\n", n, s)

        nfails = length(ts.fails)
        nerrors = length(ts.errors)

        if nfails == nerrors == 0
            println("OK")
        else
            printstyled("FAILED", color=:red, bold=true)
            print(" (")

            problems = []
            nfails > 0 && push!(problems, "failures=$nfails")
            nerrors > 0 && push!(problems, "errors=$nerrors")
            print(join(problems, ", "))

            println(")")
        end
    else
        record(get_testset(), ts)
    end
end

end
