import Random: randn
function randn(n1::Int, n2::Int)
    return ones(n1, n2)
end

using BeforeIT, MAT, Test, StatsBase

dir = @__DIR__

parameters = BeforeIT.AUSTRIA2010Q1.parameters
initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions
T = 1
model = BeforeIT.initialise_model(parameters, initial_conditions, T;)


gov = model.gov # government
cb = model.cb # central bank
rotw = model.rotw # rest of the world
firms = model.firms # firms
bank = model.bank # bank
w_act = model.w_act # active workers
w_inact = model.w_inact # inactive workers
agg = model.agg # aggregates
prop = model.prop # model properties

"""
Testing an entire epoch of the model
"""
t = 1
####### GENERAL ESTIMATIONS #######

BeforeIT.finance_insolvent_firms!(firms, bank, model)

# expectation on economic growth and inflation
Y_e, gamma_e, pi_e = BeforeIT.growth_inflation_expectations(model)
agg.Y_e, agg.gamma_e, agg.pi_e = Y_e, gamma_e, pi_e

# update growth and inflation of economic area
epsilon_Y_EA, epsilon_E, epsilon_I = BeforeIT.epsilon(prop.C)
agg.epsilon_Y_EA, agg.epsilon_E, agg.epsilon_I = epsilon_Y_EA, epsilon_E, epsilon_I

Y_EA, gamma_EA, pi_EA = BeforeIT.growth_inflation_EA(rotw, model)
rotw.Y_EA, rotw.gamma_EA, rotw.pi_EA = Y_EA, gamma_EA, pi_EA

# set central bank rate via the Taylor rule
cb.r_bar = BeforeIT.central_bank_rate(cb, model)

# update rate on loans and morgages
bank.r = BeforeIT.bank_rate(bank, model)


####### FIRM EXPECTATIONS AND DECISIONS #######

# compute firm quantity, price, investment and intermediate-goods, employment decisions, expected profits, and desired/expected loans and capital
Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, P_i = BeforeIT.firms_expectations_and_decisions(firms, model)

firms.Q_s_i .= Q_s_i
firms.I_d_i .= I_d_i
firms.DM_d_i .= DM_d_i
firms.N_d_i .= N_d_i
firms.Pi_e_i .= Pi_e_i
firms.P_i .= P_i
firms.DL_d_i .= DL_d_i
firms.K_e_i .= K_e_i
firms.L_e_i .= L_e_i

@test isapprox(mean(Q_s_i), 216.1183, rtol = 0.05)
@test isapprox(mean(I_d_i), 20.5001, rtol = 0.05)
@test isapprox(mean(DM_d_i), 109.2771, rtol = 0.05)
@test isapprox(mean(N_d_i), 6.1955, rtol = 0.05)
@test isapprox(mean(Pi_e_i), 16.4285, rtol = 0.05)
@test isapprox(mean(DL_d_i), 6.6091, rtol = 0.05)
@test isapprox(mean(K_e_i), 1210.3, rtol = 0.05)
@test isapprox(mean(L_e_i), 360.6940, rtol = 0.05)
@test isapprox(mean(model.firms.P_i), 1.0058, rtol = 0.05)


####### CREDIT MARKET, LABOUR MARKET AND PRODUCTION #######

# firms acquire new loans in a search and match market for credit
firms.DL_i .= BeforeIT.search_and_matching_credit(firms, model) # actual new loans obtained

@test isapprox(mean(firms.DL_i[firms.DL_i .> 0]), 98.0084780508992, rtol = 0.05)

# firms acquire labour in the search and match market for labour

N_i, Oh = BeforeIT.search_and_matching_labour(firms, model)
firms.N_i .= N_i
w_act.O_h .= Oh

# update wages and productivity of labour and compute production function (Leontief technology)
firms.w_i .= BeforeIT.firms_wages(firms)
firms.Y_i .= BeforeIT.firms_production(firms)

@test isapprox(mean(model.firms.Y_i), 218.6994, rtol = 0.05)

# update wages for workers
BeforeIT.update_workers_wages!(w_act, firms.w_i)

@test isapprox(mean(model.w_act.w_h), 7.6127, rtol = 0.05)

####### CONSUMPTION AND INVESTMENT BUDGET #######

# update social benefits
gov.sb_other, gov.sb_inact = BeforeIT.gov_social_benefits(gov, model)

# compute expected bank profits
Pi_e_k = BeforeIT.bank_expected_profits(bank, model)
bank.Pi_e_k = Pi_e_k

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


@test isapprox(mean(model.w_act.C_d_h), 4.2084, rtol = 0.05)
@test isapprox(mean(model.w_inact.C_d_h), 2.2375, rtol = 0.05)
@test isapprox(mean(model.firms.C_d_h), 9.1631, rtol = 0.05)
@test isapprox(mean(model.bank.C_d_h), 2922.9, rtol = 0.05)

@test isapprox(mean(model.w_act.I_d_h), 0.3494, rtol = 0.05)
@test isapprox(mean(model.w_inact.I_d_h), 0.1858, rtol = 0.05)
@test isapprox(mean(model.firms.I_d_h), 0.7608, rtol = 0.05)
@test isapprox(mean(model.bank.I_d_h), 242.6783, rtol = 0.05)

