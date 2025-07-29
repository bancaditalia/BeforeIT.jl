
import BeforeIT as Bit

using Test
using Aqua
using JuliaFormatter

@testset "BeforeIT.jl Tests" begin

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

    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(Bit, ambiguities = false, unbound_args = false,
            persistent_tasks = (tmax = 60,)) # Windows might need more time...
        @test Test.detect_ambiguities(Bit) == Tuple{Method, Method}[]
    end

    @testset "Code formatting (JuliaFormatter.jl)" begin
        @test format(Bit; style = SciMLStyle(), yas_style_nesting = true, verbose = false,
            overwrite = false)
    end

    # WARNING: this should be the last include
    include("deterministic/runtests_deterministic.jl")
end
