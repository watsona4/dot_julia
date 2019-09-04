#=
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>
=#

"""
TrackingHeap is a heap with a tracking system for the stored values.

Inserting a value into a TrackingHeap returns a tracker for the value. The
tracker can be used to access, update, and delete the value without searching
for it first. Heap order do not allow for `O(log m)` search (where `m` is the
number of values currently stored inside the heap), just for `O(m)` search, so
this feature allow for some performance gain if you need to manipulate values
anywhere in the heap (not just on top of the heap). Besides access, which is
`O(1)`, update and delete are `O(log m)` as they may need to rebalance the
tree.

If the tracking system is not needed, there is little reason to use this heap.

I wrote this package because the MutableBinaryHeap of DataStructures.jl did not
allow some behavior I wanted; behavior as:
1) a non-top value can be deleted without being made top first;
2) values can be deleted and others inserted without double rebalancing;
3) after a value is deleted, its tracker can be re-reused to re-insert
   that value or insert a new value (but this is not done automatically);
4) the arity of the heap (binary, trinary, etc..) can be defined by the
   user (by parametric type) and inccur in minimal overhead.
5) all the stored values are in a Vector{V} in heap order, for easy
   backdoor/hacking access;
6) the integer type that is the tracker type can be defined by the user;
"""
module TrackingHeaps
# TODO: To allow automatic reuse create a different heap, as the struct would
#       need an extra vector for the "already used but expired" trackers.
#       Such vector could be reset if the heap becomes empty at any time,
#       and values removed from its back do not need to be added there.
# TODO: doctests (https://docs.julialang.org/en/latest/manual/documentation/)
# TODO: (to be considered) track the largest tracker not expired, when it is
#       removed search for the second largest, and resize tk2ix accordingly.
#       This can make a single removal O(num calls to track! already done), but
#       if we search using tk2ix, then it is amortized (for each extra step in
#       some deletion, there should have been a previous track!, and the extra
#       steps consume such "savings" made by previous track!). This assumes
#       the user will not use setindex! to insert values with large
#       tracker keys.
# TODO: for now, tracker keys cannot be of a !isbits type,
#       because for efficiency/convenience we convert the N-arity to the type
#       of K and then dispatch on it with Val, but Val (or any parametric type)
#       cannot wrap !isbits types.

export TrackingHeap # the main data structure
export MinHeapOrder, MaxHeapOrder, is_higher_than # Order related exports
export SafeFromYourself, NoTrainingWheels # Safety types
export top, next_tracker, renew_tracker!, track!, update!, extract!
export extract_and_push!, extract_and_track!
export pop_and_track!, pop_once_and_track_many!
export empty!!
# This module also exports many other methods but it does so by extending
# the Base module functions, not only that, but the methods provided for
# Base allow many other functions to work over TrackingHeap as it is an
# abstractdict.

# Move these to a separated file or a minimalistic package:
@inline oneless(x) = x - one(x)
@inline onemore(x) = x + one(x)
@inline two(::Type{T}) where {T} = convert(T, 2)
@inline two(x :: T) where {T} = convert(T, 2)
@inline ispositive(x) :: Bool = x > zero(x)
# Anyway, they should not be exported.

# TODO: WHAT NEED TO BE FINISHED FOR FIRST COMMIT
# 3) write tests for everything
# 4) save to git, upload to a new repository
# 5) check version, call register to register on the julia General

"""
    MinHeapOrder

The default type for the type parameter `O` (i.e., Order) of TrackingHeap.
If used the heap will have the minimum value as top value.

See also: [`is_higher_than`](@ref), [`TrackingHeap`](@ref) 
"""
struct MinHeapOrder; end

"""
    MaxHeapOrder

The alternative type for the type parameter `O` (i.e., Order) of TrackingHeap.
If used the heap will have the maximum value as top value.

See also: [`is_higher_than`](@ref), [`TrackingHeap`](@ref) 
"""
struct MaxHeapOrder; end

