# Developer documentation for Retriever Julia package

Before you begin, make sure you have the retriever python package installed

# ALL required packeges

These packages will be installed once the Retriever.jl package is installed

Pycall
Compat
DocStringExtensions
Documenter

### PyCall

Pycall julia is used to communicate with the retriever python package objects.

### Documenter

Documenter tool is used for building documentation
To test the documentations locally, install the current source
```Julia

julia> include("src/Retriever.jl")

```

### Tests

The tests are performed in two fold
We test the python core functions, and then followed by the julia core functions.

### Register and Release Retriever

```Julia

julia> ENV["PYTHON"]="Python path where retriever python package is installed"
julia> Pkg.build("PyCall")
julia> Pkg.add("PyCall")
julia> Pkg.test("Retriever")
julia> Pkg.update()
julia> Pkg.add("PkgDev")
julia> using  PkgDev

```

```Julia

julia> PkgDev.register("Retriever")
INFO: Registering Retriever at https://github.com/weecology/Retriever.jl.git
INFO: Committing METADATA for Retriever

```

```Julia

julia> PkgDev.tag("Retriever")
INFO: Tagging Retriever v0.0.1

```

```Julia

julia> PkgDev.config()
PkgDev.jl configuration:
User name: provide git user name
User email: provide git associated email
Enter GitHub user [Defualt name]:
Do you want to change this configuration? [N]:N

```

```Shell

julia> PkgDev.publish()
INFO: Validating METADATA
INFO: Creating a personal access token for Julia Package Manager on GitHub.
	You will be asked to provide credentials to your GitHub account.

...Git Credential authentication

INFO: Pushing Retriever permanent tags: v0.0.1
INFO: Submitting METADATA changes
INFO: Forking JuliaLang/METADATA.jl to henrykironde
INFO: Pushing changes as branch pull-request/ceea745c
INFO: To create a pull-request, open:

  https://[link to the Branch created]

```
