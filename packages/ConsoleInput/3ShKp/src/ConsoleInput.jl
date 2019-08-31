module ConsoleInput

include("./utils.jl")

DlmType = Union{
    AbstractString,
    AbstractChar,
    Regex
}

function readInt(io::IO=stdin, delimiter::DlmType=" ")
    readline(io) |>
    x -> split(x, delimiter) |>
    x -> parse.(Int64, x) |>
    process
end

function readString(io::IO=stdin, delimiter::DlmType=" ")
    readline(io) |>
    x -> split(x, delimiter) |>
    process
end

function readGeneral(type, io::IO=stdin, delimiter::DlmType=" ")
    readline(io) |>
    x -> split(x, delimiter) |>
    x -> parse.(type, x) |>
    process
end

end # module
