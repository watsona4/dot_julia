using Test
using MetaArrays
using StaticArrays
using AxisArrays
using Unitful

struct TestMerge
  val::Int
end
MetaArrays.metamerge(x::TestMerge,y::TestMerge) = TestMerge(x.val + y.val)

struct TestIndex <: AbstractArray{Float64,1}
  x::Vector{Float64}
end
Base.similar(val::TestIndex,::Type{S},dims::NTuple{<:Any,Int}) where S =
  TestIndex{typeof(val.x),eltype(val),ndims(val)}(similar(val.x))
Base.size(val::TestIndex) = size(val.x)
Base.getindex(val::TestIndex,i::Int...) = getindex(val.x,i...)
# not realy a useful function, just a test:
Base.getindex(val::TestIndex,i::Float64) = val[floor(Int,i)] + val[ceil(Int,i)]

struct TestMergeFail
  val::Int
end

struct TestArray{A,T,N} <: AbstractArray{T,N}
  val::A
end
Base.similar(val::TestArray,::Type{S},dims::NTuple{<:Any,Int}) where S =
  TestArray{typeof(val.val),eltype(val),ndims(val)}(similar(val.val))
Base.size(val::TestArray) = size(val.val)
Base.getindex(val::TestArray,i::Int...) = getindex(val.val,i...)
Base.setindex!(val::TestArray,v,i::Int...) = setindex!(val.val,v,i...)

testunion(x::MetaUnion{AbstractRange}) = :range
testunion(x) = :notrange

# TODO: add some more robust tests of broadcast machinery
# (greater variety of arguments, with more call variants
# and then check for test coverage

