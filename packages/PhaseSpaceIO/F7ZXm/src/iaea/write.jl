mutable struct GeneratedAttributes
    length::Int64
    counts::Dict{ParticleType, Int64}
    energy_min::Dict{ParticleType, Float32}
    energy_max::Dict{ParticleType, Float32}
    energy_sum::Dict{ParticleType, Float64}
    x_min::Float32
    x_max::Float32
    y_min::Float32
    y_max::Float32
    z_min::Float32
    z_max::Float32
end

function GeneratedAttributes()
    GeneratedAttributes(0,
        Dict(),
        Dict(),
        Dict(),
        Dict(),
        Inf, -Inf,
        Inf, -Inf,
        Inf, -Inf
    )
end

mutable struct IAEAPhspWriter{R, I <: IO}
    record_contents::R
    generated_attributes::GeneratedAttributes
    io_header::I
    io_phsp::I
    function IAEAPhspWriter(record_contents::R, generated_attributes,
                            io_header::I, io_phsp::I) where {R, I}
        w = new{R,I}(record_contents, generated_attributes,
                io_header, io_phsp)
        finalizer(close, w) 
        w
    end
end

function increment(d, key, val=1)
    T = eltype(values(d))
    d[key] = get!(d,key,zero(T)) + val
end

function Base.write(io::IAEAPhspWriter, p::IAEAParticle)
    ret = write_particle(io.io_phsp, p, io.record_contents)
    
    ga = io.generated_attributes
    typ = p.typ
    increment(ga.counts, typ, 1)
    ga.length += 1
    increment(ga.energy_sum, typ, p.E * p.weight)
    ga.energy_min[typ] = min(get!(ga.energy_min, typ, Inf), p.E)
    ga.energy_max[typ] = max(get!(ga.energy_max, typ, -Inf), p.E)
    
    ga.x_min = min(ga.x_min, p.x)
    ga.y_min = min(ga.y_min, p.y)
    ga.z_min = min(ga.z_min, p.z)
    ga.x_max = max(ga.x_max, p.x)
    ga.y_max = max(ga.y_max, p.y)
    ga.z_max = max(ga.z_max, p.z)
    
    ret
end

function Base.write(w::IAEAPhspWriter, ps)
    ret = 0
    for p in ps
        ret += write(w,p)
    end
    ret
end

function print_key(io::IO, k)
    println(io,'$',k,":")
end
function print_val(io, v)
    if v != ""
        println(io,v)
    end
end
function println_kv(io::IO, k, v)
    print_key(io,k)
    print_val(io,v)
    println(io)
end

function println_particle_count(io, d, p::ParticleType)
    key = if p == photon
            :PHOTONS
        elseif p == electron
            :ELECTRONS
        elseif p == positron
            :POSITRONS
        elseif p == proton
            :PROTONS
        elseif p == neutron
            :NEUTRONS
        else
            error("Unknown particle type $p")
        end
    println_kv(io, key, d[p])
end

