import BeforeIT as Bit

using Test

@testset "BeforeIT.jl Tests" begin
    @testset "Model Init" begin
        include("model_init/init_model.jl")
    end

    @testset "Systems" begin
        include("systems/aggregates.jl")
        include("systems/banks.jl")
        include("systems/central_bank.jl")
        include("systems/epsilon.jl")
        include("systems/estimations.jl")
        include("systems/firms.jl")
        include("systems/government.jl")
        include("systems/households.jl")
        include("systems/rotw.jl")
    end


end
