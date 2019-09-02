
export doImport, doExport
export copyAndPermute, packAndPrepare, unpackAndCombine, checkSize
export releaseViews, createViews, createViewsNonConst
export getMap
export CombineMode, ADD, INSERT, REPLACE, ABSMAX, ZERO

# Note that all packet size information was removed due to the use of julia's
# built in serialization/objects


"""
Tells JuliaPetra how to combine data received from other processes with existing data on the calling process for specific import or export options.

Here is the list of combine modes:
  * ADD: Sum new values into existing values
  * INSERT: Insert new values that don't currently exist
  * REPLACE: REplace existing values with new values
  * ABSMAX: If ``x_{old}`` is the old value and ``x_{new}`` the incoming new value, replace ``x_{old}`` with ``\\max(x_{old}, x_{new})``
  * ZERO: Replace old values with zero
"""
@enum CombineMode ADD=1 INSERT=2 REPLACE=3 ABSMAX=4 ZERO=5


"""
An interface for providing a source when constructing and using multi-vectors and matrices in parallel.

    getMap(::SrcDistObject)
Gets the map of the indices of the object

See [`DistObject`](@ref)
"""
const SrcDistObject = Any

"""
An interface for providing a target when constructing and using multi-vectors, and matrices in parallel.


To support transfers the following methods must be implemented for the combination of source type and the target type

    getMap(::DistObject)
Gets the map of the indices of the object

    checkSizes(source::<:SrcDistObject{GID, PID, LID}, target::<:DistObject{GID, PID, LID})::Bool
Whether the source and target are compatible for a transfer

    copyAndPermute(source::<:SrcDistObject{GID, PID, LID}, target::<:DistObject{GID, PID, LID}, numSameIDs::LID, permuteToLIDs::AbstractArray{LID, 1}, permuteFromLIDs::AbstractArray{LID, 1})
Perform copies and permutations that are local to this process.

    packAndPrepare(source::<:SrcDistObject{GID, PID, LID}, target::<:DistObjectGID, PID, LID}, exportLIDs::AbstractArray{LID, 1}, distor::Distributor{GID, PID, LID})::AbstractArray
Perform any packing or preparation required for communications.  The
method returns the array of objects to export

    unpackAndCombine(target::<:DistObject{GID, PID, LID}, importLIDs::AbstractArray{LID, 1}, imports::AAbstractrray, distor::Distributor{GID, PID, LID}, cm::CombineMode)
Perform any unpacking and combining after communication

See [`SrcDistObject`](@ref)
"""
const DistObject = Any



"""
Returns true if this object is a distributed global
"""
distributedGlobal(obj) = distributedGlobal(getMap(obj))

getComm(obj) = getComm(getMap(obj))


"""
    getMap(::SrcDistObject)
    getMap(::DistObject)
Gets the map of the indices of the object
"""
function getMap end

## import/export interface ##

"""
    doImport(target, source, importer::Import{GID, PID, LID}, cm::CombineMode)
    doImport(target, source, importer::Union{Import{GID, PID, LID}, Nothing}, cm::CombineMode)

Import data into this object using an Import object ("forward mode").
A null `importer` indicates a trivial import
"""
function doImport(source, target, importer::Import{GID, PID, LID},
        cm::CombineMode) where {GID <:Integer, PID <: Integer, LID <: Integer}
    doTransfer(source, target, cm, numSameIDs(importer), permuteToLIDs(importer),
        permuteFromLIDs(importer), remoteLIDs(importer), exportLIDs(importer),
        distributor(importer), false)
end

function doImport(source, target, importer::Union{Import{GID, PID, LID}, Nothing},
        cm::CombineMode) where {GID <:Integer, PID <: Integer, LID <: Integer}
    if importer != nothing
        doImport(source, target, importer, cm)
    end
end

"""
    doExport(target, source, exporter::Export{GID, PID, LID}, cm::CombineMode)
    doExport(target, source, exporter::Union{Export{GID, PID, LID}, Nothing}, cm::CombineMode)

Export data into this object using an Export object ("forward mode")
A null `exporter` indicates a trivial import
"""
function doExport(source, target,
        exporter::Export{GID, PID, LID}, cm::CombineMode) where {
        GID <:Integer, PID <: Integer, LID <: Integer}
    doTransfer(source, target, cm, numSameIDs(exporter), permuteToLIDs(exporter),
        permuteFromLIDs(exporter), remoteLIDs(exporter), exportLIDs(exporter),
        distributor(exporter), false)
end

function doExport(source, target, exporter::Union{Export{GID, PID, LID}, Nothing},
        cm::CombineMode) where {GID <:Integer, PID <: Integer, LID <: Integer}
    if exporter != nothing
        doImport(source, target, exporter, cm)
    end
end

"""
    doImport(source, target, exporter::Export{GID, PID, LID}, cm::CombineMode)
    doImport(source, target, exporter::Union{Export{GID, PID, LID}, Nothing}, cm::CombineMode)

Import data into this object using an Export object ("reverse mode").
A null `exporter` indicates a trivial import.
"""
function doImport(source, target,
        exporter::Export{GID, PID, LID}, cm::CombineMode) where {
            GID <:Integer, PID <: Integer, LID <: Integer}
    doTransfer(source, target, cm, numSameIDs(exporter), permuteToLIDs(exporter),
        permuteFromLIDs(exporter), remoteLIDs(exporter), exportLIDs(exporter),
        distributor(exporter), true)
end

function doImport(source, target, exporter::Union{Export{GID, PID, LID}, Nothing},
        cm::CombineMode) where {GID <:Integer, PID <: Integer, LID <: Integer}
    if exporter != nothing
        doImport(source, target, exporter, cm)
    end
