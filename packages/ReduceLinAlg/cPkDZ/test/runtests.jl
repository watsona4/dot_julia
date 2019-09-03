using Reduce
using ReduceLinAlg
using Test

# write your own tests here
@test mat_jacobian((:x,),(:x,)) == mat_jacobian([:x],[:x])
@test hessian(:x,(:x,)) == hessian(:x,[:x])
@test jordan_block(:x,1) == jordan_block(Reduce.RExpr("x"),Reduce.RExpr("1")) |> parse
