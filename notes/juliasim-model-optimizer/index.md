+++
date = Date(2022, 12, 12)
title = "JuliaSim Model Optimizer"
hascode = false
tags = ["julia", "modeling", "sciml"]
descr = "Model Calibration and Parameter Estimation w/ JuliaSim"
rss = "Model Calibration and Parameter Estimation w/ JuliaSim"
rss_title = "JuliaSim Model Optimizer"
rss_pubdate = Date(2022, 12, 12)
+++

{{ notetags }}

{{ add_read_time }}

\toc

## JuliaSim Model Optimizer

Some time ago I attended a remote workshop titled "Model Calibration and Parameter Estimation with JuliaSim Model Optimizer" by the [JuliaHub](https://juliahub.com/company/about-us/) team, specifically [Jacob Vaverka](https://jvaverka.com/) and [Dr. Christopher Rackauckas](https://chrisrackauckas.com/).
Here's some knowledge.

## JuliaSim

[JuliaSim](https://juliahub.com/products/juliasim/) is a cloud-hosted platform for physical simulation.
It combines a vast array of bleeding edge [SciML](https://sciml.ai/) techniques, acausal equation-based digital twin modeling and simulation and is powered by the [Julia](https://julialang.org/) programming language.
It is preview-only software in the time of writing this post (December 2022).

JuliaSim produces surrogates of blackbox (and regular) dynamical systems using \abbr{title="Continuous Time Echo State Networks", abbr="CTESN"}s [^1].
This technique allows, amongst other features, for implicit training in parameter space to stabilize the ill-conditioning present in stiff systems.

You can leverage these surrogates to accelerate the process and there's a variety of techniques for quantifying uncertainty and noise (see the virtual populations below).
You can use JuliaSim for parameter estimation and optimal control, which is what this post is about.
There's the so-called [Model Library](https://help.juliahub.com/juliasim/stable/ModelLibrary/), a collection of acausal (equation-based) components with pre-trained surrogates of models that are ready to use.
You can thus discover and import/exchange various models, and combine yours with pre-built models and digital twins.
Lastly, there's specialized numerical environments available for use upon demand.
Everything can happen on the JuliaHub cloud-based IDE.

\figure{path="./assets/juliahub.png", caption="A visual overview of JuliaHub."}

If you want to build models, you can use the pre-made model libraries, e.g. [CellMLPhysiome.jl](https://help.juliahub.com/CellMLPhysiome/dev/) and [SBMLBioModels.jl](https://help.juliahub.com/SBMLBioModels/stable/).
You can use the [Catalyst.jl](https://github.com/SciML/Catalyst.jl) and [ModelingToolkit.jl](https://github.com/SciML/ModelingToolkit.jl) GUIs.
If you want to generate models using existing data, you can use a Digital Twin generator.
If you want to generate data using existing models, you can use a Surrogatizer and more.

\figure{path="./assets/surrogatizer.png", caption="The JuliaSim Surrogatizer GUI."}

\figure{path="./assets/surrogate-dashboard.png", caption="The Surrogate Diagnostic Summary interactive dashboard."}

### Introduction

\figure{path="./assets/juliasim.png", caption="JuliaSim at a glance."}

The Model Optimizer is a Julia package available on the JuliaHub platform named `JuliaSimModelOptimizer`.
It contains methodology to perform model calibration and analysis inside a \abbr{title="High-Performance Computing", abbr="HPC"} environment in a user-friendly manner.
It's a robust and automated framework to scale large and complex models.

## Model Calibration

A typical model calibration pipeline looks like the following:

1. First, simulate a parameter combination $\theta_i$ somewhere in the parameter space. Feed the parameters in the model, which outputs the model prediction for $\theta_i$.
2. Then collect (experimental) data for the same $\theta_i$ combinations (or vice-versa).
3. Lastly, combine model prediction and observed data to tune $\theta_i$ so that the prediction better fits the data, using a loss (usually error) function for optimization.

\figure{path="./assets/model-calibration.png", caption="Model calibration via optimization in Model Optimizer."}

### Nonlinear Model Calibration

There's three main challenges that can arise if trying to calibrate a model when nonlinearity is introduced.
Nonlinear calibration is significantly harder, mainly because:

1. Nonlinear optimization can easily hit local minima.
2. Optimization procedures/algorithms are usually serial.
3. Model parameters can be unidentifiable from data.

\figure{path="./assets/model-calibration-challenges.png", caption="The challenges of Nonlinear Calibration."}

To address the first challenge — how do we avoid local optima?
We can leverage specialized methods from Model Optimizer.
There's a variety of calibration methods available.
Which one to choose is going to ultimately depend on the specific problem at hand.

To address the second challenge — how do we do effective parallelism on a particular strategy that we're deploying?
How do we leverage large-scale cloud compute systems to solve these problems?
Proper strategy selection plays a big role here.
You can enable parallelism with certain calibration strategies.
Multiple shooting is one example that can be parallelized, so if it's an effective strategy for the case at hand it can help us break out the serial of execution.
Note that some of the available techniques are more amenable to distributed compute.

\figure{path="./assets/avoiding-local-optima.png", caption="Robust nonlinear calibration strategies."}

Lastly, to address the third challenge — how do we quantify the uncertainty in the fit?
The answer is by introducing a Model Optimizer concept called Virtual Populations.
Virtual Populations are sets of parameters which sufficiently fit all trials, all observations.
A trial is a different variation of the model which can be ran, it describes an experiment.
It's a data observation.
We can have collections of trials, multiple trials.
Having a collection allows us to define multi-simulation optimization problems.
We'll see what this means in practice later on in this post, it essentially is a a way to synthesize data to repeat stochastic optimization to better understand the parameter landscape and be able to quantify the uncertainty of global optima in the conditions observed.

\figure{path="./assets/virtual-populations.png", caption="Quantifying uncertainty using Virtual Populations."}

## Model Paradigms

So we've seen how model calibration could work at a high level, we've taken a look at some problems that might arise in nonlinear calibration,
and how Model Optimizer tackles these problems, including the concept of virtual populations which is also very helpful for another reason we'll look into below.
Before we get to really see how all of this could work in action, we need to discuss different modeling paradigms.
How do we create these simulations and have something that we can apply these Model Optimizer techniques to?

### Causal Modeling

In causal modeling, we describe the causal mechanisms of a system.
The way that this works is we provide clear rules for the interactions between functional blocks.
Here we're worried about the flow of computation — one could draw an analogy linking causal modeling with the imperative programming paradigm.

\figure{path="./assets/causal-modeling.png", caption="Causal Block diagram in <a href='https://www.mathworks.com/products/simulink.html'>Simulink</a> by The Mathworks."}

### Acausal Modeling

Instead, in acausal modeling we describe the behavior and the properties of the model components.
Then, the models are built up out of the composition of the components.
The overall dynamics of the model fall out of the cumulative behavior of the composition.
This is more akin to the declarative programming paradigm.
We only worry about the connections and the relationships between these functional blocks — we don't want to frame the problem particularly in terms of the flow of computation that has to happen, we want to think instead about individual components and the relationships between one another.

\figure{path="./assets/acausal-modeling.png", caption="Acausal modeling in <a href='https://mtk.sciml.ai/dev/'>ModelingToolkit.jl</a>, part of the <a href='https://sciml.ai/'>SciML</a> suite."}

There's some key advantages to following the acausal modeling paradigm.
Acausal modeling can be expressive.
This allows us to think like scientists and engineers instead of being limited in framing the problem only in terms of how to compute the results.
Acausal modeling can be concise.
This can allow us to build large-scale models by connecting well-tested components.
Acausal modeling can be reusable.
We can bring these well-tested components and entire component models with us to build new systems.

\figure{path="./assets/why-acausal-modeling.png", caption="Following the acausal modeling paradigm comes with important perks."}

## Modeling Toolkit

[ModelingToolkit.jl](https://mtk.sciml.ai/dev/) is a Julia acausal modeling framework and it will allow us to be expressive and concise when we write our \abbr{title="Differential Equation", abbr="DE"} models.
It will also enable us to reuse these models so we can automatically rearrange equations for better stability.
We're gonna get some extra perks here.
We're gonna get optimal code by default, without having to worry about the most optimal way to compute these things — we just worry about the mechanics and then we get the optimal code for free.
The code will also be parallelizable by default.

\figure{path="./assets/modeling-toolkit.png", caption="Acausal component-based modeling with <a href='https://mtk.sciml.ai/dev/'>ModelingToolkit.jl</a>."}

### Description

ModelingToolkit is a modeling language.
It can do both symbolic and numeric computation.
It is highly performant and parallel.
It is extendable because it brings ideas from symbolic \abbr{title="Computer Algebra System", abbr="CAS"} and causal/acausal equation-based modeling frameworks, but also because it's built in Julia and it's easy to pry into the source and modify as we please.

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

- \abbr{title="Ordinary differential equations", abbr="ODE"}s
- \abbr{title="Stochastic differential equations", abbr="SDE"}s
- \abbr{title="Partial differential equations", abbr="PDE"}s
- Nonlinear systems
- Optimization problems
- Continuous-Time Markov Chains
- Chemical Reactions (via [Catalyst.jl](https://docs.sciml.ai/Catalyst/stable/))
- Nonlinear Optimal Control

## Modeling Toolkit Standard Library

We could just use Modeling Toolkit but, if possible, we should try to use the Modeling Toolkit Standard Library, [ModelingToolkitStandardLibrary.jl](https://docs.sciml.ai/ModelingToolkitStandardLibrary/stable/).
The standard library contains pre-built components that we can leverage to dive directly into the engineering and not focus as much on the math and the programming of building everything up from scratch.

\figure{path="./assets/standard-library.png", caption="ModelingToolkit Standard Library."}

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

A Chua circuit is a simple electronic circuit that exhibits classic chaotic behavior.
It produces an oscillating waveform that never repeats.
The ease of construction of the circuit has made it a ubiquitous real-world example of a chaotic system, leading some to declare it "a paradigm for chaos" [^2].

In order to get this chaotic behavior, we need to satisfy a couple requirements.

\figure{path="./assets/chua-circuit.png", caption="Chua's circuit diagram."}

We need at least one nonlinear element if you look at the diagram above, and that's what $N_R$ stands for, our nonlinear resistor.
We need at least one locally active resistor, which is also $N_R$ in the diagram.
Then, we need at least three energy storage elements, so that's where the capacitors $C_1$ and $C_2$ and the inductor $L$ come into play.
That diagram is what we're going to be building.


[^1]: Anantharaman, R., Ma, Y., Gowda, S., Laughman, C., Shah, V., Edelman, A., & Rackauckas, C. (2020). Accelerating simulation of stiff nonlinear systems using continuous-time echo state networks. *arXiv preprint arXiv:2010.04004*.

[^2]: Madan, R. N. (Ed.). (1993). *Chua's circuit: a paradigm for chaos* (Vol. 1). World Scientific.
