# This file contains the necessary ingredients to create a PackageManager for BinDeps
struct EnvManager{T} <: BinDeps.PackageManager
    packages::Vector{String}
end

"Manager for root environment"
const Manager = EnvManager{Symbol(Conda.PREFIX)}

function Base.show(io::IO, manager::EnvManager)
    print(io, "Conda packages: ", join(manager.packages, ", "))
end

BinDeps.can_use(::Type{EnvManager}) = true

function BinDeps.package_available(manager::EnvManager{T}) where {T}
    pkgs = manager.packages
    # For each package, see if we can get info about it. If not, fail out
    for pkg in pkgs
        if !Conda.exists(pkg, T)
            return false
        end
    end
    return true
end

BinDeps.libdir(m::EnvManager{T}, ::Any) where {T} = Conda.lib_dir(T)
BinDeps.bindir(m::EnvManager{T}, ::Any) where {T} = Conda.bin_dir(T)

BinDeps.provider(::Type{EnvManager{T}}, packages::AbstractVector{<:AbstractString}; opts...) where {T} = EnvManager{T}(packages)
BinDeps.provider(::Type{EnvManager{T}}, packages::AbstractString; opts...) where {T} = EnvManager{T}([packages])

function BinDeps.generate_steps(dep::BinDeps.LibraryDependency, manager::EnvManager, opts)
    pkgs = manager.packages
    ()->install(pkgs, manager)
end

function install(pkgs, manager::EnvManager{T}) where {T}
    for pkg in pkgs
        Conda.add(pkg, T)
    end
end
