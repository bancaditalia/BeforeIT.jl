import BeforeIT as Bit

using Test

@testset "test bank actions" begin

    @testset "test bank_profits" begin
        L_i = [1.0, -1.0, 0.0]
        D_i = [1.0, -1.0, 0.0]
        D_h = [1.0, -1.0, 0.0]
        D_k = 4.0
        r_bar = 0.1
        r = 0.05
        expected_profits = 0.3
        Pi_k = Bit._bank_profits(L_i, D_i, D_h, D_k, r_bar, r)
        @test isapprox(Pi_k, expected_profits, atol = 1.0e-10)
    end

    @testset "test net_profits" begin
        Pi_k = 1.0
        theta_DIV = 0.01
        tau_FIRM = 0.2
        expected_net_profits = 0.792
        DE_k = Bit._bank_net_profits(Pi_k, theta_DIV, tau_FIRM)
        @test isapprox(DE_k, expected_net_profits, atol = 1.0e-10)
        Pi_k = -1.0
        expected_net_profits = -1.0
        DE_k = Bit._bank_net_profits(Pi_k, theta_DIV, tau_FIRM)
        @test isapprox(DE_k, expected_net_profits, atol = 1.0e-10)
    end

    #@testset "test expected_bank_profits" begin
    #    Pi_k = 1.0
    #    pi_e = 0.1
    #    gamma_e = 0.2
    #    expected_profits = 1.32
    #    Pi_k = Bit._bank_expected_profits(Pi_k, pi_e, gamma_e)
    #    @test isapprox(Pi_k, expected_profits, atol = 1.0e-10)
    #end

    @testset "finance_insolvent_firms!" begin
        @test 1 == 1

    end

    @testset "test _deposit_bank" begin
        waD_h = [1.0, 2.0, 3.0]
        wiD_h = [1.0, 2.0, 3.0]
        fD_h = [1.0, 2.0, 3.0]
        bD_h = 6.0
        fD_i = [1.0, 2.0, 3.0]
        bE_k = 6.0
        fL_i = 6.0
        expected_deposits = 30.0
        D_h = Bit._bank_deposits(waD_h, wiD_h, fD_h, bD_h, fD_i, bE_k, fL_i)
        @test isapprox(D_h, expected_deposits, atol = 1.0e-10)
    end

end
