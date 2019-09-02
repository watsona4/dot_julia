make_keys(ssh_keygen_file = settings("ssh_keygen_file")) = mktempdir() do temp
    cd(temp) do
        @info "Generating ssh key"
        filename = ".documenter"
        try
            run(`$ssh_keygen_file -f $filename -N ""`)
        catch x
            if isa(x, Base.UVError)
                error("Cannot find $ssh_keygen_file")
            else
                rethrow()
            end
        end
        read(string(filename, ".pub"), String),
            read(filename, String) |> chomp |> base64encode
    end
end
