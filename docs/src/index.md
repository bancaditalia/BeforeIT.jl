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

To check that the installation worked, try running the model in your terminal with

```julia
import BeforeIT as Bit

parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

T = 20
model = Bit.initialise_model(parameters, initial_conditions, T)
data = Bit.run!(model)
```

To plot the results of the simulation, you can use the `Plots` package

```julia
using Plots

plot(data.real_gdp)
```

## License

BeforeIT.jl is released under the GNU Affero General Public License v3 or later (AGPLv3+).

Copyright 2024 - Banca d'Italia and the authors.

## Main developers and maintainers

- [Aldo Glielmo](https://github.com/aldoglielmo) <[aldo.glielmo@bancaditalia.it](mailto:aldo.glielmo@bancaditalia.it)>
- [Mitja Devetak](https://github.com/Devetak) <[m888itja@gmail.com](mailto:m888itja@gmail.com)>
- [Adriano Meligrana](https://github.com/Tortar) <[adrianomeligrana@proton.me](mailto:adrianomeligrana@proton.me)>

## Other collaborators and contributors

- [Sebastian Poledna](https://github.com/sebastianpoledna) <[poledna@iiasa.ac.at](mailto:poledna@iiasa.ac.at)>
- [Marco Benedetti](https://www.bankit.art/people/marco-benedetti)
- [Claudia Biancotti](https://www.bankit.art/people/claudia-biancotti)
- [Sara Corbo](https://www.bankit.art/people/sara-corbo) for the logo design
- [Andrea Gentili](https://www.bankit.art/people/andrea-gentili) for suggesting the name of the pakege
- [Arnau Quera-Bofarull](https://github.com/arnauqb) for help in the deployment of the documentation
- [Steven Hoekstra](https://github.com/SGHoekstra) for fixing a bug in a script
- [Peter Reschenhofer](https://github.com/petres) for fixing a bug in a script

## Citing _BeforeIT_

A software description of the package is available [here](https://arxiv.org/abs/2502.13267). If you found _BeforeIT_ useful for your research, please cite it

```bib
@article{glielmo2025beforeit,
  title={BeforeIT. jl: High-Performance Agent-Based Macroeconomics Made Easy},
  author={Glielmo, Aldo and Devetak, Mitja and Meligrana, Adriano and Poledna, Sebastian},
  journal={arXiv preprint arXiv:2502.13267},
  year={2025}
}
```

and do not hesitate to get in touch to include your extension in the next release of the package and software description.

## Disclaimer

This package is an outcome of a research project. All errors are those of
the authors. All views expressed are personal views, not those of Bank of Italy.

## Reproducibility

```@raw html
<details><summary>The documentation of BeforeIT.jl was built using these direct dependencies,</summary>
```

```@example
using Pkg # hide
Pkg.status() # hide
```

```@raw html
</details>
```

```@raw html
<details><summary>and using this machine and Julia version.</summary>
```

```@example
using InteractiveUtils # hide
versioninfo() # hide
```

```@raw html
</details>
```

```@raw html
<details><summary>A more complete overview of all dependencies and their versions is also provided.</summary>
```

```@example
using Pkg # hide
Pkg.status(; mode = PKGMODE_MANIFEST) # hide
```

```@raw html
</details>
```

```@eval
using TOML
using Markdown
version = TOML.parse(read("../../Project.toml", String))["version"]
name = TOML.parse(read("../../Project.toml", String))["name"]
link_manifest = "https://github.com/BeforeIT/" * name * ".jl/tree/gh-pages/v" * version *
                "/assets/Manifest.toml"
link_project = "https://github.com/BeforeIT/" * name * ".jl/tree/gh-pages/v" * version *
               "/assets/Project.toml"
Markdown.parse("""You can also download the
[manifest]($link_manifest)
file and the
[project]($link_project)
file.
""")
```
