---
author: Orestis Ousoultzoglou
title: 'Juliasim Model Optimizer'
date: 2022-12-12T00:19:31+02:00
tags: ["julia", "modeling", "sciml"]
math: true
---


[JuliaSim](https://juliahub.com/products/juliasim/) is a cloud-hosted platform for physical simulation.
It combines a vast array of bleeding edge [SciML](https://sciml.ai/) techniques, acausal equation-based digital twin modeling and simulation and is powered by the [Julia](https://julialang.org/) programming language.
It is preview-only software in the time of writing this post (December 2022).

JuliaSim produces surrogates of blackbox (and regular) dynamical systems using Continuous Time Echo State Networks [^1].
This technique allows, amongst other features, for implicit training in parameter space to stabilize the ill-conditioning present in stiff systems.

You can leverage these surrogates to accelerate the process and there's a variety of techniques for quantifying uncertainty and noise (see the virtual populations below).
You can use JuliaSim for parameter estimation and optimal control, which is what this post is about.
There's the so-called [Model Library](https://help.juliahub.com/juliasim/stable/ModelLibrary/), a collection of acausal (equation-based) components with pre-trained surrogates of models that are ready to use.
You can thus discover and import/exchange various models, and combine yours with pre-built models and digital twins.
Lastly, there's specialized numerical environments available for use upon demand.
Everything can happen on the JuliaHub cloud-based IDE.

If you want to build models, you can use the pre-made model libraries, e.g. [CellMLPhysiome.jl](https://help.juliahub.com/CellMLPhysiome/dev/) and [SBMLBioModels.jl](https://help.juliahub.com/SBMLBioModels/stable/).
You can use the [Catalyst.jl](https://github.com/SciML/Catalyst.jl) and [ModelingToolkit.jl](https://github.com/SciML/ModelingToolkit.jl) GUIs.
If you want to generate models using existing data, you can use a Digital Twin generator.
If you want to generate data using existing models, you can use a Surrogatizer and more.

### Introduction

The Model Optimizer is a Julia package available on the JuliaHub platform named `JuliaSimModelOptimizer`.
It contains methodology to perform model calibration and analysis inside an HPC environment in a user-friendly manner.
It's a robust and automated framework to scale large and complex models.

- If you want to build models, you can use JuliaSim's pre-made model libraries, as well as Catalyst and ModelingToolkit GUIs
- If you already have data, but no models, you can use the Digital Twin Generator
- If you already have models, but no data, you can use the Surrogatizer, Controller Builder, Codepiler, and various Proprietary Solvers
- If you need to fit data to models, you can use the Online Digital Twin, as well as the **Model Optimizer**

## Model Calibration

A typical model calibration pipeline to quickly convert models and data into calibrated systems with quantified uncertainities looks like the following:

1. First, simulate a parameter combination $\theta_i$ somewhere in the parameter space. Feed the parameters in the model, which outputs the model prediction for $\theta_i$.
2. Then collect (experimental) data for the same $\theta_i$ combinations (or vice-versa).
3. Lastly, combine model prediction and observed data to tune $\theta_i$ so that the prediction better fits the data, using a loss (usually error) function for optimization.

### Nonlinear Model Calibration

There's three main challenges that can arise if trying to calibrate a model when nonlinearity is introduced.
Nonlinear calibration is significantly harder, mainly because:

1. Nonlinear optimization can easily hit local minima.
2. Optimization procedures/algorithms are usually serial.
3. Model parameters can be unidentifiable from data.

To address the first challenge — how do we avoid local optima?
We can leverage specialized methods from Model Optimizer.
There's a variety of calibration methods available.
Which one to choose is going to ultimately depend on the specific problem at hand.
There's a variety of robust techniques available to avoid local optima, such as single shooting, multiple shooting (data and simulation), collocation (Noise robust, spline, Radau point), combined "mixture of experts" strategies, etc.

To address the second challenge — how do we do effective parallelism on a particular strategy that we're deploying?
How do we leverage large-scale cloud compute systems to solve these problems?
Proper strategy selection plays a big role here.
You can enable parallelism with certain calibration strategies.
Multiple shooting is one example that can be parallelized, so if it's an effective strategy for the case at hand it can help us break out the serial of execution.
Note that some of the available techniques are more amenable to distributed compute.

Lastly, to address the third challenge — how do we quantify the uncertainty in the fit?
The answer is by introducing a Model Optimizer concept called Virtual Populations.
Virtual Populations are sets of parameters which sufficiently fit all trials, all observations.
A trial is a different variation of the model which can be ran, it describes an experiment.
It's a data observation.
We can have collections of trials, multiple trials.
Having a collection allows us to define multi-simulation optimization problems.
We'll see what this means in practice later on in this post, it essentially is a a way to synthesize data to repeat stochastic optimization to better understand the parameter landscape and be able to quantify the uncertainty of global optima in the conditions observed.

## Model Paradigms

So we've seen how model calibration could work at a high level, we've taken a look at some problems that might arise in nonlinear calibration,
and how Model Optimizer tackles these problems, including the concept of virtual populations which is also very helpful for another reason we'll look into below.
Before we get to really see how all of this could work in action, we need to discuss different modeling paradigms.
How do we create these simulations and have something that we can apply these Model Optimizer techniques to?

### Causal Modeling

In causal modeling, we describe the causal mechanisms of a system.
The way that this works is we provide clear rules for the interactions between functional blocks.
Here we're worried about the flow of computation — one could draw an analogy linking causal modeling with the imperative programming paradigm.

### Acausal Modeling

Instead, in acausal modeling we describe the behavior and the properties of the model components.
Then, the models are built up out of the composition of the components.
The overall dynamics of the model fall out of the cumulative behavior of the composition.
This is more akin to the declarative programming paradigm.
We only worry about the connections and the relationships between these functional blocks — we don't want to frame the problem particularly in terms of the flow of computation that has to happen, we want to think instead about individual components and the relationships between one another.

There's some key advantages to following the acausal modeling paradigm.
Acausal modeling can be **expressive**.
This allows us to think like scientists and engineers instead of being limited in framing the problem only in terms of how to compute the results. Equation-oriented modeling allows for detailed multiphysics descriptions without the need to reason about causality.
Acausal modeling can be **concise**.
This can allow us to quickly build large-scale models by connecting well-tested component models.
Acausal modeling can be **reusable**.
We can bring these well-tested components and entire component models with us to build new systems.

## Modeling Toolkit

[ModelingToolkit.jl](https://mtk.sciml.ai/dev/) is a Julia acausal modeling framework and it will allow us to be expressive and concise when we write our DE models.
It will also enable us to reuse these models so we can automatically rearrange equations for better stability.
We're gonna get some extra perks here.
We're gonna get optimal code by default, without having to worry about the most optimal way to compute these things — we just worry about the mechanics and then we get the optimal code for free.
The code will also be parallelizable by default.

### Description

ModelingToolkit is a modeling language.
It can do both symbolic and numeric computation.
It is highly performant and parallel.
It is extendable because it brings ideas from symbolic CAS and causal/acausal equation-based modeling frameworks, but also because it's built in Julia and it's easy to pry into the source and modify as we please.

The high-level modeling process is as follows: the model can be input as a high-level description.
Then, the model is analyzed and enhanced through symbolic preprocessing.
ModelingToolkit allows for automatic transformations, such as index reduction, to be applied before solving in order to easily handle equations that could not have been solved without some sort of symbolic intervention.

### Features

- Causal and acausal modeling ([Simulink](https://www.mathworks.com/products/simulink.html)/[Modelica](https://modelica.org/modelicalanguage.html)) .
- Automated model transformation, simplification, and composition.
- Automatic conversion of numerical models into symbolic models.
- Composition of models through the components, a lazy connection system, and tools for expanding/flattening
- Pervasive parallelism in symbolic computations and generated functions.
- Transformations like alias elimination and tearing of nonlinear systems for efficiently numerically handling large-scale systems of equations.
- The ability to use the entire [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl) CAS as part of the modeling process.
- Import models from common formats like [SBML](https://sbml.org/), [CellML](https://www.cellml.org/), [BioNetGen](https://bionetgen.org/), and more.
- Extendability: the whole system is written in pure [Julia](https://julialang.org/), so adding new functions, simplification rules, and model transformations has no barrier.

### Equation Types

- ODEs
- DEs
- PDEs
- Nonlinear systems
- Optimization problems
- Continuous-Time Markov Chains
- Chemical Reactions (via [Catalyst.jl](https://docs.sciml.ai/Catalyst/stable/))
- Nonlinear Optimal Control

## Modeling Toolkit Standard Library

We could just use Modeling Toolkit but, if possible, we should try to use the Modeling Toolkit Standard Library, [ModelingToolkitStandardLibrary.jl](https://docs.sciml.ai/ModelingToolkitStandardLibrary/stable/).
The standard library contains pre-built components that we can leverage to dive directly into the engineering and not focus as much on the math and the programming of building everything up from scratch.
There's "Basic Blocks", mechanical, electrical, magnetic and thermal components.

### Background

The library defines well-tested acausal connections.
In Physical Network Acausal modeling each physical domain must define a connector to combine the model components.
Each physical domain connector defines a minimum of two variables, the Through and the Across variable.
The through variable is a time derivative of some conserved quantity.
The conserved quantity is expressed by the across variable.
Generally, the physical system is given by:

- Energy dissipation:
  $\frac{\partial across}{\partial t} \cdot c_1 = through$
- Flow:
  $through \cdot c_2 = across$

For example, for the electrical domain the across variable is voltage, and the through variable is current.
So:

- Energy dissipation:
  $\frac{\partial voltage}{\partial t} \cdot capacitance = current$
- Flow:
  $current \cdot resistance = voltage$

## Example 1: Chua's Circuit

### Background

A Chua circuit is a simple electronic circuit that exhibits classic chaotic behavior.
It produces an oscillating waveform that never repeats.
The ease of construction of the circuit has made it a ubiquitous real-world example of a chaotic system, leading some to declare it "a paradigm for chaos" [^2].

In order to get this chaotic behavior, we need to satisfy a couple requirements.

We need at least one nonlinear element if you look at the diagram above, and that's what $N_R$ stands for, our nonlinear resistor.
We need at least one locally active resistor, which is also $N_R$ in the diagram.
Then, we need at least three energy storage elements, so that's where the capacitors $C_1$ and $C_2$ and the inductor $L$ come into play.
That diagram is what we're going to be building.

### Components

To get things out of the way, let's quickly load some packages:

```julia
using OrdinaryDiffEq
using ModelingToolkit
using DataFrames
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Electrical: OnePort
using Statistics
using StatsPlots
```

#### Defining Model Components

First we need to define the components we need that are not readily available in the standard library.
So we begin with defining a parameter for time, and then we can build our nonlinear resistor.
This is the code representation of exactly what was show in the diagram:

```julia
@parameters t
function NonlinearResistor(;name, Ga, Gb, Ve)
    @named oneport = OnePort()
    @unpack v, i = oneport
    pars = @parameters Ga=Ga Gb=Gb Ve=Ve
    eqs = [
        i ~ ifelse(v < -Ve,
                Gb*(v + Ve) - Ga*Ve,
                ifelse(v > Ve,
                    Gb*(v - Ve) + Ga*Ve,
                    Ga*v,
                ),
            )
    ]
    extend(ODESystem(eqs, t, [], pars; name=name), oneport)
end
```

You can see we're using some components from the electrical module, and then it's pretty straightforward to describe the various equations that we want to govern the behavior of the nonlinear resistor.
There's a couple nested `ifelse` statements which employ different equations based on different conditions of the nonlinear resistor.
What we return from this function here is an `ODESystem` which is going to help us create the component.
`NonlinearResistor` was the only component we needed to build ourselves.

#### Creating Model Components

After defining the model parameters that are not readily available in the model library, we can then create the model components.
We can do this using various standard library components and the nonlinear resistor we just built:
```julia
@named L = Inductor(L=18)
@named R = Resistor(R=12.5e-3)
@named G = Conductor(G=0.565)
@named C1 = Capacitor(C=10, v_start=4)
@named C2 = Capacitor(C=100)
@named Nr = NonlinearResistor(
    Ga = -0.757576,
    Gb = -0.409091,
    Ve=1)
@named Gnd = Ground()
```
`Inductor`, `Resistor`, `Conductor` and `Ground` are all from the electrical module of the standard library.
Note that we can create the model components with the same labels we saw on the diagram.

#### Connecting Model Components

Once we have each of these elements, we can start defining the relationships between the components.
That's what you see in the `connect` statements below:

```julia
connections = [
    connect(L.p, G.p)
    connect(G.n, Nr.p)
    connect(Nr.n, Gnd.g)
    connect(C1.p, G.n)
    connect(L.n, R.p)
    connect(G.p, C2.p)
    connect(C1.n, Gnd.g)
    connect(C2.n, Gnd.g)
    connect(R.n, Gnd.g)
]
```

### Handling the Model

We now have everything we need to create our model:

```julia
@named model = ODESystem(connections, t,
                        systems=[L, R, G, C1, C2, Nr, Gnd])
```

When talking about not necessarily having to worry about writing the code, but instead just describing the relationships between each of the components, this is what you see here.
We can `connect` the `Inductor` to the `Ground`, the `NonlinearResistor` to the `Ground`, the `Capacitor`s to the `Ground`.
We can do all of this with `connect` statements and at the end put everything in an element (`ODESystem`) called model, which is going to give us everything needed.

But! We didn't pay close attention at all in making sure this runs in an optimal way.
That's where `structural_simplify` comes into play, and it's a very handy tool:

```julia
sys = structural_simplify(model)
```

In many cases, the most convenient way to build the model may leave a lot of unnecessary variables.
Before numerically solving we can remove these equations.
`structural_simplify` structurally... simplifies algebraic equations in a system and computes the topological sort of the observed equations.

After we get the optimal version of the model, we can create our `ODEProblem`, run it over a particular timespan, and, optionally, have it save at certain timepoints (mostly for plotting later).
We can then solve the problem:

```julia
prob = ODEProblem(sys, Pair[], (0, 5e4), saveat=100)
sol = solve(prob, Rodas4())
```

Everything up to this point does not evolve Model Optimizer, it's mostly good ol' Modeling Toolkit.
You can find an example in [this toy GitHub repository](https://github.com/xlxs4/chua-circuit).

### Inverse Problem

Now we're moving on to actually take a sneak peek on the core of what Model Optimizer can do.
The first step is to begin from the experimental data.
Note that the data can be synthesized, i.e. it can be surrogate data.
Typically, what you might see here would be something like using the [CSV.jl](https://csv.juliadata.org/stable/) package to load in the saved data.
Then, you want to somehow tie the data back to the model.
In this example we can go ahead and directly use the solution that we got from calling `solve` on our problem:

```julia
data = DataFrame(sol)
```

Now we have everything needed to define a trial.
A trial is the model plus our data.
We just pass in the data, the system and, again, specify what time to run over:

```julia
trial = Trial(data, sys, tspan=(0, 5e4))
```

Finally now that we have a trial, we can go ahead and create something that is core to this Model Optimizer pipeline — the Inverse Problem.
In simple terms, the inverse problem consists in using the results of observations, experimental data, to infer the values of the parameters characterizing the system under study.
Doing this in Model Optimizer is surprisingly easy.
We're specifying the parameters that we want to optimize.
We also specify the search space we want to look into.
Lastly we're passing a collection of trials.
Note that here it's a single trial, but still inside a collection (`[trial]`):

```julia
invprob = InverseProblem([trial], sys,
    [
        R.R => (9.5e-3, 13.5e-3),
        C1.C => (9, 11),
        C2.C => (95, 105)
    ]
)
```

The output of `InverseProblem` is essentially the parameters found which cause the model to be sufficiently good fit to all data, where all data here is the collection of trials that we've passed.
In the search space, note that we pass the lower and upper bound for each model parameter.

### Virtual Population

Since that's done, we move on to seeing the concept of virtual populations applied in practice.
The virtual population is the plausible population of optimal points.
To create this virtual population, we feed in the inverse problem.
We also pass an optimization algorithm — in this case we're going to use the stochastic global optimization algorithm.
Lastly, we specify the number of max iterations we want this to run for.
We'll use 1000, a much more realistic number to use would be at about 5000:

```julia
vp = vpop(invprob,
        StochGlobalOpt(maxiters = 100),
        population_size = 50)
```

Et voilà!

Remember that when we defined our capacitors, $C_1$ and $C_2$ we passed in values for `C`.
Notice that in the results there's a parameter `C`.
Also observe that for $C_1$ the values are around 10, and for $C_2$ around 100.
This is a relatively good sign, it means we're getting close to the actual value, and it can be a good eyeball test in general.

### Recap

For a more clear way to see the results that we got, we can use [StatsPlots.jl](https://github.com/JuliaPlots/StatsPlots.jl) to visualize.
We can create a single image which is a layout of three images and for each one we're going to use a smooth density plot to show the virtual population.
For bonus points, since we know what the true value actually is, we can plot it too to use for comparison.

```julia
params = DataFrame(vp)

p1 = density(params[:,1], label = "Estimate: R")
plot!([12.5e-3,12.5e-3], [0.0, 300],
    lw=3,color=:green,label="True value: R", linestyle = :dash)

p2 = density(params[:,2], label = "Estimate: C1")
plot!([10,10], [0.0, 1],
    lw=3,color=:red,label="True value: C1", linestyle = :dash)

p3 = density(params[:,3], label = "Estimate: C2")
plot!([100,100], [0.0, 0.15],
    lw=3,color=:purple,label="True value: C2", linestyle = :dash)

l = @layout [a b c]
plot(p1, p2, p3, layout = l)
```

We can see that even with a low number of iterations we're still capturing the true values pretty well using the virtual populations.

To reiterate, we first created the model with ModelingToolkit, the acausal modeling framework.
We had to only create one component from scratch, where we were able to leverage the `OnePort` component from the electrical module of the standard library.
We connected all of the model components, we got some optimized code, and then used that to generate some synthetic data and create the inverse problem.
Directly from there, we created the virtual population.
And that was a whirlwind overview of what a Model Optimizer workflow may look like.

## Example 2: Digital Twin of a Building

### Background

Let's take a look at another, more large-scale example — a model of a real-life building.
This building exists.
It's somewhere in Phoenix, Arizona.
It is an 81-room building, 9 by 3 by 3.
It's cooled by circulating water at 5 degrees Celsius.
In the graphs below you can see real meteorological data.

More specifically, the image on the left, the building, correlates to where the vertical line is as it's moving across the two graphs on the right.
On the top is the room temperature for each room being plotted.
On the bottom is the ambient temperature.
You can note that there are 7 visible peaks and valleys on the bottom graph, which correlates with 7 sunrises and falls during the week.
Therefore, we can see the time of day and how it affects both ambient temperature and room temperature.

### Component Setup

How might we go about constructing a model like this with an acausal modeling framework like ModelingToolkit?
Well, first we load some packages, like the ones also used in the Chua circuit example, CSV to read data and a data interpolation package.
Then, here is a key bit: we can pull a package of components we've developed ourselves to break down this problem into smaller portions, very similar to a standard library (or SynBio principles, if that's your cup of tea).

Once we've done that and load our meteorological data, slice it and get everything ready, we can finally start setting our structural parameters for the model and the building.
We set some initial temperatures for the building (currently measured in Kelvin, you'll see how we can convert below).

After we've set our initial conditions, we can do some component setup.
Very similar to how we would just pull in the `Capacitor`s, the `Inductor`, the `Ground` source, we can pull in our interpolated sources, our constant sources, our step courses...
Note we even have a function to create a HEX fan there.
There's some very useful functionality we can take advantage of: we can create many of the components in one go, as you can see in the array syntax below:

```julia
@named T_ambient = InterpolateSource(interp=temp_fun)
@named Q_sensibles[1:N_rooms] = ConstantSource(k=20)
@named T_fluids[1:N_rooms] = ConstantSource(k=fromdegC(5.0))
@named m_flow_fluids[1:N_rooms] = ConstantSource(k=-0.01)
@named speeds 1:N_rooms i -> StepSource(offset=1,
                                        height=(i==5 ? 1 : 0),
                                        startTime=2.5e5)
@named fan_coils[1:N_rooms] = HEXFan(fluid_params=0f,
                                     tube_wall_params=0w,
                                     air_params=0a)
```

### Model Setup

We now have a more large-scale model to play with — more precisely, a model which clocks in at over 17000 equations.
Just like before, instead of writing this massive model by hand, we can focus purely on the relationships between our components.
Again, the model is built up by the composition of each one of these components, same as earlier.
It's worth repeating — the overall dynamics of this building model fall out of the cumulative behavior of that composition.
We can get the dynamics of the full model out of all the individual components, all their dynamics and all the connections declared here.

Thus, we only worry about the relationships, the connections between the components.
This actually happens to unfold in a concise, fast way because we're able to do this inside a `for` loop.
We're going to go over each room and set up the equations and the connections for every room in the building without having to code all this by hand.
The output is, again, an `ODESystem`:

```julia
eqns = Equation[]
for i in 1:N_rooms
    push!(eqns, connect(fan_coils[i].airPort_b, rooms[i].airPort_in))
    push!(eqns, connect(rooms[i].airPort_out, fan_coils[i].airPort_a))
    # connect source terms
    push!(eqns, connect(Q_sensibles[i].y, rooms[i].Q_sensibles))
    push!(eqns, connect(speeds[i].y, fan_coils[i].speed))
    push!(eqns, connect(T_fluids[i].y, fan_coils[i].T_fluid))
    push!(eqns, connect(m_flow_fluids[i].y, fan_coils[i].m_flow_fluid))
end

@named sys = ODESystem(eqns, t)
@named sysModel = compose(sys, [fan_coils; rooms; T_ambient; Q_sensibles;
                                T_fluids; m_flow_fluids; speeds; fan_coils])
```

### Handling the Model

Alright, let's take a look at some actual code now.
First we need to import our packages:

```julia
using BuildingModelLibrary # Our own modular components.
using JuliaSimModelOptimizer
using ModelingToolkit
using OrdinaryDiffEq
using Unitful # For physical units.
using DataFrames, CSV
using OptimizationOptimJL
using DataInterpolations # Interpolations on 1D data.
```

We'll cheat a bit this time:

```julia
datapath = joinpath(@__DIR__, "..", "data", "USA_AZ_Phoenix.722780_TMY2.mos")
```

We can grab our model directly from data now:

```julia
model = initialize_model(; datapath)
```

Now there's 2619 equations, a massive reduction from the >17000 equations we started with.
How?
The model we get out of the `initialize_model` call has already went through all the various reduction algorithms to get this structurally and algebraically simplified.

We now got a nice, lean model to work with.
We can use [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) to convert seconds to hours, Kelvin to Celsius etc. in an efficient manner that leaves little room for developer-introduced error:

```julia
day = ustrip(u"s", 24u"hr")
n_days = 5.0
t0 = 2.0 * day
tend = t0 + n_days
```

### Inverse Problem

Easy peasy.
We're going to follow the same 3 steps:

1. Load the experimental data,
2. define our trials,
3. define the inverse problem:

```julia
data = CSV.read(joinpath(@__DIR__,"..","data","building_data.csv"),
                DataFrame)
trial = Trial(data, model;
            tspan=(t0, tend),
            alg=QNDF(autodiff = false))
invprob = InverseProblem([trial], model,
    [
        @nonamespace(model.T_fluids_1_k) => (270.0, 280.0),
        @nonamespace(model.T_fluids_2_k) => (270.0, 280.0),
        @nonamespace(model.T_fluids_3_k) => (270.0, 280.0)
    ]
)
```

### Model Calibration

`calibrate` comes from Model Optimizer.
Then, we just convert the results from Kelvin to Celsius and we have the parameter estimation for this model.
That's it.
Estimated parameters that perfectly match the groundtruth data.
That's cool.

```julia
alg = SplineCollocate(maxiters=1_000, solver=BFGS(), interp=CubicSpline)
result = calibrate(invprob, alg)
uconvert.(u"°C", result.*u"K")
```

## Note

Before waving goodbye, I'd like to note down something important.
All the methods shown here (and more) are designed for large-scale simulations to fit to data.
It's a form of curve fitting that is engineered for robustness to nonlinear behavior.
One could wonder, how do you fit data to a chaotic system?
That's a well-founded question.
This is because in a chaotic system, for example, you could have great error in your simulations if you simulate the system for multiple Lyapunov times.
The Model Optimizer techniques are robust to these behaviors.
They make use of multiple shooting and things like collocation to be able to be fitting in the derivative space in a way that does not have this compounding of errors.
If you naively slap an ODE solver into BFGS and then just directly fit and hope and pray, a chaotic system *is* an example of where this approach would fail.
The building example in particular demonstrates the robustness of some of the available methods.


[^1]: Anantharaman, R., Ma, Y., Gowda, S., Laughman, C., Shah, V., Edelman, A., & Rackauckas, C. (2020). Accelerating simulation of stiff nonlinear systems using continuous-time echo state networks. *arXiv preprint arXiv:2010.04004*.

[^2]: Madan, R. N. (Ed.). (1993). *Chua's circuit: a paradigm for chaos* (Vol. 1). World Scientific.
