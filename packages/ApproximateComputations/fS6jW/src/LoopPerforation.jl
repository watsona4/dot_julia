# Loop Perforation for Approximate Computation
#
# ############################

# Loops over an expression block or function and finds the types of loops
# which we are looking to modify and applies the modification function - `replacementfn`
function LoopPerforation( ex, looptype, replacementfn )
    for i in 1:length(ex.args)
        if(typeof(ex.args[i]) == Expr && length(ex.args[i].args) > 1)
            LoopPerforation(ex.args[i], looptype, replacementfn)
        end
        
        if(typeof(ex.args[i]) == Expr && ex.args[i].head == :for)
            res = EvaluateForLoop(ex.args[i].args[1], looptype, replacementfn)
            ex.args[i].args[1].args[2] = res
        end
    end
end

# When a for loop is found this function tests to see if it is the correct type
# and passes the evaluated Expr to the replacement function so that the replacement
# will be returned. If nothing can be done, the input is returned.
function EvaluateForLoop(ex,  looptype, replacementfn)
    c = 0
    try
        c  = eval(ex)
    catch
        println( "Unable to evaluate" )
    end 

    if( isa(c, looptype) )
        return replacementfn(c)
    end

     return ex
end

# Simple provided perforation functions:

function ClipFrontAndBack(c)
    b = c.start+1
    e = c.stop-1
    return :($(b):$(e))
end

function OnlyOddIterations(c)
    b = c.start
    e = c.stop
    return :($(b):2:$(e))
end

function OnlyEvenIterations(c)
    b = c.start+1
    e = c.stop
    return :($(b):2:$(e))
end

function OnlyFirstHalf(c)
    b = c.start
    e = c.stop
    return :($(b):$(e)/2)
end

function OnlySecondHalf(c)
    b = c.start
    e = c.stop
    return :($(e)/2:$(e))
end
