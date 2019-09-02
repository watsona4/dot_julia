(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module SequencesDemo

using IntegerSequences

println("\nProduct 1*2*3")
p = ∏([1, 2, 3])
println(p)

println("\nList of first 10000 Kolakoski numbers (timing):")
@time KolakoskiList(10000)

println("\nList of first 10000 partition numbers (timing):")
@time PartitionNumberList(10000)

println("\nList of first 10000 Clausen numbers (timing):")
@time ClausenNumberList(10000)

println("\nList of first 10000 Ramanujan tau numbers (timing):")
@time RamanujanTauList(10000)

println("\nRamanujan tau of n = 10000:")
r = RamanujanTau(10000)
println(r)

println("\nAll partitions of 1, 2, 3, 4 and 5.")
for n in 1:5 Partition(n); println() end

println("\nNumber of points in square lattice on the
circle of radius √n.")
SeqShow(L004018(12))

println("\nThe product of the prime numbers dividing n.")
println(typeof([Radical(n) for n in 0:9]))
SeqShow([Radical(n) for n in 0:9])

println("\nOr:")
A = ZArray(9, Radical)
SeqShow(A)

println("\n=============")

println("\nThe exponential transform of Pascal's triangle.")
T = T055883(8)
ShowAsΔ(T)

println("\nThe row sums of the triangle above.")
Println(RowSums(T))

println("\nThe factorial of 100.")
f = F!(100)
println(f)

println("\nThe rising factorial ↑(20, 80).") # (a.k.a. Pochhammer)
rf = 20 ↑ 80
println(rf)

println("\nThe falling factorial ↓(80, 60).")
ff = 80 ↓ 60
println(ff)

println("\nThe number of divisors of n = 25920.")
t = τ(25920)
println(t)

println("\nThe sum of divisors of n = 25920.")
s = σ(25920)
println(s)

println("\nNumber of acyclic orientations of the
Turán graph T(2n, n) for n = 20.")
g = V033815(20)
println(g)

println("\nThe binomial function defined for all ZZ.
The same way as Maple and Mathematica compute the binomial.
First the familiar Pascal case:")
for n in 0:8
    for k in 0:n print(lpad(Binomial(n, k), 4)) end
    println()
end

println("\nAn extended region on the 2-dim lattice:")
for n in -5:5
    for k in -5:5
        print(lpad(Binomial(n, k), 5))
    end
    println()
end

println("\nKnuth, Graham and Patashnik write in
Concrete Mathematics: Hear us, O mathematicians
of the world! Let us not wait any longer! We can
make many formulas clearer by defining a new notation
now! Let us agree to write m ⊥ n, and to say m is
prime to n, if m and n are relatively prime.\n")
for n in 1:6
    for m in 1:6 print(⊥(m, n), " " ) end
    println()
end

println("\nUsing conversion to integer this can also be written as:\n")
for n in 1:6
    for m in 1:6 print(Int(⊥(m, n)), " " ) end
    println()
end

# Generating the OLMS logo.
# ⍊(n, k) means k is strong prime to n.
# n is strong prime to k iff n is prime to k and n does not divide k-1.
# Insert the line sum(L) == n - 5 && println(n) if you want to see why this
# triangle is called the Save-Prime-Triangle.

println("\nThe Save-Prime-Triangle, the logo of the OLMS
(open library of mathematical sequences).\n")
for n in 5:23
    T = [k for k in 1:n if ⍊(n, k)]
    L = [Int(k ∈ T) for k in 3:(n - 2)]
    println(L)
end

println("\n... have fun with Sequences!")

end # module
