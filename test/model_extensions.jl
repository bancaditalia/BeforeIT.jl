import BeforeIT as Bit

using Test

# smoke tests: only check that the shipped model variants can be built and stepped
@testset "model extensions run" begin
    # CANVAS needs the historical euro area series, available in the Italian initial conditions
    variants = (
        (Bit.ModelGR, Bit.AUSTRIA2010Q1),
        (Bit.ModelCANVAS, Bit.ITALY2010Q1),
    )
    for (constructor, state) in variants
        model = constructor(state.parameters, state.initial_conditions)
        @test model isa constructor
        Bit.run!(model, 1)
        @test model.agg.t == 2
    end
end
