
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://bancaditalia.github.io/BeforeIT.jl/dev/)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


<div align='center'>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/bancaditalia/BeforeIT.jl/main/docs/logo/logo_white_text.png">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/bancaditalia/BeforeIT.jl/main/docs/logo/logo_black_text.png">
  <img alt="Logo adapts to light and dark modes" src="https://raw.githubusercontent.com/bancaditalia/BeforeIT.jl/main/docs/logo/logo_black_text.png" width="500">
</picture>
<sup><a href="#footnote-1">*</a></sup>
</div>

# Behavioural agent-based economic forecasting

Welcome to BeforeIT.jl, a package for **B**ehavioural agent-based **e**conomic **fore**casting,
from the **IT** research unit of the Bank of Italy.

BeforeIT.jl is a Julia-based implementation of the agent-based model presented in 
[_Economic forecasting with an agent-based model_](https://www.sciencedirect.com/science/article/pii/S0014292122001891),
the first ABM matching the forecasting performance of traditional economic tools.

With BeforeIT.jl, you can perform economic forecasting and explore different counterfactual scenarios.
Thanks to its modular design, the package is also a great starting point for anyone looking to extend its
capabilities or integrate it with other tools.

Developed in Julia, a language known for its efficiency, BeforeIT.jl is both fast and user-friendly,
making it accessible whether you’re an expert programmer or just starting out.

The package currently contains the original parametrisation for Austria, as well as a parametrisation for Italy.
Recalibrating the model on other nations is possible of course, but currently not easily supported.
So get in contact if you are interested!

## Julia installation

To run this software, you will need a working Julia installation on your machine.
If you don't have Julia installed already, simply follow the short instructions
available [here](https://julialang.org/downloads/).

## Installation

To be able to run the model, you can activate a new Julia environment in any folder from the terminal by typing

```
julia --project=.
```

Then, whithin the Julia environment, you can install BeforeIT.jl as

```julia
using Pkg
Pkg.add("BeforeIT")
```

You can ensure to have installed all dependencies via

```julia
Pkg.instantiate()
```

Now you should be able to run the the following code

```julia
using BeforeIT

parameters = BeforeIT.AUSTRIA2010Q1.parameters
initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions

T = 20
model = BeforeIT.initialise_model(parameters, initial_conditions, T)
data = BeforeIT.run_one_sim!(model)
```

This will simulate the model with the original Austrian parametrisation for 20 quarters and save the results in the `data` object.
To plot the time series within the `data` object, make sure you install Plots.jl in the same environment using

```julia
Pkg.add("Plots")
```

and then try running

```julia
using Plots

plot(data.real_gdp)
```

In you want to run the script without opening a REPL, you can copy and paste the above lines into a file,
say `main.jl`, and run it directly from the terminal by typing

```
julia --project=. main.jl
```


## Docs

Extensive documentation on how to use the package is available [here](https://bancaditalia.github.io/BeforeIT.jl/dev/).
We suggest following the steps in [this tutorial](https://bancaditalia.github.io/BeforeIT.jl/dev/examples/basic_example.html) to quickly learn the basics.

## Download Source Code and Run Tests

### Clone the Repository
```bash
git clone https://github.com/bancaditalia/BeforeIT.jl.git
cd BeforeIT.jl
```

### Activate and Instantiate the Environment
```bash
julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate();'
```

### Run Tests
```bash
julia --proj test/runtests.jl
```


## Current Authors


<table>
  <tr>
    <td align="center">
      <a href="https://github.com/AldoGl">
        <img src="https://avatars.githubusercontent.com/AldoGl" width="100px;" alt="Aldo Glielmo"/><br />
        <sub><b>Aldo Glielmo</b></sub>
      </a><br />
      <p>Banca d'Italia </p>
      <p>Email: <a href="mailto:aldo.glielmo@bancaditalia.it:">aldo.glielmo@bancaditalia.it</a></p>
    </td>
    <td align="center">
      <a href="https://devetak.github.io/">
        <img src="https://avatars.githubusercontent.com/Devetak" width="100px;" alt="Mitja Devetak"/><br />
        <sub><b>Mitja Devetak</b></sub>
      </a><br />
      <p>Paris 1: Pantheon - Sorbonne</p>
    </td>
  <td align="center">
      <a href="https://github.com/Tortar">
        <img src="https://avatars.githubusercontent.com/Tortar" width="100px;" alt="Adriano Meligrana"/><br />
        <sub><b>Adriano Meligrana</b></sub>
      </a><br />
      <p>University of Turin</p>
      <p>Email: <a href="mailto:adrianomeligrana@proton.me:">adrianomeligrana@proton.me</a></p>
    </td>
  </tr>
</table>


## Disclaimer

This package is an outcome of a research project. All errors are those of
the authors. All views expressed are personal views, not those of Bank of Italy.

---

<p id="footnote-1">
* Credits to <a href="https://www.bankit.art/people/sara-corbo">Sara Corbo</a>  for the logo and to <a href="https://www.bankit.art/people/andrea-gentili">Andrea Gentili</a> for the name suggestion.
</p>
