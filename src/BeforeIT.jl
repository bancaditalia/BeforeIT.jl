module BeforeIT

import Base: length

using Ark
using LazyArrays
using LinearAlgebra
using MacroTools
using Preferences
using Quadmath
using Random
using StatsBase
using WeightVectors

const Bit = BeforeIT


# definition of agents
include("components/components.jl")

include("model_init/init_properties.jl")
include("model_init/init_model.jl")

end
