---
title: Diary
layout: diary
url: "/diary/"
summary: diary
---

1. There's a guide on writing Julia documentation in the [manual](https://docs.julialang.org/en/v1/manual/documentation/#Writing-Documentation)
2. `module`s automatically contain `using Core`, `using Base`, and definitions of `eval` and `include`. If you only want `Core` to be imported, you can use `baremodule` instead. If you don't even want `Core`, you can do `Module(:MyModuleName, false, false)` and `Core.@eval` code into it (`@eval MyModuleName add(x, y) = $(+)(x, y)`)
3. `julia --project` is the same as `julia --project=.`
4. Specialized versions of methods for specific types are `MethodInstance`s, an internal type in `Core.Compiler`
5. `Base.arrayref` in, e.g., `@code_typed` is from [boot.jl](https://github.com/JuliaLang/julia/blob/e8f89682d7b434f1159626a213756b3691f48d03/base/boot.jl#L962)
    ```julia
    # for backward compat
    arrayref(inbounds::Bool, A::Array, i::Int...) = Main.Base.getindex(A, i...)
    ```
    TODO: Why was the `arrayref`/`arrayset` interface replaced with the `getindex`/`setindex` interface? Probably related to #6
6. https://docs.julialang.org/en/v1/devdocs/boundscheck/#Propagating-inbounds TODO
