using BeforeIT, Test

@testset "test estimations actions" begin

    @testset "test growth_expectations" begin
        # TODO : how to circumvent estimate?
    end

    @testset "test growth_inflation_EA" begin

    end

    @testset "test inflation_priceindex" begin
        P_i = [1.0, 2.0, 3.0]
        Y_i = [1.0, 2.0, 3.0]
        P_bar = 2.0
        expected_inflation = log(14 / 12)
        expected_priceindex = 14 / 6
        inflation, priceindex = BeforeIT.inflation_priceindex(P_i, Y_i, P_bar)
        @test isapprox(inflation, expected_inflation, atol = 1e-10)
    end

    @testset "test _sector_specific_priceindex" begin
        P_i = [1.0, 2.0, 3.0]
        Y_i = [1.0, 2.0, 3.0]
        P_m = 2.0
        Q_m = 1.0
        expected_priceindex = 16 / 7
        priceindex = BeforeIT._sector_specific_priceindex(P_i, Y_i, P_m, Q_m)
        @test isapprox(priceindex, expected_priceindex, atol = 1e-10)
    end

end
