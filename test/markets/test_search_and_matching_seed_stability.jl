using BeforeIT, Test, MAT, StatsBase
using Random

Random.seed!(1)

dir = @__DIR__

parameters = matread(joinpath(dir, "../data/austria/parameters/2010Q1.mat"))
initial_conditions = matread(joinpath(dir, "../data/austria/initial_conditions/2010Q1.mat"))


T = 1
model = BeforeIT.initialise_model(parameters, initial_conditions, T;)


prop = model.prop
gamma_e = 0.01 # set expected growth in euro area
pi_e = 0.001   # set expected inflation in euro area

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
Pi_e_k = model.bank.Pi_k * (1 + pi_e) * (1 + gamma_e)

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

BeforeIT.government_expenditure!(model.gov, prop.products.c_G_g, model.agg.P_bar_g, pi_e)

epsilon_E = 0.28
epsilon_I = 0.36

BeforeIT.import_export!(
    model.rotw,
    model.agg.P_bar_g,
    prop.products.c_E_g,
    prop.products.c_I_g,
    pi_e,
    epsilon_E,
    epsilon_I,
)

BeforeIT.search_and_matching!(model, multi_threading = false)

rtol = 0.0001

@test isapprox(mean(model.w_act.C_h), 4.151302855524089, rtol = rtol)
@test isapprox(mean(model.w_inact.C_h), 2.205681258710137, rtol = rtol)
@test isapprox(mean(model.firms.C_h), 9.109200103004, rtol = rtol)
@test isapprox(model.bank.C_h, 2778.703108929575, rtol = rtol)

@test isapprox(mean(model.w_act.I_h), 0.34234911469290735, rtol = rtol)
@test isapprox(mean(model.w_inact.I_h), 0.1817758717013423, rtol = rtol)
@test isapprox(mean(model.firms.I_h), 0.751918893775627, rtol = rtol)
@test isapprox(model.bank.I_h, 220.37553121655245, rtol = rtol)

@test isapprox(model.gov.C_j, 14694.12354494293, rtol = rtol)
@test isapprox(model.rotw.C_l, 44353.05624186212, rtol = rtol)

@test isapprox(mean(model.firms.I_i), 20.671016463479898, rtol = rtol)
@test isapprox(mean(model.firms.DM_i), 110.18635469222951, rtol = rtol)
@test isapprox(mean(model.firms.P_bar_i), 1.0010000000000023, rtol = rtol)
@test isapprox(mean(model.firms.P_CF_i), 1.0010000000000023, rtol = rtol)
@test isapprox(mean(model.firms.Q_d_i), 217.14009621685946, rtol = rtol)
@test isapprox(mean(model.rotw.Q_d_m), 714.8836999500451, rtol = rtol)
