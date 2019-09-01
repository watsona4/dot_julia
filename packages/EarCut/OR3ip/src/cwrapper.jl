function triangulate(polygon::Vector{Vector{Point{2, Float64}}})
    lengths = map(x-> UInt32(length(x)), polygon)
    len = UInt32(length(lengths))
    array = ccall(
        (:u32_triangulate_f64, earcut),
        Tuple{Ptr{GLTriangle}, Cint},
        (Ptr{Ptr{Float64}}, Ptr{UInt32}, UInt32),
        polygon, lengths, len
    )
    unsafe_wrap(Vector{GLTriangle}, array[1], array[2])
end

function triangulate(polygon::Vector{Vector{Point{2, Float32}}})
    lengths = map(x-> UInt32(length(x)), polygon)
    len = UInt32(length(lengths))
    array = ccall(
        (:u32_triangulate_f32, earcut),
        Tuple{Ptr{GLTriangle}, Cint},
        (Ptr{Ptr{Float32}}, Ptr{UInt32}, UInt32),
        polygon, lengths, len
    )
    unsafe_wrap(Vector{GLTriangle}, array[1], array[2])
end

function triangulate(polygon::Vector{Vector{Point{2, Int64}}})
    lengths = map(x-> UInt32(length(x)), polygon)
    len = UInt32(length(lengths))
    array = ccall(
        (:u32_triangulate_i64, earcut),
        Tuple{Ptr{GLTriangle}, Cint},
        (Ptr{Ptr{Int64}}, Ptr{UInt32}, UInt32),
        polygon, lengths, len
    )
    unsafe_wrap(Vector{GLTriangle}, array[1], array[2])
end

function triangulate(polygon::Vector{Vector{Point{2, Int32}}})
    lengths = map(x-> UInt32(length(x)), polygon)
    len = UInt32(length(lengths))
    array = ccall(
        (:u32_triangulate_i32, earcut),
        Tuple{Ptr{GLTriangle}, Cint},
        (Ptr{Ptr{Int32}}, Ptr{UInt32}, UInt32),
        polygon, lengths, len
    )
    unsafe_wrap(Vector{GLTriangle}, array[1], array[2])
end
