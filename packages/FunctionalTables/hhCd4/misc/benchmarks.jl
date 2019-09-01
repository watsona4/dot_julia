#####
##### Informal benchmarks
#####

using FunctionalTables

N = 10000
a = rand(1:100, N)
b = rand('a':'z', N)
c = rand(Float64, N)

ft = sort(FunctionalTable((a = a, b = b, c = c)), (:a, :b))

m(ft) = map((_, ft) -> ft, by(ft, (:a, :b)))

@code_warntype m(ft)
@time m(ft)
# f77a599: 0.215s
# 0.09 after by optimization
# 0.07 after collect_columns rewrite

f(ft) = iterate(by(ft, (:a, :b)))
@code_warntype f(ft)



using FunctionalTables
using FunctionalTables: collect_columns, SINKCONFIG, empty_sinks, collect_columns!, start_sinks

@code_warntype collect_columns(SINKCONFIG, [(a = 1, b = 1)], TrustOrdering(()), NamedTuple{(),Tuple{}})


@code_warntype start_sinks(SINKCONFIG, (a = 1, ), NamedTuple{(:a, ), Tuple{Int}})

A = fill((a = 1, ), 3)
elt, state = iterate(A)

@code_warntype collect_columns(SINKCONFIG, A, TrustOrdering(), typeof(NamedTuple()))
@code_warntype collect_columns!(sinks, 0, SINKCONFIG, A, VerifyOrdering(), elt, state)
