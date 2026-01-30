module BeforeIT

import Base: length

using LazyArrays
using LinearAlgebra
using MacroTools
using Preferences
using Random
using StatsBase
using WeightVectors

const Bit = BeforeIT

const typeFloat = eval(Meta.parse(@load_preference("typeFloat", default = "Float64")))
const typeInt = eval(Meta.parse(@load_preference("typeInt", default = "Int")))

macro maybe_threads(cond, loop)
    return esc(
        quote
            if $cond
                $Threads.@sync $(Expr(:for, loop.args[1], :($Threads.@spawn $(loop.args[2]))))
            else
                $loop
            end
        end
    )
end

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

# data handling
include("utils/data.jl")

# functions
include("agent_actions/estimations.jl")
include("agent_actions/central_bank.jl")
include("agent_actions/firms.jl")
include("agent_actions/households.jl")
include("agent_actions/government.jl")
include("agent_actions/rotw.jl")
include("agent_actions/bank.jl")
include("agent_actions/aggregates.jl")

# full epoch
include("one_step.jl")
include("one_simulation.jl")

# markets
include("markets/search_and_matching_credit.jl")
include("markets/search_and_matching_labour.jl")
include("markets/search_and_matching.jl")

# utils
include("utils/estimate.jl")
include("utils/nfvar3.jl")
include("utils/opt.jl")
include("utils/randpl.jl")
include("utils/epsilon.jl")
include("utils/positive.jl")
include("utils/toannual.jl")
include("utils/get_predictions_from_sims.jl")
include("utils/dmtest.jl")
include("utils/mztest.jl")
include("utils/varx.jl")
include("utils/modify.jl")
include("utils/misc.jl")

# calibration
include("utils/calibration.jl")
include("utils/_calibration_steady_state.jl")
include("utils/get_accounting_identities.jl")

# standard parameters
include("utils/standard_params_initial_conditions.jl")
include("utils/standard_calibration_data.jl")

# methods for running over different dates
include("utils/save_all_predictions.jl")

# shocks
include("shocks/shocks.jl")

# model extensions
include("model_extensions/init_CANVAS.jl")

# external functions definitions
include("utils/extensions.jl")

# precompilation pipeline
include("precompile.jl")

end
