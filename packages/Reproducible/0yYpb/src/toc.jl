function maketoc(path::String; depth=2, title = "# Table of Contents")
    s = "$title\n\n"
    for item in Markdown.parse(read(path, String)).content
        for level in 1:depth
            if isa(item, Markdown.Header{level}) 
                header = strip(replace(Markdown.plain(item), "#" => ""))
                link = make_link(header)
                s *= repeat(' ', (level-1)*4) * "- [$header](#$link)\n"
            end
        end
    end
    s * "\n\n---\n\n"
end

function make_link(header)
    s = lowercase(replace(header, " " => "-"))
    s = lowercase(replace(s, "?" => ""))
end