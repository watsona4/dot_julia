# Errors and exceptions

export DropboxError
struct DropboxError
    dict::Dict
end



# Metadata

export MediaInfo, SymlinkInfo, FileSharingInfo, PropertyGroup
struct MediaInfo end            # TODO
struct SymlinkInfo end          # TODO
struct FileSharingInfo end      # TODO
struct PropertyGroup end        # TODO

export FolderSharingInfo
struct FolderSharingInfo end    # TODO

export Metadata
abstract type Metadata end
Metadata(d::Dict) = Dict(
    "file" => FileMetadata,
    "folder" => FolderMetadata,
    "deleted" => DeletedMetadata,
)[d[".tag"]](d)

export FileMetadata
struct FileMetadata <: Metadata
    name::String
    id::String
    client_modified::String
    server_modified::String
    rev::String
    size::Int64
    path_lower::Union{Nothing, String}
    path_display::Union{Nothing, String}
    media_info::Union{Nothing, MediaInfo}
    symlink_info::Union{Nothing, SymlinkInfo}
    sharing_info::Union{Nothing, FileSharingInfo}
    property_groups::Union{Nothing, Vector{PropertyGroup}}
    has_explicit_shared_members::Union{Nothing, Bool}
    content_hash::Union{Nothing, String}
end
FileMetadata(d::Dict) = FileMetadata(
    d["name"],
    d["id"],
    d["client_modified"],
    d["server_modified"],
    d["rev"],
    d["size"],
    get(d, "path_lower", nothing),
    get(d, "path_display", nothing),
    nothing,                    # TODO
    nothing,                    # TODO
    nothing,                    # TODO
    nothing,                    # TODO
    get(d, "has_explicit_shared_members", nothing),
    get(d, "content_hash", nothing)
)

export FolderMetadata
struct FolderMetadata <: Metadata
    name::String
    id::String
    path_lower::Union{Nothing, String}
    path_display::Union{Nothing, String}
    sharing_info::Union{Nothing, FolderSharingInfo}
    property_groups::Union{Nothing, Vector{PropertyGroup}}
end
FolderMetadata(d::Dict) = FolderMetadata(
    d["name"],
    d["id"],
    get(d, "path_lower", nothing),
    get(d, "path_display", nothing),
    nothing,                    # TODO
    nothing                     # TODO
)

export DeletedMetadata
struct DeletedMetadata <: Metadata
    name::String
    path_lower::Union{Nothing, String}
    path_display::Union{Nothing, String}
end
DeletedMetadata(d::Dict) = DeletedMetadata(
    d["name"],
    get(d, "path_lower", nothing),
    get(d, "path_display", nothing)
)
