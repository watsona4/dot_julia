# AST Manipulation for Approximate Computation

# Our main types and wrappers:
# ############################

using Plots.PlotMeasures

global g_ID = 0
function GetGlobalID()
   global g_ID
    g_ID = g_ID + 1
    g_ID
end

function ResetGlobalID()
   global g_ID
    println("WARNING: Global ID has been reset")
    g_ID = 0
end

abstract type TreeMember end

mutable struct Variable <: TreeMember
    var
    id
    Variable(x) = new(x, GetGlobalID())
end

mutable struct Operator <: TreeMember
    op
    leaves
    id
	result
    Operator(x::Variable) = new(identity, [x]      , GetGlobalID(), "NoStoredData"  )
    Operator(fun, x)      = new(fun     , [x]      , GetGlobalID(), "NoStoredData"  )
    Operator(fun, x,y)    = new(fun     , [x, y]   , GetGlobalID(), "NoStoredData"  )
    Operator(fun, x,y,z)  = new(fun     , [x, y, z], GetGlobalID(), "NoStoredData"  )
end

######################
## Debug function to view the tree.
##
########
function printtree(node::TreeMember, level = 0)
    outstr = "|"
    if(level > 0)
        for i in 1:level
            outstr = string(outstr,"  |")
        end
    end
    
    if(typeof(node) == Operator)
        println(string(outstr, "Function(", node.op, ") - (id:$(node.id)) - StoredData:", node.result))
        for leaf in node.leaves        
            if(leaf != nothing)
                if(typeof(leaf) <: TreeMember)
                    printtree(leaf, level+1)
                else
                    varindent ="|"
                    for i in 1:level+1
                        varindent = string(varindent,"  |")
                    end
                    print(string(varindent, "Const ", typeof(leaf), "(", leaf, ")", "\n"))
                end
            end
        end
    else
        println(string(outstr, typeof(node.var), "(", node.var, ") - (id:$(node.id))"))
    end
	
	if(level == 0)
		println("\n")
	end
end

function ToString(node::TreeMember, level = 0)
    outstr = "|"
    if(level > 0)
        for i in 1:level
            outstr = string(outstr,"~~~|")
        end
    end
    
	s = ""
    if(typeof(node) == Operator)
        s = string(s, (string(outstr, "Function(", node.op, ")")), "\n")
        for leaf in node.leaves        
            if(leaf != nothing)
                if(typeof(leaf) <: TreeMember)
                    s = string(s, ToString(leaf, level+1))
                else
                    varindent ="|"
                    for i in 1:level+1
                        varindent = string(varindent,"  |")
                    end
                    s = string(s,(string(varindent, "Const ", typeof(leaf), "(", leaf, ")", "\n")))
                end
            end
        end
    else
        s = string(s, (string(outstr, typeof(node.var), "(", node.var, ")")), "\n")
    end
	
	if(level == 0)
		s = string(s,("\n"))
	end

	s
end

# Extending the environment to allow for operators to work on wrapped types:
# ##########################################################################
# These functions allow us to automatically generate the functions we need for
# the functions we are trying to evaluate.

function GetOverrideFunctionList(func)
    display(func)
    ast = Base.uncompressed_ast(first(methods(func)))
    callsymbols = []
    for line in ast.code
        if(line.head == Symbol(:call))
            argTypes = []
            for arg in line.args[2:end]
                push!(argTypes, Float64)
            end
            
            argumentcount = length(line.args[2:end])
            argTypes[1] = TreeMember
            typeTuple = tuple(argTypes ...)
                       
            # This optimisation check excluded a number of base operators due to the fold definition: operators.jl:502
            #    for op in (:+, :*, :&, :|, :xor, :min, :max, :kron)
            #    @eval begin
            #        ($op)(a, b, c, xs...) = afoldl($op, ($op)(($op)(a,b),c), xs...)
            #    end
            #end
            #if( length(methods(eval(line.args[1].name), typeTuple)) == 0)
                push!(callsymbols, (line.args[1].name, argumentcount))   
                #println("Submitted $(line.args[1].name)")
            #end
        end
    end
    
    callsymbols
end

+(x::TreeMember, y::TreeMember) = Operator(+, x,y)
+(x::TreeMember, y) 			= Operator(+, x,y)
+(x, y::TreeMember) 			= Operator(+, x,y)

