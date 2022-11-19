using Franklin, Dates

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

function hfun_taglist()
    tag = Franklin.locvar(:fd_tag)::String
    rpaths = Franklin.globvar("fd_tag_pages")[tag]
    return write_notes(rpaths)
end

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
