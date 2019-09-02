@static if VERSION >= v"0.7.0-"
    using InteractiveUtils: versioninfo
else
    versioninfo(io; verbose=false) = Base.versioninfo(io, verbose)
end

function envinfo(io::IO = stdout; verbosity::Int = 1)
    if verbosity > 0
        versioninfo(io; verbose = verbosity > 1)
        println(io)
    end
    for ex in [:(PyCall.pyprogramname),
               :(PyCall.pyversion),
               :(PyCall.libpython),
               :(PyCall.conda),
               :(pyversion("IPython")),
               :(pyversion("julia")),
               ]
        Base.show_unquoted(io, ex)
        print(io, " = ")
        show(io, eval(ex))
        println(io)
    end
    nothing
end

function pkg_resources_version(name)
    try
        return @compatattr pyimport("pkg_resources").get_distribution(name).version
    catch err
        if err isa PyCall.PyError || err isa KeyError
            return
        end
        rethrow()
    end
end

function _pyversion(name)
    package = try
        pyimport(name)
    catch err
        if ! (err isa PyCall.PyError)
            rethrow()
        end
        return
    end
    try
        return @compatattr package.__version__
    catch err
        if ! (err isa KeyError)
            rethrow()
        end
    end
end

function pyversion(name)
    version = pkg_resources_version(name)
    if version !== nothing
        return version
    end
    return _pyversion(name)
end


function yes_or_no(prompt = string("Type \"yes\" and press enter if ",
                                   "you want to run this command.");
                   input = stdin,
                   output = stdout)
    print(output, prompt, " [yes/no]: ")
    answer = readline(input)
    if answer == "yes"
        return true
    elseif answer == "no"
        return false
    end
    @warn "Please enter \"yes\" or  \"no\".  Got: $answer"
    return false
end


conda_packages = ("ipython", "pytest")
NOT_INSTALLABLE = (false, "", Nothing)

function condajl_installation(package)
    if PyCall.conda && package in conda_packages
        message = """
        Installing $package via Conda.jl
        Execute?:
            Conda.add($package)
        """
        install = () -> Conda.add(package)
        return (true, message, install)
    end
    return NOT_INSTALLABLE
end

function conda_installation(package)
    conda = joinpath(dirname(PyCall.pyprogramname), "conda")
    if isfile(conda) && package in conda_packages
        prefix = dirname(dirname(PyCall.pyprogramname))
        command = `$conda install --prefix $prefix -c conda-forge $package`
        message = """
        Installing $package with $conda
        Execute?:
            $command
        """
        install = () -> run(command)
        return (true, message, install)
    end
    return NOT_INSTALLABLE
end

function pip_installation(package)
    if package in (conda_packages...,
                   "mock", "ipython-dev", "ipython-pre", "julia")
        args = package
        if package == "ipython-dev"
            args = `"git+git://github.com/ipython/ipython#egg=ipython"`
        elseif package == "ipython-pre"
            args = `--pre ipython`
        end
        command = `$(PyCall.pyprogramname) -m pip install --upgrade $args`
        message = """
        Installing $package for $(PyCall.pyprogramname)
        Execute?:
            $command
        """
        install = () -> run(command)
        return (true, message, install)
    end
    return NOT_INSTALLABLE
end

function install_dependency(package; force=false, dry_run=false)
    for check_installer in [condajl_installation,
                            conda_installation,
                            pip_installation]
        found, message, install = check_installer(package)
        if found
            @info message
            if !dry_run && (force || yes_or_no())
                install()
            end
            return
        end
    end
    @warn "Installing $package not supported."
end


function test_ipython_jl(args=``; inprocess=false, kwargs...)
    if inprocess
        test_ipython_jl_inprocess(args; kwargs...)
    else
        test_ipython_jl_cli(args)
    end
end

function test_ipython_jl_inprocess(args; revise=true, check=true)
    IPython._start_ipython(:ipython_options)  # setup ipython_jl.core._Main
    if revise
        @compatattr pyimport("ipython_jl").revise()
    end
    cd(@__DIR__) do
        code = @compatattr pyimport("pytest").main(collect(args))
        if !check
            return code
        end
        if code != 0
            error("$(`pytest $args`) failed with code $code")
        end
    end
end

function test_ipython_jl_cli(args)
    command = `$(PyCall.pyprogramname) -m pytest $args`
    @info command
    cd(@__DIR__) do
        run(command)
    end
end
