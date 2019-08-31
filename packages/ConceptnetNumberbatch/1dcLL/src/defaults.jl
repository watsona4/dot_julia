# Links pointing to the latest ConceptNetNumberbatch version (v"17.06")
const CONCEPTNET_MULTI_LINK = "https://conceptnet.s3.amazonaws.com/downloads/2017/numberbatch/numberbatch-17.06.txt.gz"
const CONCEPTNET_EN_LINK = "https://conceptnet.s3.amazonaws.com/downloads/2017/numberbatch/numberbatch-en-17.06.txt.gz"
const CONCEPTNET_HDF5_LINK = "https://conceptnet.s3.amazonaws.com/precomputed-data/2016/numberbatch/17.06/mini.h5"

# Accepted languages (map from conceptnet to Languages.Language)
const LANGUAGES = Dict(:en=>Languages.English(),
                       :fr=>Languages.French(),
                       :de=>Languages.German(),
                       :it=>Languages.Italian(),
                       :fi=>Languages.Finnish(),
                       :nl=>Languages.Dutch(),
                       :af=>Languages.Dutch(),
                       :pt=>Languages.Portuguese(),
                       :es=>Languages.Spanish(),
                       :ru=>Languages.Russian(),
                       :sh=>Languages.Serbian(),# and Languages.Croatian()
                       :sw=>Languages.Swedish(),
                       :cs=>Languages.Czech(),
                       :pl=>Languages.Polish(),
                       :bg=>Languages.Bulgarian(),
                       :eo=>Languages.Esperanto(),
                       :hu=>Languages.Hungarian(),
                       :el=>Languages.Greek(),
                       :no=>Languages.Nynorsk(),
                       :sl=>Languages.Slovene(),
                       :ro=>Languages.Romanian(),
                       :vi=>Languages.Vietnamese(),
                       :lv=>Languages.Latvian(),
                       :tr=>Languages.Turkish(),
                       :da=>Languages.Danish(),
                       :ar=>Languages.Arabic(),
                       :fa=>Languages.Persian(),
                       :ko=>Languages.Korean(),
                       :th=>Languages.Thai(),
                       :ka=>Languages.Georgian(),
                       :he=>Languages.Hebrew(),
                       :te=>Languages.Telugu(),
                       :et=>Languages.Estonian(),
                       :hi=>Languages.Hindi(),
                       :lt=>Languages.Lithuanian(),
                       :uk=>Languages.Ukrainian(),
                       :be=>Languages.Belarusian(),
                       :sw=>Languages.Swahili(),
                       :ur=>Languages.Urdu(),
                       :ku=>Languages.Kurdish(),
                       :az=>Languages.Azerbaijani(),
                       :ta=>Languages.Tamil()
                       # add more mappings here if needed
                       # AND supported by Languages.jl
                      )

# Regular expression on which to split text into tokens
const DEFAULT_SPLITTER = r"(,|\n|\r|\:|\\|\/|;|\.|\[|\]|\{|\}|\'|\`|\"|\"|\?|\!|\=|\~|\&|\s+)"