"""
    is_higher_than(HeapOrderType, x, y) :: Bool

To define an ordering that is not the stored value type (i.e., `V`) default,
you can create a new empty type and extend the `is_higher_than` function with a
method that takes such empty type and returns if `x` should be higher in the
heap than `y` based on it (so you do not need to wrap the value type inside a
new type for a different ordering).

Note that `is_higher_than` defaults to `<` and `>` instead of `isless` and
`!isless` (that would be `>=`).

Also, if you do not want to provide a `<` and `>` for the stored value type,
you can instead just define this function for `::Type{MinHeapOrder}` (and/or
`::Type{MaxHeapOrder}`) and `x`-and-`y` of the specific types of the values
compared.

See also: [`MinHeapOrder`](@ref), [`MaxHeapOrder`](@ref),
[`TrackingHeap`](@ref) 
"""
is_higher_than(::Type{MinHeapOrder}, x, y) :: Bool = x < y
is_higher_than(::Type{MaxHeapOrder}, x, y) :: Bool = x > y

"""
    SafeFromYourself

The default type for the type parameter `S` (i.e., Safety) of TrackingHeap.
Inform the heap methods to use `@assert` to check for any possible
inconsistencies, and throw KeyError tried to access/delete/update an
non-existent key.

See also: [`NoTrainingWheels`](@ref)
"""
struct SafeFromYourself; end

"""
    NoTrainingWheels

The alternative type for the type parameter `S` (i.e., Safety) of TrackingHeap.
Inform the heap methods avoid any checking theoretically giving the best speed.

See also: [`SafeFromYourself`](@ref)
"""
struct NoTrainingWheels; end

"""
    TrackingHeap{K, V, N, O, S} <: AbstractDict{K, V}

The type of a heap that has tracker/keys of type K (an integer), stored values
of type V, that is N-ary (binary, trinary, etc...), with the order defined by
O, and the safety level defined by S.

Equal values are allowed but, if more than one value could be the top value,
then any of the equal values may be there (they can yet be distinguished by
tracker).

The TrackingHeap implements (almost) all methods described in Dict interface,
and can be seen as a Dict (with the special property of always allowing for
fast access to the minimal/maximal value and its key). There is an AbstractHeap
of DataStructures, but it was designed for heaps without key, and then
an AbstractMutableHeap interface (for heaps with keys) was grafted into it.
Also, inheriting such interface would make necessary that this package
used DataStructures just for inheriting its abstract type.
"""
struct TrackingHeap{K, V, N, O, S} <: AbstractDict{K, V}
  svals :: Vector{V} # svals: stored values, define the ordering
  trcks :: Vector{K} # trcks: trck[i] is the tracker/key returned for svals[i]
  tk2ix :: Vector{K} # tk2ix: tk2ix[trck[i]] == i, finds svals based on tracker
end

"""
    TrackingHeap(tracking_heap) # copy constructor
    TrackingHeap(::Type{V}; kwargs = ...)

Constructs a TrackingHeap with default types for all type parameters
except V (i.e., the stored values, that has no obvious default).

This constructor also accepts a variety of keyword arguments which allow
to change the default type parameters and initialize the heap.

The constructor allow to initialize using: a values vector in heap order to
be owned by the heap (no overhead, nor checking); a values iterable
collection (the respective trackers should be assumed to be
`one(K):convert(K, length(number of initial values))`); a pairs iterable
collection. These options are mutually exclusive.

See also: [`MinHeapOrder`](@ref), [`SafeFromYourself`](@ref)

# Arguments
- `K`: The tracker keys type. Default: `typeof(length(T[]))`.
- `N`: The N-arity of the heap. Default: binary (i.e, 2).
- `O`: The ordering of the heap values. Default: MinHeapOrder.
- `S`: The safety level of the heap methods. Default: SafeFromYourself.
- `init_val_heap`: a Vector already in heap order. Default: empty.
- `init_val_coll`: an initial collections of values to be copied.
  Default: empty.
- `init_pairs`: an initial collection of pairs tracker-value to be copied.
  Default: empty.
"""
function TrackingHeap(
  ::Type{V};
  K = typeof(length(V[])),
  N = convert(K, 2),
  O = MinHeapOrder,
  S = SafeFromYourself,
  init_val_heap = Vector{V}(),
  init_val_coll = Vector{V}(),
  init_pairs = Vector{Pair{K, V}}()
) where {V}
  N = convert(K, N)
  if !isempty(init_val_heap)
    init_trcks = collect(one(K):convert(K, length(init_val_heap)))
    init_tk2ix = deepcopy(init_trcks)
    TrackingHeap{K, V, N, O, S}(init_val_heap, init_trcks, init_tk2ix)
  else
    h = TrackingHeap{K, V, N, O, S}(Vector{V}(), Vector{K}(), Vector{K}())
    if !isempty(init_val_coll)
      foreach(v -> track!(h, v), init_val_coll)
    elseif !isempty(init_pairs)
      foreach(((k, v),) -> h[k] = v, init_pairs)
    end
    h
  end
