---
title: Scratch
layout: scratch
url: "/scratch/"
summary: scratch
---

## 05-01-2024

### Initial

{{< detail "`invalidations.jl`" >}}
```julia
using SnoopCompileCore

invs = @snoopr using ADCSSims;

using SnoopCompile

trees = invalidation_trees(invs);
methinvs = trees[end];
```
{{< /detail >}}

```julia
julia> length(uinvalidated(invs))
6594
```

{{< detail "`main.jl`" >}}
```julia
using ADCSSims
using StaticArrays: SVector
using CSV: CSV
using DataFrames: DataFrame

function init(config::ADCSSims.config.Config, schedule_df::ADCSSims.DataFrame)
    vecs = generate_orbit_data(
        config.simulation.jd,
        ADCSSims.get_total_time(schedule_df, config.simulation.dt),
        config.simulation.dt,
        [
            config.orbit.mean_motion,
            config.orbit.eccentricity,
            config.orbit.inclination,
            config.orbit.RAAN,
            config.orbit.argument_of_perigee,
            config.orbit.mean_anomaly,
            config.orbit.bstar,
        ],
    )

    egm2008 = ADCSSims.GravityModels.load(
        ADCSSims.SatelliteToolboxGravityModels.IcgemFile,
        ADCSSims.SatelliteToolboxGravityModels.fetch_icgem_file(config.gravity.model),
    )

    P = Matrix{Float64}(undef, config.gravity.n_max_dP + 1, config.gravity.n_max_dP + 1)
    dP = Matrix{Float64}(undef, config.gravity.n_max_dP + 1, config.gravity.n_max_dP + 1)

    PD = PDController(config.controller.Kp, config.controller.Kd)
    sensors = (Magnetometer(), NadirSensor(), StarTracker(), SunSensor())

    inertia_matrix = ADCSSims.SMatrix{3,3}(hcat(config.simulation.inertia_matrix...))
    SimParams = SimulationParams(
        PD,
        config.simulation.qtarget,
        config.simulation.wtarget,
        egm2008,
        config.gravity.n_max_dP,
        P,
        dP,
        config.actuators.msaturation,
        config.actuators.rw_max_torque,
        sensors,
        inertia_matrix,
        config.simulation.dt,
        config.disturbances.rmd,
        deg2rad(config.logging.pointing_epsilon),
        deg2rad(config.logging.ang_vel_epsilon),
        config.geometry.face_areas,
        config.geometry.dimensions,
        config.geometry.drag_coeff,
        config.geometry.center_of_mass,
    )

    niter = length(vecs.tvector)
    state_history = Vector{Tuple{Vector{Float64},QuaternionF64}}(undef, niter)
    state_history[1] = (config.simulation.w, one(QuaternionF64))
    τw = Vector{Vector{Float64}}(undef, niter)
    τsm = Vector{Vector{Float64}}(undef, niter)
    τgrav = Vector{Vector{Float64}}(undef, niter)
    τrmd = Vector{Vector{Float64}}(undef, niter)
    rw_velocity = Vector{Vector{Float64}}(undef, niter)

    RW = ReactionWheel(;
        J=config.simulation.rw_inertia * ADCSSims.I(3),
        bias=ADCSSims.rpm2rad(config.actuators.rw_bias),
        Ksat=config.controller.rw_gain,
        w=ADCSSims.RWAngularVelocity(SVector{3}(42 * ones(3))),
        maxtorque=config.actuators.rw_max_torque,
    )
    mode_quat = Vector{QuaternionF64}(undef, niter)
    sensor_availability = Vector{Vector{Bool}}(undef, niter)
    attitude_error = Vector{Float64}(undef, niter)

    SimContext = SimulationContext(
        state_history,
        attitude_error,
        τw,
        τsm,
        τgrav,
        τrmd,
        vecs.mag_gcrf,
        RW,
        rw_velocity,
        Ref(false),
        Ref(-1),
        mode_quat,
        Ref(zeros(3)),
        sensor_availability,
    )

    curindex = 1

    return SimParams, SimContext, vecs, curindex
end

function main!(
    config_path="config.toml", schedule_path="schedule.csv", output_path="data.csv"
)
    schedule_df = parsefile(schedule_path)
    config = parsefile(config_path)

    SimParams, SimContext, vecs, curindex = init(config, schedule_df)

    run_adcs_modes!(SimParams, SimContext, schedule_df, vecs, curindex)

    q = [s[2] for s in SimContext.state]
    sun_eci = vecs.sun_pos_gcrf
    nadir_eci = -ADCSSims.normalize.(vecs.r_gcrf)
    qbody2sun = [
        align_frame_with_vector(
            rotvec(sun_eci[i], q[i]),
            rotvec(nadir_eci[i], q[i]),
            config.output.sun_q_primary_axis,
            config.output.sun_q_secondary_axis,
        ) for i in eachindex(q)
    ]

    titles = ("Magnetometer", "Nadir Sensor", "Star Tracker", "Sun Sensor")
    sensor_avail = SimContext.sensor_availability[1:(end - 1)]

    n = config.logging.log_every_n_steps
    jd_values = vecs.epochs[1:n:end]

    coeff1 = [q[1] for q in qbody2sun[1:n:end]]
    coeff2 = [q[2] for q in qbody2sun[1:n:end]]
    coeff3 = [q[3] for q in qbody2sun[1:n:end]]
    coeff4 = [q[4] for q in qbody2sun[1:n:end]]

    return nothing
end
```
{{< /detail >}}


