module ObjectStores

export ObjectStore, Bucket, Object,                # Types
       createbucket!, listcontents, deletebucket!, # Buckets: create, read, delete
       setindex!, getindex, delete!,               # Objects: create, read, delete
       isbucket, isobject,                         # Conveniences
       Permission,                                 # Re-exported from Authorization
       getpermission, setpermission!, setexpiry!,  # Re-exported from Authorization
       haspermission, permissions_conflict         # Re-exported from Authorization


using Authorization
using Logging


# Methods that are extended in this package
import Base.setindex!, Base.getindex, Base.delete!
import Authorization.setpermission!


################################################################################
# Types 

"""
Required fields:
- id::String;                                     # From Authorization.AbstractClient
- id2permission::Dict{String, Permission};        # Resource ID => Permission (from Authorization.AbstractClient)
- idpattern2permission::Dict{Regex, Permission};  # Resource ID pattern => Permission (from Authorization.AbstractClient)
- type2permission::Dict{DataType, Permission};    # Resource type => Permission (from Authorization.AbstractClient)
- rootbucketID::String  # ID of root bucket       # Specific to ObjectStores
"""
abstract type ObjectStore <: AbstractClient end

struct Bucket <: AbstractResource
    id::String
end

struct Object <: AbstractResource
    id::String
end


################################################################################
# Buckets

"Create bucket. If successful return nothing, else return an error message as a String."
function createbucket!(store::ObjectStore, bucketname::String="")
    if bucketname == ""
        resourceid = store.rootbucketID
    else
        resourceid = normpath(joinpath(store.rootbucketID, bucketname))
        n = length(store.rootbucketID)
        (length(resourceid) < n || resourceid[1:n] != store.rootbucketID) && return "Cannot create a bucket outside the root bucket"
    end
    create!(store, Bucket(resourceid))
end


"List the contents of the bucket. If successful return the value, else @warn the error message and return nothing."
function listcontents(store::ObjectStore, bucketname::String="")
    if bucketname == ""
        resourceid = store.rootbucketID
    else
        resourceid = normpath(joinpath(store.rootbucketID, bucketname))
        n = length(store.rootbucketID)
        if length(resourceid) < n || resourceid[1:n] != store.rootbucketID
            @warn "Cannot read a bucket outside the root bucket"
            nothing
        end
    end
    ok, val = read(store, Bucket(resourceid))
    if !ok
        @warn val
        return nothing
    end
    val
end


"Delete bucket. If successful return nothing, else return an error message as a String."
function deletebucket!(store::ObjectStore, bucketname::String="")
    if bucketname == ""
        resourceid = store.rootbucketID
    else
        resourceid = normpath(joinpath(store.rootbucketID, bucketname))
        n = length(store.rootbucketID)
        (length(resourceid) < n || resourceid[1:n] != store.rootbucketID) && return "Cannot delete a bucket outside the root bucket"
    end
    delete!(store, Bucket(resourceid))
end


################################################################################
# Objects

"Create/update object. If successful return nothing, else return an error message as a String."
function setindex!(store::ObjectStore, v, i::String)
    resourceid = normpath(joinpath(store.rootbucketID, i))
    n = length(store.rootbucketID)
    (length(resourceid) < n || resourceid[1:n] != store.rootbucketID) && return "Cannot create/update an object outside the root bucket"
    create!(store, Object(resourceid), v)
end


"Read object. If successful return the value, else @warn the error message and return nothing."
function getindex(store::ObjectStore, i::String)
    resourceid = normpath(joinpath(store.rootbucketID, i))
    n = length(store.rootbucketID)
    if length(resourceid) < n || resourceid[1:n] != store.rootbucketID
        @warn "Cannot read an object outside the root bucket"
        return nothing
    end
    ok, val = read(store, Object(resourceid))
    if !ok
        @warn val
        return nothing
    end
    val
end


"Delete object. If successful return nothing, else return an error message as a String."
function delete!(store::ObjectStore, i::String)
    resourceid = normpath(joinpath(store.rootbucketID, i))
    n = length(store.rootbucketID)
    (length(resourceid) < n || resourceid[1:n] != store.rootbucketID) && return "Cannot delete an object outside the root bucket"
    delete!(store, Object(resourceid))
end


################################################################################
# Conveniences

"Returns true if name refers to a bucket."
function isbucket(store::ObjectStore, name::String)
    resourceid = normpath(joinpath(store.rootbucketID, name))
    n = length(store.rootbucketID)
    if length(resourceid) < n || resourceid[1:n] != store.rootbucketID
        @warn "Cannot access buckets or objects outside the root bucket"
        false
    else
        m = parentmodule(typeof(store))
        m._isbucket(store, resourceid)
    end
end

"Returns true if name refers to an object."
function isobject(store::ObjectStore, name::String)
    resourceid = normpath(joinpath(store.rootbucketID, name))
    n = length(store.rootbucketID)
    if length(resourceid) < n || resourceid[1:n] != store.rootbucketID
        @warn "Cannot access buckets or objects outside the root bucket"
        false
    else
        m = parentmodule(typeof(store))
        m._isobject(store, resourceid)
    end
end

function setpermission!(store::ObjectStore, resourcetype::Symbol, p::Permission)
    resourcetype == :bucket && return setpermission!(store, Bucket, p)
    resourcetype == :object && return setpermission!(store, Object, p)
    @warn "Resource type unknown. Permission not set."
end


end
