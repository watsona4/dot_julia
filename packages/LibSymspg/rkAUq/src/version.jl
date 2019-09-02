spg_get_major_version() = Base.convert(Int64,
    ccall((:spg_get_major_version, libsymspg), Cint, () ))
spg_get_minor_version() = Base.convert(Int64,
    ccall((:spg_get_minor_version, libsymspg), Cint, () ))
spg_get_micro_version() = Base.convert(Int64,
    ccall((:spg_get_micro_version, libsymspg), Cint, () ))