-(x::TreeMember, y::TreeMember) = Operator(-, x,y)
-(x::TreeMember, y) 			= Operator(-, x,y)
-(x, y::TreeMember) 			= Operator(-, x,y)
-(x::TreeMember) 				= Operator(-, x)

*(x::TreeMember, y::TreeMember) = Operator(*, x,y)
*(x::TreeMember, y) 			= Operator(*, x,y)
*(x, y::TreeMember) 			= Operator(*, x,y)

/(x::TreeMember, y::TreeMember) = Operator(/, x,y)
/(x::TreeMember, y) 			= Operator(/, x,y)
/(x, y::TreeMember) 			= Operator(/, x,y)

function BuildOverrideFromArray(ovr)
    for op = ovr
        display(eval(quote
            if($(op[2] == 1))
                    $(op[1])(x::TreeMember)       = Operator(($(op[1])), x)
            elseif($(op[2] == 2))
                    $(op[1])(x::TreeMember, y)    = Operator(($(op[1])), x,y)
                    $(op[1])(x, y::TreeMember)    = Operator(($(op[1])), x,y)
                    $(op[1])(x::TreeMember, y::TreeMember)    = Operator(($(op[1])), x,y)
            elseif($(op[2] == 3))
                    $(op[1])(x::TreeMember, y, z) = Operator(($(op[1])), x,y,z)
                    $(op[1])(x, y::TreeMember, z) = Operator(($(op[1])), x,y,z)
                    $(op[1])(x, y, z::TreeMember) = Operator(($(op[1])), x,y,z)
                    $(op[1])(x::TreeMember, y::TreeMember, z::TreeMember) = Operator(($(op[1])), x,y,z)
                    $(op[1])(x, y::TreeMember, z::TreeMember) = Operator(($(op[1])), x,y,z)
                    $(op[1])(x::TreeMember, y, z::TreeMember) = Operator(($(op[1])), x,y,z)
                    $(op[1])(x::TreeMember, y::TreeMember, z) = Operator(($(op[1])), x,y,z)                  
            end
        end))
    end
	
	for op in ovr
		println("$(op[1]) - declared with $(op[2]) inputs")
	end
end

function GetOverrides(func)
    overridefunctions = GetOverrideFunctionList(func)
    override = tuple(overridefunctions...)
end

function UpdateEnvironmentForFunction(func)
    overridefunctions = GetOverrideFunctionList(func)
    override = tuple(overridefunctions...)
    BuildOverrideFromArray(override)
end

function GetConstructionFunction()
    (quote
        function BuildOverrideFromArray_Gen(ovr; verbose=true)
			disp(x) = x
			if(verbose)
				disp = display
			end
            for op = ovr
                disp(eval(quote
                    if($(op[2] == 1))
                            $(op[1])(x::TreeMember)       = Operator(($(op[1])), x)
                    elseif($(op[2] == 2))
                            $(op[1])(x::TreeMember, y)    = Operator(($(op[1])), x,y)
                            $(op[1])(x, y::TreeMember)    = Operator(($(op[1])), x,y)
                            $(op[1])(x::TreeMember, y::TreeMember)    = Operator(($(op[1])), x,y)
                    elseif($(op[2] == 3))
                            $(op[1])(x::TreeMember, y, z) = Operator(($(op[1])), x,y,z)
                            $(op[1])(x, y::TreeMember, z) = Operator(($(op[1])), x,y,z)
                            $(op[1])(x, y, z::TreeMember) = Operator(($(op[1])), x,y,z)
                            $(op[1])(x::TreeMember, y::TreeMember, z::TreeMember) = Operator(($(op[1])), x,y,z)
                            $(op[1])(x, y::TreeMember, z::TreeMember) = Operator(($(op[1])), x,y,z)
                            $(op[1])(x::TreeMember, y, z::TreeMember) = Operator(($(op[1])), x,y,z)
                            $(op[1])(x::TreeMember, y::TreeMember, z) = Operator(($(op[1])), x,y,z)                  
                    end
                end))
            end

			if(verbose)
				for op in ovr
					println("$(op[1]) - declared with $(op[2]) inputs")
				end
			end
        end
    end)
end

macro BuildOverrideFromArray()
	:(eval(GetConstructionFunction()))
end