{{< detail "`@benchmark`" >}}
```julia
julia> using BenchmarkTools
julia> @benchmark main!()
BenchmarkTools.Trial: 2 samples with 1 evaluation.
 Range (min … max):  4.287 s …    4.661 s  ┊ GC (min … max):  7.60% … 16.29%
 Time  (median):     4.474 s               ┊ GC (median):    12.13%
 Time  (mean ± σ):   4.474 s ± 263.970 ms  ┊ GC (mean ± σ):  12.13% ±  6.15%

  █                                                        █  
  █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
  4.29 s         Histogram: frequency by time         4.66 s <

 Memory estimate: 2.18 GiB, allocs estimate: 51344590.
```
{{< /detail >}}

{{< detail "`@report_opt`" >}}
```julia
julia> using JET
julia> @report_opt main!()
═════ 535 possible errors found ═════
```
{{< /detail >}}

### parsefile

No invalidations

{{< detail "`@benchmark`" >}}
```julia
julia> @benchmark parsefile("schedule.csv")
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  78.333 μs …  4.253 ms  ┊ GC (min … max): 0.00% … 61.99%
 Time  (median):     79.875 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   83.861 μs ± 92.691 μs  ┊ GC (mean ± σ):  1.74% ±  1.55%

   ▃▆▇█▇▆▅▄▃▂▁   ▂▃▃▄▄▄▃▃▂▂▁   ▁ ▁▁▁▁▁▂▁▂▂▁▁▁                 ▂
  ▇███████████████████████████████████████████▇▇█▇▇▇▇▇█▇▇▇▆▅▆ █
  78.3 μs      Histogram: log(frequency) by time      94.2 μs <

 Memory estimate: 28.47 KiB, allocs estimate: 421.
```
{{< /detail >}}

{{< detail "`@benchmark`" >}}
```julia
julia> @report_opt parsefile("schedule.csv")
═════ 1 possible error found ═════
┌ parsefile(path::String) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/io.jl:8
│┌ parsefile(path::String; kwargs::@Kwargs{}) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/io.jl:10
││ runtime dispatch detected: parsefile(%99::Val, path::String)::Any
```
{{< /detail >}}

This is due to

```julia
function parsefile(path::AbstractString; kwargs...)
    ext = lowercase(splitext(path)[2][2:end])
    return parsefile(Val(Symbol(ext)), path; kwargs...)
end
```

and, specifically,

```julia
return parsefile(Val(Symbol(ext)), path; kwargs...)
```

Alternative #1: have `parsefile` extract the extension and use either `if`-`else` or indexing a `const Dict` to return `parsecsv, parseply`, etc.
Alternative #2: use a polymorphic approach; do static dispatch on types, each associated with a file extension (e.g. `CSVFile`, `PLYFile`)

If we ever wish to move to a structure that is easier to modify by a third user, we can implement a registry pattern of sorts.

Turns out that `@report_opt CSV.File(path)` yields a bajillion errors on its own.
At least we're not dispatching on `Val` now.

### get_total_time