function print_header(io::IO, w::IAEAPhspWriter)
    println_kv(io, :IAEA_INDEX, "0 // test header")
    println_kv(io, :TITLE, "")
    println_kv(io, :FILE_TYPE, 0)
    r = w.record_contents
    ga = w.generated_attributes
    record_length = ptype_disksize(r)
    checksum = ga.length * record_length
    println_kv(io, :CHECKSUM, checksum)
    print_record_contents(io, r)
    println_kv(io, :RECORD_LENGTH, record_length)
    println_kv(io, :BYTE_ORDER, "1234")
    println_kv(io, :ORIG_HISTORIES, "$(typemax(Int32))")
    println_kv(io, :PARTICLES, ga.length)

    for p in keys(ga.counts)
        println_particle_count(io, ga.counts, p)
    end

    println_kv(io, :TRANSPORT_PARAMETERS, "")
    println_kv(io, :MACHINE_TYPE, "")
    println_kv(io, :MONTE_CARLO_CODE_VERSION, "")
    # 
    println_kv(io, :GLOBAL_PHOTON_ENERGY_CUTOFF, 0.0)
    println_kv(io, :GLOBAL_PARTICLE_ENERGY_CUTOFF, 0.0)
    println_kv(io, :COORDINATE_SYSTEM_DESCRIPTION, "")

    println(io)
    println(io, "// OPTIONAL INFORMATION")
    println(io)
    println_kv(io, :BEAM_NAME, "")
    println_kv(io, :FIELD_SIZE, "")
    println_kv(io, :NOMINAL_SSD, "")
    println_kv(io, :MC_INPUT_FILENAME, "")
    println_kv(io, :VARIANCE_REDUCTION_TECHNIQUES, "")
    println_kv(io, :INITIAL_SOURCE_DESCRIPTION, "")
    println_kv(io, :PUBLISHED_REFERENCE, "")
    println_kv(io, :AUTHORS, "")
    println_kv(io, :INSTITUTION, "")
    println_kv(io, :LINK_VALIDATION, "")
    println_kv(io, :ADDITIONAL_NOTES, "Generated via PhaseSpaceIO.jl")
    # # TODO:
    # println_kv(io, :STATISTICAL_INFORMATION_PARTICLES, "")
    stats = """
    // cm
       $(ga.x_min)  $(ga.x_max)
       $(ga.y_min)  $(ga.y_max)
       $(ga.z_min)  $(ga.z_max)"""
    println_kv(io, :STATISTICAL_INFORMATION_GEOMETRY, stats)
end

function extra_float_count(r::IAEAHeader{Nf, Ni, Nt}) where {Nf, Ni, Nt}
    Nf
end

function extra_long_count(r::IAEAHeader{Nf, Ni, Nt}) where {Nf, Ni, Nt}
    Ni
end

function print_record_contents(io::IO, r::IAEAHeader)
    # $RECORD_CONTENTS:
    # 1     // X is stored ?
    # 1     // Y is stored ?
    # 1     // Z is stored ?
    # 1     // U is stored ?
    # 1     // V is stored ?
    # 1     // W is stored ?
    # 1     // Weight is stored ?
    # 0     // Extra floats stored ?
    # 1     // Extra longs stored ?
    # 0     // Generic integer variable stored in the extralong array [ 0] 

    # $RECORD_CONSTANT:
    # 
    # $RECORD_LENGTH:
    # 33
    t = r.record_contents

    print_key(io, "RECORD_CONTENTS")
    record_constants = Float32[]
    for propstr in ["X","Y","Z", "U","V","W", "Weight"]
        field = Symbol(lowercase(string(propstr)))
        if field in propertynames(t)
            val = 0
            push!(record_constants, getproperty(t, field))
        else
            val = 1
        end
        println(io, val, " "^5, "// ", propstr, " is stored ?")
    end
    Nf = extra_float_count(r)
    Ni = extra_long_count(r)
    println(io, Nf, " "^5, "// Extra floats stored")
    println(io, Ni, " "^5, "// Extra longs stored")
    println(io, "0     // Generic integer variable stored in the extralong array [ 0]")
    println(io)
    
    print_key(io, "RECORD_CONSTANT")
    for c in record_constants
        println(io, c)
    end
    println(io)
end

function iaea_writer(path::IAEAPath, r::IAEAHeader)
    io_header = open(path.header, "w") 
    io_phsp   = open(path.phsp  , "w")
    ga = GeneratedAttributes()
    writer = IAEAPhspWriter(r, ga, io_header, io_phsp)
end
iaea_writer(path) = iaea_writer(IAEAPath(path))

function Base.flush(w::IAEAPhspWriter)
    if isopen(w.io_header)
        print_header(w.io_header, w)
    end
    flush(w.io_header)
    flush(w.io_phsp)
end

function Base.close(w::IAEAPhspWriter)
    flush(w)
    close(w.io_header)
    close(w.io_phsp)
end

function iaea_writer(f, path, r::IAEAHeader)
    w = iaea_writer(IAEAPath(path), r)
    ret = call_fenced(f, w)
    close(w)
    ret
end
