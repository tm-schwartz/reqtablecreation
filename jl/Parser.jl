module Parser
include("structs.jl")
include("cleanutils.jl")

export buildreqs!, writer, runclean


function pushrel!(reqs::Array, input, elem)
    # push a standard relation to reqs
    if isa(reqs[end], Relation) && reqs[end].rtype == uppercase(strip(elem, [' ', '('])) # if relation and rtype same as current elem
        topush = Course(popfirst!(input))
        push!(reqs[end].members, topush)
    else
        topush = Relation(elem, [reqs[end], Course(popfirst!(input))])
        pop!(reqs)
        push!(reqs, topush)
    end
end

function pushrel!(reqs::Relation, input, elem)
    # push a standard relation to reqs
    if isa(reqs.members[end], Relation) && reqs.members[end].rtype == uppercase(strip(elem, [' ', '('])) # if relation and rtype same as current elem
        topush = Course(popfirst!(input))
        push!(reqs[end].members, topush)

    else
        topush = Relation(elem, [reqs.members[end], Course(popfirst!(input))])
        pop!(reqs.members)
        push!(reqs.members, topush)
    end
end

function pushgroup!(reqs::Array, input, elem)
    rel = Relation(elem, [reqs[end]])
    pop!(reqs)
    while input[1] != ")"
        elem = popfirst!(input)
        if lowercase(elem) in ("or", "and")
            pushrel!(rel, input, elem)
        elseif lowercase(elem) in ("or (", "and (")
            pushgroup!(rel, input, elem)
        else
            push!(rel.members, Course(elem))
        end
    end
    push!(reqs, rel)
    popfirst!(input)
end

function pushgroup!(reqs::Relation, input, elem)
    rel = Relation(elem, [reqs.members[end]])
    pop!(reqs.members)
    while input[1] != ")"
        elem = popfirst!(input)
        if lowercase(elem) in ("or", "and")
            pushrel!(rel, input, elem)
        elseif lowercase(elem) in ("or (", "and (")
            pushgroup!(rel, input, elem)
        else
            push!(rel.members, Course(elem))
        end
    end
    push!(reqs.members, rel)
    popfirst!(input)
end

function buildreqs!(data::Array{String})
    #TODO take dataframe instead? run `runclean`?
    reqs = Union{Course,Relation}[]
    while !isempty(data)
        c = popfirst!(data)
        if lowercase(c) in ("or", "and")
            pushrel!(reqs, data, c)
            continue
        elseif lowercase(c) in ("or (", "and (")
            pushgroup!(reqs, data, c)
            continue
        else
            push!(reqs, Course(c))
        end
    end
    return reqs
end

""" write data to IO. Defaults to stdout. Column 3 definitions are:
 0 -> independent requirement
 1 -> OR relation
 2 -> AND relation
"""
function writer(prog::String, data::Array, io::IO=stdout,)
    function itre(it)
        for i in it.members
            if isa(i, Relation)
                itre(i)
            elseif isa(i, Course)
                print(io, prog, ',', i.name, ',')
                if it.rtype == "AND"
                    print(io, hash(it), ',', '2', '\n')
                else
                    print(io, hash(i.name), ',', '1', '\n')
                end
            end
        end
    end


    for r in data
        if isa(r, Course)
            print(io, prog, ',', r.name, ',', hash(r.name), ',', '0', '\n')
        else
            itre(r)
        end
    end
end
end
