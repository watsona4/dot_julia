include("codec.jl")

using MsgPack
using CodecZlib

export decodedata,encodedata,parsemmtf,writemmtf,fetchmmtf

"""
Decodes the MsgPack unpacked dict of the MMTF file.
"""
function decodedata(input_data::Dict)
    # Initialize optional field's default values
    dict = Dict(
        "bFactorList" => Array{Float32,1}[],
        "occupancyList" => Array{Float32,1}[],
        "atomIdList" => Array{Int32,1}[],
        "altLocList" => Array{Char,1}[],
        "insCodeList" => Array{Char,1}[],
        "sequenceIndexList" => Array{Int32,1}[],
        "chainNameList" => Array{String,1}[],
        "spaceGroup" => "",
        "bondAtomList" => Array{Int32,1}[],
        "bondOrderList" => Array{Int8,1}[],
        "mmtfVersion" => "",
        "mmtfProducer" => "",
        "structureId" => "",
        "title" => "",
        "experimentalMethods" => Array{Any,1}[],
        "depositionDate" => "",
        "releaseDate" => "",
        "entityList" => Array{Any,1}[],
        "bioAssemblyList" => Array{Any,1}[],
        "rFree" => "",
        "rWork" => "",
        "resolution" => "",
        "unitCell" => Array{Any,1}[],
        "secStructList" => Array{Int8,1}[],
        "ncsOperatorList" => Array{Any,1}[]
    )
    # Check if all mandatory fields are present in the input data.
    mandateFields = ["groupTypeList","xCoordList","yCoordList","zCoordList","groupIdList","groupList","chainsPerModel","groupsPerChain","chainIdList","numBonds","numChains","numModels","numAtoms","numGroups"]
    for field in mandateFields
        if !haskey(input_data, field)
            throw(ArgumentError("Mandatory field \"$field\" not available in input data!"))
        end    
    end
    # decode the necessary fields alone
    toDecodeFields = ["groupTypeList","xCoordList","yCoordList","zCoordList","bFactorList","occupancyList","atomIdList","altLocList","insCodeList","groupIdList","sequenceIndexList","chainNameList","chainIdList","bondAtomList","bondOrderList","secStructList"]
    for (key,value) in input_data
        if key in toDecodeFields
            dict[key] = decodearray(value)
        else    
            dict[key] = value
        end
    end
    # return the final dict
    return dict
end

