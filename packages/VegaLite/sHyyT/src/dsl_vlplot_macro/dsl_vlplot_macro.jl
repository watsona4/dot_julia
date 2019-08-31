include("shorthandparser.jl")

function walk_dict(f, d, parent)
    res = Dict{String,Any}()
    for p in d
        if p[2] isa Dict
            new_p = f(p[1]=>walk_dict(f, p[2], p[1]), parent)

            if new_p isa Vector
                for i in new_p
                    res[i[1]] = i[2]
                end
            elseif new_p isa Pair
                res[new_p[1]] = new_p[2]
            else
                error("Invalid return type.")
            end
        else
            new_p = f(p, parent)
            if new_p isa Vector
                for i in new_p
                    res[i[1]] = i[2]
                end
            elseif new_p isa Pair
                res[new_p[1]] = new_p[2]
            else
                error("Invalid return type.")
            end
        end
    end
    return res
end

function fix_shortcuts(spec::Dict{String,Any}, positional_key::String)
    # Replace a first mark shortcut
    if any(i->i[1]==positional_key, spec)
        spec["mark"] = spec[positional_key]
        delete!(spec, positional_key)
    end

    if haskey(spec, "enc")
        spec["encoding"] = spec["enc"]
        delete!(spec, "enc")
    end

    # Move top level channels into encoding
    encodings_to_be_moved = filter(i->i!="facet", collect(keys(vlschema.data["definitions"]["FacetedEncoding"]["properties"])))
    for k in collect(keys(spec))
        if string(k) in encodings_to_be_moved
            if !haskey(spec,"encoding")
                spec["encoding"] = Dict{String,Any}()
            end
            spec["encoding"][k] = spec[k]
            delete!(spec,k)
        elseif string(k)=="wrap"
            if !haskey(spec,"encoding")
                spec["encoding"] = Dict{String,Any}()
            end
            spec["encoding"]["facet"] = spec[k]
            delete!(spec,k)
        end
    end

    new_spec = walk_dict(spec, "root") do p, parent
        if p[1] == positional_key && (parent=="mark")
            return "type" => p[2]
        elseif p[1] == positional_key
            return parse_shortcut(string(p[2]))
        elseif p[1]=="typ"
            return "type"=>p[2]
        else
            return p
        end
    end



    if haskey(new_spec, "encoding")
        new_encoding_dict = Dict{String,Any}()
        for (k,v) in new_spec["encoding"]
            if v isa Symbol
                new_encoding_dict[k] = Dict{String,Any}("field"=>string(v))
            elseif v isa String
                new_encoding_dict[k] = Dict{String,Any}(parse_shortcut(v)...)   
            else
                new_encoding_dict[k] = v
            end
        end
        new_spec["encoding"] = new_encoding_dict
    end

    if haskey(new_spec, "transform")
        for transform in new_spec["transform"]
            if haskey(transform, "from") && haskey(transform["from"], "data")
                if transform["from"]["data"] isa Dict && haskey(transform["from"]["data"], "url")
                    if transform["from"]["data"]["url"] isa AbstractPath
                        as_uri = string(URI(transform["from"]["data"]["url"]))
                        transform["from"]["data"]["url"] = Sys.iswindows() ? as_uri[1:5] * as_uri[7:end] : as_uri
                    elseif transform["from"]["data"]["url"] isa URI
                        as_uri = string(transform["from"]["data"]["url"])
                        transform["from"]["data"]["url"] = Sys.iswindows() && transform["from"]["data"]["url"].scheme=="file" ? as_uri[1:5] * as_uri[7:end] : as_uri
                    end
                elseif transform["from"]["data"] isa AbstractPath
                    as_uri = string(URI(transform["from"]["data"]))
                    transform["from"]["data"] = Dict{String,Any}("url" => Sys.iswindows() ? as_uri[1:5] * as_uri[7:end] : as_uri)
                elseif transform["from"]["data"] isa URI
                    as_uri = string(transform["from"]["data"])
                    transform["from"]["data"] = Dict{String,Any}("url" => Sys.iswindows() && transform["from"]["data"].scheme=="file" ? as_uri[1:5] * as_uri[7:end] : as_uri)
                elseif TableTraits.isiterabletable(transform["from"]["data"])
                    it = IteratorInterfaceExtensions.getiterator(transform["from"]["data"])
        
                    recs = [Dict{String,Any}(string(c[1])=>isa(c[2], DataValues.DataValue) ? (isna(c[2]) ? nothing : get(c[2])) : c[2] for c in zip(keys(r), values(r))) for r in it]
                
                    transform["from"]["data"] = Dict{String,Any}("values" => recs)
                end
        
            end
        end
    end

    if haskey(new_spec, "data")
        if new_spec["data"] isa Dict && haskey(new_spec["data"], "url")
            if new_spec["data"]["url"] isa AbstractPath
                as_uri = string(URI(new_spec["data"]["url"]))
                new_spec["data"]["url"] = Sys.iswindows() ? as_uri[1:5] * as_uri[7:end] : as_uri
            elseif new_spec["data"]["url"] isa URI
                as_uri = string(new_spec["data"]["url"])
                new_spec["data"]["url"] = Sys.iswindows() && new_spec["data"]["url"].scheme=="file" ? as_uri[1:5] * as_uri[7:end] : as_uri
            end
        elseif new_spec["data"] isa AbstractPath
            as_uri = string(URI(new_spec["data"]))
            new_spec["data"] = Dict{String,Any}("url" => Sys.iswindows() ? as_uri[1:5] * as_uri[7:end] : as_uri)
        elseif new_spec["data"] isa URI
            as_uri = string(new_spec["data"])
            new_spec["data"] = Dict{String,Any}("url" => Sys.iswindows() && new_spec["data"].scheme=="file" ? as_uri[1:5] * as_uri[7:end] : as_uri)
        elseif TableTraits.isiterabletable(new_spec["data"])
            it = IteratorInterfaceExtensions.getiterator(new_spec["data"])
            set_spec_data!(new_spec, it)
            detect_encoding_type!(new_spec, it)
        end
    end

    return new_spec
