mutable struct SpglibSpacegroupType
    number::Cint
    international_short::NTuple{11, UInt8}
    international_full::NTuple{20, UInt8}
    international::NTuple{32, UInt8}
    schoenflies::NTuple{7, UInt8}
    hall_symbol::NTuple{17, UInt8}
    choice::NTuple{6, UInt8}
    pointgroup_international::NTuple{6, UInt8}
    pointgroup_schoenflies::NTuple{4, UInt8}
    arithmetic_crystal_class_number::Cint
    arithmetic_crystal_class_symbol::NTuple{7, UInt8}
end

function spg_get_spacegroup_type(hall_number::Int64)
    hall_number = Base.convert(Cint, hall_number)

    return ccall((:spg_get_spacegroup_type, libsymspg), SpglibSpacegroupType,
                (Cint, ),
                hall_number)
end
