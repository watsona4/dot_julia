module FeaturedFuncs

using ..PerFlagFuncs
using ..UtilityFuncs

export Flag
export FlagSet

export get_flat
export get_level
export get_level_flat
export remove_flat

"""
```
get_flat(s::String,
                  flags_start::Vector{String},
                  flags_stop::Vector{String},
                  inclusive::Bool = true)
```
Gets the substring based on the start and stop flag
vectors, and a Bool which determines whether the flags
themselves should be returned or not.

This function will grab the inner-most string, assuming
that you do not have multiple start flags before reaching
a corresponding stop flag.

```
julia> s = "Some text... {GRAB THIS}, some more text {GRAB THIS TOO}..."
"Some text... {GRAB THIS}, some more text {GRAB THIS TOO}..."

julia> L = BetweenFlags.get_flat(s, ["{"], ["}"])
2-element Array{String,1}:
 "{GRAB THIS}"
 "{GRAB THIS TOO}"
```
"""
function get_flat(s::String,
                  flags_start::Vector{String},
                  flags_stop::Vector{String},
                  inclusive::Bool = true)
  L = Vector{String}()
  L_start = [m for flag_start in flags_start for m in find_next_iter(s, flag_start)]
  L_stop  = [m for flag_stop  in flags_stop  for m in find_next_iter(s, flag_stop )]
  sort!(L_start)
  sort!(L_stop)
  if L_start==[] || L_stop==[]
    return Vector{String}([""])
  end
  (L_start, L_stop) = get_alternating_consecutive_vector(L_start, L_stop)
  for (i_start, i_stop) in zip(L_start, L_stop)
    b, m, a = substring_decomp_by_index(s, i_start, i_stop, flags_start, flags_stop, inclusive)
    push!(L, m)
  end
  return L
end

"""
```
get_level_flat(s::String,
               flags_start::Vector{String},
               flags_stop::Vector{String},
               inclusive::Bool = true)
```
get_level_flat gets the substring based on the `flags_start`
and `flags_stop` vectors, and a Bool which determines
whether the flags themselves should be returned or not.

This function will grab the outer-most string by ignoring
stop flags when multiple start flags occur before stop flags.

```
julia> using BetweenFlags

julia> s = "Some text... {GRAB {THIS}}, some more text {GRAB THIS TOO}..."
"Some text... {GRAB {THIS}}, some more text {GRAB THIS TOO}..."

julia> L = BetweenFlags.get_level_flat(s, ["{"], ["}"])
2-element Array{String,1}:
 "{GRAB {THIS}}"
 "{GRAB THIS TOO}"
```
"""
function get_level_flat(s::String,
                        flags_start::Vector{String},
                        flags_stop::Vector{String},
                        inclusive::Bool = true)
  L = Vector{String}()
  L_start = [m for flag_start in flags_start for m in find_next_iter(s, flag_start)]
  L_stop  = [m for flag_stop  in flags_stop  for m in find_next_iter(s, flag_stop )]
  L_start = unique(L_start)
  L_stop = unique(L_stop)
  if L_start==[] || L_stop==[]
    return Vector{String}([""])
  end
  sort!(L_start)
  sort!(L_stop)
  level = compute_level_total(s, flags_start, flags_stop)
  (L_start, L_stop) = get_alternating_consecutive_vector(L_start, L_stop, level)
  for (i_start, i_stop) in zip(L_start, L_stop)
    b, m, a = substring_decomp_by_index(s, i_start, i_stop, flags_start, flags_stop, inclusive)
    push!(L, m)
  end
  return L
end

"""
```
get_level(s::String,
          outer_flags::FlagSet,
          inner_flags::Vector{FlagSet},
          inclusive::Bool = true)
```
This is the featured function of BetweenFlags.

Gets the substring based on the outer and inner flag
sets, and a Bool which determines whether the flags
themselves should be returned or not.

To see an example of this function in action, go to
BetweenFlags/test/runtests.jl.
"""
function get_level(s::String,
                   outer_flags::FlagSet,
                   inner_flags::Vector{FlagSet},
                   inclusive::Bool = true)
  L = Vector{String}()
  flag_set_all = vcat([outer_flags], inner_flags)
  outer_flags_start = outer_flags.start.trigger
  outer_flags_stop = outer_flags.stop.trigger
  inner_flags_start = [y for x in inner_flags for y in x.start.trigger]
  inner_flags_stop  = [y for x in inner_flags for y in x.stop.trigger]

  flags_start = vcat(outer_flags_start, inner_flags_start)
  flags_stop  = vcat(outer_flags_stop , inner_flags_stop)
  L_start = [m for flag_start in flags_start for m in find_next_iter(s, flag_start)]
  L_stop  = [m for flag_stop  in flags_stop  for m in find_next_iter(s, flag_stop )]
  L_start = unique(L_start)
  L_stop = unique(L_stop)
  if L_start==[] || L_stop==[]
    return Vector{String}([""])
  end
  sort!(L_start)
  sort!(L_stop)
  level_total = compute_level_total(s, flags_start, flags_stop)
  level_per_flags = compute_level_per_flag(s, level_total, flag_set_all)
  level_outer = level_per_flags[outer_flags.ID]
  (L_start, L_stop) = get_alternating_consecutive_vector(L_start, L_stop, level_total, level_outer, s)
  for (i_start, i_stop) in zip(L_start, L_stop)
    b, m, a = substring_decomp_by_index(s, i_start, i_stop, flags_start, flags_stop, inclusive)
    push!(L, m)
  end
  return L
end

"""
```
remove_flat(s::String,
            flags_start::Vector{String},
            flags_stop::Vector{String},
            inclusive::Bool = true)
```
Removes text between flags.

The remove function is fundamentally different from get_level because
the string, `s`, in `get_level` does not change, whereas it does in
`remove_flat`. Therefore, the indexes found must, either be translated
by the number of removed characters in the correct location, or the
entire function must be called recursively. Alternatively, the
strings/flags can be removed in reverse order, preserving the output
string, which is what is done here. In addition, the return type of
`remove_flat` is a String.
"""
function remove_flat(s::String,
                     flags_start::Vector{String},
                     flags_stop::Vector{String},
                     inclusive::Bool = true)::String
  if !get_remaining_flags(s, flags_start, flags_stop)
    return s
  end
  same_flags = all([x==y for x in flags_start for y in flags_stop])
  L_start = [m for flag_start in flags_start for m in find_next_iter(s, flag_start)]
  L_stop  = [m for flag_stop  in flags_stop  for m in find_next_iter(s, flag_stop )]
  sort!(L_start)
  sort!(L_stop)
  (L_start, L_stop) = get_alternating_consecutive_vector(L_start, L_stop)
  if same_flags
    L_start = L_start[1:2:end]
    L_stop = L_stop[1:2:end]
  end
  s_new = s
  for (i_start, i_stop) in zip(reverse(L_start), reverse(L_stop))
    b, m, a = substring_decomp_by_index(s_new, i_start, i_stop, flags_start, flags_stop, inclusive)
    s_new = string(b, a)
  end
  return s_new
end

end