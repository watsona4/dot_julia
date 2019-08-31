# The sensor_status_t has a field named `type`, which is a reserved
# keyword in Julia v0.7 and below. To get around that, we can just
# construct the expression directly instead of relying on the parser.
eval(Expr(:struct, true,
    Expr(:(<:), :sensor_status_t, :LCMType),
    Expr(:block,
        Expr(:(::), :utime, :Int64),
        Expr(:(::), :sensor_name, :String),
        Expr(:(::), :rate, :Float64),
        Expr(:(::), :type, :Int16),
)))

@lcmtypesetup(sensor_status_t)
