
function jump_to_cbf(problem, name, filename)
    # these are internal functions
    c, A, b, var_cones, con_cones = Core.eval(Main, :(JuMP.conicdata($problem)))
    vartypes = Core.eval(Main, :(JuMP.vartypes_without_fixed($problem)))

    dat = mpbtocbf(name, c, A, b, con_cones, var_cones, vartypes, :Min)

    writecbfdata(filename, dat)
end