@testset "MetaArrays" begin

  @testset "MetaArray handles standard array operations" begin
    data = collect(1:10)
    x = meta(data,val=1)
    y = meta(collect(1:10),val=1)

    @test (x.^2) == (1:10).^2
    @test x[1] == data[1]
    @test size(x) == size(data)
    @test similar(x) isa MetaArray
    @test x[1:5] == data[1:5]
    @test (y[1:5] .= 1; sum(y[1:5]) == 5)
    @test (y[1] = 2; y[1] == 2)
    @test x .+ (1:10) == data .+ (1:10)
    @test (.-x) isa MetaArray
    @test collect(1:10) .+ x .+ collect(11:20) == (13:3:40)
    @test broadcast(+,collect(1:10),x,collect(11:20)) == (13:3:40)
    @test (1:10) .+ meta(1:10,val=1) .+ (11:20) isa MetaArray
    @test view(x,1:2) isa MetaArray

    x = TestIndex(collect(1:5))
    @test x[1] == 1
    @test x[1.5] == 3
  end

  @testset "MetaArray preserves metadata over array operations" begin
    data = collect(1:10)
    x = meta(data,val=1)

    @test x.val == 1
    @test x[1:5].val == x.val
    @test x[:].val == x.val
    @test (x .+ (1:10)).val == x.val
    @test (x .+= (1:10); x.val == 1)
    @test (broadcast(+,x,1:10).val == x.val)
    @test similar(x).val == x.val
    @test (.-x).val == 1

    x = meta(collect(1:10),val=1)
    y = meta(collect(1:10),val=1)
    @test vcat(x,y) isa MetaArray
    @test hcat(x,y) isa MetaArray
    @test x*y' isa MetaArray

    x = collect(1:10)
    y = meta(collect(1:10),val=1)
    @test hcat(x,y) isa Array
    @test hcat(y,x) isa MetaArray
    @test vcat(x,y) isa Array
    @test vcat(y,x) isa MetaArray
    @test x*y' isa Array
    @test y*x' isa MetaArray
  end

  @testset "MetaArray properly handles strides" begin
    @test_throws MethodError strides(meta(1:10,val=1))
    x = meta(collect(1:10),val=1)
    @test strides(x) == (1,)
    @test strides(x)[1] == stride(x,1)
  end

  @testset "MetaUnion dispatches properly" begin
    @test testunion(1:5) == :range
    @test testunion(meta(1:10,val=1)) == :range
    @test testunion(meta(collect(1:10),val=1)) == :notrange
  end

  @testset "MetaArray properly merges metadata" begin
    x = meta(collect(1:10),val=1)
    y = meta(collect(2:11),string="string")
    @test (x.+y).val == 1
    @test (x.+y).string == "string"
    @test (x .+ (1:10)).val == 1
    @test ((1:10) .+ x).val == 1

    x = MetaArray(Dict(:test => "value"),collect(1:10))
    y = MetaArray(Dict(:test => "value"),collect(2:11))
    @test getmeta((x .+ y))[:test] == "value"


    x = meta(collect(1:10),val=1)
    y = meta(collect(1:10),val=2)
    @test_throws ErrorException x.+y

    x = meta(collect(1:10),val=TestMerge(1))
    y = meta(collect(1:10),val=TestMerge(2))
    @test (x.+y).val == TestMerge(3)
    @test broadcast(+,x,y).val == TestMerge(3)

    x = meta(collect(1:10),val=(joe=2,bob=3))
    y = meta(collect(1:10),val=(bill=4,))
    @test (x.+y).val == (joe=2,bob=3,bill=4)
  end

  f(x) = (x[0u"s" .. 0.5u"s"] .= 0)

  @testset "MetaArray is AxisArray friendly" begin
    x = meta(AxisArray(rand(10,10),Axis{:time}(range(0u"s",1u"s",length=10)),
      Axis{:freq}(1:10)),val=1)
    x[0u"s" .. 0.5u"s"] = fill(0.0,size(x[0u"s" .. 0.5u"s"]))
    @test all(x[1:5] .== 0)
    x[0u"s" .. 0.5u"s"] .= 1
    @test all(x[1:5] .== 1)

    @test axisdim(x,Axis{:time}) == 1
    @test AxisArray(x) isa AxisArray
    @test AxisArrays.axes(x)[1] isa Axis{:time}
    @test AxisArrays.axes(x,1) isa Axis{:time}
    @test AxisArrays.axes(x,Axis{:time}) isa Axis{:time}
    @test axisnames(x) == (:time,:freq)
    @test axisvalues(x)[2] == 1:10
    @test size(similar(x)) == size(x)
  end

  @testset "MetaArray preserves broadcast specialization" begin
    # Range objects define a specialized lazy broadcasting style,
    # we use them to test the presevation of this lazy style
    x = meta(1:10,val=1)
    @test (x .+ 4) isa MetaArray{<:AbstractRange}
    @test (x .+ 4) == [xi+4 for xi in x]
    @test (.-x) isa MetaArray{<:AbstractRange}
    @test (1:10) .+ meta(1:10,val=1) .+ (11:20) isa MetaArray{<:AbstractRange}
    @test .-x == [-xi for xi in x]

    # SVector defines a specialized style for broadcasting, we use it to test
    # the handling of specialized broadcasting styles
    x = meta(SVector(1,2,3),val=1)
    y = meta([1,2,3],val=1)
    @test x.+y == [2,4,6]
    @test (x.+y).val == 1

    x = meta(collect(1:10),val=1)
    y = SVector((1:10)...)
    @test (x .+ y).val == 1
    @test (y .+ x).val == 1

    y = meta(y,val=1)
    x = collect(1:10)
    @test (x .+ y).val == 1
    @test (y .+ x).val == 1
  end

  @testset "MetaArray allows custom metadata type" begin
    x = MetaArray(TestMerge(2),1:10)
    y = MetaArray(TestMerge(3),1:10)
    k = MetaArray(TestMergeFail(1),1:10)
    h = MetaArray(TestMergeFail(1),1:10)
    m = MetaArray(TestMergeFail(2),1:10)

    z = x.+y
    @test x == 1:10
    @test (x.+y) == ((1:10) .+ (1:10))
    @test (x.+y).val == 5
    @test (h.+k).val == 1
    @test_throws ErrorException h.+m
  end

  @testset "Can extract metadata and underlying array" begin
    x = meta(1:10,val=1)

    @test convert(Array,x) isa Array
    @test getcontents(x) isa AbstractRange
    @test getmeta(x).val == 1
    @test getmeta(x) isa NamedTuple
  end

  @testset "Appropriate conversion" begin
    x = meta(1:10,val=1)

    @test convert(AbstractArray{Int},x) === x
    @test convert(AbstractArray{Int,1},x) === x
    @test_throws MethodError convert(AbstractArray{String},x)
    @test_throws MethodError convert(AbstractArray{Int,2},x)
    @test Array(x) == Array(1:10)

    xplus = MetaArray((test=2,),x)
    @test getcontents(xplus) == getcontents(x)
    @test xplus.val == 1
    @test xplus.test == 2

    xplus = meta(x,test=2)
    @test getcontents(xplus) == getcontents(x)
    @test xplus.val == 1
    @test xplus.test == 2
  end

  @testset "Preoper MetaArray display" begin
    expected = "MetaArray of 1:10"
    x = meta(1:10,val=1)
    iobuf = IOBuffer()
    display(TextDisplay(iobuf), x)
    @test String(take!(iobuf)) == expected
  end

  @testset "Conversion to AbstractArray passes through" begin
    x = meta(collect(1:10),val=1)
    @test convert(AbstractArray{Int},x) === x
    @test convert(AbstractArray{Int,1},x) === x
  end

  @testset "Can compute identity of underlying array" begin
    x = meta(TestArray{Array,Int,1}(collect(1:5)),val=1)
    @test similar(x) isa MetaArray{<:TestArray}
    @test zero(x) isa MetaArray{<:TestArray}
    @test one(x) isa MetaArray{<:TestArray}
    @test all(zero(x) .== 0)
    @test all(one(x) .== 1)
  end
end
