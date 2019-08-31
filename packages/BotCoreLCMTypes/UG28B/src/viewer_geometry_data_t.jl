# The viewer_geometry_data_t has a field named `type`, which is a reserved
# keyword in Julia v0.7 and below. To get around that, we can just
# construct the expression directly instead of relying on the parser
eval(Expr(:struct, true,
    Expr(:(<:), :viewer_geometry_data_t, :LCMType),
    Expr(:block,
        Expr(:(::), :type, :Int8),
        Expr(:(::), :position, :(SVector{3, Float32})),
        Expr(:(::), :quaternion, :(SVector{4, Float32})),
        Expr(:(::), :color, :(SVector{4, Float32})),
        Expr(:(::), :string_data, :String),
        Expr(:(::), :num_float_data, :Int32),
        Expr(:(::), :float_data, :(Vector{Float32})),
)))

@lcmtypesetup(viewer_geometry_data_t,
    float_data => (num_float_data,)
)
