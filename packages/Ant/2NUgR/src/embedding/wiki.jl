#!/usr/bin/env julia
# del2z <delta.z@aliyun.com>

import Base: replace
using DataStructures: Stack
using LightXML

" Parse wikipedia data dumped by wikimedia "
function parsewiki(xmlfile::AbstractString, txtfile::AbstractString)
    fin = open(xmlfile, "r")
    fout = open(txtfile, "w")

    page = ""
    numline = 0
    for line in eachline(fin)
        line = strip(line)
        numline += 1
        if line == "<page>"
            page = line
        elseif line == "</page>"
            page *= "\n" * line
            pageinfo = parsepage(page, numline)
            write(fout, "<doc id=\"$(pageinfo[:id])\" title=\"$(pageinfo[:title])\">\n",
                  "$(cleantext(pageinfo[:content]))\n</doc>\n")
        else
            page *= "\n" * line
        end
    end
    close(fin)
    close(fout)
end

" Parse one page of wikipedia "
function parsepage(page::AbstractString, numline::Int)
    pageinfo = Dict{Symbol, Any}()
    try
        xmldoc = parse_string(page)
        xroot = root(xmldoc)
        pageinfo[:ns] = content(xroot["ns"][1])
        pageinfo[:id] = content(xroot["id"][1])
        pageinfo[:title] = content(xroot["title"][1])
        if find_element(xroot, "revision") != nothing
            pageinfo[:content] = content(xroot["revision"][1]["text"][1])
        else
            pageinfo[:content] = content(xroot["text"][1])
        end
        free(xmldoc)
    catch e
        throw(e)
        println("Encounter errors before line $numline.")
    end
    pageinfo
end

" Clean unnecessary formats of contents "
function cleantext(text::AbstractString)
    text = clean1(text)
    text = clean2(text)
    text = clean3(text)
    text = clean4(text)
    text = clean5(text)
    #=
    str = replace(str, "&lt;math", "&lt;/math&gt;", " ")
    pair = search(str, "{{", "}}")
    bracefields = ["Infobox", "Taxobox", "Notability", "onesource", "More footnotes", "DEFAULTSORT"]
    while !isempty(pair)
        leftindex = collect(keys(pair))[1]
        rightindex = pop!(pair, leftindex) + length("}}") - 1
        for field in bracefields
            if startswith(str[leftindex + length("{{"):end], field)
                str = replace(str, leftindex, rightindex, "")
                update!(pair, leftindex, rightindex, rlen = 0)
                break
            end
        end
    end

    pair = search(str, "\\[\\[", "\\]\\]")
    bracketfields = ["Category"]
    while !isempty(pair)
        leftindex = collect(keys(pair))[1]
        rightindex = pop!(pair, leftindex) + length("]]") - 1
        for field in bracketfields
            if startswith(str[leftindex + length("[["):end], field)
                str = replace(str, leftindex, rightindex, "")
                update!(pair, leftindex, rightindex, rlen = 0)
                break
            end
        end
    end

    str = replace(str, Regex("{{reflist.*$") => "")
    str = replace(str, Regex("&lt;references /&gt;.*$") => "")
    str = replace(str, "{\\| class", "\\|}", "")
    str = replace(str, "&lt;ref", "&lt;/ref&gt;", "")
    str = replace(str, "&lt;ref", "/&gt;", "")
    str = replace(str, "&lt;!--", "--&gt;", "")

    str = replace(str, r"\[\[([^\|]+)\]\]" => s"\1")
    str = replace(str, r"\n==[^\n]+==\n" => "")
    str = replace(str, r"\n===[^\n]+===\n" => "")
    str = replace(str, r"\n[,.:' ，。：]*\n", "\n")
    str = replace(str, r"^\n|\n$" => "")
    str = replace(str, r"'{2,}" => "")
    str = replace(str, r"\n.{0,50}\n"), "\n")
    =#
    return text
end


