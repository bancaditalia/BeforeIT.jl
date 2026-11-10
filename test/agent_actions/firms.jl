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

    @testset "test desired_capital_material_employment" begin
        parameters, initial_conditions = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions
        firms = Bit.Model(parameters, initial_conditions).firms

        # firm 1 is limited by demand, firms 2 and 3 by their capacity K_i * kappa_i = [2, 3, 4]
        Q_s_i = [0.2, 100.0, 7.0]
        resize!(firms.K_i, 3); firms.K_i .= [4.0, 6.0, 2.0]
        resize!(firms.kappa_i, 3); firms.kappa_i .= [0.5, 0.5, 2.0]
        resize!(firms.delta_i, 3); firms.delta_i .= [0.1, 0.1, 0.2]
        resize!(firms.beta_i, 3); firms.beta_i .= [2.0, 2.0, 4.0]
        resize!(firms.alpha_bar_i, 3); firms.alpha_bar_i .= [1.0, 0.5, 2.0]

        # each firm plans for min(Q_s_i, K_i * kappa_i) = [0.2, 3, 4], whatever the other firms do
        expected_I_d_i = [0.04, 0.6, 0.4]
        expected_DM_d_i = [0.1, 1.5, 1.0]
        expected_N_d_i = [1.0, 6.0, 2.0]
        I_d_i, DM_d_i, N_d_i = Bit.desired_capital_material_employment(firms, Q_s_i)
        @test isapprox(I_d_i, expected_I_d_i, atol = 1.0e-10)
        @test isapprox(DM_d_i, expected_DM_d_i, atol = 1.0e-10)
        @test N_d_i == expected_N_d_i

        # the plans must not depend on the ordering of the firms
        p = [3, 1, 2]
        for x in (firms.K_i, firms.kappa_i, firms.delta_i, firms.beta_i, firms.alpha_bar_i)
            x .= x[p]
        end
        I_d_i, DM_d_i, N_d_i = Bit.desired_capital_material_employment(firms, Q_s_i[p])
        @test isapprox(I_d_i, expected_I_d_i[p], atol = 1.0e-10)
        @test isapprox(DM_d_i, expected_DM_d_i[p], atol = 1.0e-10)
        @test N_d_i == expected_N_d_i[p]
    end

end
