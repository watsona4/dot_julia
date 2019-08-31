module UtilityFuncs

using ..PerFlagFuncs

export Flag
export FlagSet
export substring_decomp_by_index
export compute_level_total
export compute_level_per_flag
export get_remaining_flags

"""
```
Flag(word::String,
     word_boundaries_left::Vector{String},
     word_boundaries_right::Vector{String})
```
A flag that BetweenFlags looks for to denote
the start/stop position of a given "level" or
scope. The word boundaries need only be unique
since every permutation of left and right
word boundaries are taken to determine levels.
```
julia>
using BetweenFlags
# find: ["\\nfunction", " function", ";function"]
start_flag = BetweenFlags.Flag("function",
                               ["\\n", "\\s", ";"],
                               ["\\n", "\\s"])
# find: ["\\nend", " end", ";end"]
stop_flag = BetweenFlags.Flag("end",
                              ["\\n", "\\s", ";"],
                              ["\\n", "\\s", ";"])
```
"""
struct Flag
  word :: String
  word_boundaries_left :: Vector{String}
  word_boundaries_right :: Vector{String}
  trigger :: Vector{String}
  function Flag(word, word_boundaries_left, word_boundaries_right)
    trigger = Vector{String}()
    for left in word_boundaries_left
      for right in word_boundaries_right
        push!(trigger, string(left, word, right))
      end
    end
    return new(word, word_boundaries_left, word_boundaries_right, trigger)
  end
end

"""
```
FlagSet(start::Flag, stop::Flag)
```
A flag set that defines the start and stop of
the substring of interest.

```
julia>
using BetweenFlags
# find: ["\\nfunction", " function", ";function"]
start_flag = BetweenFlags.Flag("function",
                               ["\\n", "\\s", ";"],
                               ["\\n", "\\s"])
# find: ["\\nend", " end", ";end"]
stop_flag = BetweenFlags.Flag("end",
                              ["\\n", "\\s", ";"],
                              ["\\n", "\\s", ";"])
flag_set = FlagSet(start_flag, stop_flag)
```
"""
struct FlagSet
  start :: Flag
  stop  :: Flag
  ID  :: String
  function FlagSet(start::Flag, stop::Flag)
    # return new(start, stop, start.word*stop.word) # needs testing
    return new(start, stop, start.word)
  end
end

function substring_decomp_by_index(s::String,
                                   i_start::Int,
                                   i_end::Int,
                                   flags_start::Vector{String},
                                   flags_stop::Vector{String},
                                   inclusive::Bool = true)
  if inclusive # middle and after depend on length of stop flag (LSTOP)...
    LSTOP = [length(x) for x in flags_stop if occursin(x, s[i_end:end])][1]
    before = s[1:i_start-1]
    middle = s[i_start:i_end+LSTOP-1]
    after = s[i_end+LSTOP:end]
  else # before and middle depend on length of start flag (LSTART)...
    LSTART = [length(x) for x in flags_start if occursin(x, s[1:i_start+length(x)])][1]
    before = s[1:i_start+LSTART-1]
    middle = s[i_start+LSTART:i_end-1]
    after = s[i_end:end]
  end
  return before, middle, after
end

function compute_level_total(s::String,
                             flags_start::Vector{String},
                             flags_stop::Vector{String})
  L_s = length(s)
  level = zeros(Int, L_s)
  D_o = Dict(x => length(x) for x in flags_start)
  D_c = Dict(x => length(x) for x in flags_stop)
  L_c_arr = [v for (k, v) in D_o]
  L_o_arr = [v for (k, v) in D_c]
  L_delim_max = max([max(L_o_arr...), max(L_c_arr...)]...)
  L_delim_min = min([min(L_o_arr...), min(L_c_arr...)]...)
  if L_s>L_delim_min
    for i in 1:L_s-L_delim_max
      if any([s[i:i+D_o[x]-1] == x for x in flags_start])
        level[i:end] .= level[i:end] .+ 1
      elseif any([s[i:i+D_c[x]-1] == x for x in flags_stop])
        level[i+1:end] .= level[i+1:end] .- 1
      end
    end
  end
  return level
end

function compute_level_per_flag(s::String,
                                level_total::Vector{Int},
                                flag_set_all::Vector{FlagSet})
  # Algorithm:
  # 1) Initialize level_total_modified = level_total_total
  # 2) Find the maximum of level_total_modified and
  #    ask "Which key is responsible for the most recent
  #    increase in level_total_modified?" Assign the corresponding
  #    indexes in the dictionary.
  # 3) Set level_total_modified = level_total_modified-1
  #    where these dictionary indexes were set (since
  #    the solution in these locations are now known).
  # 4) Repeat 2-3 until level_total_modified = 0 everywhere
  level_total_modified = copy(level_total)
  N = length(level_total)
  D = Dict(FS.ID => zeros(Int, N) for FS in flag_set_all)
  max_lev = max(level_total...)
  for i in max_lev:-1:1
    L_max = max(level_total_modified...)
    i_maxes = [i for (i, x) in enumerate(level_total_modified) if x==L_max]
    L_maxes = split_by_consecutives(i_maxes)
    for i_max in L_maxes
      for FS in flag_set_all
        cond_any = any([x==s[i_max[1]:i_max[1]+length(x)-1] for x in FS.start.trigger])
        if cond_any
          D[FS.ID][i_max] .+= 1
        end
      end
      level_total_modified[i_max].-= 1
    end
  end
  temp = [D[FS.ID] for FS in flag_set_all]
  level_total_check = sum(temp, dims=1)[1]
  err = [abs(x-y) for (x, y) in zip(level_total_check, level_total)]
  if !all([x<0.01 for x in err])
    error("Error: levels not conservative.")
  end
  return D
end

function get_remaining_flags(s::String,
                             flags_start::Vector{String},
                             flags_stop::Vector{String})::Bool
  same_flags = all([x==y for x in flags_start for y in flags_stop])
  if same_flags
    remaining_flags = any([occursin(y, s) for y in flags_start]) && any([occursin(y, s) for y in flags_stop])
  else
    c_start = sum([count_flags(s, y) for y in flags_start])
    c_stop  = sum([count_flags(s, y) for y in flags_stop])
    if c_start == 0 || c_stop == 0
      remaining_flags = false
    else
      f_start = [findfirst(y, s)[1] for y in flags_start]
      f_stop  = [findfirst(y, s)[1] for y in flags_stop]
      remaining_flags = any([a<b for a in f_start for b in f_stop])
    end
  end
  return remaining_flags
end

end