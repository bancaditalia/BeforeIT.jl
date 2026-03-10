import BeforeIT as Bit

using Test
using Runic

@testset "BeforeIT.jl Tests" begin

    #utils
    include("utils/positive.jl")
    include("utils/randpl.jl")
    include("utils/nfvar3_and_estimate.jl")
    include("utils/estimations.jl")
    include("utils/modify.jl")
    include("utils/zenodo_calibration.jl")

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

    @testset "Quality (Aqua.jl)" begin
        include("package_sanity_tests.jl")
    end

    # WARNING: this should be the last include
    include("deterministic/runtests_deterministic.jl")

    @testset "Format (Runic.jl)" begin
        isformat = Bit.format_package(check = true)
        @test isformat == true
        if isformat == false
            @warn "Formatting failed: use `import BeforeIT as Bit; using Runic; Bit.format_package()` to run the formatter"
        end
    end

end
