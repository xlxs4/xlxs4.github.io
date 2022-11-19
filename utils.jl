using Franklin, Dates

function hfun_bar(vname)
    val = Meta.parse(vname[1])
    return round(sqrt(val); digits=2)
end

function hfun_m1fill(vname)
    var = vname[1]
    return Franklin.pagevar("index", var)
end

function hfun_jlinsert(arg)
    arg = first(arg)
    if arg == "social-icons"
        return social_icons()
    elseif arg == "read-time"
        return read_time()
    elseif arg == "pagetags"
        return pagetags()
    else
        error("unknown argument arg = $arg")
    end
end

function read_time()
    src = joinpath(Franklin.PATHS[:folder], Franklin.FD_ENV[:CUR_PATH])
    nwords = length(split(read(src, String)))
    nmin = ceil(Int, nwords / 220)
    return "$(nmin) minute$(nmin > 1 ? "s" : "")"
end

function social_icons()
    icons = locvar("social")
    isempty(icons) && return ""
    io = IOBuffer()
    println(io, "<div class=\"social-icons\">")
    for (name, url) in pairs(icons)
        name = string(name)
        svg = Franklin.convert_html("{{ svg $(name) }}")
        svg = strip(svg)
        isempty(svg) && (@warn "could not find svg icon for social.$name, skipping"; continue)
        aref = """&nbsp; <a href="$(url)" title="$(name)">$(svg)</a> &nbsp;"""
        println(io, aref)
    end
    println(io, "</div>")
    r = Franklin.convert_html(String(take!(io)))
    return r
end

function pagetags()
    io = IOBuffer()
    for tag in Franklin.locvar("tags")
        print(io, "<span class=\"tag\"><a href=\"/tag/$(tag)\">$(tag)</a></span>")
    end
    return strip(String(take!(io)))
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

function hfun_definetagtitle()
    return hfun_define(["title", "#$(locvar("fd_tag"))"])
end

function hfun_define(arg)
    vname = arg[1]
    vdef = repr(get(arg, 2, nothing))
    Franklin.set_vars!(Franklin.LOCAL_VARS, [vname => vdef, ]) # TODO: Use set_var! instead ???
    return ""
end
function hfun_undef(arg)
    arg = arg[1]
    haskey(Franklin.LOCAL_VARS, arg) && delete!(Franklin.LOCAL_VARS, arg)
    return ""
end

function hfun_list_posts(folders)
    pages = String[]
    root = Franklin.PATHS[:folder]
    for folder in folders
        startswith(folder, "/") && (folder = folder[2:end])
        cd(root) do
            foreach(((r, _, fs),) ->  append!(pages, joinpath.(r, fs)), walkdir(folder))
        end
    end
    filter!(x -> endswith(x, ".md"), pages)
    for i in eachindex(pages)
        pages[i] = replace(pages[i], r"\.md$"=>"")
    end
    return list_pages_by_date(pages)
end

function hfun_svg(arg)
    name = arg[1]
    svg = Franklin.convert_html("{{ define svg.$(name) }} {{ insert svg.html }} {{ undef svg.$(name) }}")
    # delete html comments
    svg = strip(replace(strip(svg), r"^<!--.*-->$"m => ""))
    return svg
end

function list_pages_by_date(pages)
    # Collect required information from the pages
    items = Dict{Int,Any}()
    for page in pages
        date = pagevar(page, "date")
        date === nothing && error("no date found on page $page")
        date = Date(date)
        title = something(pagevar(page, "markdown_title"), pagevar(page, "title"))
        title === nothing && error("no title found on page $page")
        title = Franklin.md2html(title; stripp=true)
        stitle = something(pagevar(page, "title"), title) # for sorting (no <code> etc)
        url = get_url(page)
        push!(get!(items, year(date), []), (date=date, title=title, stitle=stitle, url=url))
    end
    # Write out the list
    io = IOBuffer()
    for k in sort!(collect(keys(items)); rev=true)
        year_items = items[k]
        # Sort primarily by date (in reverse) and secondary by title
        lt = (x, y) -> x.date == y.date ? x.stitle > y.stitle : x.date < y.date
        sort!(year_items; lt=lt, rev=true)
        print(io, """
            <div class="posts-group">
              <div class="post-year">$(k)</div>
              <ul class="posts-list">
            """)
        for item in year_items
            print(io, """
                    <li class="post-item">
                      <a href=\"$(item.url)\">
                        <span class="post-title">$(item.title)</span>
                        <span class="post-day">$(Dates.format(item.date, "d u"))</span>
                      </a>
                    </li>
                """)
        end
        print(io, """
              </ul>
            </div>
            """)
    end
    return String(take!(io))
end

hfun_taglist() = list_pages_by_date(globvar("fd_tag_pages")[locvar(:fd_tag)])

function hfun_get_url()
    Franklin.get_url(Franklin.locvar("fd_rpath"))
end

let counter = 0
    global function hfun_unique_id(n=nothing)
        if n !== nothing
            counter += 1
        end
        return "unique-id-$(counter)"
    end
end

function hfun_markdown2html(arg)
    arg = first(arg)
    if arg == "website_description" || arg == "title" || arg == "markdown_title"
        str = locvar(arg)
        @assert str !== nothing
        return Franklin.md2html(str; stripp=true)
    else
        error("unknown argument arg = $arg")
    end
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
