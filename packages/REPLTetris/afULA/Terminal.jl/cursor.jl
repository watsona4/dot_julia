cursor_deleteline(buf::IO=terminal.out_stream)               = print(buf, "\x1b[2K")

cursor_hide(buf::IO=terminal.out_stream)                     = print(buf, "\x1b[?25l")
cursor_show(buf::IO=terminal.out_stream)                     = print(buf, "\x1b[?25h")

cursor_save_position(buf::IO=terminal.out_stream)            = print(buf, "\x1b[s")
cursor_restore_position(buf::IO=terminal.out_stream)         = print(buf, "\x1b[u")

cursor_move_abs(buf::IO, c::Vector{Int}=[0,0])  = print(buf, "\x1b[$(c[2]);$(c[1])H")
cursor_move_abs(c::Vector{Int}) = cursor_move_abs(terminal.out_stream, c)

# ToDo: Remove x offset after newline
function cursor_move_rel(buf::IO, c=[0,0])
    x = c[1] >= 0 ? "\x1b[$(abs(c[1]))A" : "\x1b[$(abs(c[1]))B"
    y = c[2] >= 0 ? "\x1b[$(abs(c[2]))C" : "\x1b[$(abs(c[2]))D"
    print(buf, x,y)
end
cursor_move_rel(c::Vector{Int}) = cursor_move_rel(terminal.out_stream, c)


function clear_screen()
    buf = IOBuffer()
    cursor_move_abs(buf, [0,0])
    for y in 1:50
        cursor_move_abs(buf, [0,y])
        cursor_deleteline(buf)
    end
    print(String(take!(buf)))
end

"""
    put(pos::Vector, s::String)
Put text `s` on screen at coordinates `pos`.
Does not change cursor position.
"""
function put(buf::IO, pos::Vector, s::String)
    cursor_save_position(buf)
    cursor_move_abs(buf, pos)
    print(buf, s)
    cursor_restore_position(buf)
end
put(pos::Vector, s::String) = put(terminal.out_stream, pos::Vector, s::String)

function put(buf::IO, pos::Vector, color::Crayon, s::String)
    print(buf, color)
    put(buf, pos, s)
end
put(buf::IO, pos::Vector, c::Symbol, s::String) = put(buf, pos, Crayon(foreground=c), s)
put(pos::Vector, c::Union{Symbol, Crayon}, s::String) = put(terminal.out_stream, pos, c, s)

function terminal_screen(data::Array{String}, origin::Vector{Int}=[1,1];
                colors::Array{Symbol}=fill(:white, size(data)))
    buf = IOBuffer()
    x1, y1 = origin
    dy, dx = size(data)
    row_heigths, column_widths = _row_column_sizes(data)
    for x in 1:dx, y in 1:dy
        d = data[y, x]
        s = String.(split(d, "\n"))
        for i in 1:row_heigths[y]
            line = i > length(s) ? "" : s[i]
            put(buf, [sum(column_widths[1:x-1])+3x+x1,sum(row_heigths[1:y-1])+y+y1+i], colors[y,x], line)
        end
    end
    print(String(take!(buf)))
end

function _row_column_sizes(data::Array{String})
    size_string(s::String) = length(split(s, "\n")), maximum(length.(split(s, "\n")))
    size_data = size_string.(data)
    row_heigths = maximum(getindex.(size_data, 1), 2)
    column_widths = maximum(getindex.(size_data,2), 1)
    row_heigths, column_widths
end
