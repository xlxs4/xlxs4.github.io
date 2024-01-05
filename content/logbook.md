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

```julia
julia> using JET
julia> @report_opt main!()
═════ 535 possible errors found ═════
```
