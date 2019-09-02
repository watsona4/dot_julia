#MDDatasets show functions
#-------------------------------------------------------------------------------

#==DataF1 show functions
===============================================================================#
#show() a compact version of a vector:
function _showcompact(io::IO, x::Vector{T}) where T<:Number
	maxelem = 10 #WANTCONST
	if length(x)>maxelem
		print(io, "[")
		for i in 1:(maxelem-3)
			print(io, x[i], ",")
		end
		print(io, "...")
		for v in x[end-1:end]
			print(io, ",", v)
		end
		print(io, "]")
	else
		show(io, x)
	end
end

#Don't show module name/subtypes for DataF1:
function Base.show(io::IO, ds::DataF1{TX,TY}) where {TX<:Number, TY<:Number}
	print(io, "DataF1(x=")
		_showcompact(io, ds.x)
		print(io, ",y=")
		_showcompact(io, ds.y)
		print(io, ")")
end


#==Misc show functions
===============================================================================#
#==
function Base.show(io::IO, d::DataScalar{T}) where T
	print(io, "DataScalar{$T}($(d.v))")
end
==#

function Base.show(io::IO, p::Point2D{TX,TY}) where {TX,TY}
	print(io, "Point2D{$TX,$TY}($(p.x), $(p.y))")
end

function Base.show(ctx::IOContext, p::Point2D)
	if get(ctx.dict, :compact, false) #Show compact:
		print(io, "pt($(p.x), $(p.y))")
	else
		show(ctx.io, p)
	end
end

function Base.show(io::IO, x::CrossType)
	proplist = String[]
	x.v&XINGTYPE_RISE != 0 ? push!(proplist, "rise") : nothing
	x.v&XINGTYPE_FALL != 0 ? push!(proplist, "fall") : nothing
	x.v&XINGTYPE_SING != 0 ? push!(proplist, "sing") : nothing
	x.v&XINGTYPE_FLAT != 0 ? push!(proplist, "flat") : nothing
	x.v&XINGTYPE_THRU != 0 ? push!(proplist, "thru") : nothing
	x.v&XINGTYPE_REV != 0 ? push!(proplist, "rev") : nothing
	x.v&XINGTYPE_FIRSTLAST != 0 ? push!(proplist, "firstlast") : nothing

	print(io, "CrossType(", join(proplist, ", "), ")")
end


#Last line
