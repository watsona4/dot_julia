# Cassette.@context SpecCtx

# +(x, y) = 30

# function cassettepost(m::Method, expr::Expr)
#   tv, decls, file, line = arg_decl_parts(m)
#   sig = unwrap_unionall(m.sig)
#   ft0 = sig.parameters[1]
#   ft = unwrap_unionall(ft0)
#   d1 = decls[1]

# end
# Cassette.overdub(::SpecCtx, ::typeof(+), x, y) = 3

struct MethodSpec{TAGS <: Tuple}
  tags::TAGS
  spec::Expr
end

struct SpecTable
  specs::Dict{Method, Vector{MethodSpec}}
end

const spectable = SpecTable(Dict())

function addspec!(m::Method, spec::MethodSpec, st::SpecTable)
  if m in keys(st.specs)
    push!(st.specs[m], spec)
  else
    st.specs[m] = [spec]
  end
end

function addspec!(m::Method, spec::MethodSpec)
  global spectable
  addspec!(m, spec, spectable)
end

function addspec!(f, argtypes)
end

"
@Spec [tags...] [method_specifier] clause_1 [clause_2 ... clause_n] [comment]

Define an invariant that should be true

A spec may access 
- Special meta characters
-- `_res`: The return value
-- `_a1`, `_a2`, `_an`: The value of the 1st, 2nd, nth argument

Tags
- :nocheck - Never check this specification
- :incomplete - Indicates that spec is incomplete

"
macro spec(args...)
end

## Method Specifies

"All methods, globally"
function allmethods() end

"Most recently created method of generic function `func`"
newestmethod(func::Function) = sort(methods(func).ms, by=m->m.min_world)[end]

"Predicate indicates if `prop` of `m` is `c` - m::Method -> m.prop = c"
filtermethod(prop, c) = m -> getfield(m, prop) == c

"Predicate indicates `pred(prop)` of is `true` -  m::Method -> m.prop = c"
filtermethod(prop, pred::Function) = m -> pred(getfield(m, prop))

# Diagnostics

"Methods without specifications"
function checkmissing()
end

"Incomplete specifications"
function checkincomplete()
end