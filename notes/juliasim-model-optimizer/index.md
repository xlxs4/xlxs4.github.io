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

[JuliaSim](https://juliahub.com/products/juliasim/) is a cloud-hosted platform for physical simulation. It combines a vast array of bleeding edge [SciML](https://sciml.ai/) techniques, acausal equation-based digital twin modeling and simulation and is powered by the [Julia](https://julialang.org/) programming language. It is preview-only software in the time of writing this post (December 2022).

JuliaSim produces surrogates of blackbox (and regular) dynamical systems using [Continuous Time Echo State Networks](https://arxiv.org/pdf/2010.04004.pdf) (CTESNs). This technique allows, amongst other features, for implicit training in parameter space to stabilize the ill-conditioning present in stiff systems.

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
