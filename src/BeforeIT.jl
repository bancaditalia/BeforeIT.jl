module BeforeIT

import Base: length

import Ark
import JLD2
using LinearAlgebra
using MacroTools
using Preferences
using Quadmath
using Random
using StatsBase
using WeightVectors

const IntType = eval(Meta.parse(@load_preference("IntType", default = "Int")))
const FloatType = eval(Meta.parse(@load_preference("FloatType", default = "Float64")))

include("utils/estimate.jl")
include("utils/ecs_utils.jl")
include("utils/nfvar3.jl")
include("utils/julia_svd.jl")

include("components/components.jl")

include("resources/aggregates.jl")
include("resources/properties.jl")
include("resources/shocks.jl")
include("resources/epsilons.jl")

include("cache/firm_cache.jl")
include("cache/search_and_matching.jl")
include("cache/search_and_matching_labor.jl")

include("model_init/init_model.jl")
include("model_init/firms.jl")
include("model_init/workers.jl")
include("model_init/bank.jl")
include("model_init/government.jl")
include("model_init/rotw.jl")
include("model_init/aggregates.jl")

include("utils/randpl.jl")
include("utils/standard_params_initial_conditions.jl")

include("systems/epsilon.jl")
include("systems/aggregates.jl")
include("systems/banks.jl")
include("systems/central_bank.jl")
include("systems/estimations.jl")
include("systems/firms.jl")
include("systems/government.jl")
include("systems/households.jl")
include("systems/rotw.jl")
include("systems/markets/search_and_matching.jl")
include("systems/markets/search_and_matching_credit.jl")
include("systems/markets/search_and_matching_labor.jl")

include("schedule/one_step.jl")


end
