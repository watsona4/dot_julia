function wordpiece_tokenize(token, dict)
    # This is a longest-match-first algorithm.
    out_tokens = []
    start = 1
    while start <= length(token)
        finish = length(token)
        final_token = ""
        for i in finish:-1:start
            # String Indexing Error for an unknown reason. Might be because of unicode chars.
            tkn = try
                start == 1 ? token[start:i] : string("##", token[start:i])
            catch
                ""
            end
            if tkn in keys(dict)
                final_token = tkn
                finish = i
                break
            end
        end
        if final_token == "" # if there is no match at all, assign unk token
            return ["[UNK]"]
        end
        push!(out_tokens, final_token)
        start = finish + 1
    end
    return out_tokens
end

function process_punc(tokens)
    out_tokens = []
    for token in tokens
        out = []
        str = ""
        for (i, char) in enumerate(token)
            if ispunct(char)
                str != "" && push!(out, str)
                str = ""
                push!(out, string(char))
            else
                str = string(str, char)
            end
        end
        str != "" && push!(out, str)
        append!(out_tokens, out)
    end
    return out_tokens
end

function bert_tokenize(text, dict; lower_case=true)
    text = strip(text)
    text == "" && return []
    if lower_case
        text = lowercase(text)
    end
    tokens = split(text)
    tokens = process_punc(tokens)
    out_tokens = []
    for token in tokens
        append!(out_tokens, wordpiece_tokenize(token, dict))
    end
    return out_tokens
end
