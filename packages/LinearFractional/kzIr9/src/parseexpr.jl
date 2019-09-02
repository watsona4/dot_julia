addtoexpr_reorder(ex::Val{false}, arg) = arg
addtoexpr_reorder(ex::Val{false}, args...) = (*)(args...)
