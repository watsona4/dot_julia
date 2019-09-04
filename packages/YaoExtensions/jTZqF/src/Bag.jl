export Bag, enable_block!, disable_block!, setcontent!, isenabled
"""
    Bag{N}<:TagBlock{AbstractBlock, N}

A bag is a trivil container, but can
    * `setcontent!(bag, content)`
    * `disable_block!(bag)`
    * `enable_block!(bag)`
"""
mutable struct Bag{N}<:TagBlock{AbstractBlock, N}
    content::AbstractBlock{N}
    mask::Bool
end
Bag(b::AbstractBlock) = Bag(b,true)

Yao.content(bag) = bag.content
Yao.chcontent(bag::Bag, content) = Bag(content)
Yao.mat(bag::Bag{N}) where N = bag.mask ? mat(bag.content) : IMatrix{1<<N}()
Yao.apply!(reg::AbstractRegister, bag::Bag) = bag.mask ? apply!(reg, bag.content) : reg
Yao.ishermitian(bag::Bag) = bag.mask ? ishermitian(bag.content) : true
Yao.isreflexive(bag::Bag) = bag.mask ? isreflexive(bag.content) : true
Yao.isunitary(bag::Bag) = bag.mask ? isunitary(bag.content) : true
YaoBlocks.occupied_locs(bag::Bag) = bag.mask ? occupied_locs(bag.content) : ()
setcontent!(bag::Bag, content) = (bag.content = content; bag)
disable_block!(b::Bag) = (b.mask = false; b)
enable_block!(b::Bag) = (b.mask = true; b)
isenabled(b::Bag) = b.mask

function YaoBlocks.print_annotation(io::IO, bag::Bag)
    printstyled(io, isenabled(bag) ? "[⊙] " : "[⊗] "; bold=true, color=isenabled(bag) ? :green : :red)
end

function Base.show(io::IO, ::MIME"plain/text", blk::Bag)
    return print_tree(io, blk; title=false, compact=false)
end