end
function TrackingHeap(
  heap :: TrackingHeap{K, V, N, O, S}
) where {K, V, N, O, S}
  deepcopy(heap) # fallbacks to copy
end

#################### THE INTERNAL HELPER METHODS FOLLOW #################### 

"""
    parent_ix

Internal helper method. Do not use. Subject to change.
"""
@inline function parent_ix(::Val{N}, cix :: K) where {K, N}
  n = convert(K, N)
  div(cix + (n - two(K)), n)
end
# TODO: The inline below only work if the type of the tracker is Int, fix that.
@inline parent_ix(::Val{2}, cix) = cix >> 1

"""
    last_child_ix

Internal helper method. Do not use. Subject to change.
"""
last_child_ix(::Val{N}, pix :: K) where {K, N} = onemore(pix * convert(K, N))

"""
    sift_down!(heap, ix)

Internal use. May be documented in the future.
Avoid use unless strictly necessary.
"""
function sift_down!(
  heap :: TrackingHeap{K, V, N, O, S}, ix :: K
) where {K, V, N, O, S}
  svals, trcks, tk2ix = heap.svals, heap.trcks, heap.tk2ix

  # Save the value and its tracker before the sift.
  sval = svals[ix]
  trck = trcks[ix]

  # This will not change. Need to be rigth type to avoid instability.
  last_ix_heap = convert(K, length(svals))
  
  while true
    lc_ix = last_child_ix(Val(N), ix)
    fc_ix = lc_ix - oneless(N)
    # If value is already in the last layer/level (i.e., have no child), break.
    last_ix_heap < fc_ix && break
    lc_ix = min(lc_ix, last_ix_heap)
    min_child_value, min_child_ix = svals[fc_ix], fc_ix
    for curr_child_ix = onemore(fc_ix):lc_ix
      if is_higher_than(O, svals[curr_child_ix], min_child_value)
        min_child_ix = curr_child_ix
        min_child_value = svals[curr_child_ix]
      end
    end
    # If the highest child cannot raise above sval, then sval cannot go down.
    !is_higher_than(O, min_child_value, sval) && break

    # Otherwise, the smallest child goes up (i.e., takes value place as parent).
    svals[ix] = svals[min_child_ix]
    trcks[ix] = trcks[min_child_ix]
    tk2ix[trcks[ix]] = ix

    # Now we need to check if sval will stay at its new position, or descend
    # even more.
    ix = min_child_ix
  end

  # If sval is at the last layer/level or all of its childs are smaller than
  # it, then we can finally write it at its final position. Note that no time
  # was wasted copying it to candidate positions.
  svals[ix] = sval
  trcks[ix] = trck
  tk2ix[trck] = ix
end

"""
    sift_up!(heap, ix)

Internal use. May be documented in the future.
Avoid use unless strictly necessary.
"""
function sift_up!(
  heap :: TrackingHeap{K, V, N, O, S}, ix :: K
) where {K, V, N, O, S}
  svals, trcks, tk2ix = heap.svals, heap.trcks, heap.tk2ix

  # Save the sval and its tracker before the sift.
  sval = svals[ix]
  trck = trcks[ix]
  while ix > one(K) # while ix is not the root (i.e., we can go up yet)
    pix = parent_ix(Val(N), ix)
    # If sval cannot be above its parent, then sval must stay at ix.
    !is_higher_than(O, sval, svals[pix]) && break

    # Otherwise, sval should be at parent position or above, bring the
    # parent down.
    svals[ix] = svals[pix]
    trcks[ix] = trcks[pix]
    tk2ix[trcks[ix]] = ix

    # Now we need to check if sval will stay at its new position, or ascend
    # even more.
    ix = pix
  end

  # If sval is at root position or have a smaller parent, then we can
  # finally write it at its final position. Note that no time was wasted
  # copying it to candidate positions.
  svals[ix] = sval
  trcks[ix] = trck
  tk2ix[trck] = ix
end