########################################
## Tree Manipulation Functions
##
########
function GetAllTrees(node)
    treelist = []
    if(typeof(node) == Operator)  
        push!(treelist, node)   
        for leaf in node.leaves        
            if(leaf != nothing)                
                if(typeof(leaf) <: TreeMember)
                    childarray = copy(GetAllTrees(leaf))
                    treelist = vcat(treelist, childarray)
                else
                    push!(treelist, Variable(copy(leaf)))
                end
                
            end
        end
    else
        treelist = vcat(treelist, node)
    end    
    treelist
end

function GetSubTree(tree, id)
	trees = GetAllTrees(tree)
	for t in trees
		if(t.id == id)
			return t
		end
	end
end

HasId(x::TreeMember, target ) = x.id == target
HasId(x, target ) = false

function ReplaceSubTree(node, replnode, targetID)   
    if(typeof(node) == Operator)  
        for i in 1:length(node.leaves)        
            if(node.leaves[i] != nothing)                
                if HasId(node.leaves[i], targetID)
                    if(typeof(node.leaves[i]) != typeof(replnode) )
                        node.leaves[i] = typeof(node.leaves[i])(replnode)
                    else
                        node.leaves[i] = replnode
                    end
                else
                    ReplaceSubTree(node.leaves[i], replnode, targetID)
                end                
            end
        end
    end    
end

function WrapTree(node::TreeMember)
   Operator(identity, node) 
end

function UnwrapTree(node::TreeMember)
    if(node.op == identity)
       return node.leaves[1]
    end
end

function FullUnwrap(node::TreeMember)   
    current = node
    while(typeof(current) == Operator && current.op == identity)
       current = current.leaves[1]
    end
    return current
end

# Function to execute an AST

SymbolDict = Dict()
function SetSymbolValue(name, value)
	SymbolDict[name] = value
end

ClearSymbolDict() = SymbolDict = Dict()

function EmulateTree(node, localSymbolDict = Dict())   
    result = 0    

    if(typeof(node) == Operator)
        operation = node.op
		emulatedInputs = []
		for leaf in node.leaves
			push!(emulatedInputs, EmulateTree(leaf, localSymbolDict) )
		end
        #emulatedInputs = EmulateTree.(node.leaves, localSymbolDict)
        result = operation(emulatedInputs...)   
		node.result = result		
    elseif (typeof(node) == Variable)
        result = node.var
    else
        result = node
    end    
    
    if(typeof(result) == Symbol)
		if(haskey(localSymbolDict, result) )
			result = localSymbolDict[result]
		elseif(haskey(SymbolDict, result))
			result = SymbolDict[result]
		else
			@show localSymbolDict
			@show SymbolDict
			println("ERROR: Undefined symbol: $(result)")
			println("ERROR: Proceeding with nil value...")
			result = 0
		end
    end
    
    result
end


function InArray(arr, x)
	for v in arr
		if(v == x)
			return true
		end
	end
	
	return false
end

#########################
## Extracting all instances from trees
##
##########

function GetAllLeaves(tree)
	nodes = GetAllTrees(tree)
    GetAllLeavesList(nodes)
end

function GetAllLeavesList(nodes)
    variables = []
    for v in nodes
        if(typeof(v) != Operator)
			if( !InArray(variables, v) )
				push!(variables, v)
			end
        end
    end
    variables
end

function GetAllSymbols(node)
    GetAllSymbolsList(GetAllLeavesList(node))
end

function GetAllSymbols(tree::TreeMember)
	nodes = GetAllTrees(tree)
    GetAllSymbolsList(GetAllLeavesList(nodes))
end

function GetAllSymbolsList(leafArray)
    variables = []
    for v in leafArray
        if(typeof(v) == Variable)
            if(typeof(v.var) == Symbol)
                push!(variables, v.var)
            end
        elseif typeof(v) == Symbol
            push!(variables, v)
        end 
    end
    variables
end

function GetOperators(tree)
    nodes = GetAllTrees(tree)
    operators = []
    for v in nodes
        if(typeof(v) == Operator)
			if( !InArray(operators, v) )
				push!(operators, v)
			end
        end
    end
    operators
end

function GetOperatorIDs(tree)
    operators = GetOperators(tree)
    ids = []
    for op in operators
        push!(ids, op.id)
    end
    
    ids
end


