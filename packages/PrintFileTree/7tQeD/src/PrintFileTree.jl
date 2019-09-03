module PrintFileTree

export printfiletree

"""
    printfiletree()
    printfiletree(root)

Like the unix utility `tree` (https://linux.die.net/man/1/tree).

Prints complete recursive directory structure of root and all its contents.
"""
function printfiletree(root=".")
    println(root);
    d,f = printfiletree_helper(root)
    println("\n$d directories, $f files")
end
function printfiletree_helper(root, depth=0, opendirs=[true], dirscount=fill(0), filescount=fill(0))
    files = readdir(root)
    for (i,f) in enumerate(files)
        startswith(f, ".") && continue
        lastitem = (i == length(files))
        lastitem && (opendirs[end] = false)
        for p in opendirs[1:end-1]
            print(p ? "│   " : "    ")
        end
        println("$(lastitem ? "└" : "├")── " * f) # path
        path = joinpath(root, f)

        if isdir(path)
            dirscount[] += 1
            push!(opendirs, true)
            printfiletree_helper(path, depth+1, opendirs, dirscount, filescount)
            pop!(opendirs)
        else
            filescount[] += 1
        end
    end
    dirscount[], filescount[]
end

end # module
