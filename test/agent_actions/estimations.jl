import BeforeIT as Bit

using Test

@testset "test estimations actions" begin

    parameters, initial_conditions = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.Model(parameters, initial_conditions)

    @testset "test growth_expectations" begin
        # TODO
    end

    @testset "test growth_inflation_EA" begin
        # TODO
    end

    @testset "test inflation_priceindex" begin

        resize!(model.firms.P_i, 3); model.firms.P_i .= [1.0, 2.0, 3.0]
        resize!(model.firms.Y_i, 3); model.firms.Y_i .= [1.0, 2.0, 3.0]
        model.agg.P_bar = 2.0
        expected_inflation = log(14 / 12)
        expected_priceindex = 14 / 6
        inflation, priceindex = Bit.inflation_priceindex(model.firms, model)
        @test isapprox(inflation, expected_inflation, atol = 1.0e-10)
    end

    @testset "test sector_specific_priceindex" begin
        resize!(model.firms.P_i, 3); model.firms.P_i .= [1.0, 2.0, 3.0]
        resize!(model.firms.Q_i, 3); model.firms.Q_i .= [1.0, 2.0, 3.0]
        resize!(model.firms.G_i, 3); model.firms.G_i .= [1, 1, 1]
        model.rotw.P_m[1] = 2.0
        model.rotw.Q_m[1] = 1.0
        G = model.prop.G
        expected_priceindex = 16 / 7
        priceindex = Bit.sector_specific_priceindex(model.firms, model.rotw, G)
        @test isapprox(priceindex[1], expected_priceindex, atol = 1.0e-10)
    end

end
