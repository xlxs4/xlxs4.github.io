+++
date = "2021-10-20"
title = "What do you do?"
var"layout-post" = nothing
tags = ["welcome", "topic"]
rss = "This is a stub for a lengthier article on what my thesis is about."

# Dependent variables
website_description = replace(rss, "*" => "")
rss_pubdate = Date(date)
+++

~~~
<h1><a href="{{ get_url }}">{{ markdown2html title }}</a></h1>
~~~

This is a stub for a lengthier article on what my thesis is about.