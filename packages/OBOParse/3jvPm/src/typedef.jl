# FIXME add description
"""
"""
struct Typedef
    id::String
    name::String
    namespace::String
    xref::String
end

Base.isequal(td1::Typedef, td2::Typedef) = td1.id == td2.id
Base.:(==)(td1::Typedef, td2::Typedef) = isequal(td1, td2)
