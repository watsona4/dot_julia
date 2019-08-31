mutable struct ResettableStack{T,iip}
  data::Vector{T}
  cur::Int
  numResets::Int
  ResettableStack(ty::Type{T}) where {T} = new{T,true}(Vector{T}(),0,0)
  ResettableStack{iip}(ty::Type{T}) where {T,iip} = new{T,iip}(Vector{T}(),0,0)
end

isinplace(::ResettableStack{T,iip}) where {T,iip} = iip


isempty(S::ResettableStack) = S.cur==0
length(S::ResettableStack)  = S.cur

function push!(S::ResettableStack,x)
  if S.cur==length(S.data)
    S.cur+=1
    push!(S.data,x)
  else
    S.cur+=1
    S.data[S.cur]=x
  end
  nothing
end

safecopy(x) = copy(x)
safecopy(x::Union{Number,StaticArray}) = x
safecopy(x::Nothing) = nothing

# For DiffEqNoiseProcess S₂ fast updates
function copyat_or_push!(S::ResettableStack,x)
  if S.cur==length(S.data)
    S.cur+=1
    push!(S.data,safecopy.(x))
  else
    S.cur+=1
    curx = S.data[S.cur]
    if !isinplace(S)
      S.data[S.cur] = x
    else
      curx[2] .= x[2]
      if x[3] != nothing
        curx[3] .= x[3]
      end
      S.data[S.cur] = (x[1],curx[2],curx[3])
    end
  end
  nothing
end

function pop!(S::ResettableStack)
  S.cur-=1
  S.data[S.cur+1]
end

function iterate(S::ResettableStack, state=S.cur)
    if state == 0
        return nothing
    end

    state -= 1
    (S.data[state+1],state)
end

function reset!(S::ResettableStack,force_reset = false)
  S.numResets += 1
  S.cur = 0
  if length(S.data) > 5 && (S.numResets%FULL_RESET_COUNT==0 || force_reset)
    resize!(S.data,max(length(S.data)÷2,5))
  end
  nothing
end
