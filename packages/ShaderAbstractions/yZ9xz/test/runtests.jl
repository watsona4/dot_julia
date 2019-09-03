using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray
using Test, GeometryTypes
import GeometryBasics

struct WebGL <: ShaderAbstractions.AbstractContext end

m = GLNormalMesh(Sphere(Point3f0(0), 1f0))

mvao = VertexArray(m)
instances = VertexArray(positions = rand(GeometryBasics.Point{3, Float32}, 100))

x = ShaderAbstractions.InstancedProgram(
    WebGL(),
    "void main(){}\n", "void main(){}\n",
    mvao,
    instances,
    model = Mat4f0(I),
    view = Mat4f0(I),
    projection = Mat4f0(I),
)

@test x.program.fragment_source == read(joinpath(@__DIR__, "test.frag"), String)
@test x.program.vertex_source == read(joinpath(@__DIR__, "test.vert"), String)
