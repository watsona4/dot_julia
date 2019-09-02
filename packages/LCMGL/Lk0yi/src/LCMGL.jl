module LCMGL

depsjl = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
isfile(depsjl) ? include(depsjl) : error("LCMGL not properly ",
    "installed. Please run\nPkg.build(\"LCMGL\")")

import Base: unsafe_convert
using Libdl
export LCM, LCMGLClient,
	switch_buffer,
	begin_mode,
	end_mode,
	vertex,
	color,
	normal,
	scale_axes,
	point_size,
	line_width,
	translate,
	rotate,
	push_matrix,
	pop_matrix,
	load_identity,
	sphere,
	draw_axes

POINTS         = 0x0000
LINES          = 0x0001
LINE_LOOP      = 0x0002
LINE_STRIP     = 0x0003
TRIANGLES      = 0x0004
TRIANGLE_STRIP = 0x0005
TRIANGLE_FAN   = 0x0006
QUADS          = 0x0007
QUAD_STRIP     = 0x0008
POLYGON        = 0x0009


mutable struct LCM
    pointer::Ptr{Cvoid}

    LCM() = begin
        lc = new(ccall((:lcm_create, liblcm), Ptr{Cvoid}, (Ptr{UInt8},), ""))
		finalizer(close, lc)
        lc
    end
end
unsafe_convert(::Type{Ptr{Cvoid}}, lc::LCM) = lc.pointer

function close(lcm::LCM)
	if lcm.pointer != C_NULL
	    ccall((:lcm_destroy, liblcm), Cvoid, (Ptr{Cvoid},), lcm)
		lcm.pointer = C_NULL
	end
end

function LCM(func::Function)
    lc = LCM()
    try
        func(lc)
    finally
        close(lc)
    end
end

struct Clcmgl
    lcm::Ptr{Cvoid}
    name::Ptr{Cchar}
    channel_name::Ptr{Cchar}
    scene::Int32
    sequence::Int32
    data::Ptr{UInt8}
    datalen::Cint
    data_alloc::Cint
    texture_count::UInt32
end

mutable struct LCMGLClient
    lcm::LCM
	name::AbstractString
    pointer::Ptr{Clcmgl}

    LCMGLClient(lcm::LCM, name::AbstractString) = begin
        gl = new(lcm, name,
                 ccall((:bot_lcmgl_init, libbot2_lcmgl_client),
				       Ptr{Clcmgl}, (Ptr{Cvoid}, Ptr{UInt8}), lcm, name))
        finalizer(close, gl)
        gl
    end
end
unsafe_convert(::Type{Ptr{Clcmgl}}, gl::LCMGLClient) = gl.pointer

function datalen(lcmgl::LCMGLClient)
    (lcmgl.pointer == C_NULL) && error("LCMGLClient is unininitialized")
    cgl = unsafe_load(lcmgl.pointer)
    cgl.datalen
end

function close(lcmgl::LCMGLClient)
	if lcmgl.pointer != C_NULL
		ccall((:bot_lcmgl_destroy, libbot2_lcmgl_client),
		      Cvoid, (Ptr{Clcmgl},), lcmgl)
		lcmgl.pointer = C_NULL
	end
end

LCMGLClient(name::AbstractString) = LCMGLClient(LCM(), name)

function LCMGLClient(func::Function, name::AbstractString, automatically_switch_buffer::Bool=true)
    LCM() do lc
        LCMGLClient(func, lc, name, automatically_switch_buffer)
    end
end

function LCMGLClient(func::Function, lcm::LCM, name::AbstractString, automatically_switch_buffer::Bool=true)
    gl = LCMGLClient(lcm, name)
    try
        func(gl)
        if automatically_switch_buffer && datalen(gl) > 0
            switch_buffer(gl)
        end
    finally
		close(gl)
    end
end

switch_buffer(gl::LCMGLClient) = ccall((:bot_lcmgl_switch_buffer, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl},), gl)

# begin and end are reserved keywords in Julia, so I've renamed
# them to begin_mode and end_mode
begin_mode(gl::LCMGLClient, mode::Integer) = ccall((:bot_lcmgl_begin, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cuint), gl, mode)
end_mode(gl::LCMGLClient) = ccall((:bot_lcmgl_end, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl},), gl)

vertex(gl::LCMGLClient, x, y) = ccall((:bot_lcmgl_vertex2d, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cdouble, Cdouble), gl, x, y)
vertex(gl::LCMGLClient, x, y, z) = ccall((:bot_lcmgl_vertex3d, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cdouble, Cdouble, Cdouble), gl, x, y, z)

color(gl::LCMGLClient, red, green, blue) = ccall((:bot_lcmgl_color3f, libbot2_lcmgl_client),
    Cvoid, (Ptr{Clcmgl}, Cfloat, Cfloat, Cfloat), gl.pointer, red, green, blue)
color(gl::LCMGLClient, red, green, blue, alpha) = ccall((:bot_lcmgl_color4f, libbot2_lcmgl_client),
    Cvoid, (Ptr{Clcmgl}, Cfloat, Cfloat, Cfloat, Cfloat), gl.pointer, red, green, blue, alpha)
normal(gl::LCMGLClient, x, y, z) = ccall((:bot_lcmgl_normal3f, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cfloat, Cfloat, Cfloat), gl, x, y, z)
scale_axes(gl::LCMGLClient, x, y, z) = ccall((:bot_lcmgl_scalef, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cfloat, Cfloat, Cfloat), gl, x, y, z)

point_size(gl::LCMGLClient, size) = ccall((:bot_lcmgl_point_size, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cfloat), gl, size)
line_width(gl::LCMGLClient, width) = ccall((:bot_lcmgl_line_width, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cfloat), gl, width)


translate(gl::LCMGLClient, v0, v1, v2) = ccall((:bot_lcmgl_translated, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cdouble, Cdouble, Cdouble), gl, v0, v1, v2)
rotate(gl::LCMGLClient, angle, x, y, z) = ccall((:bot_lcmgl_rotated, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl}, Cdouble, Cdouble, Cdouble, Cdouble), gl, angle, x, y, z)
push_matrix(gl::LCMGLClient) = ccall((:bot_lcmgl_push_matrix, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl},), gl)
pop_matrix(gl::LCMGLClient) = ccall((:bot_lcmgl_pop_matrix, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl},), gl)

sphere(gl::LCMGLClient, origin, radius, slices, stacks) = ccall((:bot_lcmgl_sphere, libbot2_lcmgl_client),
    Cvoid, (Ptr{Clcmgl}, Ptr{Cdouble}, Cdouble, Cint, Cint), gl, origin, radius, slices, stacks)

draw_axes(gl::LCMGLClient) = ccall((:bot_lcmgl_draw_axes, libbot2_lcmgl_client), Cvoid, (Ptr{Clcmgl},), gl)

function __init__()
    @static if Sys.islinux()
        Libdl.dlopen(liblcm, Libdl.RTLD_GLOBAL)
    end
end


end

import LCMGL
