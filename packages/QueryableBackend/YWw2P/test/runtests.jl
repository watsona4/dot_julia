using QueryableBackend
import QueryOperators
import IteratorInterfaceExtensions
using Query
using Test

struct ExampleSource
end

function QueryOperators.query(x::ExampleSource)
    return QueryableBackend.QueryableSource() do querytree
        return [(a=1, b=1), (a=2, b=2)]
    end
end

@testset "QueryableBackend" begin

source = ExampleSource()

r = source |> @filter(_.a>3) |> @map(_.a) |> 
    IteratorInterfaceExtensions.getiterator |> collect

@test r == [(a=1, b=1), (a=2, b=2)]

end