"""
    sift!(heap, ix, previous_sval)

Internal use. May be documented in the future.
Avoid use unless strictly necessary.
"""
function sift!(
  heap :: TrackingHeap{K, V, N, O, S},
  ix :: K,
  previous_sval :: V
) where {K, V, N, O, S}
  if is_higher_than(O, previous_sval, heap.svals[ix])
    sift_down!(heap, ix)
  else
    sift_up!(heap, ix)
  end
end

#################### START OF THE EXPORTED API #################### 

"""
    top(heap) -> (sval, trck)

Returns the "highest" value stored inside the heap and its tracker. `O(1)`.

See also: [`is_higher_than`](@ref)
"""
function top(
  heap :: TrackingHeap{K, V, N, O, S}
) :: Pair{K, V} where {K, V, N, O, S}
  Pair(heap.trcks[1], heap.svals[1])
end

"""
    next_tracker(heap) -> trck

Return the same tracker the next call of `track!` would return, without
modifying the heap in any way. `O(1)`.

See also: [`track!`](@ref)
"""
function next_tracker(
  heap :: TrackingHeap{K, V, N, O, S}
) :: K where {K, V, N, O, S}
  onemore(convert(K, length(heap.tk2ix)))
end

"""
    renew_tracker!(heap, old_trck, new_trck = next_tracker(heap)) -> new_trck

Marks `old_trck` as unused, begins using `new_trck` to refer to the
value previously pointed by `old_trck`, and returns new_trck.

Does not need any rebalancing, `O(1)`, but may inccur in memory allocation if
`new_trck` was never used. The `new_trck` can be a tracker already used in the
past, but must not be in use at the moment.

See also: [`pop_and_track!`](@ref), [`update!`](@ref), [`next_tracker`](@ref),
[`extract_and_track!`](@ref)
"""
function renew_tracker!(
  heap :: TrackingHeap{K, V, N, O, S},
  old_trck :: K
) :: K where {K, V, N, O, S}
  S === SafeFromYourself &&
    !haskey(heap, old_trck) &&
    throw(KeyError(old_trck))

  ix = heap.tk2ix[old_trck]
  push!(heap.tk2ix, ix)
  new_trck = convert(K, length(heap.tk2ix))
  heap.trcks[ix] = new_trck

  return new_trck
end
function renew_tracker!(
  heap :: TrackingHeap{K, V, N, O, S},
  old_trck :: K,
  new_trck :: K
) :: K where {K, V, N, O, S}
  S === SafeFromYourself &&
    !haskey(heap, old_trck) &&
    throw(KeyError(old_trck))
  S === SafeFromYourself && @assert !haskey(heap, new_trck)

  ix = heap.tk2ix[old_trck]
  heap.trcks[ix] = new_trck
  max_trck = length(heap.tk2ix)
  if new_trck == onemore(max_trck)
    push!(heap.tk2ix, ix)
  else
    new_trck > max_trck && resize!(heap.tk2ix, new_trck)
    heap.tk2ix[new_trck] = ix
  end

  return new_trck
end

"""
    track!(heap, sval) -> trck

Insert a new sval into the heap and return a new "never used" tracker for it.

The return is the same the method `next_tracker` would give if called before
`track!`.
The heap may need to be rebalanced, so `O(log m)`.

See also: [`pop_and_track!`](@ref), [`next_tracker`](@ref), [`empty!!`](@ref)
"""
function track!(
  heap :: TrackingHeap{K, V, N, O, S},
  sval :: V
) :: K where {K, V, N, O, S}
  S === SafeFromYourself && @assert length(heap.svals) == length(heap.trcks)
  push!(heap.svals, sval)
  ix = convert(K, length(heap.svals))
  push!(heap.tk2ix, ix)
  trck = convert(K, length(heap.tk2ix))
  push!(heap.trcks, trck)

	sift_up!(heap, ix)

  return trck
end

"""
    update!(heap, trck, new_value) -> heap
    update!(heap, trck => new_value) -> heap

Update the value pointed by `trck`. `O(log m)`.

Similar to `setindex!` but assumes `trck` exists, if it does not, gives a
KeyError when `S === SafeFromYourself`, and undefined behaviour when `S
!== SafeFromYourself`.

See also: [`setindex!`](@ref)
"""
function update!(
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K,
  new_value :: V
) :: TrackingHeap{K, V, N, O, S} where {K, V, N, O, S}
  S === SafeFromYourself && !haskey(heap, trck) && throw(KeyError(trck))

  ix = heap.tk2ix[trck]
  old_value = heap.svals[ix]
  heap.svals[ix] = new_value

  sift!(heap, ix, old_value)

  heap
