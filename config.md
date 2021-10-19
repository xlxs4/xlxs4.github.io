<!-- RSS settings -->

@def website_title = "Max Koslowski"
@def website_description = "My personal academic website. I am a PhD student @IndEcol developing sustainable development pathways. Sometimes I post about research, PhD life, and other topics."
@def website_url = "https://maximikos.github.io"
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
@def sitename = "Max Koslowski"
@def author.name = "Max Koslowski"
@def author = "Max Koslowski"

<!-- Social icons -->
@def social = (
        ssh = "https://www.ntnu.edu/employees/maximilian.koslowski",
        linkedin = "https://www.linkedin.com/in/maximilian-koslowski-711365143/",
        github = "https://github.com/maximiko",
        twitter = "https://twitter.com/maximikos"
    )

<!-- Logo -->
@def logo.mark = "\$"
@def logo.text = "cd /home/max"

<!-- Menu -->
@def menu = [
        (name = "posts", url = "/posts/"),
        (name = "research", url = "/research/"),
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
