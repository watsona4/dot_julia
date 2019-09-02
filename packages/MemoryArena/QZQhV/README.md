# MemoryArena
A Julia module that provides a type-safe memory arena based
on the TypedArena in the Rust library.

This allows fast allocation of large numbers of objects of the
same type. The memory arena does not allow deallocation of individual
objects, rather all objects are cleaned up when the memory arena is
manually destroyed.

## Warnings
1. At this point, the `TypedArena` does not support `Union` types or abstract
types. This is a planned feature.

2. You should not store objects in the arena which contain
references to objects managed by the Julia garbage collector. Doing so
will almost surely result in corrupt memory and a crashing program.

3. Type safety and program stability can be compromised if you directly
manipulate the pointer contained by the RefCell. Do so at your own risk.
