abstract type Requirement end

struct Course <: Requirement
    name::String
end

mutable struct Relation <: Requirement
    rtype::String
    members::Array{Requirement,1}
    Relation(rtype::String, members::Array) = new(uppercase(strip(rtype, [' ', '('])), members)
end

function Relation(inpt)
    if isa(inpt, String)
        return Relation(inpt, Requirement[])
    elseif isa(inpt, Array) && eltype(inpt) == Requirement 
        return Relation("", inpt)
    else
        return error("either rtype or members have incorrect type")
    end
end

Relation() = Relation("", Requirement[])
