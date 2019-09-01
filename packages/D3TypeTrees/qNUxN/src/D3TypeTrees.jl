
isdefined(Base, :__precompile__) && __precompile__()

"""
Module for visualizing julia type hierarchies
"""
module D3TypeTrees

#################################################################################
# Exports

export TypeTree
export DisplayTypeTree

#################################################################################
# Imports

using JSON
using D3Trees
using InteractiveUtils

function wrap(t::Type)
	s = InteractiveUtils.subtypes(t)
	if isempty(s)
		d = try
			[string(fn) for fn in fieldnames(t)]
		catch
			[]
		end
	else
		d = Dict()
		for t_inner in s
			if t_inner != t
				d[string(t_inner)] =  wrap(t_inner)
			end
		end
	end
	return d
end


function get_children(d::Dict, c = Array{Array{Any,1},1}(),n = Array{String,1}(),f = Array{String,1}(); scopesep = ".")
	cc = Array{Any,1}()
	for (k,v) in d
		K = join(split(String(k),"."),scopesep)
		if isa(v,Dict) 
			get_children(v,c,n,f,scopesep = scopesep)
			push!(cc,K)
		elseif isa(v,Array)
			push!(c,[])
			push!(cc,K)
		end
		if !(K in n)
			push!(n,K)
			push!(f,isa(v,Array) ? join(v,"\n") : "Abstract")
		end
	end
	push!(c,reverse(cc))
	c = [[findall(x->x==i, reverse(n))[1] for i in j] for j in reverse(c)]
	#c = reverse(c)
	return c[2:end], reverse(n), reverse(f)
end

function TypeTree(t::Type; init_expand=1, scopesep = ".")
	t = Dict(string(t)=>wrap(t))
	children, names, fields = get_children(t,scopesep = scopesep)
	tree = D3Tree(children,text = names,tooltip = fields,init_expand=init_expand)
	return tree
end

function DisplayTypeTree(t::Type; browser="google chrome", init_expand=1, scopesep = ".")
    tree = TypeTree(t,init_expand = init_expand, scopesep = scopesep)
    DisplayTypeTree(tree,browser = browser)
end

function DisplayTypeTree(tree::D3Trees.D3Tree; browser="google chrome")
    inbrowser(tree,browser)
end

end #module