end
function update!(
  heap :: TrackingHeap{K, V, N, O, S},
  elem :: Pair{K, V},
) :: TrackingHeap{K, V, N, O, S} where {K, V, N, O, S}
  trck, new_value = elem
  update!(heap, trck, new_value)
end

"""
    extract!(heap, trck) -> sval

Delete the value referred by `trck` in the `heap`, and return it.

The `trck` can then be used to re-insert it, or to insert another value.

The heap may need to be rebalanced, so `O(log m)`.

See also: [`delete!`](@ref), [`empty!`](@ref)
"""
function extract!(
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K
) :: V where {K, V, N, O, S}
  # Asserts and abbreviations.
  S === SafeFromYourself && !haskey(heap, trck) && throw(KeyError(trck))
  svals, trcks, tk2ix = heap.svals, heap.trcks, heap.tk2ix

  ix = tk2ix[trck]
  # Save deleted value for knowing how to sift the one that takes its place,
  # and also for returning it.
  del_sval = svals[ix]
  # If the heap has values after the one removed, then the gap left needs
  # to be filled, we use the last value to do so.
  if ix < length(heap)
    svals[ix] = last(svals)
    trcks[ix] = last(trcks)
    tk2ix[trcks[ix]] = ix
  end
  # Delete the last value, which was the one removed, or was already moved to
  # the position of the one deleted to fill the gap.
  pop!(svals)
  pop!(trcks)
 
  # There will only be a value to sift if the position of the extracted value
  # was not in the last position of the heap.
	ix < length(heap) && sift!(heap, ix, del_sval)

  del_sval
end

"""
    extract_and_push!(heap, old_trck, new_trck => new_sval) -> old_sval

Similar to `extract_and_track!` but let you define `new_trck`.

CAUTION: guarantee that the value referred by old_trck will be extracted and
the new pair will be pushed but does not guarantee that the internal heap
structure will end up in the same state as calling `extract!` followed by
`push!`.

See also: [`extract_and_track!`](@ref), [`extract!`](@ref)
"""
function extract_and_push!(
  heap :: TrackingHeap{K, V, N, O, S},
  old_trck :: K,
  new_pair :: Pair{K, V}
) :: V where {K, V, N, O, S}
  S === SafeFromYourself &&
    !haskey(heap, old_trck) &&
    throw(KeyError(old_trck))
  new_trck, new_sval = new_pair

  # TODO: this can be more optimized by checking if the new_trck is in use
  # and if so, check which one of old_trck and new_trck is the best to update!
  old_sval = heap[old_trck]
  update!(heap, old_trck, new_sval)
  if old_trck != new_trck
    haskey(heap, new_trck) && delete!(heap, new_trck)
    renew_tracker!(heap, old_trck, new_trck)
  end

  return old_sval
end

"""
    extract_and_track!(heap, old_trck, new_sval) -> (old_sval, new_trck)

Similar to calling `extract!` followed by `track!` but more optimized.

CAUTION: guarantee that the value referred by old_trck will be extracted and
the new value will be tracked but does not guarantee that the internal heap
structure will end up in the same state as calling `extract!` followed by
`track!`.

See also: [`pop_and_track!`](@ref), [`extract!`](@ref), [`track!`](@ref),
"""
function extract_and_track!(
  heap :: TrackingHeap{K, V, N, O, S},
  old_trck :: K,
  new_sval :: V
) :: Tuple{V, K} where {K, V, N, O, S}
  S === SafeFromYourself && !haskey(heap, old_trck) &&
    throw(KeyError(old_trck))

  old_sval = heap[old_trck]
  update!(heap, old_trck, new_sval)
  new_trck = renew_tracker!(heap, old_trck)

  return old_sval, new_trck
end

"""
    pop_and_track!(heap, new_sval) -> ((top_sval, top_trck), new_trck)

Similar to calling `pop!` followed by `track!` but more optimized.

CAUTION: guarantee that the top will be popped and the new value will be
tracked but does not guarantee that the internal heap structure will end up in
the same state as calling `pop!` followed by `track!`.

See also: [`pop!`](@ref), [`track!`](@ref),
"""
function pop_and_track!(
  heap :: TrackingHeap{K, V, N, O, S},
  new_sval :: V
) :: Tuple{Pair{K, V}, K} where {K, V, N, O, S}
  old_pair = top(heap)
  old_trck = first(old_pair)
  update!(heap, old_trck, new_sval)
  new_trck = renew_tracker!(heap, old_trck)

  return old_pair, new_trck
