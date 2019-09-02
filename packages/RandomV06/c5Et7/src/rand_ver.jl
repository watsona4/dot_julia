#=

ver_rand and its variants

=#

#using Random

#=
using Random: srand, rand, rand!, 
randn, randn!, randexp, randexp!, 
bitrand, 
randstring, 
randsubseq,randsubseq!,
shuffle,shuffle!,
randperm, randcycle
=#

#import Random

rand_ver(::Type{V06}, args...) = RandomV06.rand(args...)
seed_ver!(::Type{V06}, args...) = RandomV06.srand(args...)
rand_ver!(::Type{V06}, args...) = RandomV06.rand!(args...)
randn_ver(::Type{V06}, args...) = RandomV06.randn(args...)
randn_ver!(::Type{V06}, args...) = RandomV06.randn!(args...)
randexp_ver(::Type{V06}, args...) = RandomV06.randexp(args...)
randexp_ver!(::Type{V06}, args...) = RandomV06.randexp!(args...)
bitrand_ver(::Type{V06}, args...) = RandomV06.bitrand(args...)
randstring_ver(::Type{V06}, args...) = RandomV06.randstring(args...)
randsubseq_ver(::Type{V06}, args...) = RandomV06.randsubseq(args...)
randsubseq_ver!(::Type{V06}, args...) = RandomV06.randsubseq!(args...)
shuffle_ver(::Type{V06}, args...) = RandomV06.shuffle(args...)
shuffle_ver!(::Type{V06}, args...) = RandomV06.shuffle!(args...)
randperm_ver(::Type{V06}, args...) = RandomV06.randperm(args...)
randcycle_ver(::Type{V06}, args...) = RandomV06.randcycle(args...)

seed_ver!(::Type{Vcur}, args...) = Random.seed!(args...)
rand_ver(::Type{Vcur}, args...) = Random.rand(args...)
rand_ver!(::Type{Vcur}, args...) = Random.rand!(args...)
randn_ver(::Type{Vcur}, args...) = Random.randn(args...)
randn_ver!(::Type{Vcur}, args...) = Random.randn!(args...)
randexp_ver(::Type{Vcur}, args...) = Random.randexp(args...)
randexp_ver!(::Type{Vcur}, args...) = Random.randexp!(args...)
bitrand_ver(::Type{Vcur}, args...) = Random.bitrand(args...)
randstring_ver(::Type{Vcur}, args...) = Random.randstring(args...)
randsubseq_ver(::Type{Vcur}, args...) = Random.randsubseq(args...)
randsubseq_ver!(::Type{Vcur}, args...) = Random.randsubseq!(args...)
shuffle_ver(::Type{Vcur}, args...) = Random.shuffle(args...)
shuffle_ver!(::Type{Vcur}, args...) = Random.shuffle!(args...)
randperm_ver(::Type{Vcur}, args...) = Random.randperm(args...)
randcycle_ver(::Type{Vcur}, args...) = Random.randcycle(args...)

;

