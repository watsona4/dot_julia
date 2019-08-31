using Test
using BKTrees

@testset "Constructors" begin
        T = Int
        val::T = 1
        vals = T[1,2,3]
        foo(x,y)=abs(x-y)

        node = Node{T}()
        @test node isa Node{T}
        @test node.item == nothing

        node = Node(val) 
        @test node isa Node{T} && node.item==val &&
            isempty(node.children)

        bkt = BKTree{T}()
        @test bkt isa BKTree{T}
        @test bkt.root isa Node{T}
        @test bkt.root.item == nothing

        bkt = BKTree{T}(foo)
        @test bkt isa BKTree{T}
        @test bkt.root isa Node{T}
        @test bkt.root.item == nothing
        @test bkt.f == foo
        @test isempty(bkt.root.children)

        node = Node(val)
        bkt = BKTree(node)
        @test bkt isa BKTree{T}
        @test bkt.root isa Node{T}
        @test bkt.root.item == val
        @test isempty(bkt.root.children)

        bkt = BKTree(val)
        @test bkt isa BKTree{T}
        @test bkt.root isa Node{T}
        @test bkt.root.item == val
        @test isempty(bkt.root.children)
        
        bkt = BKTree(vals)
        @test bkt isa BKTree{T}
        @test bkt.root isa Node{T}
        @test bkt.f == BKTrees.hamming_distance
        @test !isempty(bkt.root.children)
        
        bkt = BKTree(foo, vals)
        @test bkt isa BKTree{T}
        @test bkt.root isa Node{T}
        @test bkt.f == foo
        @test !isempty(bkt.root.children)
end



@testset "add!, find" begin
    bkt = BKTree{Int}()
    for val in [0,1,2,5]
        add!(bkt, val)
    end
    target = 3
    result = find(bkt, target, 10, k=5)
	for (i, (dist, item)) in enumerate(result)
		i==1 && @test dist == 1.0 && item==1
		i==2 && @test dist == 1.0 && item==2
		i==3 && @test dist == 2.0 && item==0
		i==4 && @test dist == 2.0 && item==5
	end
end



# show methods
@testset "Show methods" begin
    buf = IOBuffer()
    T = Int
    try
        node = Node{T}()
        show(buf, node)
        @test true
    catch
        @test false
    end
    try
        tree = BKTree{T}()
        show(buf, tree)
        @test true
    catch
        @test false
    end
end
