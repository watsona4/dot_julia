using Tables
Tables.istable(::Type{<:Trajectory}) = true
Tables.rowaccess(::Type{<:Trajectory}) = true
Tables.rows(X::Trajectory) = pairs(X)
Tables.columnaccess(::Type{<:Trajectory}) = true
Tables.columns(X::Trajectory) = (t = X.t, x = X.x)
