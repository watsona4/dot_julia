#InspectDR: Functionality for user-overwritable styles (ex: used in stylesheets)
#-------------------------------------------------------------------------------


#==Main types
===============================================================================#
abstract type AbstractStyle end
struct StyleDefaultType end #Keep style default
const StyleDefault = StyleDefaultType()

#Defines a "style" object (to implement user-overwritable styles):
mutable struct StyleType{T<:AbstractStyle}
	values::T #Active values
	defaults::T #Defaults for this style
	overwrite::Set{Symbol} #Masks out which elements user wishes to overwrite
end
StyleType(defaults::T) where T<:AbstractStyle =
	StyleType(deepcopy(defaults), defaults, Set{Symbol}([]))


#==Main functions
===============================================================================#
function overwritestyleattrib(s::Set{Symbol}, key::Symbol, value::StyleDefaultType)
	if key in s
		pop!(s, key)
	end
	return
end
overwritestyleattrib(s::Set{Symbol}, key::Symbol, value) = push!(s, key)

overwrite!(s::AbstractStyle, key::Symbol, value::StyleDefaultType) = nothing
function overwrite!(s::AbstractStyle, key::Symbol, value)
	value = convert(typeof(getfield(s, key)), value) #Need proper type
	setfield!(s, key, value)
end

function overwrite!(s::StyleType, key::Symbol, value)
	overwrite!(s.values, key, value)
	overwritestyleattrib(s.overwrite, key, value)
end

function refresh!(s::StyleType)
	proplist = fieldnames(typeof(s.defaults))
	for key in proplist
		if !(key in s.overwrite)
			value = getfield(s.defaults, key)
			setfield!(s.values, key, value)
		end
	end
	return
end

function setstyle!(s::StyleType{T}, value::T; refresh::Bool=true) where T<:AbstractStyle
	s.defaults = value
	if refresh
		refresh!(s)
	end
	return
end


#==Mutators
===============================================================================#
Base.setindex!(s::AbstractStyle, value, key::Symbol) = overwrite!(s, key, value)
Base.setindex!(s::StyleType, value, key::Symbol) = overwrite!(s, key, value)
Base.getindex(s::AbstractStyle, key::Symbol) = getfield(s, key)
Base.getindex(s::StyleType, key::Symbol) = getfield(s.values, key)


#Last line
