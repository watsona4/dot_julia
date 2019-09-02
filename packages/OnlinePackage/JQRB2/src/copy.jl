export copy_package
"""
    copy_package(model, package)

create a new package based off of model. model must be in the working directory.
"""
function copy_package(model, package)
    if !isdir(model)
        error("cannot find $model")
    elseif isdir(package)
        error("$package already exists")
    else
        @info "copying $model to $package"
        cp(model, package, force = true)
        cd(package)
        @info "removing old git repository"
        rm(".git", recursive = true)
        @info "replacing all occurances of $model with $package"
        foreach(walkdir(pwd())) do dir_tuple
            base_dir, folders, files = dir_tuple
            foreach(files) do file
                new_path = joinpath(base_dir, file)
                write(new_path, join(
                    Generator(readlines(new_path)) do line
                        replace(line, Regex("\\b$model\\b") => package)
                    end,
                    '\n'
                ))
            end
        end
    end

    src_model = joinpath("src", "$model.jl")
    src_package = joinpath("src", "$package.jl")

    if !isfile(src_model)
        @warn "$src_model does not exist"
    else
        @info "renameing $src_model to $src_package"
        mv(src_model, src_package)
    end

    @info "initializing new git repository"
    my_repo = LibGit2.init(pwd())
    url = "https://github.com/$(settings("username"))/$package.jl.git"
    @info "setting origin to $url"
    LibGit2.set_remote_url(my_repo, "origin", url)
    @info "initial empty commit"
    LibGit2.commit(my_repo, "initial empty commit")
    @info "creating gh-pages branch"
    LibGit2.branch!(my_repo, "gh-pages", set_head=false)
end
