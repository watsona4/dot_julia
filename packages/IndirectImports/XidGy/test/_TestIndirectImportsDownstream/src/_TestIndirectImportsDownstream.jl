module _TestIndirectImportsDownstream

using IndirectImports

@indirect import _TestIndirectImportsUpstream
@indirect _TestIndirectImportsUpstream.fun(x) = x + 1

dispatch(::typeof(_TestIndirectImportsUpstream.fun)) = :fun
dispatch(::typeof(_TestIndirectImportsUpstream.fun2)) = :fun2

# Test other importing syntax:
@indirect import _TestIndirectImportsUpstream: f1
@indirect import _TestIndirectImportsUpstream: f2, f3
@indirect import _TestIndirectImportsUpstream: f4, f5, f6

struct Config1 end
struct Config2 end

@indirect _TestIndirectImportsUpstream.op(::Config1, x, y) = x + y
@indirect _TestIndirectImportsUpstream.op(::Config2, x, y) = x - y

end # module
