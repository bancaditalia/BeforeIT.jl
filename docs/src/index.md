```@meta
CurrentModule = BeforeIT 
```

# Behavioural agent-based economic forecasting in Julia


Welcome to BeforeIT.jl, a Julia implementation of the agent-based model presented in [Economic forecasting with an agent-based model](https://www.sciencedirect.com/science/article/pii/S0014292122001891), the first ABM matching the performance of traditional economic forecasting tools.

With BeforeIT.jl, you can perform economic forecasting and explore different counterfactual scenarios. Thanks to its modular design, the package is also a great starting point for anyone looking to extend its capabilities or integrate it with other tools.

Developed in Julia, a language known for its efficiency, BeforeIT.jl is both fast and user-friendly, making it accessible whether you’re an expert programmer or just starting out.

## Julia installation

To run this software, you will need a working Julia installation on your machine.
If you don't have it installed already, simply follow the short instructions available [here](https://julialang.org/downloads/).

## BeforeIT.jl Installation

To install BeforeIT.jl, simply open a Julia REPL by writing `julia` in your terminal, and then execute the following

```julia
using Pkg
Pkg.add("BeforeIT")
```

## Quick example

To check that the installation worked, try running the model in your terminal following

```julia
using BeforeIT

parameters = BeforeIT.AUSTRIA2010Q1.parameters
initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions

T = 20
model = BeforeIT.initialise_model(parameters, initial_conditions, T)
data = BeforeIT.run_one_sim!(model)
```

To plot the results of the simulation, install the `Plots` package via ```Pkg.add("Plots")```  and then run

```julia
using Plots

plot(data.real_gdp)
```

## License

BeforeIT.jl is released under the GNU Affero General Public License v3 or later (AGPLv3+).

Copyright 2024- Banca d'Italia and the authors.

## Main developers and maintainers

- [Aldo Glielmo](https://github.com/AldoGl) <[aldo.glielmo@bancaditalia.it](mailto:aldo.glielmo@bancaditalia.it)>
- [Mitja Devetak](https://github.com/Devetak) <[m888itja@gmail.com](mailto:m888itja@gmail.com)>

## Other collaborators and contributors

- [Sebastian Poledna](https://github.com/sebastianpoledna) <[poledna@iiasa.ac.at](mailto:poledna@iiasa.ac.at)>
- [Marco Benedetti](https://www.bankit.art/people/marco-benedetti)
- [Sara Corbo](https://www.bankit.art/people/sara-corbo) for the logo design
- [Andrea Gentili](https://www.bankit.art/people/andrea-gentili) for suggesting the name of the pakege
- [Arnau Quera-Bofarull](https://github.com/arnauqb) for help in the deployment of the documentation
- [Steven Hoekstra](https://github.com/SGHoekstra) for fixing a bug in a script
- [Adriano Meligrana](https://github.com/Tortar) for fixing a bug in a script

## Disclaimer

This package is an outcome of a research project. All errors are those of
the authors. All views expressed are personal views, not those of Bank of Italy.
