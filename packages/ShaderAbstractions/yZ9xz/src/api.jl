
struct Program
    context::AbstractContext
    vertexarray::AbstractArray
    uniforms::Dict{Symbol, Any}
    vertex_source::String
    fragment_source::String
end

struct InstancedProgram
    program::Program
    per_instance::AbstractArray
end

name_type_iter(x) = (s = Tables.schema(x); zip(s.names, s.types))

function getter_function(io, T, t_str, name, plot)
    println(io, t_str, " get_$(name)(){return $name;}")
end

function getter_function(io, ::AbstractSampler, t_str, name, plot)
end


function InstancedProgram(
        context::AbstractContext,
        vertshader, fragshader,
        instance::AbstractVector,
        per_instance::AbstractVector;
        uniforms...
    )
    instance_attributes = sprint() do io
        println(io, "\n// Per instance attributes: ")
        for (name, T) in name_type_iter(per_instance)
            t_str = type_string(context, T)
            println(io, "in ", t_str, " $name;")
            getter_function(io, T, t_str, name, uniforms)
        end
        println(io)
    end
    p = Program(
        context,
        instance_attributes * vertshader,
        fragshader,
        instance; uniforms...
    )
    InstancedProgram(p, per_instance)
end

function Program(
        context::AbstractContext,
        vertshader, fragshader,
        instance::AbstractVector;
        uniforms...
    )
    c_uniforms = Dict{Symbol, Any}()
    uniform_block = sprint() do io
        println(io, "\n// Uniforms: ")
        for (name, v) in uniforms
            vc = convert_uniform(context, v)
            t_str = type_string(context, vc)
            println(io, "uniform ", t_str, " $name;")
            getter_function(io, vc, t_str, name, uniforms)
            c_uniforms[name] = vc
        end
        println(io)
    end
    src = sprint() do io
        println(io, "// Instance inputs: ")
        for (name, T) in name_type_iter(instance)
            t_str = type_string(context, T)
            println(io, "in ", t_str, " $name;")
            getter_function(io, T, t_str, name, uniforms)
        end
        println(io, uniform_block)
        println(io)
        println(io, vertshader)
    end
    precision = """
    #version 300 es
    precision mediump int;
    precision mediump float;
    precision mediump sampler2D;
    precision mediump sampler3D;

    """
    Program(
        context, instance, c_uniforms,
        precision * src,
        precision * """
        out vec4 fragment_color;
        """ * uniform_block * fragshader
    )
end
