using Lattices

ups(::Type{ST}, ltc::Lattices.AbstractLattice) where ST = ups(ST, size(ltc))
downs(::Type{ST}, ltc::Lattices.AbstractLattice) where ST = downs(ST, size(ltc))
Random.rand(::Type{ST}, ltc::Lattices.AbstractLattice) where ST = rand(ST, size(ltc))

ups(ltc::Lattices.AbstractLattice) = ups(Bit{Int}, ltc)
downs(ltc::Lattices.AbstractLattice) = downs(Bit{Int}, ltc)
Random.rand(ltc::Lattices.AbstractLattice) = rand(Bit{Int}, ltc)

HilbertSpace{L}(ltc::Lattices.AbstractLattice) where L = HilbertSpace{L}(size(ltc)...)
HilbertSpace(ltc::Lattices.AbstractLattice) = HilbertSpace{Bit{Int}}(ltc)