"""
Encodes the MMTF Dict.
"""
function encodedata(MMTFDict::Dict)
    encodedMMTFDict = Dict()
    encodedMMTFDict["groupTypeList"] = encodearray(MMTFDict["groupTypeList"], 4, 0)
    encodedMMTFDict["xCoordList"] = encodearray(MMTFDict["xCoordList"], 10, COORD_DIVIDER)
    encodedMMTFDict["yCoordList"] = encodearray(MMTFDict["yCoordList"], 10, COORD_DIVIDER)
    encodedMMTFDict["zCoordList"] = encodearray(MMTFDict["zCoordList"], 10, COORD_DIVIDER)
    encodedMMTFDict["bFactorList"] = encodearray(MMTFDict["bFactorList"], 10, OCC_B_FACTOR_DIVIDER)
    encodedMMTFDict["occupancyList"] = encodearray(MMTFDict["occupancyList"], 9, OCC_B_FACTOR_DIVIDER)
    encodedMMTFDict["atomIdList"] = encodearray(MMTFDict["atomIdList"], 8, 0)
    encodedMMTFDict["altLocList"] = encodearray(MMTFDict["altLocList"], 6, 0)
    encodedMMTFDict["insCodeList"] = encodearray(MMTFDict["insCodeList"], 6, 0)
    encodedMMTFDict["groupIdList"] = encodearray(MMTFDict["groupIdList"], 8, 0)
    encodedMMTFDict["sequenceIndexList"] = encodearray(MMTFDict["sequenceIndexList"], 8, 0)
    encodedMMTFDict["chainNameList"] = encodearray(MMTFDict["chainNameList"], 5, 4)
    encodedMMTFDict["chainIdList"] = encodearray(MMTFDict["chainIdList"], 5, 4)
    encodedMMTFDict["bondAtomList"] = encodearray(MMTFDict["bondAtomList"], 4, 0)
    encodedMMTFDict["bondOrderList"] = encodearray(MMTFDict["bondOrderList"], 2, 0)
    encodedMMTFDict["secStructList"] = encodearray(MMTFDict["secStructList"], 2, 0)
    encodedMMTFDict["groupList"] = MMTFDict["groupList"]
    encodedMMTFDict["chainsPerModel"] = MMTFDict["chainsPerModel"]
    encodedMMTFDict["groupsPerChain"] = MMTFDict["groupsPerChain"]
    encodedMMTFDict["spaceGroup"] = MMTFDict["spaceGroup"]
    encodedMMTFDict["mmtfVersion"] = MMTFDict["mmtfVersion"]
    encodedMMTFDict["mmtfProducer"] = MMTFDict["mmtfProducer"]
    encodedMMTFDict["structureId"] = MMTFDict["structureId"]
    encodedMMTFDict["entityList"] = MMTFDict["entityList"]
    encodedMMTFDict["bioAssemblyList"] = MMTFDict["bioAssemblyList"]
    encodedMMTFDict["rFree"] = MMTFDict["rFree"]
    encodedMMTFDict["rWork"] = MMTFDict["rWork"]
    encodedMMTFDict["resolution"] = MMTFDict["resolution"]
    encodedMMTFDict["title"] = MMTFDict["title"]
    encodedMMTFDict["experimentalMethods"] = MMTFDict["experimentalMethods"]
    encodedMMTFDict["depositionDate"] = MMTFDict["depositionDate"]
    encodedMMTFDict["releaseDate"] = MMTFDict["releaseDate"]
    encodedMMTFDict["unitCell"] = MMTFDict["unitCell"]
    encodedMMTFDict["numBonds"] = MMTFDict["numBonds"]
    encodedMMTFDict["numChains"] = MMTFDict["numChains"]
    encodedMMTFDict["numModels"] = MMTFDict["numModels"]
    encodedMMTFDict["numAtoms"] = MMTFDict["numAtoms"]
    encodedMMTFDict["numGroups"] = MMTFDict["numGroups"]
    encodedMMTFDict["ncsOperatorList"] = MMTFDict["ncsOperatorList"]
    return encodedMMTFDict
end

"""
Parses the MMTF file into a MMTFDict.
filepath: Path of the input file.
"""
function parsemmtf(filepath::AbstractString; gzip::Bool=false)
    return open(filepath) do input
        parsemmtf(input,gzip=gzip)
    end
end

function parsemmtf(input::IO; gzip::Bool=false)
    if gzip
        decompressed = IOBuffer()
        write(decompressed, GzipDecompressorStream(input))
        decodedata(unpack(take!(decompressed)))
    else
        decodedata(unpack(input))
    end
end

"""
Writes the MMTFDict back to a file.
MMTFDict: Dict containing the decoded MMTF data to be written to file.
filepath: Path to write the file
"""
function writemmtf(MMTFDict::Dict, filepath::AbstractString; gzip::Bool=false)
    open(filepath, "w") do output
        writemmtf(MMTFDict,output,gzip=gzip)
    end
end

function writemmtf(MMTFDict::Dict, output::IO; gzip::Bool=false)
    if gzip
        stream=IOBuffer(pack(encodedata(MMTFDict)))
        write(output,GzipCompressorStream(stream))
    else
        pack(output,encodedata(MMTFDict))
    end
end

"""
Fetches a file from RCSB server and decodes it into a MMTFDict.
pdbid: ID of the PDB file to be fetched and decoded.
"""
function fetchmmtf(pdbid)
    tempfile = tempname()
    download("$(BASE_URL)/$(pdbid).mmtf.gz",tempfile)
    parsemmtf(tempfile,gzip=true)
end