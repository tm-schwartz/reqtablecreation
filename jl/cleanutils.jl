replaceescchar(str) = lowercase(replace(unescape_string(str),
    "\xa0" => " ",
    "'" => "",
    "\t" => "",
    "," => " |",
    "+" => "and")
)

finfiltr(arr) = filter(x -> !isempty(strip(x)) && !occursin("()", x), arr)

function fixgroup(str)
    r = Regex("(?<andor>(or|and))\\s\\s\\|\\s\\(")  # replace `or | (` with `or (`
    s = SubstitutionString("\\g<andor> (")          # converts to single element  in final arr
    r2 = Regex("(?<paror>\\)\\s)(?<oa>(or|and))")   # replace `) or` with `) | or`
    s2 = SubstitutionString("\\g<paror> | \\g<oa>") # converts to two seperate elements in final array
    return replace(str, r => s, r2 => s2)
end

function regexextrct(str)
    # TODO crssubjnumb misses hlth 1001 for comm dental hlth coord cert 1618
    # TODO need to fix chopper, or move stripping strngs ending in `or` somewhere else.
    # if a string ends in `or` it is not valid but `or` is kept.
    # examples: cdhc and computer information systems cyber sec 1618. maybe just add another
    # filter function to get rid of or/and at end?
    crssubjnumb = "(\\w{2,4}\\s\\d{3,4}\\w?\\s(?=\\|))"
    andor = "(\\sor\\s\\(.*\\))|(\\sand\\s\\(.*\\))|(\\sor\\s)|(\\sand\\s)"
    parenth = "[()]"
    skills = "(?<=\\|\\s)[\\w\\s&]{4,}\\sskills\\s\\d?"
    series = "(?<=\\|\\s)[\\w\\s\\-\\d]{4,}\\sseries"
    proficiency = "(?<=\\|\\s)[\\w\\s\\-&\\d]{4,}\\d?\\sproficiency\\s\\d?"
    divider = "(\\|(=? \\||))"
    return join(map(x -> x.match, eachmatch(Regex("$crssubjnumb|$andor|$parenth|$skills|$series|$proficiency|$divider"), str)))
end

function chopper(str)
    if startswith(str, "|") && endswith(str, "|")
        return chop(str, head=1, tail=1)
    elseif startswith(str, "|")
        return chop(str, head=1, tail=0)
    elseif startswith(str, "or")
        return chop(str, head=2, tail=0)
    elseif startswith(str, "and")
        return chop(str, head=3, tail=0)
    elseif endswith(str, "|")
        return chop(str, head=0, tail=1)
    elseif endswith(str, "or")
        return chop(str, head=0, tail=2)
    elseif endswith(str, "and")
        return chop(str, head=0, tail=3)
    else
        return ""
    end
end

function runclean(str)
    rec = replaceescchar(str)
    fg = fixgroup(rec)
    re = strip(regexextrct(fg))
    c = re
    while true
        toret = c
        c = chopper(strip(c))
        if isempty(c)
            arr = finfiltr(split(toret, "|", keepempty=false))
            return convert(Array{String},collect(map(strip, arr)))
        end
    end
end
