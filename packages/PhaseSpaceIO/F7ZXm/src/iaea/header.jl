function load(io::IO, ::Type{IAEAHeader})
    read_header(io)
end

const MANDATORY_KEYWORDS = [
:IAEA_INDEX,
:TITLE,
:FILE_TYPE,
:CHECKSUM,
:RECORD_CONTENTS,
:RECORD_CONSTANT,
:RECORD_LENGTH,
:BYTE_ORDER,
:TRANSPORT_PARAMETERS,
:MACHINE_TYPE,
:MONTE_CARLO_CODE_VERSION,
:GLOBAL_PHOTON_ENERGY_CUTOFF,
:GLOBAL_PARTICLE_ENERGY_CUTOFF,
:COORDINATE_SYSTEM_DESCRIPTION,
]
# $ORIG_HISTORIES:

function validate_header_dict(d)
    for key in MANDATORY_KEYWORDS
        @argcheck key ∈ keys(d)
    end
    ft = parse(Int, stripcomments(d[:FILE_TYPE]))
    if ft == 0 # phase space
        @argcheck :ORIG_HISTORIES ∈ keys(d)
        @argcheck :PARTICLES ∈ keys(d)
    elseif ft == 1 # event generator
        @argcheck :INPUT_FILE_FOR_EVENT_GENERATOR ∈ keys(d)
    end
end

const RKEY = r"\$(.*):"

iskeyline(s) = occursin(RKEY, s)
isemptyline(s) = strip(s) == ""
parsekey(line) = Symbol(match(RKEY, line)[1])
stripcomments(s) = strip(first(split(s, "//")))

function read_header_dict(io::IO; validate::Bool=false)
    d = OrderedDict{Symbol, String}()
    val_lines = String[]
    line = readline(io)
    key = parsekey(line)
    while !eof(io)
        line = readline(io)
        if iskeyline(line)
            val = join(val_lines, '\n')
            d[key] = val
            key = parsekey(line)
            empty!(val_lines)
        else
            push!(val_lines, line)
        end
    end
    d[key] = join(val_lines, '\n')
    @assert eof(io)
    if validate
        validate_header_dict(d)
    end
    d
end

function cleanup_record(s)
    lines = split(s, '\n')
    lines = map(stripcomments, lines)
    filter(l -> !isemptyline(l), lines)
end

function read_header(io::IO)
    d = read_header_dict(io)
    IAEAHeader(d)
end

function IAEAHeader(d::AbstractDict)

    contents  = cleanup_record(d[:RECORD_CONTENTS])
    constants = cleanup_record(d[:RECORD_CONSTANT])

    read_next!(T, c) = parse(T, popfirst!(c))
    read_next!(::Type{Bool}, c) = Bool(parse(Int, popfirst!(c)))
    function add_next_default!(d,key,contents, constants)
        stored_in_phsp = read_next!(Bool, contents)
        stored_in_header = !stored_in_phsp
        T = Float32
        if stored_in_header
            d[key] = read_next!(T, constants)
        end
    end

    rcd = OrderedDict()
    add_next_default!(rcd,:x,contents, constants)
    add_next_default!(rcd,:y,contents, constants)
    add_next_default!(rcd,:z,contents, constants)
    add_next_default!(rcd,:u,contents, constants)
    add_next_default!(rcd,:v,contents, constants)
    add_next_default!(rcd,:w,contents, constants)
    @assert !haskey(rcd, :w)
    add_next_default!(rcd, :weight, contents, constants)
    Nf = read_next!(Int, contents)
    Ni = read_next!(Int, contents)
    @assert isempty(constants)
    rc = (;rcd...)
    raw = OrderedDict{Symbol, String}(
        (k=>chomp(v)) for (k,v) in pairs(d) if 
        !(k in [:RECORD_CONSTANT, :RECORD_CONSTANT]))

    # NT = typeof(rc)
    IAEAHeader{Nf, Ni}(rc, raw)
end
