---
title: Diary
layout: diary
url: "/diary/"
summary: diary
---

1. There's a guide on writing Julia documentation in the [manual](https://docs.julialang.org/en/v1/manual/documentation/#Writing-Documentation)
2. `module`s automatically contain `using Core`, `using Base`, and definitions of `eval` and `include`. If you only want `Core` to be imported, you can use `baremodule` instead. If you don't even want `Core`, you can do `Module(:MyModuleName, false, false)` and `Core.@eval` code into it (`@eval MyModuleName add(x, y) = $(+)(x, y)`)
