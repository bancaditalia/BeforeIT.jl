
@testset "one epoch deterministic" begin

    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

    for multi_threading in [false, true]
        model = Bit.Model(parameters, initial_conditions)
    
        gov = model.gov # government
        cb = model.cb # central bank
        rotw = model.rotw # rest of the world
        firms = model.firms # firms
        bank = model.bank # bank
        w_act = model.w_act # active workers
        w_inact = model.w_inact # inactive workers
        agg = model.agg # aggregates
        prop = model.prop # model properties
    
        prop = model.prop
        agg.Y_e, agg.gamma_e, agg.pi_e = Bit.growth_inflation_expectations(model)
    
        @test isapprox(agg.Y_e, 134929.5631)
        @test isapprox(agg.gamma_e, 0.0021822, rtol = 1e-4)
    
        agg.epsilon_Y_EA, agg.epsilon_E, agg.epsilon_I = Bit.epsilon(prop.C)
    
        rotw.Y_EA, rotw.gamma_EA, rotw.pi_EA = Bit.growth_inflation_EA(rotw, model)
    
        @test isapprox(rotw.gamma_EA, 0.0016278, rtol = 1e-5)
        @test isapprox(rotw.Y_EA, 2358680.8201, rtol = 1e-5)
        @test isapprox(rotw.pi_EA, 0.0033723, rtol = 1e-5)
    
        # set central bank rate via the Taylor rule
        cb.r_bar = Bit.central_bank_rate(cb, model)
        @test isapprox(cb.r_bar, 0.0017616, rtol = 1e-4)
    
        # update rate on loans and morgages
        bank.r = Bit.bank_rate(bank, model)
        @test isapprox(bank.r, 0.028476, rtol = 1e-4)
    
        Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, P_i =
            Bit.firms_expectations_and_decisions(firms, model)
    
        firms.Q_s_i .= Q_s_i
        firms.I_d_i .= I_d_i
        firms.DM_d_i .= DM_d_i
        firms.N_d_i .= N_d_i
        firms.Pi_e_i .= Pi_e_i
        firms.P_i .= P_i
        firms.DL_d_i .= DL_d_i
        firms.K_e_i .= K_e_i
        firms.L_e_i .= L_e_i
    
        @test isapprox(mean(Q_s_i), 220.0311, rtol = 1e-6)
        @test isapprox(mean(I_d_i), 21.6029, rtol = 1e-5)
        @test isapprox(mean(DM_d_i), 110.8158, rtol = 1e-5)
        @test isapprox(mean(N_d_i), 6.2436, rtol = 1e-5)
        @test isapprox(mean(Pi_e_i), 17.5269, rtol = 1e-5)
        @test isapprox(mean(DL_d_i), 6.3063, rtol = 1e-5)
        @test isapprox(mean(K_e_i), 1265.3191, rtol = 1e-5)
        @test isapprox(mean(L_e_i), 360.694, rtol = 1e-5)
        @test isapprox(mean(firms.P_i), 1.0031, rtol = 1e-4)
    
        firms.DL_i .= Bit.search_and_matching_credit(firms, model) # actual new loans obtained
        @test isapprox(mean(firms.DL_i[firms.DL_i .> 0]), 95.9791, rtol = 1e-6)
    
        N_i, Oh = Bit.search_and_matching_labour(firms, model)
        firms.N_i .= N_i
        w_act.O_h .= Oh
    
        firms.w_i .= Bit.firms_wages(firms)
        firms.Y_i .= Bit.firms_production(firms)
    
        # @test isapprox(mean(V_i), 0.0, rtol = 1e-6)
        @test isapprox(mean(firms.w_i), 6.6122, rtol = 1e-5)
        @test isapprox(mean(firms.Y_i), 220.0311, rtol = 1e-6)
    
        # update wages for workers
        Bit.update_workers_wages!(w_act, firms.w_i)
    
        @test isapprox(mean(model.w_act.w_h), 7.5221, rtol = 1e-5)
    
        gov.sb_other, gov.sb_inact = Bit.gov_social_benefits(gov, model)
    
        @test isapprox(gov.sb_other, 0.59157, rtol = 1e-5)
        @test isapprox(gov.sb_inact, 2.2434, rtol = 1e-4)
    
        Pi_e_k = Bit.bank_expected_profits(bank, model)
        bank.Pi_e_k = Pi_e_k
        @test isapprox(Pi_e_k, 6510.4793, rtol = 1e-5)
    
        C_d_h, I_d_h = Bit.households_budget_act(w_act, model)
        w_act.C_d_h .= C_d_h
        w_act.I_d_h .= I_d_h
        C_d_h, I_d_h = Bit.households_budget_inact(w_inact, model)
        w_inact.C_d_h .= C_d_h
        w_inact.I_d_h .= I_d_h
        C_d_h, I_d_h = Bit.households_budget(firms, model)
        firms.C_d_h .= C_d_h
        firms.I_d_h .= I_d_h
        bank.C_d_h, bank.I_d_h = Bit.households_budget(bank, model)
    
        C_d_h_sum = sum(w_act.C_d_h) + sum(w_inact.C_d_h) + sum(firms.C_d_h) + bank.C_d_h
        I_d_h_sum = sum(w_act.I_d_h) + sum(w_inact.I_d_h) + sum(firms.I_d_h) + bank.I_d_h
    
        @test isapprox(C_d_h_sum, 35538.3159, rtol = 1e-9, atol = 1e-6)
        @test isapprox(I_d_h_sum, 2950.5957, rtol = 1e-6, atol = 1e-6)
    
        C_G, C_d_j = Bit.gov_expenditure(gov, model)
        gov.C_G = C_G
        gov.C_d_j .= C_d_j
    
        @test isapprox(mean(gov.C_G), 14783.2494, rtol = 1e-6, atol = 1e-6)
        @test isapprox(mean(gov.C_d_j), 95.0572, rtol = 1e-6, atol = 1e-6)
    
        C_E, Y_I, C_d_l, Y_m, P_m = Bit.rotw_import_export(rotw, model)
        rotw.C_E = C_E
        rotw.Y_I = Y_I
        rotw.C_d_l .= C_d_l
        rotw.Y_m .= Y_m
        rotw.P_m .= P_m
    
        @test isapprox(mean(rotw.C_E), 34246.8702, rtol = 1e-6, atol = 1e-6)
        @test isapprox(mean(rotw.C_d_l), 110.1048, rtol = 1e-6, atol = 1e-6)
        @test isapprox(rotw.Y_I, 33214.9736, rtol = 1e-6, atol = 1e-6)
        @test isapprox(mean(rotw.Y_m), 535.7254, rtol = 1e-6, atol = 1e-6)
        @test isapprox(mean(rotw.P_m), 1.0031, rtol = 1e-4, atol = 1e-6)
    
        Bit.search_and_matching!(model, multi_threading)
    
        C_h_sum = sum(w_act.C_h) + sum(w_inact.C_h) + sum(firms.C_h) + bank.C_h
        I_h_sum = sum(w_act.I_h) + sum(w_inact.I_h) + sum(firms.I_h) + bank.I_h
        K_h_sum = sum(w_act.K_h) + sum(w_inact.K_h) + sum(firms.K_h) + bank.K_h
        @test isapprox(C_h_sum, 35136.4805, rtol = 1e-8, atol = 1e-6)
        @test isapprox(I_h_sum, 2699.6511, rtol = 1e-7, atol = 1e-6)
        @test isapprox(K_h_sum, 408076.5511, rtol = 1e-8, atol = 1e-6)
    
        @test isapprox(mean(firms.Q_d_i), 220.092, rtol = 1e-6)
        @test isapprox(mean(firms.Q_i), 216.6644, rtol = 1e-6)
        @test isapprox(mean(rotw.Q_d_m), 527.2969, rtol = 1e-6)
        @test isapprox(mean(rotw.Q_m), 527.2969, rtol = 1e-5)
        @test isapprox(mean(firms.I_i), 21.6029, rtol = 1e-5)
        @test isapprox(mean(firms.DM_i), 110.7829, rtol = 1e-6)
        @test isapprox(mean(firms.P_CF_i), 1.0031, rtol = 1e-4)
        @test isapprox(mean(firms.P_bar_i), 1.0031, rtol = 1e-4)
        @test isapprox(gov.C_j, 14370.3493, rtol = 1e-5)
        @test isapprox(gov.P_j, 1.0031, rtol = 1e-4)
    
        K_i, M_i, DS_i, S_i = Bit.firms_stocks(firms)
        firms.K_i .= K_i
        firms.M_i .= M_i
        firms.DS_i .= DS_i
        firms.S_i .= S_i
    
        @test isapprox(mean(firms.K_i), 1261.4216, rtol = 1e-6)
        @test isapprox(mean(firms.M_i), 130.0548, rtol = 1e-6)
        @test isapprox(mean(firms.DS_i), 3.3667, atol = 1e-5)
        @test isapprox(mean(firms.S_i), 3.3667, atol = 1e-5)
    
        # update firms profits
        firms.Pi_i .= Bit.firms_profits(firms, model)
        @test isapprox(mean(firms.Pi_i), 17.5491, rtol = 1e-2)
    
        # update bank profits
        bank.Pi_k = Bit.bank_profits(bank, model)
        @test isapprox(bank.Pi_k, 6486.6381, rtol = 1e-5)
    
        # update bank equity
        bank.E_k = Bit.bank_equity(bank, model)
        @test isapprox(bank.E_k, 90742.39, rtol = 1e-5)
    
        # update actual income of all households
        w_act.Y_h .= Bit.households_income_act(w_act, model)
        w_inact.Y_h .= Bit.households_income_inact(w_inact, model)
    
        firms.Y_h .= Bit.households_income(firms, model)
        bank.Y_h = Bit.households_income(bank, model)
    
        # update savings (deposits) of all households
        w_act.D_h .= Bit.households_deposits(w_act, model)
        w_inact.D_h .= Bit.households_deposits(w_inact, model)
        firms.D_h .= Bit.households_deposits(firms, model)
        bank.D_h = Bit.households_deposits(bank, model)
    
        Y_h_sum = sum(w_act.Y_h) + sum(w_inact.Y_h) + sum(firms.Y_h) + bank.Y_h
        D_h_sum = sum(w_act.D_h) + sum(w_inact.D_h) + sum(firms.D_h) + bank.D_h
        @test isapprox(Y_h_sum, 45032.3263, rtol = 1e-2)
        @test isapprox(D_h_sum, 221816.6764, rtol = 1e-3)
    
        # compute central bank profits
        E_CB = Bit.central_bank_equity(cb, model)
        Pi_CB = E_CB - cb.E_CB
        cb.E_CB = E_CB
        @test isapprox(Pi_CB, 1866.3821, rtol = 1e-5)

        # compute gov revenues (Y_G), surplus/deficit (Pi_G) and debt (L_H)
        gov.Y_G = Bit.gov_revenues(model)
        @test isapprox(gov.Y_G, 28783.0089, rtol = 1e-2)
    
        # compute gov deficit/surplus
        L_G = Bit.gov_loans(gov, model)
        Pi_G = L_G - gov.L_G
        gov.L_G = L_G
        @test isapprox(Pi_G, 3140.6916, rtol = 1e-2)
        @test isapprox(gov.L_G, 235751.5916, rtol = 1e-4)
    
        # compute firms deposits, loans and equity
        D_i = Bit.firms_deposits(firms, model)
        DD_i = D_i .- firms.D_i
        firms.D_i .= D_i
    
        firms.L_i .= Bit.firms_loans(firms, model)
        firms.E_i .= Bit.firms_equity(firms, model)
    
        @test isapprox(mean(DD_i), -14.8245, rtol = 1e-2)
        @test isapprox(mean(firms.D_i), 71.7925, rtol = 1e-3)
        @test isapprox(mean(firms.L_i), 367.0003, rtol = 1e-5)
        @test isapprox(mean(firms.E_i), 1103.945, rtol = 1e-2)
    
        # check central bank equity
        @test isapprox(cb.E_CB, 108046.2821, rtol = 1e-2)
    
        # update net credit/debit position of rest of the world
        rotw.D_RoW = Bit.rotw_deposits(rotw, model)
        @test isapprox(rotw.D_RoW, -644.0817, rtol = 1e-5)
    
        # update bank net credit/debit position
        bank.D_k = Bit.bank_deposits(bank, model)
        @test isapprox(bank.D_k, 128349.3912, rtol = 1e-3)
    end
end
