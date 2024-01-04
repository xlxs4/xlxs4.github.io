---
title: Diary
layout: diary
url: "/diary/"
summary: diary
---

{{< diaryList >}}
There's a guide on writing Julia documentation in the [manual](https://docs.julialang.org/en/v1/manual/documentation/#Writing-Documentation)
%%

`module`s automatically contain `using Core`, `using Base`, and definitions of `eval` and `include`. If you only want `Core` to be imported, you can use `baremodule` instead. If you don't even want `Core`, you can do `Module(:MyModuleName, false, false)` and `Core.@eval` code into it (`@eval MyModuleName add(x, y) = $(+)(x, y)`)
%%

`julia --project` is the same as `julia --project=.`
%%

Specialized versions of methods for specific types are `MethodInstance`s, an internal type in `Core.Compiler`
%%

`Base.arrayref` in, e.g., `@code_typed` is from [boot.jl](https://github.com/JuliaLang/julia/blob/e8f89682d7b434f1159626a213756b3691f48d03/base/boot.jl#L962)

```julia
# for backward compat
arrayref(inbounds::Bool, A::Array, i::Int...) = Main.Base.getindex(A, i...)
```

> as of 1..11, `arrayref` is no longer a thing Julia knows about. `Array` is basically a first class `mutable struct` built on top of `Memory`. Initially we removed `arrayref` entirely, but it turns out that enough people were using it (mostly for dumb reasons) that we added a fallback to prevent code from breaking

cf. 8
%%

https://docs.julialang.org/en/v1/devdocs/boundscheck/#Propagating-inbounds TODO
%%

Calls annotated `::Union{}` do not return
%%

https://hackmd.io/@vtjnash/rkzazi7an TODO
%%

In REPL, `using REPL; ModuleName <Alt+m>`: ["Set mod as the default contextual module in the REPL, both for evaluating expressions and printing them."](https://docs.julialang.org/en/v1/stdlib/REPL/#Changing-the-contextual-module-which-is-active-at-the-REPL)
%%

`@allocated`
%%

If you want to add custom diff rules for [`ForwardDiff.jl`](https://github.com/JuliaDiff/ForwardDiff.jl), use [ForwardDiffChainRules.jl](https://github.com/ThummeTo/ForwardDiffChainRules.jl) to [add a ForwardDiff dispatch for an already existing frule](https://github.com/ThummeTo/ForwardDiffChainRules.jl/blob/decd2c40a2eea4a1ae6aea9852a35ee2f7a22575/README.md?plain=1#L28).
Note that you can't add rules to `DiffRules` directly.
The reason is `ForwardDiff` works by adding dispatches for the `DiffRules` rules; to do that, it reads the `DiffRules` tables containing all the rules. Doing, say, `DiffRules.@define_diffrule`, adds the rules *after* they've been read by `ForwardDiff`, so you get no dispatches for your custom rule.
You can also do something to add an additional dispatch of your function for values of type `ForwardDiff.Dual`: `myfunction(::ForwardDiff.Dual)`.
However, this is redundant and error-prone, while with `ForwardDiffChainRules` you can *re-use* the differentiation code defined in an existing `ChainRulesCore.frule` without having to re-code the diff rules.
%%

{{< /diaryList >}}
