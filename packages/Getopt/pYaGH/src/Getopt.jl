module Getopt

export getopt

struct GetoptIter
	args::Array{String}
	ostr::String
	longopts::Array{String}
end

function Base.iterate(g::GetoptIter, (pos, ind) = (firstindex(g.args), 1))
	if g.ostr[1] != '+' # allow options to appear after main arguments
		while ind <= lastindex(g.args) && (g.args[ind][1] != '-' || g.args[ind] == "-")
			ind += 1
		end
	end
	if ind > lastindex(g.args) || g.args[ind][1] != '-' || g.args[ind] == "-" return nothing end
	if length(g.args[ind]) >= 2 && g.args[ind][1] == '-' && g.args[ind][2] == '-'
		if length(g.args[ind]) == 2 # actually, Julia will always filter out "--" in ARGS. Ugh!
			deleteat!(g.args, ind)
			return nothing
		end
		optopt, optarg, pos = "?", "", 0
		if length(g.longopts) > 0
			eqpos = findfirst(isequal('='), g.args[ind])
			a = eqpos == nothing ? g.args[ind][3:end] : g.args[ind][3:eqpos-1]
			n_matches, match = 0, ""
			for l in g.longopts
				r = findfirst(a, l)
				if r != nothing && r[1] == 1
					n_matches += 1
					match = l
				end
			end
			if n_matches == 1
				optopt = string("--", match[end] == '=' ? match[1:end-1] : match);
				if eqpos != nothing
					optarg = g.args[ind][eqpos+1:end]
				elseif match[end] == '=' && ind + 1 <= lastindex(g.args)
					deleteat!(g.args, ind)
					optarg = g.args[ind]
				end
			end
		end
	else
		if pos == 1 pos = 2 end
		optopt, optarg = g.args[ind][pos], ""
		pos += 1
		i = findfirst(isequal(optopt), g.ostr)
		if i == nothing # unknown option
			optopt = '?'
		elseif i < length(g.ostr) && g.ostr[i + 1] == ':' # require argument
			if pos <= length(g.args[ind])
				optarg = g.args[ind][pos:end]
			elseif ind + 1 <= lastindex(g.args)
				deleteat!(g.args, ind)
				optarg = g.args[ind]
			end
			pos = 0
		end
		optopt = optopt == '?' ? "?" : string('-', optopt)
	end
	if pos == 0 || pos > length(g.args[ind])
		deleteat!(g.args, ind) # FIXME: can be slow when ostr[1] == '-'
		pos = 1
	end
	return ((optopt, optarg), (pos, ind))
end

"""
    getopt(args::Array{String}, ostr::String, longopts::Array{String}=String[])

Iterate through command line options with a getopt-like interface and remove
options from `args`.

`args` is typically `ARGS`. By default, options are allowed to occur after
non-option arguments. If `ostr[1]=='+'`, the default behavior is disabled.

# Examples
```julia
for (opt, arg) in Getopt.getopt(ARGS, "xy:", ["foo", "bar="])
	@show (opt, arg)
end
@show ARGS # only non-option arguments remain
```
"""
getopt(args::Array{String}, ostr::String, longopts::Array{String} = String[]) = GetoptIter(args, ostr, longopts)

end