end

"""
    doExport(source, target, importer::Import{GID, PID, LID}, cm::CombineMode)
    doExport(source, target, importer::Union{Import{GID, PID, LID}, Nothing}, cm::CombineMode)

Export data into this object using an Import object ("reverse mode")
A null `importer` indicates a trivial export.
"""
function doExport(source, target,
        importer::Import{GID, PID, LID}, cm::CombineMode) where {
            GID <:Integer, PID <: Integer, LID <: Integer}
    doTransfer(source, target, cm, numSameIDs(importer), permuteToLIDs(importer),
        permuteFromLIDs(importer), remoteLIDs(importer), exportLIDs(importer),
        distributor(importer), true)
end

function doExport(source, target, importer::Union{Import{GID, PID, LID}, Nothing},
        cm::CombineMode) where {GID <:Integer, PID <: Integer, LID <: Integer}
    if importer != nothing
        doImport(source, target, importer, cm)
    end
end


## import/export functionality ##

"""
    checkSizes(source, target)::Bool

Compare the source and target objects for compatiblity.  By default, returns false.  Override this to allow transfering to/from subtypes
"""
checkSizes(source, target) = false

"""
    copyAndPermute(source::<:SrcDistObject{GID, PID, LID}, target::<:DistObject{GID, PID, LID}, numSameIDs::LID, permuteToLIDs::AbstractArray{LID, 1}, permuteFromLIDs::AbstractArray{LID, 1})
Perform copies and permutations that are local to this process.
"""
function copyAndPermute end

"""
    packAndPrepare(source::<:SrcDistObject{GID, PID, LID}, target::<:DistObjectGID, PID, LID}, exportLIDs::AbstractArray{LID, 1}, distor::Distributor{GID, PID, LID})::AbstractArray
Perform any packing or preparation required for communications.  The
method returns the array of objects to export
"""
function packAndPrepare end

"""
    unpackAndCombine(target::<:DistObject{GID, PID, LID}, importLIDs::AbstractArray{LID, 1}, imports::AAbstractrray, distor::Distributor{GID, PID, LID}, cm::CombineMode)
Perform any unpacking and combining after communication
"""
function unpackAndCombine end

"""
    doTransfer(src, target, cm::CombineMode, numSameIDs::LID, permuteToLIDs::AbstractArray{LID, 1}, permuteFromLIDs::AbstractArray{LID, 1}, remoteLIDs::AbstractArray{LID, 1}, exportLIDs::AbstractArray{LID, 1}, distor::Distributor{GID, PID, LID}, reversed::Bool)

Perform actual redistribution of data across memory images
"""
function doTransfer(source, target, cm::CombineMode,
        numSameIDs::LID, permuteToLIDs::AbstractArray{LID, 1},
        permuteFromLIDs::AbstractArray{LID, 1}, remoteLIDs::AbstractArray{LID, 1},
        exportLIDs::AbstractArray{LID, 1}, distor::Distributor{GID, PID, LID},
        reversed::Bool) where {GID <: Integer, PID <: Integer, LID <: Integer}

    if !checkSizes(source, target)
        throw(InvalidArgumentError("checkSize() indicates that the destination " *
                "object is not a legal target for redistribution from the " *
                "source object.  This probably means that they do not have " *
                "the same dimensions.  For example, MultiVectors must have " *
                "the same number of rows and columns."))
    end

    readAlso = true #from TPetras rwo
    if cm == INSERT || cm == REPLACE
        numIDsToWrite = numSameIDs + length(permuteToLIDs) + length(remoteLIDs)
        if numIDsToWrite == numMyElements(getMap(target))
            # overwriting all local data in the destination, so write-only suffices

            #TODO look at FIXME on line 503
            readAlso = false
        end
    end

    #TODO look at FIXME on line 514
    createViews(source)

    #tell target to create a view of its data
    #TODO look at FIXME on line 531
    createViewsNonConst(target, readAlso)

    if numSameIDs + length(permuteToLIDs) != 0
        copyAndPermute(source, target, numSameIDs, permuteToLIDs, permuteFromLIDs)
    end

    # only need to pack & send comm buffers if combine mode is not ZERO
    # ZERO combine mode indicates results are the same as if all zeros were recieved
    if cm != ZERO
        exports = packAndPrepare(source, target, exportLIDs, distor)

        if ((reversed && distributedGlobal(target))
                || (!reversed && distributedGlobal(source)))
            if reversed
                #do exchange of remote data
                imports = resolveReverse(distor, exports)
            else
                imports = resolve(distor, exports)
            end

            unpackAndCombine(target, remoteLIDs, imports, distor, cm)
        end
    end

    releaseViews(source)
    releaseViews(target)

    nothing
end

"""
    createViews(obj)

doTransfer calls this on the source object.  By default it does nothing, but the source object can use this as a hint to fetch data from a compute buffer on an off-CPU decice (such as GPU) into host memory
"""
function createViews(obj)
end

"""
    createViewsNonConst(obj, readAlso::Bool)

doTransfer calls this on the target object.  By default it does nothing, but the target object can use this as a hint to fetch data from a compute buffer on an off-CPU decice (such as GPU) into host memory
readAlso indicates whether the doTransfer might read from the original buffer
"""
function createViewsNonConst(obj, readAlso::Bool)
end


"""
    releaseViews(obj)

doTransfer calls this on the target and source as it completes to allow any releasing of buffers or views.  By default it does nothing
"""
function releaseViews(obj)
end