####### GOVERNMENT SPENDING BUDGET, IMPORT-EXPORT BUDGET #######

# compute gov expenditure
C_G, C_d_j = BeforeIT.gov_expenditure(gov, model)
gov.C_G = C_G
gov.C_d_j .= C_d_j

@test isapprox(mean(model.gov.C_G), 14961, rtol = 0.05)
@test isapprox(mean(model.gov.C_d_j), 94.2925, rtol = 0.05)

# compute demand for export and supply of imports 
C_E, Y_I, C_d_l, Y_m, P_m = BeforeIT.rotw_import_export(rotw, model)
rotw.C_E = C_E
rotw.Y_I = Y_I
rotw.C_d_l .= C_d_l
rotw.Y_m .= Y_m
rotw.P_m .= P_m

@test isapprox(mean(model.rotw.C_E), 35237, rtol = 0.05)
@test isapprox(mean(model.rotw.C_d_l), 113.4786, rtol = 0.05)
@test isapprox(model.rotw.Y_I, 34437, rtol = 0.05)


####### GENERAL SEARCH AND MATCHING FOR ALL GOODS #######


BeforeIT.search_and_matching!(model, false)

@test isapprox(mean(model.w_act.C_h), 4.2298, rtol = 0.05)
@test isapprox(mean(model.w_inact.C_h), 2.2471, rtol = 0.05)
@test isapprox(mean(model.firms.C_h), 9.2015, rtol = 0.05)
@test isapprox(model.bank.C_h, 2919.4, rtol = 0.05)

@test isapprox(mean(model.w_act.I_h), 0.3508, rtol = 0.05)
@test isapprox(mean(model.w_inact.I_h), 0.1863, rtol = 0.05)
@test isapprox(mean(model.firms.I_h), 0.7621, rtol = 0.05)
@test isapprox(model.bank.I_h, 240.7679, rtol = 0.05)

@test isapprox(model.gov.C_j, 14837, rtol = 0.05)
@test isapprox(model.rotw.C_l, 35380, rtol = 0.05)

@test isapprox(mean(model.firms.I_i), 20.4739, rtol = 0.05)
@test isapprox(mean(mean(model.firms.DM_i)), 109.7708, rtol = 0.05)
@test isapprox(mean(model.firms.DM_i), 109.1375, rtol = 0.05)
@test isapprox(mean(model.firms.P_bar_i), 1.0077, rtol = 0.05)
@test isapprox(mean(model.firms.P_CF_i), 1.0077, rtol = 0.05)
@test isapprox(mean(model.firms.Q_d_i), 215.9086, rtol = 0.05)
@test isapprox(mean(model.rotw.Q_d_m), 551.7461, rtol = 0.05)

####### FINAL GENERAL ACCOUNTING #######

# update inflation and update global price index
model.agg.pi_[prop.T_prime + t], model.agg.P_bar = BeforeIT.inflation_priceindex(firms.P_i, firms.Y_i, model.agg.P_bar)

# update sector-specific price index
model.agg.P_bar_g .= BeforeIT.sector_specific_priceindex(firms, rotw, prop.G)

# update CF index and HH (CPI) index
model.agg.P_bar_CF = sum(prop.products.b_CF_g .* model.agg.P_bar_g)
model.agg.P_bar_HH = sum(prop.products.b_HH_g .* model.agg.P_bar_g)

# update firms stocks
# update firms stocks
K_i, M_i, DS_i, S_i = BeforeIT.firms_stocks(firms)
firms.K_i .= K_i
firms.M_i .= M_i
firms.DS_i .= DS_i
firms.S_i .= S_i

@test isapprox(mean(model.firms.K_i), 1203.2, rtol = 0.05)
@test isapprox(mean(model.firms.M_i), 128.3496, rtol = 0.05)
@test isapprox(mean(model.firms.S_i), 0.16, atol = 0.5)

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

# compute central bank profits
cb.E_CB = BeforeIT.central_bank_equity(cb, model)

# compute government revenues (Y_G), surplus/deficit (Pi_G) and debt (L_H)
gov.Y_G = BeforeIT.gov_revenues(model)

@test isapprox(gov.Y_G, 28620, rtol = 0.05)

# compute government deficit/surplus and update the government debt
L_G = BeforeIT.gov_loans(gov, model)
Pi_G = L_G - gov.L_G
gov.L_G = L_G

@test isapprox(Pi_G, 3845, rtol = 0.05) 

# compute firms deposits, loans and equity
firms.D_i .= BeforeIT.firms_deposits(firms, model)

firms.L_i .= BeforeIT.firms_loans(firms, model)

firms.E_i .= BeforeIT.firms_equity(firms, model)

# update net credit/debit position of rest of the world
rotw.D_RoW = BeforeIT.rotw_deposits(rotw, model)

# update bank net credit/debit position
bank.D_k = BeforeIT.bank_deposits(bank, model)

# update GDP with the results of the time step
model.agg.Y[prop.T_prime + t] = sum(firms.Y_i)
