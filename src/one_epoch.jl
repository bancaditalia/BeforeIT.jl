

"""
    run_one_epoch!(model; multi_threading = false)

This function simulates a single epoch the economic model, updating various components of the model based 
the interactions between different economic agents. It accepts a `model` object, which encapsulates the state for the
simulation, and an optional boolean parameter `multi_threading` to enable or disable multi-threading.

Key operations performed include:
- Financial adjustments for firms and banks, including insolvency checks and profit calculations.
- Economic expectations and adjustments, such as growth, inflation, and central bank rates.
- Labor and credit market operations, including wage updates and loan processing.
- Household economic activities, including consumption and investment budgeting.
- Government and international trade financial activities, including budgeting and trade balances.
- General market matching and accounting updates to reflect changes in economic indicators and positions.

The function updates the model in-place and does not return any value.
"""
function run_one_epoch!(model; multi_threading = false, shock = NoShock())

    gov = model.gov # government
    cb = model.cb # central bank
    rotw = model.rotw # rest of the world
    firms = model.firms # firms
    bank = model.bank # bank
    w_act = model.w_act # active workers
    w_inact = model.w_inact # inactive workers
    agg = model.agg # aggregates
    prop = model.prop # model properties

    # return an error if t is greater than T
    if agg.t > prop.T + 1
        error("The model has already reached the final time step.")
    end

    BeforeIT.finance_insolvent_firms!(firms, bank, model)

    ####### GENERAL ESTIMATIONS #######

    # expectation on economic growth and inflation
    agg.Y_e, agg.gamma_e, agg.pi_e = BeforeIT.growth_inflation_expectations(model)

    # update growth and inflation of economic area
    agg.epsilon_Y_EA, agg.epsilon_E, agg.epsilon_I = BeforeIT.epsilon(prop.C)

    rotw.Y_EA, rotw.gamma_EA, rotw.pi_EA = BeforeIT.growth_inflation_EA(rotw, model)

    # set central bank rate via the Taylor rule
    cb.r_bar = BeforeIT.central_bank_rate(cb, model)

    # apply an eventual shock to the model, the default does nothing
    shock(model)

    # update rate on loans and morgages
    bank.r = BeforeIT.bank_rate(bank, model)

    ####### FIRM EXPECTATIONS AND DECISIONS #######

    # compute firm quantity, price, investment and intermediate-goods, employment decisions, expected profits, and desired/expected loans and capital
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

    ####### CREDIT MARKET, LABOUR MARKET AND PRODUCTION #######

    # firms acquire new loans in a search and match market for credit
    firms.DL_i .= BeforeIT.search_and_matching_credit(firms, model) # actual new loans obtained

    # firms acquire labour in the search and match market for labour
    N_i, Oh = BeforeIT.search_and_matching_labour(firms, model)
    firms.N_i .= N_i
    w_act.O_h .= Oh


    # update wages and productivity of labour and compute production function (Leontief technology)
    firms.w_i .= BeforeIT.firms_wages(firms)
    firms.Y_i .= BeforeIT.firms_production(firms)


    # update wages for workers
    BeforeIT.update_workers_wages!(w_act, firms.w_i)


    ####### CONSUMPTION AND INVESTMENT BUDGET #######

    # update social benefits
    gov.sb_other, gov.sb_inact = BeforeIT.gov_social_benefits(gov, model)

    # compute expected bank profits
    bank.Pi_e_k = BeforeIT.bank_expected_profits(bank, model)

    # compute consumption and investment budget for all hauseholds
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


    ####### GOVERNMENT SPENDING BUDGET, IMPORT-EXPORT BUDGET #######

    # compute gov expenditure
    C_G, C_d_j = BeforeIT.gov_expenditure(gov, model)
    gov.C_G = C_G
    gov.C_d_j .= C_d_j

    # compute demand for export and supply of imports 
    C_E, Y_I, C_d_l, Y_m, P_m = BeforeIT.rotw_import_export(rotw, model)
    rotw.C_E = C_E
    rotw.Y_I = Y_I
    rotw.C_d_l .= C_d_l
    rotw.Y_m .= Y_m
    rotw.P_m .= P_m

    ####### GENERAL SEARCH AND MATCHING FOR ALL GOODS #######

    BeforeIT.search_and_matching!(model, multi_threading)

    ####### FINAL GENERAL ACCOUNTING #######

    # update inflation and update global price index
    agg.pi_[prop.T_prime + agg.t], agg.P_bar = BeforeIT.inflation_priceindex(firms.P_i, firms.Y_i, agg.P_bar)

    # update sector-specific price index
    agg.P_bar_g .= BeforeIT.sector_specific_priceindex(firms, rotw, prop.G)

    # update CF index and HH (CPI) index
    agg.P_bar_CF = sum(prop.products.b_CF_g .* agg.P_bar_g)
    agg.P_bar_HH = sum(prop.products.b_HH_g .* agg.P_bar_g)

    # update firms stocks
    K_i, M_i, DS_i, S_i = BeforeIT.firms_stocks(firms)
    firms.K_i .= K_i
    firms.M_i .= M_i
    firms.DS_i .= DS_i
    firms.S_i .= S_i

    # update firms profits
    firms.Pi_i .= BeforeIT.firms_profits(firms, model)

    # update bank profits
    bank.Pi_k = BeforeIT.bank_profits(bank, model)

    # update bank equity
    bank.E_k = BeforeIT.bank_equity(bank, model)

    # update actual income of all households
    w_act.Y_h .= BeforeIT.households_income_act(w_act, model)
    w_inact.Y_h .= BeforeIT.households_income_inact(w_inact, model)
    firms.Y_h .= BeforeIT.households_income(firms, model)
    bank.Y_h = BeforeIT.households_income(bank, model)

    # update savings (deposits) of all households
    w_act.D_h .= BeforeIT.households_deposits(w_act, model)
    w_inact.D_h .= BeforeIT.households_deposits(w_inact, model)
    firms.D_h .= BeforeIT.households_deposits(firms, model)
    bank.D_h = BeforeIT.households_deposits(bank, model)

    # compute central bank equity
    cb.E_CB = BeforeIT.central_bank_equity(cb, model)

    # compute government revenues (Y_G), surplus/deficit (Pi_G) and debt (L_H)
    gov.Y_G = BeforeIT.gov_revenues(model)

    # compute government deficit/surplus and update the government debt
    gov.L_G = BeforeIT.gov_loans(gov, model)

    # compute firms deposits, loans and equity
    firms.D_i .= BeforeIT.firms_deposits(firms, model)

    firms.L_i .= BeforeIT.firms_loans(firms, model)

    firms.E_i .= BeforeIT.firms_equity(firms, model)

    # update net credit/debit position of rest of the world
    rotw.D_RoW = BeforeIT.rotw_deposits(rotw, model)

    # update bank net credit/debit position
    bank.D_k = BeforeIT.bank_deposits(bank, model)

    # update GDP with the results of the time step
    agg.Y[prop.T_prime + agg.t] = sum(firms.Y_i)

    agg.t += 1
end
