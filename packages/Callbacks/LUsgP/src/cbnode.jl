"Callback Node"
struct CbNode{F, TPL <: Tuple}
  parent::F
  children::TPL
end

p → c::Tuple = CbNode(p, c)
p → c = CbNode(p, (c,))

datamerge(x, data) = nothing
datamerge(data1::NamedTuple, data2::NamedTuple) = merge(data1, data2)

trigger(data, child) = nothing
trigger(data::NamedTuple, child) = child(data)

function (cbt::CbNode)(data)
  data2 = datamerge(cbt.parent(data), data)
  for child in cbt.children
    trigger(data2, child)
  end
end