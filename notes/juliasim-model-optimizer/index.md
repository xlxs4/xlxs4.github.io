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

### JuliaSim

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

### Model Calibration

A typical model calibration pipeline looks like the following:

1. First, simulate a parameter combination $\theta_i$ somewhere in the parameter space. Feed the parameters in the model, which outputs the model prediction for $\theta_i$.
2. Then collect (experimental) data for the same $\theta_i$ combinations (or vice-versa).
3. Lastly, combine model prediction and observed data to tune $\theta_i$ so that the prediction better fits the data, using a loss (usually error) function for optimization.

\figure{path="./assets/model-calibration.png", caption="Model calibration via optimization in Model Optimizer."}

#### Nonlinear Model Calibration

There's three main challenges that can arise if trying to calibrate a model when nonlinearity is introduced.
Nonlinear calibration is significantly harder, mainly because:

1. Nonlinear optimization can easily hit local minima
2. Optimization procedures/algorithms are usually serial
3. Model parameters can be unidentifiable from data

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


[^1]: Anantharaman, R., Ma, Y., Gowda, S., Laughman, C., Shah, V., Edelman, A., & Rackauckas, C. (2020). Accelerating simulation of stiff nonlinear systems using continuous-time echo state networks. *arXiv preprint arXiv:2010.04004*.