end

"""
    pop_once_and_track_many!(heap, new_svals)::((top_sval,top_trck), new_trcks)

Similar to calling `pop!` once followed by many calls to `track!` but more
optimized.

CAUTION: guarantee that the top will be popped and the new values will be
tracked but does not guarantee that the internal heap structure will end up in
the same state as it would by calling `pop!` followed by calls to `track!` (in
the same order given in the array).

See also: [`pop!`](@ref), [`track!`](@ref), [`pop_and_track!`](@ref)
"""
function pop_once_and_track_many!(
  heap :: TrackingHeap{K, V, N, O, S},
  new_svals
) :: Tuple{Pair{K, V}, Vector{K}} where {K, V, N, O, S}
  if isempty(new_svals)
    popped_sval = pop!(heap)
    (popped_sval, K[])
  else
    S === SafeFromYourself && @assert eltype(new_svals) == V
    new_trcks = K[]
    sizehint!(new_trcks, length(new_svals))
    min_new_sval, min_new_sval_ix = findmin(new_svals)
    popped_sval, min_new_sval_trck = pop_and_track!(heap, min_new_sval)
    for new_sval_ix in eachindex(new_svals)
      if new_sval_ix == min_new_sval_ix
        new_trck = min_new_sval_trck
      else
        new_trck = track!(heap, new_svals[new_sval_ix])
      end
      push!(new_trcks, new_trck)
    end
    S === SafeFromYourself && @assert length(new_trcks) == length(new_svals)
    S === SafeFromYourself && @assert !isnothing(popped_sval)
    (popped_sval, new_trcks)
  end
end

function Base.empty(
  heap :: TrackingHeap{K, V, N, O, S}
) where {K, V, N, O, S}
  TrackingHeap(V, K = K, N = N, O = O, S = S)
end

# BELOW ARE ITERATION INTERFACE METHODS: iterate
# https://docs.julialang.org/en/v1/base/collections/#lib-collections-iteration-1
# IteratorSize and IteratorEltype are default.

function Base.iterate(
  heap :: TrackingHeap{K, V, N, O, S}
) :: Union{Nothing, Tuple{Pair{K, V}, K}} where {K, V, N, O, S}
  isempty(heap) && return nothing
  first_ix = one(K)
  (heap.trcks[first_ix] => heap.svals[first_ix], first_ix)
end

function Base.iterate(
  heap :: TrackingHeap{K, V, N, O, S},
  last_ix :: K
) :: Union{Nothing, Tuple{Pair{K, V}, K}} where {K, V, N, O, S}
  curr_ix = onemore(last_ix)
  curr_ix > length(heap) && return nothing
  (heap.trcks[curr_ix] => heap.svals[curr_ix], curr_ix)
end

# BELOW ARE GENERAL COLLECTION INTERFACE METHODS: isempty, empty!, and length
# https://docs.julialang.org/en/v1/base/collections/#General-Collections-1

"""
    isempty(heap) :: Bool

Returns true if the heap has no values stored; false otherwise. `O(1)`.
"""
function Base.isempty(
  heap :: TrackingHeap
) :: Bool
  isempty(heap.svals)
end

"""
    empty!(heap) -> heap

Delete all stored values efficiently (consider internals structure unused).
`O(1)`.

CAUTION: this does not reset which trackers are considered "never used",
so a call to `next_tracker` before `empty!` and another after will return
the same.

Do not guarantee that previous `sizehint!` or any vector growth have their
effect negated.

See also: [`extract!`](@ref), [`delete!`](@ref), [`track!`](@ref)
"""
function Base.empty!(
  heap :: TrackingHeap{K, V, N, O, S}
) :: TrackingHeap{K, V, N, O, S} where {K, V, N, O, S}
  empty!(heap.svals)
  empty!(heap.trcks)
  heap
end

