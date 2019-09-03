#=Copyright 2018 Vidrio Technologies, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=#

module ScanImageTiffReader

import Base: length, size
export Context, data, description, length, metadata, pxtype, size

_release = "1.3"
_libname = begin
    external = joinpath(dirname(dirname(@__FILE__)), "external")
    if Sys.iswindows()
        lp = joinpath(external, "ScanImageTiffReader-$_release-win64", "lib")
    elseif Sys.isapple()
        lp = joinpath(external, "ScanImageTiffReader-$_release-Darwin", "lib")
    elseif Sys.islinux()
        lp = joinpath(external, "ScanImageTiffReader-$_release-Linux", "lib")
    else
        error("you done goofed")
    end

    joinpath(lp, Sys.iswindows() ? "ScanImageTiffReaderAPI.dll" : "libScanImageTiffReaderAPI.so")
end
_typemap = [UInt8, UInt16, UInt32, UInt64, Int8, Int16, Int32, Int64, Float32, Float64]

"""
    Context(handle::Ptr{Cvoid}, log::Ptr{UInt8})
"""
struct Context
    handle::Ptr{Cvoid}
    log::Ptr{UInt8}
end

struct strides_array
    strides_0::Int64
    strides_1::Int64
    strides_2::Int64
    strides_3::Int64
    strides_4::Int64
    strides_5::Int64
    strides_6::Int64
    strides_7::Int64
    strides_8::Int64
    strides_9::Int64
    strides_10::Int64
end

struct dims_array
    dims_0::UInt64
    dims_1::UInt64
    dims_2::UInt64
    dims_3::UInt64
    dims_4::UInt64
    dims_5::UInt64
    dims_6::UInt64
    dims_7::UInt64
    dims_8::UInt64
    dims_9::UInt64
end

struct Size
    ndim::UInt32
    typeid::Int32
    strides::strides_array
    dims::dims_array
end

"""
    open(func::Function, filename::AbstractString, args...)

Open a ScanImage TIFF file `filename` for reading and apply `func` to it
(with optional arguments).

# Examples
```jldoctest
ScanImageTiffReader.open(mytif) do io
    length(io)
end
# output
10
```
"""
function open(func::Function, filename::AbstractString, args...)
    handle = @eval ccall((:ScanImageTiffReader_Open, $(_libname)), Context,
                         (Ptr{UInt8}, ), $(filename))

    if handle.log != C_NULL
        throw(ErrorException(unsafe_string(handle.log)))
    end

    try
        func(handle, args...)
    finally
        @eval ccall((:ScanImageTiffReader_Close, $(_libname)), Cvoid,
                    (Ptr{Context}, ), $(Ref(handle)))
    end
end

"""
    size(ctx::Context)

Return the shape of the data in the TIFF file.

# Examples
```jldoctest
ScanImageTiffReader.open(mytif) do io
    size(io)
end
# output
(512, 512, 10)
```
"""
function size(ctx::Context)
    s = @eval ccall((:ScanImageTiffReader_GetShape, $(_libname)), Size,
                    (Ptr{Context}, ), $(Ref(ctx)));

    if ctx.log != C_NULL
        throw(ErrorException(unsafe_string(ctx.log)))
    end

    Int64.(getfield.(Ref(s.dims), fieldnames(dims_array)[1:s.ndim]))
end

"""
    pxtype(ctx::Context)

Return the type of the data in the TIFF file.

# Examples
```jldoctest
ScanImageTiffReader.open(mytif) do io
    pxtype(io)
end
# output
Int16
```
"""
function pxtype(ctx::Context)
    s = @eval ccall((:ScanImageTiffReader_GetShape,$(_libname)), Size,
                    (Ptr{Context}, ), $(Ref(ctx)));

    if ctx.log!=C_NULL
        throw(ErrorException(unsafe_string(ctx.log)))
    end

    _typemap[s.typeid + 1] # julia is 1-based
end

