using Revise
using BeforeIT
using MAT
using Test

dir = @__DIR__

parameters = matread(joinpath(dir, "../data/steady_state/parameters/2010Q1.mat"))
initial_conditions = matread(joinpath(dir, "../data/steady_state/initial_conditions/2010Q1.mat"))

T = 1
model = BeforeIT.init_model(parameters, initial_conditions, T;)
data = BeforeIT.init_data(model)


println(BeforeIT.get_accounting_identity_banks(model))


"""
Testing an entire epoch of the model
"""

####### GENERAL ESTIMATIONS #######
t = 1
prop = model.prop

# expectation on economic growth
Y_e, gamma_e = BeforeIT.growth_expectations(model.agg.Y, prop.T_prime, t)

# expectation on inflation
pi_e = BeforeIT.inflation_expectations(model.agg.pi_, prop.T_prime, t)

# update growth and inflation of economic area
epsilon_Y_EA, epsilon_E, epsilon_I = BeforeIT.epsilon(prop.C; rand = true) # use rand=false for testing
Y_EA, gamma_EA, pi_EA = BeforeIT.growth_inflation_EA(model.rotw, epsilon_Y_EA)
model.rotw.Y_EA, model.rotw.pi_EA = Y_EA, pi_EA

# set central bank rate via the Taylor rule
BeforeIT.taylor_rule!(model.cb, gamma_EA, pi_EA)

# update rate on loans and morgages
BeforeIT.update_bank_rate!(model.bank, model.cb.r_bar, prop.mu)

####### FIRM EXPECTATIONS AND DECISIONS #######

# compute firm quantity, price, investment and intermediate-goods, employment decisions, expected profits, and desired/expected loans and capital
Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, new_P_i = BeforeIT.firms_expectations_and_decisions(
    model.firms,
    prop.tau_SIF,
    prop.tau_FIRM,
    prop.theta,
    prop.theta_DIV,
    model.agg.P_bar_HH,
    model.agg.P_bar_CF,
    model.agg.P_bar_g,
    prop.products.a_sg,
    gamma_e,
    pi_e,
)

model.firms.P_i .= new_P_i


####### CREDIT MARKET, LABOUR MARKET AND PRODUCTION #######

# firms acquire new loans in a search and match market for credit
DL_i = BeforeIT.search_and_matching_credit(DL_d_i, K_e_i, L_e_i, model.bank.E_k, prop.zeta, prop.zeta_LTV) # actual loans obtained

# firms acquire labour in the search and match market for labour
V_i = N_d_i .- model.firms.N_i

temp_N_i, temp_Oh = BeforeIT.search_and_matching_labour(model.firms.N_i, V_i, model.w_act.O_h)
model.w_act.O_h .= temp_Oh
model.firms.N_i .= temp_N_i

# update wages and productivity of labour and compute production function (Leontief technology)
model.firms.w_i .= BeforeIT.wages_firms(model.firms, Q_s_i)
model.firms.Y_i .= BeforeIT.production(model.firms, Q_s_i)


# update wages for workers
BeforeIT.update_workers_wages!(model.w_act, model.firms.w_i)



####### CONSUMPTION AND INVESTMENT BUDGET #######

# update social benefits
BeforeIT.update_social_benefits!(model.gov, gamma_e)

# compute expected bank profits
Pi_e_k = BeforeIT.expected_bank_profits(model.bank.Pi_k, pi_e, gamma_e)

# compute consumption and investment budget for all hauseholds
BeforeIT.cons_inv_budget_w_act!(
    model.w_act,
    prop.psi,
    prop.psi_H,
    prop.tau_VAT,
    prop.tau_CF,
    model.gov.sb_other,
    model.agg.P_bar_HH,
    pi_e,
    prop.tau_SIW,
    prop.tau_INC,
    prop.theta_UB,
)

