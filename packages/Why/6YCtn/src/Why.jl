using Random

module Why
QUERY_COUNT = 0

function why()
    return make_ans()
end

const begins = ("because ", "")
const fins = ("wanted it", "decided so", "made it happen", "caused it", "could not prevent it", "permited it")
const mess_persistent = ("Why do you keep asking these questions?", "Please stop.")
const single = ("I do not know.", "42", "You must find that answer yourself.", "It is axiomatic.")
function make_ans()
    if (global QUERY_COUNT+=1) > 5 + rand(1:15)
        global QUERY_COUNT -= rand(1:10)
        return message = mess_persistent[rand(1:length(mess_persistent))]
    elseif rand() < 0.15
        return message = single[rand(1:length(single))]
    end
    return uppercasefirst(rand_element(begins) * noun(1.0) * rand_element(fins) * ".")
end

#Nouns
const preps = ("the", "a", "some")
const nouns = ("compiler", "person", "research software engineer", "type pirate", "cockatoo", "manager", "programmer", "software", "penguin", "config file", "divine being", "struct")
function noun(p)
    (rand()>p) && return ""
    return rand_element(preps)*" "*adj(0.80)*rand_element(nouns)*" "*and(noun(p/2))
end

#Ajectives
const adjs = ("fast", "type-safe", "harmless", "deceitful", "cool", "self aware", "scary", "insecure", "paranoid", "cunning", "irrelevant", "undocumented", "rudimentary", "primitive")
function adj(p)
    (rand()>p) && return ""
    return adv(0.5)*rand_element(adjs)*" "*and(adj(p/2.5))
end

#Adverbs
const advs = ("vaguely", "extraordinarily", "properly", "very", "not at all", "probably")
function adv(p)
    (rand()>p) && return ""
    return rand_element(advs)*" "
end


#Extra functions
function and(s::String)
    (s=="") && return s
    return "and " * s
end

rand_element(tup::Tuple) = tup[rand(1:length(tup))]

export why

#Preparing for expanding.

#Nouns
#const proper_nouns = ("Bob", "Alice", "Kim")
#const concrete_nouns = ("compiler", "person", "research software engineer", "type pirate", "cockatoo", "manager", "programmer", "software", "penguin", "config file", "divine being")
#const abstract_nouns = ("truth", "joy")
#const collective_nouns = ("online community")

#Verbs


#Adjective
#const descriptive_adjectives = ("scary", "cool", "backwards")
#const quantitative_adjectives = ("one", "two", "seventeen", "many", "few", "several")
#const possessive_adjectives = ("their")
#const distributive_adjectives = ("every", "any")
#const articles = ("a", "the", "some") # "An"?

#Adverbs
#const time_adverbs = ("never", "soon", "recentyl")
#const space_adverbs = ("there", "somewhere", "everywhere")
#const manner_adverbs = ("polietly", "neatly", "promptly")
#const degree_adverbs = ("quite", "too", "so")
#const ferquency_adverbs = ("seldom", "usually", "again")

#Pronouns


#Prepositions


#Conjuctions


#Determiners


#Exclamations





end # module
