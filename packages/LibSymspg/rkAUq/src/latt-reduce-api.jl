spg_niggli_reduce!(lattice::Array{Float64, 2},
                symprec::Float64=1e-5) = ccall((:spg_niggli_reduce, libsymspg), Int32,
                                              (Ptr{Float64}, Float64),
                                              lattice, symprec)

spg_delaunay_reduce!(lattice::Array{Float64, 2},
                    symprec::Float64=1e-5) = ccall((:spg_delaunay_reduce, libsymspg), Int32,
                                                  (Ptr{Float64}, Float64),
                                                  lattice, symprec)
