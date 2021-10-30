+++
date = "2021-10-20"
title = "What do you do?"
var"layout-post" = nothing
tags = ["welcome", "topic"]
rss = "This is a stub for a lengthier article on what my PhD is about."

# Dependent variables
website_description = replace(rss, "*" => "")
rss_pubdate = Date(date)
+++

~~~
<h1><a href="{{ get_url }}">{{ markdown2html title }}</a></h1>
~~~

This is a stub for a lengthier article on what my PhD is about.

Only briefly, I can already tell that I will research pathways for how the UN Sustainable Development Goals can be achieved. For that I will work at the intersection of two modelling families: input-output analysis and integrated assessment modelling. The former was pioneered by Wassily Leontief and is used for all sorts of economic analysis but also environmental footprinting; the latter describes an approach where large-scale models are put together to model different compartments of the Earth system, and which are frequently employed for analyses such as those shown in the IPCC reports.