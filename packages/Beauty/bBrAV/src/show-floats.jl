# Part of Beauty.jl: Add Beauty to your julia output.
# Copyright (C) 2019 Quantum Factory GmbH

Base.show(io::IO, ::MIME"text/plain", n::AbstractFloat) =
    print(
        io,
        format_float(
            "text/plain",
            n;
            unicode = hasunicodesupport(io)
        )
    )
Base.show(io::IO, ::MIME"text/latex", n::AbstractFloat) =
    print(io, format_float("text/latex", n))
Base.show(io::IO, ::MIME"text/html", n::AbstractFloat) =
    print(io, format_float("text/html", n))
Base.show(io::IO, ::MIME"text/markdown", n::AbstractFloat) =
    print(io, format_float("text/plain", n; unicode = true))

format_float(
    mime::String,
    n::AbstractFloat,
    err::AbstractFloat = sqrt(eps(n)); # default to typ. num. error
    unicode::Bool = false
) = format_number(
    mime,
    n,
    err,
    unicode = unicode
)
