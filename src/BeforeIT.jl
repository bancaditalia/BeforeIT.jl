module BeforeIT

import Base: length

using ChunkSplitters
using DynamicSampling
using LazyArrays
using LinearAlgebra
using Random
using StatsBase

const Bit = BeforeIT

# definition of agents
include("model_init/agents.jl")

# model initialisation function
include("model_init/init_properties.jl")
include("model_init/init_banks.jl")
include("model_init/init_firms.jl")
include("model_init/init_workers.jl")
include("model_init/init_government.jl")
include("model_init/init_rest_of_the_world.jl")
include("model_init/init_aggregates.jl")
include("model_init/init.jl")

# functions
include("agent_actions/estimations.jl")
include("agent_actions/central_bank.jl")
include("agent_actions/firms.jl")
include("agent_actions/households.jl")
include("agent_actions/government.jl")
include("agent_actions/rotw.jl")
include("agent_actions/bank.jl")

# full epoch
include("one_epoch.jl")
include("one_simulation.jl")

# data handling
include("utils/data.jl")

# markets
include("markets/search_and_matching_credit.jl")
include("markets/search_and_matching_labour.jl")
include("markets/search_and_matching.jl")

# utils
include("utils/estimate.jl")
include("utils/nfvar3.jl")
include("utils/randpl.jl")
include("utils/epsilon.jl")
include("utils/positive.jl")
include("utils/toannual.jl")
include("utils/get_predictions_from_sims.jl")
include("utils/plot_data_vector.jl")
include("utils/dmtest.jl")
include("utils/mztest.jl")
include("utils/varx.jl")
include("utils/plot_predictions_vs_real.jl")

# calibration
include("utils/calibration.jl")
include("utils/_calibration_steady_state.jl")
include("utils/get_accounting_identities.jl")

# standard parameters
include("utils/standard_params_initial_conditions.jl")
include("utils/standard_calibration_data.jl")

# shocks
include("shocks/shocks.jl")

# precompilation pipeline
include("precompile.jl")

end
