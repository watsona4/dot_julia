# Part of Beauty.jl: Add Beauty to your julia output.
# Copyright (C) 2019 Quantum Factory GmbH

using Measurements
using DocStringExtensions

"""

Show displays `Measurements.Measurement` objects.

$(SIGNATURES)

"""
Base.show(io::IO, ::MIME"text/plain", n::Measurements.Measurement) =
    print(
        io,
        format_measurement(
            "text/plain",
            n;
            unicode = hasunicodesupport(io)
        )
    )
Base.show(io::IO, ::MIME"text/latex", n::Measurements.Measurement) =
    print(io, format_measurement("text/latex", n))
Base.show(io::IO, ::MIME"text/html", n::Measurements.Measurement) =
    print(io, format_measurement("text/html", n))
Base.show(io::IO, ::MIME"text/markdown", n::Measurements.Measurement) =
    print(io, format_measurement("text/plain", n, unicode = true))

format_measurement(
    mime::String,
    n::Measurements.Measurement;
    unicode=false
) = format_number(
    mime,
    Measurements.value(n),
    Measurements.uncertainty(n),
    unicode = unicode
)
