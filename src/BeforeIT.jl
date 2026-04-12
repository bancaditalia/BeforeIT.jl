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
import JLD2


include("components/components.jl")

include("resources/aggregates.jl")
include("resources/properties.jl")

include("model_init/init_model.jl")
include("model_init/firms.jl")
include("model_init/workers.jl")
include("model_init/bank.jl")
include("model_init/government.jl")
include("model_init/rotw.jl")
include("model_init/aggregates.jl")

include("utils/randpl.jl")

params = JLD2.load("data/austria/parameters/2010Q1.jld2")
init_conditions = JLD2.load("data/austria/initial_conditions/2010Q1.jld2")
const AUSTRIA = Properties(params, init_conditions)

end
