#MDDatasets: meas interface
#Intent: use meas(:MEASTYPE, ...) to minimize namespace pollution.
#-------------------------------------------------------------------------------

meas(mtype::Symbol, args...; kwargs...) =
	meas(DS(mtype), args...; kwargs...)
meas(::DS{T}, args...; kwargs...) where T<:Symbol =
	throw(ArgumentError("Measurement type: meas($mtype, ...) not recognized."))

meas(::DS{:xcross}, args...; kwargs...) = xcross(args...; kwargs...)
meas(::DS{:ycross}, args...; kwargs...) = ycross(args...; kwargs...)
meas(::DS{:xcross1}, args...; kwargs...) = xcross1(args...; kwargs...)
meas(::DS{:ycross1}, args...; kwargs...) = ycross1(args...; kwargs...)

meas(::DS{:delay}, args...; kwargs...) = measdelay(args...; kwargs...)

#Last Line
