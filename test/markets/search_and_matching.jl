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
    agg = model.agg         # aggregate variables

    prop = model.prop # model properties

    gamma_e = 0.01 # set expected growth in euro area
    pi_e = 0.001   # set expected inflation in euro area

    agg.gamma_e = gamma_e
    agg.pi_e = pi_e

    Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, P_i =
        BeforeIT.firms_expectations_and_decisions(model.firms, model)

    firms.Q_s_i .= Q_s_i
    firms.I_d_i .= I_d_i
    firms.DM_d_i .= DM_d_i
    firms.N_d_i .= N_d_i
    firms.Pi_e_i .= Pi_e_i
    firms.P_i .= P_i
    firms.DL_d_i .= DL_d_i
    firms.K_e_i .= K_e_i
    firms.L_e_i .= L_e_i

    Pi_e_k = BeforeIT.bank_expected_profits(bank, model)
    bank.Pi_e_k = Pi_e_k

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

    epsilon_E = 0.28
    epsilon_I = 0.36

    agg.epsilon_E = epsilon_E
    agg.epsilon_I = epsilon_I

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
    @test isapprox(mean(firms.I_i), 20.671016463479898, rtol = rtol)
    @test isapprox(mean(firms.DM_i), 110.18635469222951, rtol = rtol)
    @test isapprox(mean(firms.P_bar_i), 1.0010000000000023, rtol = rtol)
    @test isapprox(mean(firms.P_CF_i), 1.0010000000000023, rtol = rtol)

    # the expected numbers of these tests are not stable so different seeds
    # will make them fail
    @test isapprox(bank.I_h, 244.42776822353426, rtol = rtol)
    @test isapprox(mean(w_act.I_h), 0.3420136195963817, rtol = rtol)
    @test isapprox(mean(w_inact.I_h), 0.18162243697695482, rtol = rtol)
    @test isapprox(mean(firms.I_h), 0.7316919957786155, rtol = rtol)
    @test isapprox(mean(w_inact.C_h), 2.203922884342319, rtol = rtol)
    @test isapprox(mean(firms.C_h), 9.0276113211221, rtol = rtol)
    @test isapprox(bank.C_h, 2940.438274750598, rtol = rtol)
    @test isapprox(gov.C_j, 14684.361815480583, rtol = rtol)
    @test isapprox(rotw.C_l, 44260.46666796691, rtol = rtol)
    @test isapprox(mean(firms.Q_d_i), 216.9251832069571, rtol = rtol)
    @test isapprox(mean(rotw.Q_d_m), 717.0466954045518, rtol = rtol)
end
