export ConditionBlock, condition

struct ConditionBlock{N, BTT<:AbstractBlock{N}, BTF<:AbstractBlock{N}} <: CompositeBlock{N}
    m::Measure
    block_true::BTT
    block_false::BTF
    function ConditionBlock(m::Measure, block_true::BTT, block_false::BTF) where {N, BTT<:AbstractBlock{N}, BTF<:AbstractBlock{N}}
        new{N, BTT, BTF}(m, block_true, block_false)
    end
end

subblocks(c::ConditionBlock) = (c.m, c.block_true, c.block_false)
chsubblocks(c::ConditionBlock, blocks) = ConditionBlock(blocks...)

function apply!(reg::AbstractRegister{B}, c::ConditionBlock) where B
    if !isdefined(c.m, :results)
        println("Conditioned on a measurement that has not been performed.")
        throw(UndefRefError())
    end
    for i = 1:B
        viewbatch(reg, i) |> (c.m.results[i] == 0 ? c.block_false : c.block_true)
    end
    reg
end

condition(m, a::AbstractBlock{N}, b::Nothing) where N = ConditionBlock(m, a, eyeblock(N))
condition(m, a::Nothing, b::AbstractBlock{N}) where N = ConditionBlock(m, eyeblock(N), b)
mat(c::ConditionBlock) = throw(ArgumentError("ConditionBlock does not has matrix representation, try `mat(c.block_true)` or `mat(c.block_false)`"))

function print_block(io::IO, c::ConditionBlock)
    print(io, "if result(id = $(objectid(c.m)))")
end

function print_subblocks(io::IO, tree::ConditionBlock, depth, charset, active_levels)
    child_active_levels = active_levels

    print_prefix(io, depth+1, charset, active_levels)
    print_tree(
        io, tree.block_true;
        depth=depth+1,
        active_levels=child_active_levels,
        charset=charset,
        roottree=tree,
    )
    print_prefix(io, depth, charset, active_levels)
    println(io, "else")
    print_prefix(io, depth+1, charset, active_levels)
    print_tree(
        io, tree.block_false;
        depth=depth+1,
        active_levels=child_active_levels,
        charset=charset,
        roottree=tree,
    )
    print_prefix(io, depth, charset, active_levels)
    println(io, "end")
end
