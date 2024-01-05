---
title: Logbook
layout: logbook
url: "/logbook/"
summary: logbook
---

## 05-01-2024

`invalidations.jl`:

```julia
using SnoopCompileCore

invs = @snoopr using ADCSSims;

using SnoopCompile

trees = invalidation_trees(invs);
methinvs = trees[end];
```

```julia-repl
julia> length(uinvalidated(invs))
6594
```