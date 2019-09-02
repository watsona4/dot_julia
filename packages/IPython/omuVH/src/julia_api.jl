module JuliaAPI

using Compat
using Compat.REPL

function eval_str(code::AbstractString;
                  scope::Module = Main,
                  filename::AbstractString = "string",
                  auto_jlwrap = true,
                  force_jlwrap = false)
    return include_string(scope, code, filename)
end

@static if VERSION < v"0.7-"
    getattr(obj, name) = getfield(obj, Symbol(name))
    function setattr(obj, name, value)
        setfield!(obj, Symbol(name), value)
        return nothing
    end
else
    getattr(obj, name) = getproperty(obj, Symbol(name))
    function setattr(obj, name, value)
        setproperty!(obj, Symbol(name), value)
        return nothing
    end
end

function setattr(mod::Module, name, value)
    Base.eval(mod, :($(Symbol(name)) = $value))
    return nothing
end

@static if VERSION < v"0.7-"
    completions(_a...; __k...) = String[]
else
    function completions(string, pos, context_module = Main)
        ret, _, should_complete =
            REPL.completions(string, pos, context_module)
        if should_complete
            return map(REPL.completion_text, ret)
        else
            return String[]
        end
    end
end

end  # module