BeforeIT.cons_inv_budget_w_inact!(
    model.w_inact,
    prop.psi,
    prop.psi_H,
    prop.tau_VAT,
    prop.tau_CF,
    model.gov.sb_inact,
    model.gov.sb_other,
    model.agg.P_bar_HH,
    pi_e,
)

BeforeIT.cons_inv_budget_fowner!(
    model.firms,
    prop.psi,
    prop.psi_H,
    prop.tau_VAT,
    prop.tau_CF,
    prop.tau_INC,
    prop.tau_FIRM,
    prop.theta_DIV,
    Pi_e_i,
    model.gov.sb_other,
    model.agg.P_bar_HH,
    pi_e,
)

BeforeIT.cons_inv_budget_bowner!(
    model.bank,
    prop.psi,
    prop.psi_H,
    prop.tau_VAT,
    prop.tau_CF,
    prop.tau_INC,
    prop.tau_FIRM,
    prop.theta_DIV,
    Pi_e_k,
    model.gov.sb_other,
    model.agg.P_bar_HH,
    pi_e,
)


####### GOVERNMENT SPENDING BUDGET, IMPORT-EXPORT BUDGET #######

# compute government expenditure
BeforeIT.government_expenditure!(model.gov, prop.products.c_G_g, model.agg.P_bar_g, pi_e)

# compute demand for export and supply of imports 
BeforeIT.import_export!(
    model.rotw,
    model.agg.P_bar_g,
    prop.products.c_E_g,
    prop.products.c_I_g,
    pi_e,
    epsilon_E,
    epsilon_I,
)


####### GENERAL SEARCH AND MATCHING FOR ALL GOODS #######

BeforeIT.search_and_matching!(
    model.w_act,
    model.w_inact,
    model.firms,
    model.gov,
    model.bank,
    model.rotw,
    model.agg,
    prop,
    DM_d_i,
    I_d_i;
    multi_threading = false,
)

####### FINAL GENERAL ACCOUNTING #######

# update inflation and update global price index
model.agg.pi_[prop.T_prime + t], model.agg.P_bar =
    BeforeIT.inflation_priceindex(model.firms.P_i, model.firms.Y_i, model.agg.P_bar)

# update sector-specific price index
model.agg.P_bar_g .= BeforeIT.sector_specific_priceindex(model.firms, model.rotw, prop.G)

# update CF index and HH (CPI) index
model.agg.P_bar_CF = sum(prop.products.b_CF_g .* model.agg.P_bar_g)
model.agg.P_bar_HH = sum(prop.products.b_HH_g .* model.agg.P_bar_g)

# update firms stocks
BeforeIT.update_firms_stocks!(model.firms)

# update firms profits
model.firms.Pi_i .=
    BeforeIT.firms_profits(model.firms, model.agg.P_bar, model.agg.P_bar_HH, prop.tau_SIF, model.bank.r, model.cb.r_bar)

# update bank profits
model.bank.Pi_k = BeforeIT.bank_profits(model.bank, model.w_act, model.firms, model.cb.r_bar)

# update bank equity
model.bank.E_k += BeforeIT.net_profits(model.bank.Pi_k, prop.theta_DIV, prop.tau_FIRM)

# update actual income of all households
model.w_act.Y_h .= BeforeIT.households_income_act(
    model.w_act.w_h,
    model.w_act.O_h,
    prop.tau_SIW,
    prop.tau_INC,
    prop.theta_UB,
    model.gov.sb_other,
    model.agg.P_bar_HH,
)

model.w_inact.Y_h .=
    BeforeIT.income_w_inact(length(model.w_inact), model.gov.sb_inact, model.gov.sb_other, model.agg.P_bar_HH)

model.firms.Y_h .= BeforeIT.income_fowner(
    model.firms.Pi_i,
    prop.tau_INC,
    prop.tau_FIRM,
    prop.theta_DIV,
    model.gov.sb_other,
    model.agg.P_bar_HH,
)

