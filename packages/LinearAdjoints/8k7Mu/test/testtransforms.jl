testex = :(a___laref___i + b___laref___i___laref___j ^ 2 + exp(log(c___laref___1)))
testvars = [:a___laref___i, :b___laref___i___laref___j, :c___laref___1]
utex = :(a[i] + b[i, j] ^ 2 + exp(log(c[1])))
ex, vars = LinearAdjoints.transformrefs(utex, [:a, :b, :c])
@test ex == testex
@test vars == testvars
@test utex == LinearAdjoints.untransformrefs(ex)
@test LinearAdjoints.transformrefs(:(b[i, j + exp(k)]), [:b])[1] == Symbol("b___laref___i___laref___j + exp(k)")
@test LinearAdjoints.untransformrefs(Symbol("b___laref___i___laref___j + exp(k)")) == :(b[i, j + exp(k)])
@test LinearAdjoints.untransformrefs(Symbol("b___laref___end + exp(k)")) == :(b[end + exp(k)])
