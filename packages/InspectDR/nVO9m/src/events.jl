#InspectDR: Event handling
#-------------------------------------------------------------------------------

#=TODO:
Use Reactive?  Don't want to risk slowing down InspectDR by adding another
module for the simple interaction needed here.
=#


#==Types
===============================================================================#
struct HandlerInfo
	listener::Any
	fn::Function
end
#Raises event:
#fn(listener, source, args...)
#    where source is the signal generator.


#==Functions
===============================================================================#
raiseevent(::Nothing, source, args...) = nothing

function raiseevent(info::HandlerInfo, source, args...)
	eventhandler = info.fn
	eventhandler(info.listener, source, args...)
end

function raiseevent(infolist::Vector{HandlerInfo}, source, args...)
	for info in infolist
		raiseevent(info, source, args...)
	end
end


#Last line