end

function convert_curly_style_array(exprs, positional_key)
    res = Expr(:vect)

    for ex in exprs
        if ex isa Expr && ex.head==:braces
            push!(res.args, :( Dict{String,Any}($(convert_curly_style(ex.args, positional_key)...)) ))
        else
            push!(res.args, ex)
        end
    end

    return res
end

function convert_curly_style(exprs, positional_key)
    new_exprs=[]
    for ex in exprs
        if ex isa Expr && ex.head==:(=)
            if ex.args[2] isa Expr && ex.args[2].head==:braces
                push!(new_exprs, :( $(string(ex.args[1])) => Dict{String,Any}($(convert_curly_style(ex.args[2].args, positional_key)...)) ))
            elseif ex.args[2] isa Expr && ex.args[2].head==:vect
                push!(new_exprs, :( $(string(ex.args[1])) => $(convert_curly_style_array(ex.args[2].args, positional_key)) ))
            else
                push!(new_exprs, :( $(string(ex.args[1])) => $(esc(ex.args[2])) ))
            end
        else
            push!(new_exprs, :( $(string(positional_key)) => $(esc(ex)) ))
        end
    end

    return new_exprs
end

macro vlplot(ex...)
    positional_key = gensym()

    new_ex = convert_curly_style(ex, positional_key)

    return :( VegaLite.VLSpec{:plot}(fix_shortcuts(Dict{String,Any}($(new_ex...)), $(string(positional_key)))) )
end

function Base.:+(a::VLSpec{:plot}, b::VLSpec{:plot})
    new_spec = deepcopy(a.params)
    if haskey(new_spec, "facet") || haskey(new_spec, "repeat")
        new_spec["spec"] = deepcopy(b.params)
    elseif haskey(b.params, "vconcat")
        new_spec["vconcat"] = deepcopy(b.params["vconcat"])
    elseif haskey(b.params, "hconcat")
        new_spec["hconcat"] = deepcopy(b.params["hconcat"])
    else
        if !haskey(new_spec,"layer")
            new_spec["layer"] = []
        end
        push!(new_spec["layer"], deepcopy(b.params))
    end
    
    return VLSpec{:plot}(new_spec)
end

function Base.hcat(A::VLSpec{:plot}...)
    spec = VLSpec{:plot}(Dict{String,Any}())
    spec.params["hconcat"] = []
    for i in A
        push!(spec.params["hconcat"], deepcopy(i.params))
    end
    return spec
end

function Base.vcat(A::VLSpec{:plot}...)
  spec = VLSpec{:plot}(Dict{String,Any}())
  spec.params["vconcat"] = []
  for i in A
      push!(spec.params["vconcat"], deepcopy(i.params))
  end
  return spec
end

function interactive()
    i -> begin
        i.params["selection"] = Dict{String,Any}()
        i.params["selection"]["selector001"] = Dict{String,Any}()
        i.params["selection"]["selector001"]["type"] = "interval"
        i.params["selection"]["selector001"]["bind"] = "scales"
        i.params["selection"]["selector001"]["encodings"] = ["x", "y"]
        i.params["selection"]["selector001"]["on"] = "[mousedown, window:mouseup] > window:mousemove!"
        i.params["selection"]["selector001"]["translate"] = "[mousedown, window:mouseup] > window:mousemove!"
        i.params["selection"]["selector001"]["zoom"] = "wheel!"
        i.params["selection"]["selector001"]["mark"] = Dict("fill"=>"#333", "fillOpacity"=>0.125, "stroke"=>"white")
        i.params["selection"]["selector001"]["resolve"] = "global"
        return i
    end
end
