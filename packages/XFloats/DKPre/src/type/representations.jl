Base.string(x::XFloat16) = string(Float16(reinterpret(Float32, x)))
Base.string(x::XFloat32) = string(Float32(reinterpret(Float64, x)))

Base.show(io::IO, x::XFloat16) = print(io, Float16(reinterpret(Float32, x)))
Base.show(io::IO, x::XFloat32) = print(io, Float32(reinterpret(Float64, x)))

Base.tryparse(::Type{XFloat16}, x::String) = reinterpret(XFloat16, tryparse(Float32, x))
Base.tryparse(::Type{XFloat32}, x::String) = reinterpret(XFloat32, tryparse(Float64, x))

Base.Printf.ini_dec(d::XFloat16, ndigits, digits) =
    Base.Printf.ini_dec(reinterpret(Float32, d), ndigits, digits)

Base.Printf.ini_dec(d::XFloat32, ndigits, digits) =
    Base.Printf.ini_dec(reinterpret(Float64, d), ndigits, digits)

Base.Printf.ini_dec(d::XFloat16, ndigits::Int32, digits) =
    Base.Printf.ini_dec(reinterpret(Float32, d), ndigits, digits)

Base.Printf.ini_dec(d::XFloat32, ndigits::Int32, digits) =
    Base.Printf.ini_dec(reinterpret(Float64, d), ndigits, digits)

Base.Printf.ini_dec(d::XFloat16, ndigits::Int64, digits) =
    Base.Printf.ini_dec(reinterpret(Float32, d), ndigits, digits)

Base.Printf.ini_dec(d::XFloat32, ndigits::Int64, digits) =
    Base.Printf.ini_dec(reinterpret(Float64, d), ndigits, digits)


Base.hash(x::XFloat16) = hash(reinterpret(Float32, x))
Base.hash(x::XFloat32) = hash(reinterpret(Float64, x))
Base.hash(x::XFloat16, h::UInt) = hash(Float64(reinterpret(Float32,x)), h)
Base.hash(x::XFloat32, h::UInt) = hash(reinterpret(Float64,x), h)
