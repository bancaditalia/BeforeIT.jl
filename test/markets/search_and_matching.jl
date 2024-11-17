using BeforeIT, Test, MAT, StatsBase
using Random

@testset "search and matching" begin
    Random.seed!(1)

    parameters = BeforeIT.AUSTRIA2010Q1.parameters
    initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions

    T = 1
    model = BeforeIT.init_model(parameters, initial_conditions, T;)

    gov = model.gov         # government
    cb = model.cb           # central bank
    rotw = model.rotw       # rest of the world
    firms = model.firms     # firms
    bank = model.bank       # bank
    w_act = model.w_act     # active workers
    w_inact = model.w_inact # inactive workers
    agg = model.agg         # aggregates
    prop = model.prop       # model properties

    BeforeIT.finance_insolvent_firms!(firms, bank, model)

    agg.Y_e, agg.gamma_e, agg.pi_e = BeforeIT.growth_inflation_expectations(model)

    agg.epsilon_Y_EA, agg.epsilon_E, agg.epsilon_I = BeforeIT.epsilon(prop.C)

    rotw.Y_EA, rotw.gamma_EA, rotw.pi_EA = BeforeIT.growth_inflation_EA(rotw, model)

    cb.r_bar = BeforeIT.central_bank_rate(cb, model)

    bank.r = BeforeIT.bank_rate(bank, model)

    Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, P_i =
        BeforeIT.firms_expectations_and_decisions(firms, model)

    firms.Q_s_i .= Q_s_i
    firms.I_d_i .= I_d_i
    firms.DM_d_i .= DM_d_i
    firms.N_d_i .= N_d_i
    firms.Pi_e_i .= Pi_e_i
    firms.P_i .= P_i
    firms.DL_d_i .= DL_d_i
    firms.K_e_i .= K_e_i
    firms.L_e_i .= L_e_i

    firms.DL_i .= BeforeIT.search_and_matching_credit(firms, model)

    N_i, Oh = BeforeIT.search_and_matching_labour(firms, model)
    firms.N_i .= N_i
    w_act.O_h .= Oh

    firms.w_i .= BeforeIT.firms_wages(firms)
    firms.Y_i .= BeforeIT.firms_production(firms)

    BeforeIT.update_workers_wages!(w_act, firms.w_i)

    gov.sb_other, gov.sb_inact = BeforeIT.gov_social_benefits(gov, model)

    bank.Pi_e_k = BeforeIT.bank_expected_profits(bank, model)

    C_d_h, I_d_h = BeforeIT.households_budget_act(w_act, model)
    w_act.C_d_h .= C_d_h
    w_act.I_d_h .= I_d_h
    C_d_h, I_d_h = BeforeIT.households_budget_inact(w_inact, model)
    w_inact.C_d_h .= C_d_h
    w_inact.I_d_h .= I_d_h
    C_d_h, I_d_h = BeforeIT.households_budget(firms, model)
    firms.C_d_h .= C_d_h
    firms.I_d_h .= I_d_h
    bank.C_d_h, bank.I_d_h = BeforeIT.households_budget(bank, model)

    C_G, C_d_j = BeforeIT.gov_expenditure(gov, model)
    gov.C_G = C_G
    gov.C_d_j .= C_d_j

    C_E, Y_I, C_d_l, Y_m, P_m = BeforeIT.rotw_import_export(rotw, model)
    rotw.C_E = C_E
    rotw.Y_I = Y_I
    rotw.C_d_l .= C_d_l
    rotw.Y_m .= Y_m
    rotw.P_m .= P_m

    BeforeIT.search_and_matching!(model, false)

    rtol = 0.0001
    # NOTE: the expected numbers come out of the original implementation, 
    # and only hold for the serial code (without multithreading)
    @test isapprox(mean(w_act.C_h), 4.148850396106796, rtol = rtol)
    @test isapprox(mean(firms.I_i), 20.5075, rtol = 2*0.12763)
    @test isapprox(mean(firms.DM_i), 109.3163, rtol = 2*0.68033)
    @test isapprox(mean(firms.P_bar_i), 1.0031, rtol = 2*0.0044726)
    @test isapprox(mean(firms.P_CF_i), 1.0031, rtol = 2*0.0044726)

    @test isapprox(bank.I_h, 244.42776822353426, rtol = rtol)
    @test isapprox(mean(w_act.I_h), 0.32975, rtol = 2*0.0025351)
    @test isapprox(mean(w_inact.I_h), 0.18162243697695482, rtol = rtol)
    @test isapprox(mean(firms.I_h), 0.7316919957786155, rtol = rtol)
    @test isapprox(mean(w_inact.C_h), 2.203922884342319, rtol = rtol)
    @test isapprox(mean(firms.C_h), 9.0276113211221, rtol = rtol)
    @test isapprox(bank.C_h, 2940.438274750598, rtol = rtol)
    @test isapprox(gov.C_j, 14684.361815480583, rtol = rtol)
    @test isapprox(rotw.C_l, 44260.46666796691, rtol = rtol)
    @test isapprox(mean(firms.Q_d_i), 216.2474, rtol = 2*1.2275)
    @test isapprox(mean(rotw.Q_d_m), 719.2385742449192, rtol = rtol)
end