model.bank.Y_h = BeforeIT.income_bowner(
    model.bank.Pi_k,
    prop.tau_INC,
    prop.tau_FIRM,
    prop.theta_DIV,
    model.gov.sb_other,
    model.agg.P_bar_HH,
)

# update savings (deposits) of all households
model.w_act.D_h .+= BeforeIT.new_deposits(model.w_act, prop.tau_VAT, prop.tau_CF, model.cb.r_bar, model.bank.r)
model.w_inact.D_h .+= BeforeIT.new_deposits(model.w_inact, prop.tau_VAT, prop.tau_CF, model.cb.r_bar, model.bank.r)
model.firms.D_h .+= BeforeIT.new_deposits(model.firms, prop.tau_VAT, prop.tau_CF, model.cb.r_bar, model.bank.r)
model.bank.D_h += BeforeIT.new_deposits(model.bank, prop.tau_VAT, prop.tau_CF, model.cb.r_bar, model.bank.r)

# update central bank equity
model.cb.E_CB = BeforeIT.central_bank_equity(model.cb.r_bar, model.bank.D_k, model.gov.L_G, model.cb.r_G)

# compute government revenues (Y_G), surplus/deficit (Pi_G) and debt (L_H)
Y_G = BeforeIT.government_revenues(
    model.w_act,
    model.w_inact,
    model.firms,
    model.bank,
    model.rotw,
    prop,
    model.agg.P_bar_HH,
)

# compute government deficit/surplus
Pi_G = BeforeIT.government_debt(model.gov, model.w_act, prop, Y_G, model.cb.r_G, model.agg.P_bar_HH)

model.gov.L_G += Pi_G

# compute firms deposits, loans and equity
DD_i = BeforeIT.new_deposits_firms(model.firms, DL_i, prop, model.bank.r, model.cb.r_bar, model.agg.P_bar_HH)
model.firms.D_i .+= DD_i

model.firms.L_i .= (1 - prop.theta) * model.firms.L_i + DL_i

model.firms.E_i .= BeforeIT.equity_firms(model.firms, prop.products.a_sg, model.agg.P_bar_g, model.agg.P_bar_CF)


# update net credit/debit position of rest of the world
model.rotw.D_RoW -= BeforeIT.new_deposits_rotw(model.rotw, prop.tau_EXPORT)

# update bank net credit/debit position
model.bank.D_k = BeforeIT.deposits_bank(model.bank, model.w_act, model.w_inact, model.firms)

# update GDP with the results of the time step
model.agg.Y[prop.T_prime + t] = sum(model.firms.Y_i)

BeforeIT.finance_insolvent_firms!(model.firms, model.bank, model.agg.P_bar_CF, prop.zeta_b)

BeforeIT.update_data!(data, model, prop, 1)

println("Identities")
println(BeforeIT.get_accounting_identities(data))
println(BeforeIT.get_accounting_identity_banks(model))

# income accounting and production accounting should be equal
zero = sum(data.nominal_gva - data.compensation_employees - data.operating_surplus - data.taxes_production)
println(zero)

# compare nominal_gdp to total expenditure
zero = sum(
    data.nominal_gdp - data.nominal_household_consumption - data.nominal_government_consumption -
    data.nominal_capitalformation - data.nominal_exports + data.nominal_imports,
)
println(zero)
# @assert isapprox(zero, 0.0, atol = 1e-7)

# compare real_gdp to total expenditure
zero = sum(
    data.real_gdp - data.real_household_consumption - data.real_government_consumption - data.real_capitalformation - data.real_exports + data.real_imports,
)
println(zero)

# accounting identity of balance sheet of central bank
zero = model.cb.E_CB + model.rotw.D_RoW - model.gov.L_G + model.bank.D_k
println(zero)

# accounting identity of balance sheet of commercial bank
zero =
    sum(model.firms.D_i) + sum(model.w_act.D_h) + sum(model.w_inact.D_h) + sum(model.bank.E_k) - sum(model.firms.L_i) -
    model.bank.D_k
println(zero)
