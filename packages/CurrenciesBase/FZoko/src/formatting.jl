# Single-line output in two-argument `show`
Base.show(io::IO, m::Monetary) = print(io, m / majorunit(m), currency(m))

# # Multi-line output with MIME types
# function Base.show(io::IO, ::MIME"text/plain", m::Monetary)
#     if get(io, :compact, false)
#         print(io, m / majorunit(m), currency(m))
#     else
#         print(io, format(m; styles=[:plain]))
#     end
# end

# function Base.show(io::IO, ::MIME"text/latex", m::Monetary)
#     print(io, string('$', format(m; styles=[:latex]), '$'))
# end