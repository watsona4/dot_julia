using DetectionTheory

fToProcess = ["DetectionTheory.jl"]
for fNameb in fToProcess
    fIn = open(string("../src/", fNameb), "r")
    fOut = open(string("test_", fNameb), "w")
    lns = readlines(fIn)
    idxStart = (Int)[]
    idxStop = (Int)[]
    for i=1:length(lns)
        if lns[i] == "```julia"
            push!(idxStart, i+1)
        elseif lns[i] == "```"
            push!(idxStop, i-1)
        end
    end
    for i=1:length(idxStart)
        for j=idxStart[i]:idxStop[i]
            write(fOut, lns[j]*"\n")
        end
    end
    close(fIn); close(fOut)
end

for fName2 in fToProcess
    fNameTest = string("test_", fName2)
    include(fNameTest)
end