##################
## Tree Editing Functions
##
######
function ReplaceAllVariablesOfType(node::TreeMember, targettype, replacementtype) 
    if(typeof(node) == Operator)
        for i in 1:length(node.leaves)
            if(node.leaves[i] != nothing)
                if(typeof(node.leaves[i]) == Operator)
                    ReplaceAllVariablesOfType(node.leaves[i], targettype, replacementtype)
                elseif (typeof(node.leaves[i]) == Variable)
                    if(typeof(node.leaves[i].var)==targettype)
                       node.leaves[i].var =  replacementtype(node.leaves[i].var)
                    end
                end
            end
        end
    end    
end

function ReplaceTypeOfSpecifiedVariable(node::TreeMember, id, replacementtype)
    if(typeof(node) == Operator)
        for i in 1:length(node.leaves)
            if(node.leaves[i] != nothing)
                if(typeof(node.leaves[i]) == Operator)
                    ReplaceTypeOfSpecifiedVariable(node.leaves[i], id, replacementtype)
                elseif (typeof(node.leaves[i]) == Variable)
                    if( node.leaves[i].id== id)
                       node.leaves[i].var =  replacementtype(node.leaves[i].var)
                    end
                end
            end
        end
    end    
end

function ReplaceConstantsWithVariables(node::TreeMember) 
    if(typeof(node) == Operator)
        for i in 1:length(node.leaves)
            if(node.leaves[i] != nothing)
                if(typeof(node.leaves[i]) <: TreeMember)
                    ReplaceConstantsWithVariables(node.leaves[i])
                else
                    node.leaves[i] = Variable(node.leaves[i])
                end
            end
        end
    end    
end

###############
## Extracting computing information from tree
##
#####

# Getting all the results for a specific id
function GetResultForID(node, id)
    if(node.id == id)
        return node.result
    elseif(typeof(node) == Operator)
        for i in 1:length(node.leaves)
            if(node.leaves[i] != nothing)
                if(typeof(node.leaves[i]) == Operator)
                     ret = GetResultForID(node.leaves[i], id)
                     if(ret != "notfound")
                        return ret
                     end
                end
            end
        end
    end
       
    return "notfound"
end

function SetResultForID(node, id, val)
    if(node.id == id)
        node.result = val
    elseif(typeof(node) == Operator)
        for i in 1:length(node.leaves)
            if(node.leaves[i] != nothing)
                if(typeof(node.leaves[i]) == Operator)
                     SetResultForID(node.leaves[i], id, val)
                end
            end
        end
    end
end

################
## Helper to compute the error difference of two differently typed trees
##
#####

function TreeComparison(tree_a::TreeMember, tree_b::TreeMember, inputsa, inputsb)
    
    # Check that the input length is valid
    if(length(inputsa) != length(inputsb))
       throw(ErrorException("Error:Comparison ranges must be of equal length!")) 
    end
    
    # Check that the input array is of type Array{Pair{Symbol, Any}, 1}
    ########TODO########
    
    # Initialise a results array
    resulta = []
    resultb = []
    
    # Push the results into the array
    for input in inputsa
        SetSymbolValue(input[1], input[2])
        push!(resulta,EmulateTree(tree_a))
    end
    
    for input in inputsb
        SetSymbolValue(input[1], input[2])
        push!(resultb,EmulateTree(tree_b))
    end
    
    # Calculate the error
    diff      = abs.(resulta - resultb)
    maxerr    = maximum(diff)
    minerr    = minimum(diff)
    medianerr = median(diff)
    meanerr   = mean(diff)
    
    # return results
    (minerr, maxerr, medianerr, meanerr, diff)
    
end

function PrintTreeComparisonError(error)
    println("Min    Error $(error[1])")
    println("Max    Error $(error[2])")
    println("Median Error $(error[3])")
    println("Mean   Error $(error[4])")  
end


