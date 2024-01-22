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

{{< detail "Wait, `arrayref`?" >}}
```julia
# for backward compat
arrayref(inbounds::Bool, A::Array, i::Int...) = Main.Base.getindex(A, i...)
```

> as of 1..11, `arrayref` is no longer a thing Julia knows about. `Array` is basically a first class `mutable struct` built on top of `Memory`. Initially we removed `arrayref` entirely, but it turns out that enough people were using it (mostly for dumb reasons) that we added a fallback to prevent code from breaking

cf. [#8](https://xlxs4.com/diary/#entry8)
{{< /detail >}}
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
{{< detail "Details" >}}
Note that you can't add rules to `DiffRules` directly.
The reason is `ForwardDiff` works by adding dispatches for the `DiffRules` rules; to do that, it reads the `DiffRules` tables containing all the rules. Doing, say, `DiffRules.@define_diffrule`, adds the rules *after* they've been read by `ForwardDiff`, so you get no dispatches for your custom rule.
You can also do something to add an additional dispatch of your function for values of type `ForwardDiff.Dual`: `myfunction(::ForwardDiff.Dual)`.
However, this is redundant and error-prone, while with `ForwardDiffChainRules` you can *re-use* the differentiation code defined in an existing `ChainRulesCore.frule` without having to re-code the diff rules
{{< /detail >}}
%%

Increase `VSCode -> Settings (UI) -> Terminal > Integrated: Scrollback` for larger history buffer in REPL
%%

`CSV.File` is multithreaded by default; see [here](https://csv.juliadata.org/stable/reading.html#ntasks)
%%

[`Pkg.activate(; temp=true)`](https://github.com/JuliaLang/Pkg.jl/blob/cc71837381da2569b0d8e9d2c6130a13f3f5b8f4/src/Pkg.jl#L526-L555): Create and activate a temporary environment that will be deleted when the julia process is exited
%%

Writing documentation [according to the field values of a type instance rather than just the type itself](https://docs.julialang.org/en/v1/manual/documentation/#Dynamic-documentation)
%%

Using [metaprogramming for docgen](https://docs.julialang.org/en/v1/manual/documentation/#Advanced-Usage)
%%

[`julia --help-hidden`](https://docs.julialang.org/en/v1/manual/command-line-interface/#command-line-interface)
%%

Use [`TimerOutputs.jl`](https://github.com/KristofferC/TimerOutputs.jl) for profiling together with Revise
{{< detail "Example usage" >}}
```julia
using TimerOutputs

# Create a TimerOutput, this is the main type that keeps track of everything.
const to = TimerOutput()

# Time a section code with the label "sleep" to the `TimerOutput` named "to"
@timeit to "sleep" sleep(0.02)

# Create a function to later time
rands() = rand(10^7)

# Time the function, @timeit returns the value being evaluated, just like Base @time
rand_vals = @timeit to "randoms" rands();

# Nested sections (sections with same name are not accumulated
# if they have different parents)
function time_test()
    @timeit to "nest 1" begin
        sleep(0.1)
        # 3 calls to the same label
        @timeit to "level 2.1" sleep(0.03)
        @timeit to "level 2.1" sleep(0.03)
        @timeit to "level 2.1" sleep(0.03)
        @timeit to "level 2.2" sleep(0.2)
    end
    @timeit to "nest 2" begin
        @timeit to "level 2.1" sleep(0.3)
        @timeit to "level 2.2" sleep(0.4)
    end
end

time_test()

# exception safe
function i_will_throw()
    @timeit to "throwing" begin
        sleep(0.5)
        throw(error("this is fine..."))
        print("nope")
    end
end

i_will_throw()

# Use disable_timer! to selectively turn off a timer, enable_timer! turns it on again
disable_timer!(to)
@timeit to "not recorded" sleep(0.1)
enable_timer!(to)

# Use @notimeit to disable timer and re-enable it afterwards (if it was enabled
# before)
@notimeit to time_test()

# Call to a previously used label accumulates data
for i in 1:100
    @timeit to "sleep" sleep(0.01)
end

# Can also annotate function definitions
@timeit to funcdef(x) = x

funcdef(2)

# Or to instrument an existing function:
foo(x) = x + 1
timed_foo = to(foo)
timed_foo(5)
```

```julia
julia> show(to) # Print the timings in the default way
────────────────────────────────────────────────────────────────────────
                            Time                    Allocations
                    ───────────────────────   ────────────────────────
Tot / % measured:        94.9s /   3.1%            115MiB /  76.6%

Section       ncalls     time    %tot     avg     alloc    %tot      avg
────────────────────────────────────────────────────────────────────────
sleep            101    1.22s   41.2%  12.1ms   12.6KiB    0.0%     128B
nest 2             1    704ms   23.7%   704ms   1.69KiB    0.0%  1.69KiB
level 2.2        1    402ms   13.5%   402ms      112B    0.0%     112B
level 2.1        1    302ms   10.2%   302ms      112B    0.0%     112B
throwing           1    503ms   16.9%   503ms      208B    0.0%     208B
nest 1             1    399ms   13.5%   399ms   2.31KiB    0.0%  2.31KiB
level 2.2        1    201ms    6.8%   201ms      112B    0.0%     112B
level 2.1        3   96.3ms    3.2%  32.1ms      640B    0.0%     213B
randoms            1    137ms    4.6%   137ms   88.1MiB  100.0%  88.1MiB
foo                1    375ns    0.0%   375ns     0.00B    0.0%    0.00B
funcdef            1    334ns    0.0%   334ns     0.00B    0.0%    0.00B
────────────────────────────────────────────────────────────────────────
```
{{< /detail >}}
%%

Use the new [Package Extensions](https://docs.julialang.org/en/v1.10/manual/code-loading/#man-extensions)
%%

The compiler will [decide against specializing](https://docs.julialang.org/en/v1/manual/performance-tips/#Be-aware-of-when-Julia-avoids-specializing) on `Type`, `Function`, `Vararg`. You can add a type parameter to force specialization.
[`Cthulhu`](https://github.com/JuliaDebug/Cthulhu.jl/issues/456), `JET` (through `@report_opt`) and `@code_warntype` can get confused by this.
This can also be a reason `StaticCompile` can fail due to dynamism while everything appears to be typestable.
[#21](https://xlxs4.com/diary/#entry21) should catch these correctly.
%%

[`AllocCheck.jl`](https://github.com/JuliaLang/AllocCheck.jl)
%%

Always prefix `abstract` `type`s with `Abstract`, e.g. `AbstractMyType`.
If its a parametric type, keep it as is (e.g. `Base.Complex` instead of `AbstractComplex`).
Be mindful of `Ref` vs `Refvalue`, too.
%%

`Base.@nospecializeinfer` was added (but not advertized in any way) in Julia 1.10.
You can check what it does in the [introducing PR](https://github.com/JuliaLang/julia/pull/41931).
An example of its use can be found in this [JLD2 PR](https://github.com/JuliaIO/JLD2.jl/pull/527).
You can use `SnoopCompile.@snoopi_deep` to figure out where to despecialize to cut down on time spent on time inference and make precompilation way more effective.
%%

Currently, `precompile` only caches results for type-inference, not other stages in code generation.
For that reason, efforts at reducing latency should be informed by measuring the amount of time spent on type-inference.
You can do that using [`SnoopCompile.@snoopi_deep`](https://timholy.github.io/SnoopCompile.jl/stable/snoopi_deep/).
%%

Argument standardization is a very important technique for reducing specilization: do `foo(x::X, y::Y)` instead of `foo(x, y)`.
{{< detail "Code" >}}
instead of
```julia
function foo(x, y)
    # some huge function, slow to compile,
    # and you'd prefer not to compile it many times
    # for different types of x and y
end
```
consider whether you can write it safely as
```julia
function foo(x::X, y::Y) # X and Y are concrete types
    # some huge function, but the concrete typing ensures
    # you only compile it once
end
# This allows you to still call it with any argument types
foo(x, y) = foo(convert(X, x)::X, convert(Y, y)::Y)
```
{{</ detail >}}
{{< detail "More" >}}
Part of the power of Julia is the ability to specify generic methods that "do the right thing" for a wide variety of types.
However, when you're doing a standard task, e.g., writing some data to a file, there's no reason to recompile your "`save`" method for a filename encoded as a `String`, and again for a `SubString{String}`, and for `SubstitutionString`, and so on: if `save` isn't sensitive to the precise encoding of the filename, it should be safe to instead convert all filenams to `String`, reducing the diversity of input arguments for expensive-to-compile methods.
{{< /detail >}}
%%

Specilization often improves runtime performance, but incurs extra inference and code-generation time costs.
Some times it can even hurt both runtime and compile time perfomance.
You can use [`pgdsgui`](https://timholy.github.io/SnoopCompile.jl/stable/pgdsgui/) for PGDS, aka, Profile-Guided DeSpecialization.
%%

The [SnoopCompile documentation](https://timholy.github.io/SnoopCompile.jl/stable/) is a great resource for improving performance and taking a peak at language internals.
%%

[`ProfileCanvas`](https://github.com/pfitzseb/ProfileCanvas.jl) is great for profiling work either inside VSCode or a Pluto notebook.
There's `@profview`, but also `@profview_allocs` to profile memory allocations.
%%

There are several reasons not to use higher order functions
{{< detail "More" >}}
1. Julia sometimes [doesn't properly specialize](https://docs.julialang.org/en/v1/manual/performance-tips/#Be-aware-of-when-Julia-avoids-specializing) higher order functions which [can be hard to reason about](https://github.com/JuliaLang/julia/issues/51423)
2. It complicates stacktraces by adding more wrapper functions where no real business logic happens, and stacktraces with anonymous functions are especially harder to read
3. It encourages closures, which are vulnerable to the [slow closure bug](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-captured) which has proven very hard to fix
4. The [recursive inference](https://discourse.julialang.org/t/failure-to-optimize-due-to-type-recursion/108568) issue
{{< /detail >}}
%%

The `mapfoldl`/`mapreduce` implementations have way too many layers.
It is very complicated, often slow, and often comes with inference problems.
%%

A way for finer grained control over what is considered to be API is speciliazing `getproperty`.
Everything that is then accessible through `getproperty` is considered to be API.
{{< detail "Commonly used example" >}}
```julia
module Package

const f = Internals.f
export f

module Internals
# everything else
end

end
```
{{< /detail >}}
%%

It'd be better if `==` errored instead of falling back to `===`, but that would [be breaking](https://github.com/JuliaLang/julia/issues/40717).
%%

A great resource for Julia internals is the `devdocs`: https://docs.julialang.org/en/v1.11-dev/devdocs/object/
%%

To enter `Pkg` mode without having to type `]` you can do `julia -E'using Pkg; pkg"status"'`
%%

A few things that are on master now:
- `pkg> add --weak/--extra Foo`
- `pkg> add` now adds compat entries for the added deps if the active env is a package
- Julia now prefers reading `Manifest-v{major}.{minor}.toml` over `Manifest.toml` so you can have version specific manifests
%%

[`OnlineStats`](https://github.com/joshday/OnlineStats.jl) is amazing
%%

`PartialStruct` intermediate types from `@code_warntype` is about constant propagation.
It means the compiler knows that some values are guaranteed to be constant, but other parts of the `struct` are not
%%

There is no limit to the number of uniquely parametric-typed fields in a `struct`, but it's more and more work for the compiler
%%

In Julia GitHub actions you might try to specify a version like `1.10-rc2` and get an error.
Remember, it needs to be in `~1.10.0-rc2` form
%%

{{< /diaryList >}}
