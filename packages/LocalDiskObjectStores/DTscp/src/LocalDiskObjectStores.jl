module LocalDiskObjectStores

export LocalDiskObjectStore

using Reexport
@reexport using ObjectStores


################################################################################
# Types

struct LocalDiskObjectStore <: ObjectStore
    id::String;
    id2permission::Dict{String, Permission};        # Resource ID => Permission
    idpattern2permission::Dict{Regex, Permission};  # Resource ID pattern => Permission
    type2permission::Dict{DataType, Permission};    # Resource type => Permission
    rootbucketID::String  # ID of root bucket

    function LocalDiskObjectStore(id, id2permission, idpattern2permission, type2permission, rootbucketID)
        newstore = new(id, id2permission, idpattern2permission, type2permission, rootbucketID)
        _isobject(newstore, rootbucketID) && error("Root already exists as an object. Cannot use it as a bucket.")
        if !_isbucket(newstore, rootbucketID)  # Root does not exist...create it
            msg = createbucket!(newstore)      # One arg implies bucketname is root
            msg != nothing && @warn msg        # Couldn't create root bucket...warn
        end
        newstore
    end
end


function LocalDiskObjectStore(rootbucketID::String)
    id = ""
    id2permission        = Dict{String, Permission}()
    idpattern2permission = Dict{Regex,  Permission}()
    type2permission      = Dict{DataType, Permission}()
    LocalDiskObjectStore(id, id2permission, idpattern2permission, type2permission, rootbucketID)
end


################################################################################
# Buckets

"Create bucket. If successful return nothing, else return an error message as a String."
function _create!(client::LocalDiskObjectStore, bucket::Bucket)
    _isbucket(client, bucket.id) && return "Bucket already exists. Cannot create it again."
    cb, bktname = splitdir(bucket.id)
    !_isbucket(client, cb) && return "Cannot create bucket within a non-existent bucket."
    try
        mkdir(bucket.id)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


"Read bucket. If successful return (true, value), else return (false, errormessage::String)."
function _read(client::LocalDiskObjectStore, bucket::Bucket)
    _isobject(client, bucket.id)  && return (false, "Bucket ID refers to an object")
    !_isbucket(client, bucket.id) && return (false, "Bucket doesn't exist")
    try
        return (true, readdir(bucket.id))
    catch e
        return (false, e.prefix)  # Assumes e is a SystemError
    end
end


"Delete bucket. If successful return nothing, else return an error message as a String."
function _delete!(client::LocalDiskObjectStore, bucket::Bucket)
    ok, contents = _read(client, bucket)
    contents == nothing && return "Resource is not a bucket. Cannot delete it with this function."
    !isempty(contents)  && return "Bucket is not empty. Cannot delete it."
    try
        rm(bucket.id)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


################################################################################
# Objects

"Create object. If successful return nothing, else return an error message as a String."
function _create!(client::LocalDiskObjectStore, object::Object, v)
    try
        resourceid = object.id
        _isbucket(client, resourceid) && return "$(resourceid) is a bucket, not an object"
        cb, shortname = splitdir(resourceid)
        !_isbucket(client, cb) && return "Cannot create object $(resourceid) inside a non-existent bucket."
        write(object.id, v)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


"Read object. If successful return (true, value), else return (false, errormessage::String)."
function _read(client::LocalDiskObjectStore, object::Object)
    !_isobject(client, object.id) && return (false, "Object ID does not refer to an existing object")
    try
        true, read(object.id)
    catch e
        return false, e.prefix  # Assumes e is a SystemError
    end
end


"Delete object. If successful return nothing, else return an error message as a String."
function _delete!(client::LocalDiskObjectStore, object::Object)
    !_isobject(client, object.id) && return "Object ID does not refer to an existing object. Cannot delete a non-existent object."
    try
        rm(object.id)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


################################################################################
# Conveniences

_isbucket(client::LocalDiskObjectStore, resourceid::String) = isdir(resourceid)

_isobject(client::LocalDiskObjectStore, resourceid::String) = isfile(resourceid)

end
