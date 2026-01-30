import BeforeIT as Bit

using Test

@testset "test bank actions" begin

    parameters, initial_conditions = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.Model(parameters, initial_conditions)

    @testset "test bank_profits" begin

        resize!(model.firms.L_i, 3); model.firms.L_i .= [1.0, -1.0, 0.0]
        resize!(model.firms.D_i, 3); model.firms.D_i .= [1.0, -1.0, 0.0]
        resize!(model.firms.D_h, 3); model.firms.D_h .= [1.0, -1.0, 0.0]
        resize!(model.w_act.D_h, 0); resize!(model.w_inact.D_h, 0); model.bank.D_h = 0.0
        model.bank.D_k = 4.0
        model.cb.r_bar = 0.1
        model.bank.r = 0.05

        expected_profits = 0.3
        Pi_k = Bit.bank_profits(model)
        @test isapprox(Pi_k, expected_profits, atol = 1.0e-10)
    end

    @testset "test bank_expected_profits" begin
        model.bank.Pi_k = 1.0
        model.agg.pi_e = 0.1
        model.agg.gamma_e = 0.2
        expected_profits = 1.32
        Pi_k = Bit.bank_expected_profits(model)
        @test isapprox(Pi_k, expected_profits, atol = 1.0e-10)
    end

    @testset "test bank_equity" begin
        # TODO
    end

    @testset "test finance_insolvent_firms!" begin
        # TODO
    end

    @testset "test bank_deposits" begin
        w_act, w_inact, firms, bank = model.w_act, model.w_inact, model.firms, model.bank
        resize!(w_act.D_h, 3); w_act.D_h .= [1.0, 2.0, 3.0]
        resize!(w_inact.D_h, 3); w_inact.D_h .= [1.0, 2.0, 3.0]
        resize!(firms.D_h, 3); firms.D_h .= [1.0, 2.0, 3.0]
        resize!(firms.D_i, 3); firms.D_i .= [1.0, 2.0, 3.0]
        resize!(firms.D_i, 3); firms.L_i .= [6.0, 0.0, 0.0]
        bank.D_h = 6.0
        bank.E_k = 6.0
        expected_deposits = 30.0
        D_h = Bit.bank_deposits(model)
        @test isapprox(D_h, expected_deposits, atol = 1.0e-10)
    end

end
