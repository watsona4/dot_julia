using VegaLite
using JSON
using Test

@testset "macro" begin

spec = vl"""
{
  "data": {
    "values": [
      {"a": "A","b": 28}, {"a": "B","b": 55}
    ]
  },
  "mark": "bar",
  "encoding": {
    "x": {"field": "a", "type": "ordinal"},
    "y": {"field": "b", "type": "quantitative"}
  }
}
"""

@test isa(spec, VegaLite.VLSpec)
@test spec.params == JSON.parse("""
{
  "data": {
    "values": [
      {"a": "A","b": 28}, {"a": "B","b": 55}
    ]
  },
  "mark": "bar",
  "encoding": {
    "x": {"field": "a", "type": "ordinal"},
    "y": {"field": "b", "type": "quantitative"}
  }
}
""")

end
