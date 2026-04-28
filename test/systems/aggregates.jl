@testset "System Parity: GDP and Time Tracking" begin

    model = Bit.ECSModel(Bit.STEADY_STATE2010Q1)

    world = model.world
    properties = Bit.properties(model)
    # Fetch initial resources and properties
    macro_state = Ark.get_resource(world, Bit.MacroeconomicState)
    time_index = Ark.get_resource(world, Bit.TimeIndex)

    T_prime = properties.dimensions.interval_for_expectation_estimation
    initial_step = time_index.step
    initial_history_length = length(macro_state.gross_domestic_product_history)

    # 1. Calculate Expected GDP (OOP: sum(firms.Y_i))
    # We simulate the OOP behavior by iterating over the ECS components directly
    expected_gdp = 0.0
    for (_, output) in Ark.Query(world, (Bit.Components.Output,))
        expected_gdp += sum(output.amount)
    end

    # 2. Run the ECS Systems
    Bit.set_gross_domestic_product!(world)
    Bit.set_time!(world)

    # 3. Verify Functional Parity for GDP (OOP: push!(agg.Y, 0.0); agg.Y[...] = sum(firms.Y_i))
    @test length(macro_state.gross_domestic_product_history) == initial_history_length + 1

    # The history should be updated at the index T_prime + initial_step
    # (Note: we use initial_step because set_time! happens after set_gross_domestic_product! in the original sequence)
    target_index = T_prime + initial_step
    @test isapprox(macro_state.gross_domestic_product_history[target_index], expected_gdp, atol = 1.0e-7)

    # 4. Verify Time Increment (OOP: model.agg.t += 1)
    @test time_index.step == initial_step + 1
end
