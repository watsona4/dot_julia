# GoogleCloudObjectStores

This package defines an [ObjectStore](https://github.com/JockLawrie/ObjectStores.jl) that uses _Google Cloud Storage_ as the storage back-end.

__NOTE:__

1. Google Cloud Storage does not allow the creation of buckets within buckets; buckets can contain only objects.
2. Therefore a `GoogleCloudObjectStore` does not allow specification of a root bucket.
3. Bucket names must be unique across your Google Cloud Platform (GCP) project.
4. Some bucket names are rejected by GCP anyway, such as "xxx".


### Example 1: Bucket store with read-only permission

```julia
using Dates
using GoogleCloudObjectStores

# Create store
store = GoogleCloudObjectStore("my_gcs_credentials.json")
listcontents(store)   # Returns nothing. Store doesn't have read permission
setpermission!(store, :bucket, Permission(false, true, false, false))  # cRud (read-only) permission for all buckets within the root bucket
setpermission!(store, :object, Permission(false, true, false, false))  # cRud (read-only) permission for all objects within the root bucket
listcontents(store)   # A list of all buckets in the store

# Bucket abc123foo
createbucket!(store, "abc123foo")  # Fails (returns error message) because the store has no create permission

# Add temporary CRUD permission for bucket abc123foo
expiry = now() + Second(60)  # Set permission expiry for 60 seconds
setpermission!(store, "abc123foo", Permission(true, true, true, true, expiry))
createbucket!(store, "abc123foo")
createbucket!(store, "abc123foozzz")  # Fails (returns error message) because the store has no create permission for this bucket
listcontents(store)
isbucket(store, "abc123foo")  # Bucket now exists
isobject(store, "abc123foo")  # "abc123foo" is a bucket not an object

# Object abc123foo/myobject
store["abc123foo/myobject"] = "My first object"  # No-op, store doesn't have create permission
isobject(store, "abc123foo/myobject")            # "abc123foo/myobject" doesn't exist

# Add temporary create permission for objects in bucket abc123foo
setpermission!(store, r"^abc123foo/.+", Permission(true, true, true, true, expiry))
store["abc123foo/myobject"] = "My object"
isobject(store, "abc123foo/myobject")  # "abc123foo/myobject" now exists
store["abc123foo/myobject"]
store["abc123foo/myobject"] = (value="Some new value", mimetype="application/json")  # An alternative way to create objects
store["abc123foo/myobject"]
delete!(store, "abc123foo/myobject")
isobject(store, "abc123foo/myobject")  # "abc123foo/myobject" no longer exists
createbucket!(store, "zzz")            # Failed (returns error msg) because store has no create permission for other buckets/objects

# Let permission expire
sleep(max(0, convert(Int, Dates.value(expiry - now())) / 1000))  # Sleep until permission expires
store["abc123foo/myobject"] = "My first object"  # No-op, store no longer has create permission
isobject(store, "abc123foo/myobject")            # "abc123foo/myobject" doesn't exist because the store's create permission expired

# Clean up
setpermission!(store, "abc123foo", Permission(false, true, false, true))   # Allow delete permission
deletebucket!(store, "abc123foo")
setpermission!(store, "abc123foo", Permission(false, true, false, false))  # Revert to read-only permission
listcontents(store)
```


### Example 2: Bucket store with unrestricted read/create/delete permission on buckets and objects

```julia
using GoogleCloudObjectStores

# Create store
store = GoogleCloudObjectStore("my_gcs_credentials.json")
setpermission!(store, :bucket, Permission(true, true, true, true))
setpermission!(store, :object, Permission(true, true, true, true))
listcontents(store)   # A list of all buckets in the store

# Bucket abc123foo
createbucket!(store, "../abc123foo")  # Failed (returns error msg) because the bucket name is invalid
createbucket!(store, "abc123foo")     # Success (returns nothing)
listcontents(store)                   # The list of all buckets in the store now contains "abc123foo"
isbucket(store, "abc123foo")
createbucket!(store, "abc123foo")     # Failed (returns error msg) because the bucket already exists

# Object abc123foo/myobject
store["abc123foo/myobject"] = "My first object" # Success (returns value)
listcontents(store, "abc123foo")                # Lists the contents of the abc123foo bucket
listcontents(store, "abc123foo/myobject")       # Failed (returns nothing) because we can only list the contents of buckets, not objects
store["abc123foo/myobject"]                     # Get myobject's value
store["abc123foo/my_nonexistent_object"]        # Returns nothing because the object does not exist
isobject(store, "abc123foo/myobject")
isobject(store, "abc123foo/my_nonexistent_object")

deletebucket!(store, "abc123foo")     # Failed (returns error msg) because the bucket is not empty
delete!(store, "abc123foo/myobject")  # Success (returns nothing)
deletebucket!(store, "abc123foo")     # Success (returns nothing) because the bucket was empty
listcontents(store)
```
