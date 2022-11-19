using Dates
using Franklin
using Weave

function hfun_bar(vname)
    val = Meta.parse(vname[1])
    return round(sqrt(val); digits=2)
end

function hfun_m1fill(vname)
    var = vname[1]
    return Franklin.pagevar("index", var)
end

function hfun_eval(arg)
    x = Core.eval(Franklin, Meta.parse(join(arg)))
    io = IOBuffer()
    show(io, "text/plain", x)
    return String(take!(io))
end

function write_notes(rpaths)::String
    sort_notes!(rpaths)
    curyear = Dates.year(Franklin.pagevar(rpaths[1], :date))
    io = IOBuffer()
    write(io, "<h3 class=\"notes\">$curyear</h3>")
    write(io, "<ul class=\"notes\">")
    for rp in rpaths
        year = Dates.year(Franklin.pagevar(rp, :date))
        if year < curyear
            write(io, "<h3 class=\"notes\">$year</h3>")
            curyear = year
        end
        title = Franklin.pagevar(rp, :title)
        descr = Franklin.pagevar(rp, :descr)
        descr === nothing && error("no description found on page $rp")
        pubdate = Dates.format(Date(Franklin.pagevar(rp, :date)), "U d")
        path = joinpath(splitpath(rp)[1:2]...)
        write(
            io,
            """
      <li class="note">
          <p>
              <span class="note">$pubdate</span>
              <a class="note" href="/$path/">$title</a>
              <span class="note-descr tag">$descr</span>
          </p>
      </li>
      """,
        )
    end
    write(io, "</ul>")  #= notes =#
    return String(take!(io))
end

function sort_notes!(rpaths)
    sorter(p) = begin
        pvd = Franklin.pagevar(p, :date)
        if isnothing(pvd)
            return Date(Dates.unix2datetime(stat(p * ".md").ctime))
        end
        return pvd
    end
    return sort!(rpaths; by=sorter, rev=true)
end

function hfun_allnotes()::String
    rpaths = [
        joinpath("notes", note, "index.md") for
        note in readdir("notes") if !endswith(note, ".md")
    ]
    return write_notes(rpaths)
end

function hfun_taglist()
    tag = Franklin.locvar(:fd_tag)::String
    rpaths = Franklin.globvar("fd_tag_pages")[tag]
    return write_notes(rpaths)
end

function hfun_weave2html(document)
    f_name = tempname(pwd()) * ".html"
    weave(first(document); out_path=f_name)
    text = read(f_name, String)
    final = x ->
        replace(x, r"<span class='hljl-.*?>" => "") |> # Removes weave code block syntax
        x ->
            replace(x, "</span>" => "") |> # Removes weave code block syntax
            x ->
                replace(
                    x,
                    "<pre class='hljl'>\n" => "<pre><code class = \"language-julia\">", # Replaces weave code block syntax with Franklin's
                ) |> x -> replace(x, "</pre>" => "</code></pre>")("<!DOCTYPE html>\n<HTML lang = \"en\">" *
                                                                  split(text, "</HEAD>")[2]) # Replaces weave code block syntax with Franklin's
    rm(f_name)
    return final
end

"""
    newnote(;title::String, descr::String, tags::Vector{String}, code=false)
"""
function newnote(;title::String, descr::String, tags::Vector{String}, code=false)
    path = joinpath(@__DIR__, "notes", replace(lowercase(title), " " => "-"))
    note = joinpath(path, "index.md")
    mkpath(path)
    touch(note)
    y = Dates.year(Dates.today())
    m = Dates.month(Dates.today())
    d = Dates.day(Dates.today())
    open(note, "w") do io
        write(io, """
        +++
        title = "$title"
        descr = "$descr"
        rss = "$descr"
        date = Date($y, $m, $d)
        hascode = $code
        tags = $(sort(tags))
        +++

        {{ notetags }}

        ## $title

        \\toc

        ### Subtitle
        """)
    end
end
