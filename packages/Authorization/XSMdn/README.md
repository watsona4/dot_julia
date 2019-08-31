# Authorization.jl

A small but flexible API for controlling an __authenticated__ client's access to resources.

Some use cases are listed at the bottom of this README.


## Resources

All resources (subtypes of `AbstractResource`) have an `id`.
Resources may also have fields other than `id`.


## Clients

A client is a type (subtype of `AbstractClient`) that represents an entity wishing to access some resources.
Clients may represent users, web apps, data storage clients, etc.


## Permissions

A client's access to a resource is determined by its `Permission` for the resource.
The `Permission` type is defined as:

```julia
struct Permission
    create::Bool
    read::Bool
    update::Bool
    delete::Bool
    expiry::DateTime
end
```

Permissions created without an expiry are given an (almost) infinite expiry.

A client can loosely be thought of as a mapping from resources to `Permission`s.

More precisely, the mapping is a hierarchy of 3 maps.

As we move up the hierarchy:
- Each level maps a smaller set of resources to permissions than the previous level.
- The permissions override those specified at the previous level.

The levels are:

1. At the bottom of the hierarchy is the map from resource type to permission.
   This allows the same permission to be applied to all resources with the same type.
   For example a client may have read-only access to the entire local system.
   In this case the resources are directories and files and the associated permission is `Permission(false, true, false, false, expiry)`.

2. In the middle of the hierarchy is the map from resource ID pattern (`Regex`s) to permission.
   This mapping overrides the permissions specified in the type-to-permission mapping.
   Continuing our file system example, the same client could also have write access to a particular directory using this mapping.

3. At the top of the hierarchy is the map from resource ID to permission.
   This mapping allows access control for specific resources.

This framework allows both fine-grained and somewhat coarse access control within the same client, provided the permissions don't conflict within a level of the hierarchy (test for conflicts via `permissions_conflict(client, resourceid)`).

Here's a quick sample of the API:

```julia
# Allow cRud (read-only) access without expiry to resources with type resource_type
setpermission!(client, resource_type, Permission(false, true, false, false))

# Allow CRUD (read/write) access for 5 minutes to resources with IDs starting with "mycollection/"
setpermission!(client, r"mycollection/*", Permission(true, true, true, true, now() + Minute(5)))

p = getpermission(client, resource)  # Get the permission settings for the specific resource
setexpiry!(client, now() + Hour(1))  # Set an expiry for all the resources that the client has access to

haspermission(client, resource, :create)    # True if the client has :create access to the resource
permissions_conflict(client, "myresource")  # True if the rules that define the client's access to the resource with ID "myresource" conflict
```


## Accessing Resources

Use `haspermission(client, resource, action)` to determine whether the client has permission to act on the resource (create/read/update/delete).
Here the `action` is one of `:create`, `:read`, `:update`, `:delete`.

This package also provides `create!`, `read`, `update!` and `delete!`.
Each has the same signature, namely `(client, resource, args...)`.
Each works as follows:
- Check whether the client has permission to act on the resource.
    - If so, act on the resource.
        - If all is well, return `nothing` when creating/updating/deleting, and return `(true, value)` when reading
        - Else return an error message when creating/updating/deleting, and return `(false, error message)` when reading
    - Else return an error message when creating/updating/deleting, and return `(false, error message)` when reading


## Use Cases

### Object Storage

In object storage, data is stored as objects and objects are grouped into buckets.
The [ObjectStores](https://github.com/JockLawrie/ObjectStores.jl) package defines a common API for object storage that allows the storage back-end to be swapped without changing any code.

Examples of object stores include:
- [LocalDiskObjectStores.jl](https://github.com/JockLawrie/LocalDiskObjectStores.jl), which uses the local file system to store objects (files) in buckets (directories).
- [GCSObjectStores.jl](https://github.com/JockLawrie/GCSObjectStores.jl), which uses Google Cloud Storage as the storage back-end.

This authorization framework is used to control access to buckets and objects.


### Web app authorization

Authorization.jl can be used to implement web-app sessions.

Suppose a user's access is determined by his/her subscription to an app. 

Then, for example, `setpermission!(client, App, permission)` sets permissions for all resources related to the app with type `App`.
Also, `setexpiry(client, expiry)` can be used to set an expiry on all resources to which the client has access.
The client can then be used as the session object.
When a request comes in, the client and requested resource can be identified from the request (and perhaps server state).
Determining whether the client has permission to access the resource is then a matter of calling `haspermission`.


## Developing a new client

If you are developing a new client for some resources and would like to use this framework:

1. Ensure that the type of your client is a subtype of `AbstractClient`.
   Concrete subtypes are required to include some mandatory fields - see the `AbstractClient` dosctring.
   You can also include fields that are specific to your client type.

2. Similarly, ensure that the types of your resources are subtypes of `AbstractResource`.
   Also ensure that your concrete subtypes of `AbstractResource` have an `id::String` field.
