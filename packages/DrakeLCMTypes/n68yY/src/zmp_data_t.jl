mutable struct zmp_data_t <: LCMType
    timestamp::Int64
    A::SMatrix{4, 4, Float64, 16}
    B::SMatrix{4, 2, Float64, 8}
    C::SMatrix{2, 4, Float64, 8}
    D::SMatrix{2, 2, Float64, 4}
    x0::SMatrix{4, 1, Float64, 4}
    y0::SMatrix{2, 1, Float64, 2}
    u0::SMatrix{2, 1, Float64, 2}
    R::SMatrix{2, 2, Float64, 4}
    Qy::SMatrix{2, 2, Float64, 4}
    S::SMatrix{4, 4, Float64, 16}
    s1::SMatrix{4, 1, Float64, 4}
    s1dot::SMatrix{4, 1, Float64, 4}
    s2::Float64
    s2dot::Float64

    com::SMatrix{4, 1, Float64, 4}
end

@lcmtypesetup(zmp_data_t)
