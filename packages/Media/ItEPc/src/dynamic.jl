import Base: getindex, setindex!

function dynamic_eq(def)
  name, val = def.args
  if isexpr(name, :(::))
    name, T = name.args
    :(const $(esc(name)) = Ref{$(esc(T))}($(esc(val))))
  else
    :(const $(esc(name)) = Ref($(esc(val))))
  end
end

function dynamic_let(ex)
  # bindings = [:(bind($(esc(b.args[1])), $(esc(b.args[2])), t)) for b in block(ex.args[1]).args]
  bs = [(esc(b.args[1]), esc(b.args[2])) for b in block(ex.args[1]).args]
  xs = [gensym() for n = 1:length(bs)]
  save = [:($(esc(x)) = $b[]) for (x, (b, v)) in zip(xs, bs)]
  set = [:($b[] = $v) for (x, (b, v)) in zip(xs, bs)]
  unset = [:($b[] = $(esc(x))) for (x, (b, v)) in zip(xs, bs)]
  :(let $(xs...)
    try
      $(save...)
      $(set...)
      $(esc(ex.args[2]))
    finally
      $(unset...)
    end
  end)
end

macro dynamic(def)
  isexpr(def, :(=)) ? dynamic_eq(def) :
  isexpr(def, :let) ? dynamic_let(def) :
  error("Unsupported @dynamic expression")
end
