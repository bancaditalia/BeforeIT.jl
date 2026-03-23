import BeforeIT as Bit

using Test

@testset "test bank actions" begin

    parameters, initial_conditions = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.Model(parameters, initial_conditions)

    @testset "test bank_profits" begin

        resize!(model.firms.L_i, 3); model.firms.L_i .= [1.0, -1.0, 0.0]
        resize!(model.firms.D_i, 3); model.firms.D_i .= [1.0, -1.0, 0.0]
        resize!(model.firms.D_h, 3); model.firms.D_h .= [1.0, -1.0, 0.0]
        resize!(model.firms.B_i, 3); model.firms.B_i .= [1, 1, 1]  # Assign all firms to bank 1
        model.prop.I = 3  # Update number of firms
        resize!(model.w_act.D_h, 0)
        resize!(model.w_inact.D_h, 0)
        resize!(model.w_act.B_h, 0)
        resize!(model.w_inact.B_h, 0)
        resize!(model.banks.firms[1], 3)
        resize!(model.banks.w_act[1], 0)
        resize!(model.banks.w_inact[1], 0)
        model.prop.H = 0  # Update number of workers
        model.banks.D_h[1] = 0.0
        model.banks.D_k[1] = 4.0
        model.cb.r_bar = 0.1
        model.banks.r[1] = 0.05

        expected_profits = 0.3
        Pi_k = Bit.banks_profits(model)
        @test isapprox(mean(Pi_k), expected_profits, atol = 1.0e-10)
    end

    @testset "test bank_expected_profits" begin
        Pi_k = fill(1.0, length(model.banks.Pi_k))
        model.banks.Pi_k .= Pi_k
        model.agg.pi_e = 0.1
        model.agg.gamma_e = 0.2
        expected_profits = 1.32
        Pi_k = Bit.banks_expected_profits(model)
        @test isapprox(mean(Pi_k), expected_profits, atol = 1.0e-10)
    end

    @testset "test bank_equity" begin
        # TODO
    end

    @testset "test finance_insolvent_firms!" begin
        # TODO
    end

    parameters, initial_conditions = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.Model(parameters, initial_conditions)

    @testset "test bank_deposits" begin
        w_act, w_inact, firms, banks = model.w_act, model.w_inact, model.firms, model.banks
        resize!(w_act.D_h, 3); w_act.D_h .= [1.0, 2.0, 3.0]
        resize!(w_inact.D_h, 3); w_inact.D_h .= [1.0, 2.0, 3.0]
        resize!(w_act.B_h, 3); w_act.B_h .= [1, 1, 1]  # Assign all active workers to bank 1
        resize!(w_inact.B_h, 3); w_inact.B_h .= [1, 1, 1]  # Assign all inactive workers to bank 1
        resize!(firms.D_h, 3); firms.D_h .= [1.0, 2.0, 3.0]
        resize!(firms.D_i, 3); firms.D_i .= [1.0, 2.0, 3.0]
        resize!(firms.L_i, 3); firms.L_i .= [6.0, 0.0, 0.0]
        resize!(firms.B_i, 3); firms.B_i .= [1, 1, 1]  # Assign all firms to bank 1
        resize!(banks.firms[1], 3)
        resize!(banks.w_act[1], 3)
        resize!(banks.w_inact[1], 3)
        model.prop.I = 3  # Update number of firms
        model.prop.H = 3  # Update number of active workers
        banks.D_h[1] = 6.0
        banks.E_k[1] = 6.0
        expected_deposits = 30.0
        D_h = Bit.banks_deposits(model)
        @test isapprox(mean(D_h), expected_deposits, atol = 1.0e-10)
    end

end
