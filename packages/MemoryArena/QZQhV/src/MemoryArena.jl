module MemoryArena
using Base.Checked

export TypedArena, RefCell
export alloc, destroy

# An immutable reference cell. Attempting to deference a null
# reference will return `nothing`.
struct RefCell{T}
    ptr::Ptr{T}
end

RefCell{T}(::Nothing) where {T} = RefCell{T}(C_NULL)

function Base.getindex(rc::RefCell)
    if rc.ptr == C_NULL
        nothing
    else
        unsafe_load(rc.ptr)
    end
end

struct TypedArenaChunk{T}
    next::Ptr{TypedArenaChunk{T}}
    capacity::UInt64
end

function create_chunk(next::Ptr{TypedArenaChunk{T}},
                      capacity::UInt64) where T
    elem_size = checked_mul(sizeof(T) * capacity)
    size = checked_add(elem_size, sizeof(TypedArenaChunk{T}))
    chunk_ptr = convert(Ptr{TypedArenaChunk{T}}, Libc.malloc(size))
    if chunk_ptr == C_NULL
        nothing
    else
        unsafe_store!(chunk_ptr, TypedArenaChunk{T}(next, capacity))
        chunk_ptr
    end
end

function start(chunk_ptr::Ptr{TypedArenaChunk{T}}) where T
    chunk_ptr + sizeof(TypedArenaChunk{T})
end

function end_ptr(chunk_ptr::Ptr{TypedArenaChunk{T}}) where T
    chunk = unsafe_load(chunk_ptr)
    elem_size = checked_mul(chunk.capacity, sizeof(T))
    chunk_ptr + elem_size
end

function destroy(chunk::Ptr{TypedArenaChunk{T}}) where T
    next = unsafe_load(chunk).next
    Libc.free(chunk)
    if !(next == C_NULL)
        destroy(next)
    end
end

# A memory arena that can only hold one type of object
mutable struct TypedArena{T}
    # Pointer to the next object
    ptr::Ptr{T}
    # Pointer to the current end of the arena
    # Allocation past this point will cause a new
    # chunk of memory to be allocated
    end_ptr::Ptr{T}
    # Reference to the first memory chunk
    # allocated to the arena
    first::Ptr{TypedArenaChunk{T}}
end

TypedArena{T}() where {T} = TypedArena{T}(UInt64(8))

function TypedArena{T}(capacity::UInt64) where T
    if T isa Union
        throw(ErrorException("Union types are not supported."))
    end
    chunk_ptr = create_chunk(convert(Ptr{TypedArenaChunk{T}}, C_NULL), capacity)
    if chunk_ptr === nothing
        throw(OutOfMemoryError())
    end
    TypedArena{T}(start(chunk_ptr), end_ptr(chunk_ptr),
                  chunk_ptr)
end

function alloc(arena::TypedArena{T}, object::T) where T
    if arena.ptr == arena.end_ptr
        grow(arena)
    end

    objptr = arena.ptr
    unsafe_store!(objptr, object)
    arena.ptr += sizeof(T)
    RefCell{T}(objptr)
end

function grow(arena::TypedArena{T}) where {T}
    old_chunk = unsafe_load(arena.first)
    capacity = checked_mul(old_chunk.capacity, UInt64(2))
    new_chunk = create_chunk(arena.first, capacity)
    if new_chunk === nothing
        throw(OutOfMemoryError())
    end
    
    arena.ptr = start(new_chunk)
    arena.end_ptr = end_ptr(new_chunk)
    arena.first = new_chunk
end

function destroy(arena::TypedArena)
    destroy(arena.first)
end
end # end Module TypedArena
