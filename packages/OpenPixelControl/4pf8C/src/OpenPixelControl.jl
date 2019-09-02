"""
    OpenPixelControl

A small package providing the functionality of an [OpenPixelControl](https://openpixelcontrol.org)
client in [Julia](https://julialang.org).

"""
module OpenPixelControl
  using Sockets
  using Colors
  export OpenPixelConnection
  export setInterpolation, setPixel, close
  import Sockets: close
  import Colors: AbstractRGB, red, green, blue
"""
    OpenPixelConnection

A struct containing all necessary information for the status of the OPC connection.

This for now only requires the one field
* `connection` which is a `TCPSocket`. 

# Constructors

* `OpenPixelConnection()` – generates a connection to `localhost:7890`
* `OpenPixelConnection(port)` – generates a connection to `localhost:port`
* `OpenPixelConnection(host,port)` – generates a connection ho `host:port`
"""
struct OpenPixelConnection
  connection::TCPSocket
  OpenPixelConnection() = OpenPixelConnection(7890)
  OpenPixelConnection(port::Int) = new(connect(port)) # localhost
  OpenPixelConnection(host,port::Int) = new(connect(host,port))
end
"""
    close(o)

close the [`OpenPixelConnection`](@ref)` o`.
"""
close(o::OpenPixelConnection) = close(o.connection)
"""
    setInterpolation(o[, true)

set interpolation mode of the [`OpenPixelConnection`](@ref)` o` to `true`
(default) or `false`.
"""
function setInterpolation(o::OpenPixelConnection, interpolate::Bool=true)
  if interpolate
    config_byte = UInt8(0)
  else
    config_byte = UInt8(2)
  end
  # message header (all channels, system command, length: 5, )
  header = UInt8.( [0, 255, 0, 5, 0, 1, 0, 2] )
  data = Tuple([ header...,config_byte])
  write(o.connection, Ref(data))
end
"""
setPixel(o,colors[, channel=0, command=0])

send pixel `colors` to the OPC server `o` on the given `channel` with given `command`.

# Input

* `o::OpenPixelConnection` – the connection representing the server to send
  the colors to
* `colors::Array{<:AbstractRGB}` – an array of RGB colors, each entry
  representing one pixel's color
* `channel::Integer` – (`0`) determines the channel/strand `[1-255]` to send the values to.
  The default `0` refers to all channels
* `command::Integer` – (`0`) command to use to send the pixel. The value `0` is the default by
  [openpixelcontrol.org](https://openpixelcontrol.org)
"""
setPixel( o::OpenPixelConnection, colors::NTuple{N,<: AbstractRGB{T}},
  channel::Integer = 0, command::Integer = 0) where {T,N} =
setPixel(o::OpenPixelConnection,
  UInt8.( round.(255 .* red.(colors)) ),
  UInt8.( round.(255 .* green.(colors)) ),
  UInt8.( round.(255 .* blue.(colors)) ),
  channel, command
)
"""
setPixel(o,r,b,g[, channel=0, command=0])

send pixel colors represented by three `NTuples{N,UInt8}` of same length
to the OPC server `o` on the given `channel` with given `command`.

# Input

* `o::OpenPixelConnection` – the connection representing the server to send
  the colors to
* `r`,`g`,`b::NTuple{N,UInt8}` – three `NTuples` of `UInt8` with same length
  `N` representing the 8bit an array of RGB colors, each set of entries
  representing one pixel's color
* `channel::Integer` – (`0`) determines the channel/strand `[1-255]` to send the values to.
  The default `0` refers to all channels
* `command::Integer` – (`0`) command to use to send the pixel. The value `0` is the default by
  [openpixelcontrol.org](https://openpixelcontrol.org)
"""
function setPixel( opc::OpenPixelConnection,
  redChannel::NTuple{N,UInt8}, greenChannel::NTuple{N,UInt8}, blueChannel::NTuple{N,UInt8},
  channel::Integer = 0, command::Integer=0) where N
  ch=UInt8(channel)
  cmd=UInt8(command)
  numberOfPixel = length(redChannel)
  numData = numberOfPixel*3
  lowByte = UInt8( rem(numData,256) )
  highByte = UInt8( div(numData,256) )
  # reshape the r g and b tuple into (r1,g1,b1,r2,...)
  data = Tuple([ ch, cmd, highByte, lowByte,
    Tuple( Iterators.flatten( collect(zip(redChannel,greenChannel,blueChannel))) )... ]
  )
  write(opc.connection, Ref(data))
end
end # module