function GetErrorInTree(hiprecTree, loprecTree, inputSymbol, hiprec_inputValues, loprec_inputValues; fetchtimeline = false)
    
    outputTree = deepcopy(loprecTree)
    
    # Copy the trees for each result instance
    hiprec_testarray = []
    for v in hiprec_inputValues
        push!(hiprec_testarray, ( (inputSymbol,v) , deepcopy(hiprecTree) ) ) 
    end
    
    loprec_testarray = []
    for v in loprec_inputValues
        push!(loprec_testarray, ( (inputSymbol,v) , deepcopy(loprecTree) ) ) 
    end

    # Calculate the output results
    for i in 1:length(hiprec_testarray)
        d = Dict(hiprec_testarray[i][1][1]=>hiprec_testarray[i][1][2])
        EmulateTree(hiprec_testarray[i][2], d )
    end

    for i in 1:length(loprec_testarray)
        d = Dict(loprec_testarray[i][1][1]=>loprec_testarray[i][1][2])
        EmulateTree(loprec_testarray[i][2], d )
    end
    
    # Get the list of operator IDs
    operatorlist = GetOperators(hiprec_testarray[2][2])
    ids = GetOperatorIDs(hiprec_testarray[2][2])
    
    # Calculate the min,max, median and mean error for each.
    nodeerrors = []
    sumres     = [0.0,0.0,0.0,0.0]
    maxmax     = 0.0
	
	timelinedb = Dict()
	
    for id in ids    
        targetID = id
        hiprecres = []
        for entry in hiprec_testarray
            res = GetResultForID(entry[2], targetID)
            push!(hiprecres, res)
        end

        loprecres = []
        for entry in loprec_testarray
            res = GetResultForID(entry[2], targetID)
            push!(loprecres, res)
        end



        dif = abs.(hiprecres - Float64.(loprecres))
        minval  = minimum(dif)
        maxval  = maximum(dif)
        medval  = median(dif)
        meanval = median(dif)
		
		if( fetchtimeline )
			timelinedb[targetID] = dif
		end

        push!(nodeerrors, (id, minval, maxval, medval, meanval))
        sumres[1] += minval
        sumres[2] += maxval
        sumres[3] += medval
        sumres[4] += meanval

        maxmax = max(maxval, maxmax)
    end
    
    for data in nodeerrors
        maxval = data[3]
        id = data[1]
        SetResultForID( outputTree, id, maxval )
    end

	if(fetchtimeline)
		return outputTree,timelinedb
	end
	
    outputTree
end

function PlotASTError(tree, errordict, hiprec_inputs, res=(2048,512))
    arr = []
    for i in hiprec_inputs
        push!(arr, i)
    end

    maxerror = 0.0
    for entry in errordict
        maxerror = max(maximum(entry[2]), maxerror)
    end

    ps = []
    for entry in errordict
        newplot = plot(arr, entry[2], title="OperatorID: $(entry[1])", ylims = (0,maxerror), legend=:none)
        push!(ps, newplot)

        idtree = GetSubTree(tree,entry[1]) 
        helper = plot([0, 1], [0, 1], framestyle=:none, legend=:none, linecolor=:white)
        annotate!(helper, [(0.0, 0.5, text(ToString(idtree), :left, 6) )])
        push!(ps, helper)
    end
    
    pAll = plot(ps..., layout = (Int64.(length(ps)/2),2), size=(res[1], (length(ps)/2)*res[2]), margin = 15.0mm) ##size=(2048,length(ps)*512)
    pAll
end


############################
## Source Code Generation for AST Tree
##
#######

function TreeToFunction(node::TreeMember, name)
    symbols = GetAllSymbols(node)
    funcbody = TreeToFunctionLeaf(node)
	
	inputstring = ""
	for inp in 1:length(symbols)
		inputstring = string(inputstring, "$(symbols[inp])" )
		if(inp != length(symbols))
			inputstring = string(inputstring, ", ")
		end
	end
	
    parsed = eval(Meta.parse("$(name)($(inputstring))= " * funcbody))
end
function TreeToFunctionLeaf(node::TreeMember)
    s = ""
    if(typeof(node) == Operator)
        leafcount = length(node.leaves)
        if( leafcount == 1)
            s = string(s, "(", node.op, TreeToFunctionLeaf(node.leaves[1]), ")" )
        elseif (leafcount == 2)
            s = string(s, "(", TreeToFunctionLeaf(node.leaves[1]), node.op, TreeToFunctionLeaf(node.leaves[2]), ")")
        else
            s = string(s, node.op, "(")
            for i in 1:length(node.leaves)
                if(node.leaves[i] != nothing)
                    if(typeof(node.leaves[i]) <: TreeMember)
                        s = string(s, TreeToFunctionLeaf(node.leaves[i]) )
                    else
                        s = string(s, node.leaves[i])
                    end

                    if(i != length(node.leaves))
                        s = string(s, ",")
                    end

                end
            end
            s = string(s, ")")
        end
    else
        s = string(s, node.var)
    end
    s
end   




