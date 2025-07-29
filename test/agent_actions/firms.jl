
import BeforeIT as Bit

using Test

@testset "test firms actions" begin
    @testset "test get_leontief_production" begin
        Q_s_i = [1.0, 2.0, 0.0]
        N_i = [1.0, 2.0, 3.0]
        alpha_i = [1.0, 2.0, 3.0]
        K_i = [1.0, 2.0, 3.0]
        kappa_i = [1.0, 0.0, 3.0]
        M_i = [1.0, 2.0, 3.0]
        beta_i = [1.0, 2.0, 3.0]
        expected_Y_i = [1.0, 0.0, 0.0]
        Y_i = Bit.leontief_production(Q_s_i, N_i, alpha_i, K_i, kappa_i, M_i, beta_i)
        @test Y_i == expected_Y_i
    end
end