"""
    data(ctx::Context)

Return an n-dimensional array containing the image stack.

# Examples
```jldoctest; output=false
using ScanImageTiffReader
d = ScanImageTiffReader.open(mytif) do io
    data(io)
end
d[1:10, 1:10, 1]
# output
10×10 Array{Int16,2}:
  9844   8752  10596  10153   8711   9879   8827   9004   9684   8604
 10038   9315   8696   9950   9061   8582   9013  10098  10364   9551
 10618  10610  10536   9716  10187   8813  10033  10206   8567  10299
  9535   9417   9435  10227   9336   9300   9822   9799   9511   8991
  9190  10558  10147  10129   9564   9112   9622   9074   8570   9614
  9152   9148  10318  10175   8917  10477  10200   9530   9591   8780
  9708   9749  10424   8796   8952  10358   9195   9367   9154   8618
 10136   8884  10197   9472   9141   9774   9026   9514   9945   8416
  9008  10001   9679   8854   9217   8927   9310  10315   9682   9176
  9301   9186   8765   9407   9358   8626   9943   8780   9384   9837
```
"""
function data(ctx::Context)
    out = Array{pxtype(ctx)}(undef, size(ctx)...)
    @eval ccall((:ScanImageTiffReader_GetData, $(_libname)), Int,
                (Ptr{Context}, Ptr{Cvoid}, Csize_t), $(Ref(ctx)), $(out), sizeof($(out)));

    if ctx.log != C_NULL
        throw(ErrorException(unsafe_string(ctx.log)))
    end

    out
end

"""
    length(ctx::Context)

Return the number of planes in the image stack.

# Examples
```jldoctest
ScanImageTiffReader.open(mytif) do io
    length(io)
end
# output
10
```
"""
function length(ctx::Context)
    n = @eval ccall((:ScanImageTiffReader_GetImageDescriptionCount, $(_libname)),
                    Int32, (Ptr{Context}, ), $(Ref(ctx)))

    if ctx.log != C_NULL
        throw(ErrorException(unsafe_string(ctx.log)))
    end

    n
end

"""
    description(ctx::Context, iframe::Int)

Return the contents of the image description tag for frame `iframe`.

# Examples
```jldoctest
desc = ScanImageTiffReader.open(mytif) do io
    description(io, 1)
end
print(desc)
# output
frameNumbers = 1
acquisitionNumbers = 1
frameNumberAcquisition = 1
frameTimestamps_sec = 0.000000
acqTriggerTimestamps_sec =
nextFileMarkerTimestamps_sec =
endOfAcquisition =  0
endOfAcquisitionMode = 0
dcOverVoltage = 0
epoch = [2016 6 4 13 51 7.8046]
```
"""
function description(ctx::Context, iframe::Int)
    sz = @eval ccall((:ScanImageTiffReader_GetImageDescriptionSizeBytes, $(_libname)),
                     Csize_t, (Ptr{Context}, Cint), $(Ref(ctx)), $(iframe) - 1) # convert to zero based
    sz != 0 || return ""

    str = Vector{UInt8}(undef, sz)
    @eval ccall((:ScanImageTiffReader_GetImageDescription,$(_libname)), Csize_t,
                (Ptr{Context}, Cint, Ptr{UInt8}, Csize_t),
                $(Ref(ctx)), $(iframe) - 1, $(str), sizeof($(str))) # convert to zero based
    if ctx.log != C_NULL
        throw(ErrorException(unsafe_string(ctx.log)))
    end

    unsafe_string(pointer(str))
end

"""
    metadata(ctx::Context)

Read the ScanImage metadata section from the file.

This data section is not part of the Tiff specification, so common Tiff readers
will not be able to access this data.

In ScanImage 2016 and later, this is a JSON string.  For previous versions of
ScanImage, this is a bytestring that must be deserialized in MATLAB.

# Examples

```jldoctest
ScanImageTiffReader.open(mytif) do io
    JSON.parse(metadata(io))
end
# output
Dict{String,Any} with 2 entries:
  "SI"        => Dict{String,Any}("hConfigurationSaver"=>Dict{String,Any}("usrF…
  "RoiGroups" => Dict{String,Any}("photostimRoiGroups"=>nothing,"imagingRoiGrou…
```
"""
function metadata(ctx::Context)
    sz = @eval ccall((:ScanImageTiffReader_GetMetadataSizeBytes, $(_libname)),
                     Csize_t, (Ptr{Context}, ), $(Ref(ctx)))
    sz != 0 || return ""

    str = Vector{UInt8}(undef, sz)
    @eval ccall((:ScanImageTiffReader_GetMetadata, $(_libname)), Csize_t,
                (Ptr{Context}, Ptr{UInt8}, Csize_t),
                $(Ref(ctx)), $(str), sizeof($(str)))
    if ctx.log != C_NULL
        throw(ErrorException(unsafe_string(ctx.log)))
    end

    unsafe_string(pointer(str))
end

end