{{< detail "`@report_opt`" >}}
```julia
julia> @report_opt ADCSSims.get_total_time(schedule_df, config.simulation.dt)
═════ 6 possible errors found ═════
┌ get_total_time(df::DataFrames.DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:36
│┌ sum(a::Base.SkipMissing{T} where T<:(AbstractVector)) @ Base ./reduce.jl:564
││┌ sum(a::Base.SkipMissing{T} where T<:(AbstractVector); kw::@Kwargs{}) @ Base ./reduce.jl:564
│││┌ sum(f::typeof(identity), a::Base.SkipMissing{T} where T<:(AbstractVector)) @ Base ./reduce.jl:535
││││┌ sum(f::typeof(identity), a::Base.SkipMissing{T} where T<:(AbstractVector); kw::@Kwargs{}) @ Base ./reduce.jl:535
│││││┌ mapreduce(f::typeof(identity), op::typeof(Base.add_sum), itr::Base.SkipMissing{T} where T<:(AbstractVector)) @ Base ./missing.jl:283
││││││┌ eltype(x::SparseArrays.ReadOnly{T, 1, V} where {T, V<:AbstractVector{T}}) @ SparseArrays /Users/julia/.julia/scratchspaces/a66863c6-20e8-4ff4-8a62-49f30b1f605e/agent-cache/default-honeycrisp-HL2F7YQ3XH.0/build/default-honeycrisp-HL2F7YQ3XH-0/julialang/julia-release-1-dot-10/usr/share/julia/stdlib/v1.10/SparseArrays/src/readonly.jl:17
│││││││ runtime dispatch detected: eltype(%1::AbstractVector)::Any
││││││└────────────────────
┌ get_total_time(df::DataFrames.DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:36
│ runtime dispatch detected: ADCSSims.sum(%9::Base.SkipMissing{T} where T<:(AbstractVector))::Any
└────────────────────
┌ get_total_time(df::DataFrames.DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:38
│ runtime dispatch detected: (%10::Any ADCSSims.:/ dt::Float64)::Any
└────────────────────
┌ get_total_time(df::DataFrames.DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:38
│ runtime dispatch detected: ADCSSims.round(%33::Any)::Any
└────────────────────
┌ get_total_time(df::DataFrames.DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:38
│ runtime dispatch detected: (%34::Any ADCSSims.:* dt::Float64)::Any
└────────────────────
┌ get_total_time(df::DataFrames.DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:39
│ runtime dispatch detected: Core.kwcall(%36::@NamedTuple{digits::Int64}, ADCSSims.round, %35::Any)::Any
└────────────────────
```
{{< /detail >}}

Adding a `collect` just shifted the type instability to it and then back to `sum`:

{{< detail "`@report_opt`" >}}
```julia
julia> @report_opt ADCSSims.get_total_time(schedule_df, config.simulation.dt)
═════ 6 possible errors found ═════
┌ get_total_time(df::DataFrame, dt::Float64) @ Main ./REPL[17]:2
│ runtime dispatch detected: collect(%9::Base.SkipMissing{T} where T<:(AbstractVector))::Vector
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ Main ./REPL[17]:2
│ runtime dispatch detected: sum(%10::Vector)::Any
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ Main ./REPL[17]:4
│ runtime dispatch detected: (%11::Any / dt::Float64)::Any
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ Main ./REPL[17]:4
│ runtime dispatch detected: round(%34::Any)::Any
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ Main ./REPL[17]:4
│ runtime dispatch detected: (%35::Any * dt::Float64)::Any
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ Main ./REPL[17]:5
│ runtime dispatch detected: Core.kwcall(%37::@NamedTuple{digits::Int64}, round, %36::Any)::Any
```
{{< /detail >}}

Cutting `skipmissing` doesn't help much:

{{< detail "`@report_opt`" >}}
```
julia> @report_opt ADCSSims.get_total_time(schedule_df, config.simulation.dt)
═════ 5 possible errors found ═════
┌ get_total_time(df::DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:36
│ runtime dispatch detected: ADCSSims.sum(%1::AbstractVector)::Any
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:38
│ runtime dispatch detected: (%2::Any ADCSSims.:/ dt::Float64)::Any
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:38
│ runtime dispatch detected: ADCSSims.round(%25::Any)::Any
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:38
│ runtime dispatch detected: (%26::Any ADCSSims.:* dt::Float64)::Any
└────────────────────
┌ get_total_time(df::DataFrame, dt::Float64) @ ADCSSims /Users/xlxs4/GitHub/ADCSSims.jl/src/utils.jl:39
│ runtime dispatch detected: Core.kwcall(%28::@NamedTuple{digits::Int64}, ADCSSims.round, %27::Any)::Any
└────────────────────
```
{{< /detail >}}

Seems like the compiler isn't able to compile an instance where `df[!, "duration"]` is a `Vector{Float64}`.
Instead of being more explicit, let's remove the barrier by directly passing a vector to the method instead of the whole `DataFrame`:

{{< detail "`@report_opt`" >}}
```julia
julia> @report_opt ADCSSims.get_total_time(schedule_df[!, "duration"], config.simulation.dt)
No errors detected
```
{{< /detail >}}
