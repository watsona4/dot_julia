#MDDatasets function tools
#-------------------------------------------------------------------------------

#==Basic tools
===============================================================================#

#Get the value of a particular keyword in the list of keyword arguments:
getkwarg(kwargs::Base.Iterators.Pairs, s::Symbol) = get(kwargs, s, nothing)

#==Ensure interface (similar to assert)
===============================================================================#
#=Similar to assert.  However, unlike assert, "ensure" is not meant for
debugging.  Thus, ensure is never meant to be compiled out.
=#
function ensure(cond::Bool, err)
	if !cond; throw(err); end
end

#Conditionnally generate error using "do" syntax:
function ensure(fn::Function, cond::Bool)
	if !cond; throw(fn()); end
end

#Last line