" Clean headings of page "
function clean1(text::AbstractString)
    text = replace(text, r"'''''(.*?)'''''" => s"\1")
    text = replace(text, r"'''(.*?)'''" => s"\1")
    text = replace(text, r"''(.*?)''" => s"\1")
    text = replace(text, r"======(.*?)======" => "")
    text = replace(text, r"=====(.*?)=====" => "")
    text = replace(text, r"====(.*?)====" => "")
    text = replace(text, r"===(.*?)===" => "")
    text = replace(text, r"==(.*?)==" => "")
    text = replace(text, r"----" => "")
    return text
end


" Clean html marks "
function clean2(text::AbstractString)
    text = replace(text, r"<math>(.*?)</math>"s => "")
    text = replace(text, r"<ref[ >](.*?)</ref>"s => "")
    text = replace(text, r"<!--(.*?)-->"s => "")
    return text
end


" Clean extra boxes "
function clean3(text::AbstractString)
    text = replace(text, r"^{{Taxobox(.*?)^}}"ms => "")
    text = replace(text, r"^{{Infobox(.*?)^}}"ms => "")
    text = replace(text, r"^{\| class(.*?)^\|}"ms => "")
    text = replace(text, r"{{reflist[}|](.*?)$"s => "")
    return text
end


" Clean external links "
function clean4(text::AbstractString)
    return text
end


" Clean other formats "
function clean5(text::AbstractString)
    text = replace(text, r"^\n+|\n+$" => "")
    text = replace(text, r"\n[,.:' ，。：]*\n", "\n")
    text = replace(text, r"\n+" => "\n")
    return text
end


" Search paired patterns and return matched offsets "
function search(s::AbstractString, left::AbstractString, right::AbstractString)
    pair = Dict{Int, Int}()
    match(Regex("$left"), s) === nothing && return pair
    stack = Stack{Int}()
    for m in eachmatch(Regex("($left|$right)"), s)
        if match(Regex("$left"), m.match) != nothing
            push!(stack, m.offset)
        elseif match(Regex("$right"), m.match) != nothing
            !isempty(stack) && push!(pair, pop!(stack) => m.offset)
        else
            println("Incorrect substring '$(m.match)' matching patterns ('$left', '$right')")
        end
    end
    return pair
end


" Replace `s[leftindex:rightindex]` by `r` "
function Base.replace(s::AbstractString, leftindex::Int, rightindex::Int, r::AbstractString)
    s[1:thisind(s, leftindex - 1)] * r * s[thisind(s, rightindex + 1):end]
end


" Replace all substrings matching `pat` with `r` "
function Base.replace(s::AbstractString, pat::Regex, r::AbstractString)
    while true
        match(pat, s) === nothing && break
        s = replace(s, pat => r)
    end
    return s
end


" Replace all substrings between `left` and `right` patterns with `r` "
function Base.replace(s::AbstractString, left::AbstractString, right::AbstractString, r::AbstractString)
    pair = search(s, left, right)
    rightlen = length(right) - count(c -> c == '\\', right)
    rlen = length(r)
    while !isempty(pair)
        leftindex = maximum(keys(pair))
        rightindex = pop!(pair, leftindex) + rightlen - 1
        s = replace(s, leftindex, rightindex, r)
        update!(pair, leftindex, rightindex, rlen = rlen)
    end
    return s
end


" Update paired dict after replacement "
function update!(pair::Dict{Int, Int}, leftindex::Int, rightindex::Int; rlen::Int = 0)
    plen = rightindex - leftindex + 1
    for (i, j) in sort(collect(pair))
        if i < leftindex && j < leftindex
            continue
        elseif i < leftindex && j > rightindex
            pair[i] = j - plen + rlen
        elseif i >= leftindex && j <= rightindex
            delete!(pair, i)
        elseif i > rightindex && j > rightindex
            delete!(pair, i)
            pair[i - plen + rlen] = j - plen + rlen
        else
            println("Mismatched paired pattern ($i, $j)")
        end
    end
end

