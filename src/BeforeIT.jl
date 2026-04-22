module BeforeIT

import Base: length

import Ark
using LazyArrays
using LinearAlgebra
using MacroTools
using Preferences
using Quadmath
using Random
using StatsBase
using WeightVectors
import JLD2


include("utils/estimate.jl")
include("utils/ecs_utils.jl")

include("components/components.jl")

include("resources/aggregates.jl")
include("resources/properties.jl")
include("resources/shocks.jl")
include("resources/epsilons.jl")
include("cache/firm_cache.jl")

include("model_init/init_model.jl")
include("model_init/firms.jl")
include("model_init/workers.jl")
include("model_init/bank.jl")
include("model_init/government.jl")
include("model_init/rotw.jl")
include("model_init/aggregates.jl")

include("utils/randpl.jl")
include("utils/standard_params_initial_conditions.jl")

include("systems/banks.jl")
include("systems/central_bank.jl")
include("systems/estimations.jl")
include("systems/firms.jl")

end
