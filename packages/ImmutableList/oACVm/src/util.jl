
""" O(length(lst1)), O(1) if either list is empty.. needs improvment """

function listAppend(lst1::List{T}, lst2 = nil::List{T})::List{T} where {T}
  if listEmpty(lst2)
    return lst1
  end
  if listEmpty(lst1)
    return lst2
  end
  for c in listReverse(lst1)
    lst2 = cons(c, lst2)
  end
  lst2
end

function listLength(lst::List{T})::Int where {T}
  length(lst)
end

""" O(n) """
function listMember(element::T, lst::List{T})::Bool where {T}
  for e in lst
    if e == element
      return true
    end
  end
  false
end

""" O(index) """
function listGet(lst::List{T}, index #= one-based index =#::Int)::T where {T}
  if index == 1
    return listHead(lst)
  end
  local cntr::Integer = 0
  for i in lst
    cntr += 1
    if index == cntr
      return i
    end
  end
end

""" O(1) """
function listRest(lst::List{T})::List{T} where {T}
  if isa(lst, Nil) nil else lst.tail end
end

""" O(1) """
function listHead(lst::List{T})::T where {T }
  if isa(lst, Nil) nil else lst.head end
end

""" O(index) """
function listDelete(inLst::List{A}, index #= one-based index =#::Int)::List{A} where {A}
  local outLst::List{A}
  #= Defined in the runtime =#
  outLst
end

""" O(1) """
function listEmpty(lst::List{T})::Bool where {T}
  if isa(lst, Nil) true else false end;
end

export listAppend
export listReverse
export listReverseInPlace
export listLength
export listMember
export listGet
export listRest
export listHead
export listDelete
export listEmpty
