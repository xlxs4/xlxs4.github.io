<!-- RSS settings -->

@def website_title = "xlxs4"
@def website_description = "My personal website."
@def website_url = "https://xlxs4.github.io"
@def generate_rss = true

+++
# Exclude everything that is not explicitly included in _include
_include = ["_assets/", "_css/", "_libs/", "_layout/", "index.html", "404.md", "posts/", "about/", "about_site/", "research/", "another_me/", "images/"]
_exclude = if get(ENV, "FRANKLIN_OPTIMIZE", nothing) == "true"
        # ["_libs/highlight/highlight.min.js"]
        String[]
    else
        String[]
    end
ignore = [setdiff([isfile(x) ? x : x * "/" for x in readdir()], _include); _exclude]
+++



<!-- Theme specific options -->
<!-- @def title = "Max Koslowski" -->
@def sitename = "xlxs4"
@def author.name = "Orestis Ousoultzoglou"
@def author = "xlxs4"

<!-- Social icons -->
@def social = (
        github = "https://github.com/xlxs4",
        twitter = "https://twitter.com/orousoultzoglou"
    )

<!-- Logo -->
@def logo.mark = "\$"
@def logo.text = "cd /home/xlxs4"

<!-- Menu -->
@def menu = [
        (name = "posts", url = "/posts/"),
        (name = "about", url = "/about/"),
    ]


\newcommand{\codetoggle}[1]{
~~~
<div class="toggle-code-wrap" style="position:relative">
<input id="{{ unique_id new }}" type="checkbox" checked=true">
<label for="{{ unique_id }}" class="switch">
  <span class="slider round"></span>
</label>
<div class="toggle-code-new">
~~~
`````julia
!#1
`````
~~~
</div>
<div class="toggle-code-old">
~~~
`````julia-old
!#1
`````
~~~
</div>
</div>
~~~
}
