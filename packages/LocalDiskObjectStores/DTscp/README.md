# LocalDiskObjectStores 

This package defines an [ObjectStore](https://github.com/JockLawrie/ObjectStores.jl) that uses the local file system as the storage back-end.

[![Build Status](https://travis-ci.org/JuliaIO/LocalDiskObjectStores.jl.svg)](https://travis-ci.org/JuliaIO/LocalDiskObjectStores.jl)
[![codecov.io](http://codecov.io/github/JuliaIO/LocalDiskObjectStores.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaIO/LocalDiskObjectStores.jl?branch=master)


## Usage

### Example 1: Bucket store with read-only permission

```julia
using Dates
using LocalDiskObjectStores

# Create store
store = LocalDiskObjectStore("/tmp/rootbucket")    # Root bucket is /tmp/rootbucket
listcontents(store)  # Returns nothing. Store doesn't have read permission
setpermission!(store, :bucket, Permission(false, true, false, false))  # cRud (read-only) permission for all buckets within the root bucket
setpermission!(store, :object, Permission(false, true, false, false))  # cRud (read-only) permission for all objects within the root bucket

# Root bucket
listcontents(store)      # Root bucket doesn't yet exist
createbucket!(store)     # Failed (returns error msg) because store has no create permission
isbucket(store, "")      # Root bucket still doesn't exist
mkdir("/tmp/rootbucket")
isbucket(store, "")      # Root bucket now exists
listcontents(store)      # Root bucket is empty

# Bucket root/xxx
listcontents(store, "xxx")
createbucket!(store, "xxx")
mkdir("/tmp/rootbucket/xxx")
isbucket(store, "xxx")        # Bucket now exists
isobject(store, "xxx")        # "xxx" is a bucket not an object

# Object root/xxx/myobject
store["xxx/myobject"] = "My first object"  # No-op, store doesn't have create permission
isobject(store, "xxx/myobject")            # "xxx/myobject" doesn't exist

# Add temporary create permission for objects in bucket root/xxx
setpermission!(store, r"^/tmp/rootbucket/xxx/.+", Permission(true, true, true, true, now() + Second(5)))
store["xxx/myobject"] = "My object"
isobject(store, "xxx/myobject")        # "xxx/myobject" now exists
String(store["xxx/myobject"])
store["xxx/myobject"] = "Some new value"
String(store["xxx/myobject"])
delete!(store, "xxx/myobject")
isobject(store, "xxx/myobject")        # "xxx/myobject" no longer exists
createbucket!(store, "zzz")            # Failed (returns error msg) because store has no create permission for other buckets/objects

sleep(5)                                   # Sleep until permission expires
store["xxx/myobject"] = "My first object"  # No-op, store no longer has create permission
isobject(store, "xxx/myobject")            # "xxx/myobject" doesn't exist because the store's create permission expired

# Clean up
rm("/tmp/rootbucket", recursive=true)
```

### Example 2: Bucket store with unrestricted read/create/delete permission on buckets and objects

```julia
using LocalDiskObjectStores

# Create store
store = LocalDiskObjectStore("/tmp/rootbucket")
setpermission!(store, :bucket, Permission(true, true, true, true))
setpermission!(store, :object, Permission(true, true, true, true))

# Root bucket
listcontents(store)   # Root bucket doesn't yet exist
createbucket!(store)  # Success (returns nothing). Root bucket created
listcontents(store)   # Root bucket is empty

createbucket!(store, "../xxx")  # Failed (returns error msg) because the bucket root/../xxx is outside the root bucket

# Bucket root/xxx
createbucket!(store, "xxx")  # Success (returns nothing)
listcontents(store)          # Lists the contents of the root bucket
createbucket!(store, "xxx")  # Failed (returns error msg) because the bucket already exists

# Object root/xxx/myobject
store["xxx/myobject"] = "My first object" # Success (returns value)
listcontents(store, "xxx")                # Lists the contents of the xxx bucket
listcontents(store, "xxx/myobject")       # Failed (returns nothing) because we can only list the contents of buckets, not objects
String(store["xxx/myobject"])             # Get myobject's value
store["xxx/my_nonexistent_object"]        # Returns nothing because the object does not exist

store["xxx/yyy/newobject"] = "Some new value"  # Fails (returns error msg) because containing bucket doesn't exist
isobject(store, "xxx/yyy/newobject")

createbucket!(store, "xxx/yyy")  # Success (returns nothing), bucket yyy created inside bucket xxx
listcontents(store, "xxx")       # Bucket xxx contains the object myobject and the bucket yyy
listcontents(store, "xxx/yyy")   # Empty vector...bucket exists and is empty

deletebucket!(store, "xxx")      # Failed (returns error msg) because the bucket is not empty
delete!(store, "xxx/myobject")   # Success (returns nothing)
deletebucket!(store, "xxx/yyy")  # Success (returns nothing)
deletebucket!(store, "xxx")      # Success (returns nothing) because the bucket was empty
listcontents(store)

# Clean up
rm("/tmp/rootbucket")
```
