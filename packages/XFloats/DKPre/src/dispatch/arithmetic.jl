Base.:(+)(x::XFloat16, y::XFloat16) = reinterpret(XFloat16, (+)(reinterpret(Float32, x), reinterpret(Float32, y)))
Base.:(-)(x::XFloat16, y::XFloat16) = reinterpret(XFloat16, (-)(reinterpret(Float32, x), reinterpret(Float32, y)))
Base.:(*)(x::XFloat16, y::XFloat16) = reinterpret(XFloat16, (*)(reinterpret(Float32, x), reinterpret(Float32, y)))
Base.:(/)(x::XFloat16, y::XFloat16) = reinterpret(XFloat16, (/)(reinterpret(Float32, x), reinterpret(Float32, y)))
Base.:(\)(x::XFloat16, y::XFloat16) = reinterpret(XFloat16, (\)(reinterpret(Float32, x), reinterpret(Float32, y)))

Base.:(+)(x::XFloat32, y::XFloat32) = reinterpret(XFloat32, (+)(reinterpret(Float64, x), reinterpret(Float64, y)))
Base.:(-)(x::XFloat32, y::XFloat32) = reinterpret(XFloat32, (-)(reinterpret(Float64, x), reinterpret(Float64, y)))
Base.:(*)(x::XFloat32, y::XFloat32) = reinterpret(XFloat32, (*)(reinterpret(Float64, x), reinterpret(Float64, y)))
Base.:(/)(x::XFloat32, y::XFloat32) = reinterpret(XFloat32, (/)(reinterpret(Float64, x), reinterpret(Float64, y)))
Base.:(\)(x::XFloat32, y::XFloat32) = reinterpret(XFloat32, (\)(reinterpret(Float64, x), reinterpret(Float64, y)))

