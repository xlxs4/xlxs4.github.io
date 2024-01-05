---
title: Logbook
layout: logbook
url: "/logbook/"
summary: logbook
---

## 05-01-2024

### Initial

Unique invalidations:

`invalidations.jl`:

<summary>`invalidations.jl`</summary>
<details>

```julia
using SnoopCompileCore

invs = @snoopr using ADCSSims;

using SnoopCompile

trees = invalidation_trees(invs);
methinvs = trees[end];
```

</details>

```julia-repl
julia> length(uinvalidated(invs))
6594
```

