---
title: Logbook
layout: logbook
url: "/logbook/"
summary: logbook
---

## 05-01-2024

### Initial

Unique invalidations:

{{< detail "`invalidations.jl`" >}}
```julia
using SnoopCompileCore

invs = @snoopr using ADCSSims;

using SnoopCompile

trees = invalidation_trees(invs);
methinvs = trees[end];
```
{{< /detail >}}

```julia-repl
julia> length(uinvalidated(invs))
6594
```

