using Test
using Dates
using LocalDiskObjectStores


################################################################################
# Store with read-only permission

# Create store
store = LocalDiskObjectStore("/tmp/rootbucket")
@test listcontents(store) == nothing  # Store doesn't have read permission
setpermission!(store, :bucket, Permission(false, true, false, false))
setpermission!(store, :object, Permission(false, true, false, false))

# Root bucket
@test listcontents(store) == nothing          # Root bucket doesn't yet exist
@test typeof(createbucket!(store)) == String  # Failed (returns error msg) because store has no create permission
@test !isbucket(store, "")                    # Root bucket still doesn't exist
mkdir("/tmp/rootbucket")
@test isbucket(store, "")                     # Root bucket now exists
@test isempty(listcontents(store))            # Root bucket is empty

# Bucket root/xxx
@test listcontents(store, "xxx") == nothing  # True because the bucket does not exist
@test typeof(createbucket!(store, "xxx")) == String  # Failed (returns error msg) because store has no create permission
mkdir("/tmp/rootbucket/xxx")
@test isbucket(store, "xxx")                 # Bucket now exists.
@test !isobject(store, "xxx")                # "xxx" is a bucket not an object.

# Object root/xxx/myobject
store["xxx/myobject"] = "My first object"    # No-op, store doesn't have create permission
@test !isobject(store, "xxx/myobject")       # "xxx/myobject" doesn't exist

# Add temporary create permission for objects in bucket root/xxx
setpermission!(store, r"^/tmp/rootbucket/xxx/.+", Permission(true, true, true, true, now() + Second(5)))
store["xxx/myobject"] = "My object"
@test isobject(store, "xxx/myobject")        # "xxx/myobject" now exists
@test String(store["xxx/myobject"]) == "My object"
store["xxx/myobject"] = "Some new value"
@test String(store["xxx/myobject"]) == "Some new value"
@test delete!(store, "xxx/myobject") == nothing      # Success (returns nothing)
@test !isobject(store, "xxx/myobject")               # "xxx/myobject" no longer exists
@test typeof(createbucket!(store, "zzz")) == String  # Failed (returns error msg) because store has no create permission for other buckets/objects

sleep(5)                                   # Sleep until permission expires
store["xxx/myobject"] = "My first object"  # No-op, store no longer has create permission
@test !isobject(store, "xxx/myobject")     # "xxx/myobject" doesn't exist because create permission expired

# Clean up
rm("/tmp/rootbucket", recursive=true)


################################################################################
# Store with unrestricted read/create/delete permission on buckets and objects

# Create store
store = LocalDiskObjectStore("/tmp/rootbucket")
setpermission!(store, :bucket, Permission(true, true, true, true))
setpermission!(store, :object, Permission(true, true, true, true))

# Root bucket
@test listcontents(store) == nothing   # Root bucket doesn't yet exist
@test createbucket!(store) == nothing  # Success (returns nothing)
@test isempty(listcontents(store))     # Root bucket is empty

@test typeof(createbucket!(store, "../xxx")) == String  # Failed (returns error msg) because the bucket is outside the root bucket

# Bucket root/xxx
@test createbucket!(store, "xxx") == nothing              # Success (returns nothing)
@test listcontents(store) == ["xxx"]                      # Lists the contents of the root bucket
@test typeof(createbucket!(store, "xxx")) == String       # Failed (returns error msg) because the bucket already exists

# Object root/xxx/myobject
store["xxx/myobject"] = "My first object"                 # Success (returns value)
@test listcontents(store, "xxx") == ["myobject"]          # Lists the contents of the xxx bucket
@test listcontents(store, "xxx/myobject") == nothing      # Failed (returns nothing) because we can only list the contents of buckets, not objects
@test String(store["xxx/myobject"]) == "My first object"  # Get myobject's value
@test store["xxx/my_nonexistent_object"] == nothing       # True because the object does not exist

store["xxx/yyy/newobject"] = "Containing bucket doesn't exist"  # Fails (returns error msg) because containing bucket doesn't exist
@test !isobject(store, "xxx/yyy/newobject")

@test createbucket!(store, "xxx/yyy") == nothing          # Success (returns nothing), bucket yyy created inside bucket xxx
@test listcontents(store, "xxx") == ["myobject", "yyy"]   # Bucket xxx contains the object myobject and the bucket yyy
@test isempty(listcontents(store, "xxx/yyy"))             # Empty vector...bucket exists and is empty

@test typeof(deletebucket!(store, "xxx")) == String  # Failed (returns error msg) because the bucket is not empty
@test delete!(store, "xxx/myobject") == nothing      # Success (returns nothing)
@test deletebucket!(store, "xxx/yyy") == nothing     # Success (returns nothing)
@test deletebucket!(store, "xxx") == nothing         # Success (returns nothing) because the bucket was empty
@test isempty(listcontents(store))
rm("/tmp/rootbucket")  # Clean up
