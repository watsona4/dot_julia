
module RandomV06

    import Random

    include("random_v06.jl")

    const V06 = Val{6}
    const V07 = Val{7}
    const Vcur = Val{7}

    include("rand_ver.jl")

    export rand_ver,
        seed_ver!,
        rand_ver!,
        randn_ver,
        randn_ver!,
        randexp_ver,
        randexp_ver!,
        bitrand_ver,
        randstring_ver,
        randsubseq_ver,
        randsubseq_ver!,
        shuffle_ver,
        shuffle_ver!,
        randperm_ver,
        randcycle_ver

end