"""
    empty!!(heap) -> heap

Delete all stored values efficiently (consider internals structure unused).
`O(1)`.

CAUTION: this resets which trackers are considered "never used", so a call to
`next_tracker` or `track!` after it will return the first tracker a newly
created TrackingHeap gives (and so on).

Do not guarantee that previous `sizehint!` or any vector growth have their
effect negated.

See also: [`extract!`](@ref), [`delete!`](@ref)
[`track!`](@ref)
"""
function empty!!(
  heap :: TrackingHeap{K, V, N, O, S}
) :: TrackingHeap{K, V, N, O, S} where {K, V, N, O, S}
  empty!(heap.svals)
  empty!(heap.trcks)
  empty!(heap.tk2ix)
  heap
end

"""
    length(heap) :: K

Returns the number of values currently stored inside the heap. `O(1)`.
"""
function Base.length(
  heap :: TrackingHeap{K, V, N, O, S}
) :: K where {K, V, N, O, S}
  convert(K, length(heap.svals))
end

# NO ITERABLE COLLECTION INTERFACE METHODS IS IMPLEMENTED.
# The eltype, indexin, in, ∈, ∋, ∉, ∌, unique, allunique, reduce, fold{l,r},
# sum, prod, any, all, count, foreach, map*, first, and collect are default.
# Base.{maximum,minimum,extrema} are default and note they work over pairs, so
# they search for the maximum/minimum tracker key.
# Base.{argmin,argmax,findmin,findmax} are default and give the expected value
# considering the values (and not the keys). They are not optimized as top.
# The destructive version of many of the previous methods (basically anything
# that interacted with AbstractArray) was not implemented.

# BELOW ARE INDEXABLE COLLECTION INTERFACE METHODS: getindex, setindex!,
# firstindex, and lastindex.

"""
    getindex(heap, trck) -> sval

Return the value referred by `trck` in `heap`. O(1).
 
Only check if the tracker key exists if `S === SafeFromYourself`.

See also: [`setindex!`](@ref)
"""
function Base.getindex(
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K
) :: V where {K, V, N, O, S}
  S === SafeFromYourself && !haskey(heap, trck) && throw(KeyError(trck))
  return heap.svals[heap.tk2ix[trck]]
end

"""
    setindex!(heap, new_value, trck) -> heap

Begin tracking new_value using trck if such tracker is not yet in use,
update the value pointed by trck if such tracker was already in use.

Will rebalance the heap if necessary. `O(log m)`. Note: a vector with length
equal to the highest used `trck` is kept, so giving `new_value` and arbitrarily
large tracker can cause massive (and unnecessary) memory use.

See also: [`update!`](@ref)
"""
function Base.setindex!(
  heap :: TrackingHeap{K, V, N, O, S},
  new_value :: V,
  trck :: K
) :: TrackingHeap{K, V, N, O, S} where {K, V, N, O, S}
  S === SafeFromYourself && @assert length(heap.svals) == length(heap.trcks)
  if haskey(heap, trck)
    update!(heap, trck, new_value)
  else
    push!(heap.svals, new_value)
    push!(heap.trcks, trck)
    ix = convert(K, length(heap.trcks))

    max_trck = convert(K, length(heap.tk2ix))
    if trck > max_trck
      if trck == onemore(max_trck) 
        push!(heap.tk2ix, ix)
      else
        resize!(heap.tk2ix, trck)
        heap.tk2ix[trck] = ix
      end
    else
      heap.tk2ix[trck] = ix
    end

    sift_up!(heap, ix)
  end

  heap
end

function Base.firstindex(
  heap :: TrackingHeap{K, V, N, O, S}
) :: K where {K, V, N, O, S}
  first(heap.trcks)
end

function Base.lastindex(
  heap :: TrackingHeap{K, V, N, O, S}
) :: K where {K, V, N, O, S}
  last(heap.trcks)
end

# BELOW ARE DICT INTERFACE METHODS: haskey, get, get!, getkey, delete!, pop!,
# keys, values, pairs, merge, merge!, sizehint!, keytype, and valtype.
# No get* method protect against type instability nor intend to do so.

function Base.haskey(
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K
) where {K, V, N, O, S}
  S === SafeFromYourself && ispositive(trck)
  trcks, tk2ix = heap.trcks, heap.tk2ix # abbreviate
  # The length of tk2ix need to allow trck and, as tk2ix can have uninitialized
  # values (from resize), the value of tk2ix[trck] needs to be inside the
  # expected bounds (the number of values currently inside the heap) and,
  # finally, trcks[tk2ix[trck]] needs to agree on which is its tracker (if it
  # does not, it can be be an expired tracker).
  length(tk2ix) >= trck && tk2ix[trck] in one(K):convert(K, length(trcks)) &&
    trcks[tk2ix[trck]] == trck
