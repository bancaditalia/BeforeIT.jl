
import BeforeIT as Bit

using Test

@testset "BeforeIT.jl Tests" begin
    
    include("package_sanity_tests.jl")

    #utils
    include("utils/positive.jl")
    include("utils/randpl.jl")
    include("utils/nfvar3_and_estimate.jl")
    include("utils/estimations.jl")

    # search_and_matching
    include("markets/search_and_matching.jl")

    # agent_actions
    @testset "test agent actions" begin
        include("./agent_actions/bank.jl")
        include("./agent_actions/central_bank.jl")
        include("./agent_actions/firms.jl")
        include("./agent_actions/estimations.jl")
    end

    # accounting identities
    include("accounting_identities.jl")

    # shock tests
    include("shocks/shocks.jl")

    # WARNING: this should be the last include
    include("deterministic/runtests_deterministic.jl")
end
