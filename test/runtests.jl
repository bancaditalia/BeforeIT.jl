using BeforeIT, Test

#utils
@time include("utils/test_epsilon.jl")
include("utils/positive.jl")
@time include("utils/test_randpl.jl")
@time include("utils/test_nfvar3_and_estimate.jl")

# one epoch
@time include("model_init/test_initialise_model.jl")
@time include("test_one_epoch.jl")
@time include("utils/test_estimations.jl")

# search_and_matching
@time include("markets/test_search_and_matching_mod.jl")
#@time include("test_search_and_matching_seed_stability.jl")

# agent_actions
@testset "test agent actions" begin
    include("./agent_actions/bank.jl")
    include("./agent_actions/central_bank.jl")
    include("./agent_actions/firms.jl")
    include("./agent_actions/estimations.jl")
end

# accounting identities
@time include("test_accounting_identities.jl")

# shock tests
include("shocks/shocks.jl")

# WARNING: this should be the last include
include("deterministic/runtests_deterministic.jl")