end

function Base.get(
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K,
  default
) where {K, V, N, O, S}
  haskey(heap, trck) ? heap[trck] : default
end

function Base.get(
  f :: Function,
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K
) where {K, V, N, O, S}
  haskey(heap, trck) ? heap[trck] : f()
end

function Base.get!(
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K,
  default :: V
) where {K, V, N, O, S}
  haskey(heap, trck) ? heap[trck] : heap[trck] = default
end

function Base.get!(
  f :: Function,
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K
) where {K, V, N, O, S}
  haskey(heap, trck) ? heap[trck] : heap[trck] = f()
end

function Base.getkey(
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K,
  default
) where {K, V, N, O, S}
  haskey(heap, trck) ? trck : default
end

# TODO: Maybe, in the future, implement a `merge!` method specific for heaps
# that is more optimized than the fallback provided in abstractdict.jl
# NOTE: both `merge!` variants are implemented by abstractdict.jl, but both
# `merge` variants needs to be defined for the specific type to avoid returning a
# `Dict` instead of a `TrackingHeap`.
function Base.merge(
  h :: TrackingHeap{K, V, N, O, S},
  others :: AbstractDict...
) where {K, V, N, O, S}
  pK = Union{K, map(keytype, others)...}
  pV = Union{V, map(valtype, others)...}
  new_h = TrackingHeap(pV; K = pK, N = N, O = O, S = S)
  merge!(new_h, h, others...)
  new_h
end

function Base.merge(
  combine :: Function,
  h :: TrackingHeap{K, V, N, O, S},
  others :: AbstractDict...
) where {K, V, N, O, S}
  pK = Union{K, map(keytype, others)...}
  pV = Union{V, map(valtype, others)...}
  new_h = TrackingHeap(pV; K = pK, N = N, O = O, S = S)
  merge!(combine, new_h, h, others...)
  new_h
end

function Base.sizehint!(
  heap :: TrackingHeap{K, V, N, O, S}, size :: K
) where {K, V, N, O, S} 
  sizehint!(heap.svals, size)
  sizehint!(heap.trcks, size)
  # It can be that tk2ix is (or will be) larger than the other two (because
  # after some insertal and removal of values without reusing keys it will
  # grow larger than the other two), but there is no harm in passing sizehint!
  # to it.
  sizehint!(heap.tk2ix, size)
end

function Base.sizehint!(
  heap :: TrackingHeap{K, V, N, O, S}, size
) where {K, V, N, O, S} 
  sizehint!(heap, convert(K, size))
end

"""
    delete!(heap, trck) -> heap

Delete the value referred by `trck` in the `heap`, and return the `heap`.

The `trck` can then be used to re-insert it, or to insert another value.

The heap may need to be rebalanced, so `O(log m)`.

See also: [`extract!`](@ref), [`pop!`](@ref)
"""
function Base.delete!(
  heap :: TrackingHeap{K, V, N, O, S},
  trck :: K
) :: TrackingHeap{K, V, N, O, S} where {K, V, N, O, S}
  S === SafeFromYourself && !haskey(heap, trck) && throw(KeyError(trck))
  extract!(heap, trck)
  heap
end

"""
    pop!(heap) -> Pair(sval, trck)

Delete the stored value at top of the heap, and return the `tracker => value`.

The `trck` can then be used to re-insert it, or to insert another value.

The heap may need to be rebalanced, so `O(log m)`.

See also: [`extract!`](@ref), [`delete!`](@ref)
"""
function Base.pop!( 
  heap :: TrackingHeap{K, V, N, O, S}
) :: Pair{K, V} where {K, V, N, O, S}
  S === SafeFromYourself && @assert !isempty(heap) 
  old_top = top(heap)

  extract!(heap, first(old_top))

  old_top
end

Base.keys(heap :: TrackingHeap) = heap.trcks
Base.values(heap :: TrackingHeap) = heap.svals
function Base.pairs(heap :: TrackingHeap)
  (Pair(k, v) for (k, v) in zip(keys(heap), values(heap)))
end

Base.keytype(heap :: TrackingHeap{K, V, N, O, S}) where {K, V, N, O, S} = K
Base.valtype(heap :: TrackingHeap{K, V, N, O, S}) where {K, V, N, O, S} = V

end # module

