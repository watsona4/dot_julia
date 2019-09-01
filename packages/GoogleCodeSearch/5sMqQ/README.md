# GoogleCodeSearch.jl

A Julia wrapper over [Google Code Search](https://github.com/google/codesearch).

[![Build Status](https://travis-ci.org/tanmaykm/GoogleCodeSearch.jl.svg?branch=master)](https://travis-ci.org/tanmaykm/GoogleCodeSearch.jl)

A context (`Ctx`) instance encapsulates the index location and provides a useful way to split indexing across multiple indices. It also holds a lock to handle it being called across tasks.

```julia

julia> # A resolver method is used to determine which index a path should be indexed in.
julia> # Useful to split indexing across multiple files for performance.
julia> # By default only a single index will be created.

julia> my_index_resolver(ctx::Ctx, inpath::String) = joinpath(ctx.store, "myindex")
my_index_resolver (generic function with 1 method)

julia> # storedir is where all indices are kept (`$HOME/.googlecodesearchjl` by default)

julia> storedir="/tmp/store/"
"/tmp/store/"

julia> ctx = Ctx(store=storedir, resolver=my_index_resolver)
GoogleCodeSearch.Ctx(store="/tmp/store/")
```

Index paths by calling the index method. While indexing, ensure paths are sorted such that paths appearing later are not substrings of those earlier. Otherwise, the earlier indexed entries are erased (strange behavior of `cindex`).

```julia
julia> index(ctx, "/tmp/dir1");

julia> index(ctx, ["/tmp/dir2", "/tmp/dir3", "/tmp/dir4"]);
```

Search by calling the search method with a regex pattern to search for. Optionally pass the following parameters:
- `ignorecase`: boolean, whether to ignore case during search (default false)
- `pathfilter`: a regular expression string to restrict search only to matching paths

The search method returns a vector of named tuples, each describing a match.
- `file`: path that matched
- `line`: line number therein that matched
- `text`: text that matched

```julia
julia> search(ctx, "Include"; ignorecase=true, pathfilter=".*dir1.*")
17-element Array{NamedTuple{(:file, :line, :text),Tuple{String,Int64,String}},1}:
 (file = "/tmp/dir1/plugin/resolve.jl", line = 5, text = "# At the end it walks through the dependency tree and outputs include statements in the correct order.\n")                              
 (file = "/tmp/dir1/plugin/resolve.jl", line = 110, text = "function genincludes(folder::String)\n")                                                                                              
 (file = "/tmp/dir1/plugin/resolve.jl", line = 115, text = "    open(fullsrcpath(folder, \"modelincludes.jl\"), \"w\") do inclfile\n")                                                            
 (file = "/tmp/dir1/plugin/src/main/resources/julia/client.mustache", line = 13, text = "include(\"modelincludes.jl\")\n")                                                                        
 (file = "/tmp/dir1/plugin/src/main/resources/julia/client.mustache", line = 15, text = "include(\"api_{{classname}}.jl\"){{/apis}}{{/apiInfo}}\n")                                               
 ...
```

A HTTP service with JSON interface can be brought up with the `run_http` method. Use optional parameter `ops` to sepcify the operations that should be exposed. Additional keywords, identical to what `HTTP.serve` would accept can also be passed to this method to enable other features e.g. SSL, port reuse.

```julia
julia> using GoogleCodeSearch

julia> ctx = Ctx();

julia> run_http(ctx; host=ip"0.0.0.0", port=5555, ops=(:index, :search))
```
