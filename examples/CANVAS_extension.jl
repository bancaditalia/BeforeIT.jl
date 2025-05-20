"""
--------- CANVAS model by overwriting ---------

There are 4 major changes from the Poledna et al. (2023) to the CANVAS model (Hommes et al., 2025)

1) Increased heterogeneity with respect to consumer behaviour and initiasation
2) Increased heterogeniety with respect to firm initialisation
3) Demand pull firm level price and quanitity setting
4) Adaptive learning for the central bank to learn the parameters of the Taylor rule

This script implements changes 3 and 4 by overwriting the methods that govern that behaviour. 
To introduce changes 1 and 2 we need dissagregated data at the household and firm level.
"""

import BeforeIT as Bit
using Plots, Dates

# get parameters and initial conditiosn
T = 12
cal = Bit.ITALY_CALIBRATION
calibration_date = DateTime(2010, 03, 31)

p, ic = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.001)

# expand series with T new time steps in the future
Y_EA_series = vec(vcat(ic["Y_EA_series"], zeros(Float64, T)))
pi_EA_series = vec(vcat(ic["pi_EA_series"], zeros(Float64, T)))
r_bar_series = vec(vcat(ic["r_bar_series"], zeros(Float64, T)))

# define a new central bank for the CANVAS model
mutable struct CentralBankCANVAS{Float64} <: Bit.AbstractCentralBank
    Bit.@centralBank Float64
    r_bar_series::Vector{Float64}
end

# define new firms for the CANVAS model
mutable struct FirmsCANVAS{Float64, Int} <: Bit.AbstractFirms
    Bit.@firm Float64 Int
end

# define a new rest of the world for the CANVAS model
mutable struct RestOfTheWorldCANVAS{Float64} <: Bit.AbstractRestOfTheWorld
    Bit.@restOfTheWorld Float64
    Y_EA_series::Vector{Float64}
    pi_EA_series::Vector{Float64}
end

# define new functions for the CANVAS-specific agents

function Bit.firms_expectations_and_decisions(firms::FirmsCANVAS, model::Bit.AbstractModel)

    # unpack non-firm variables
    tau_SIF = model.prop.tau_SIF
    tau_FIRM = model.prop.tau_FIRM
    theta = model.prop.theta
    theta_DIV = model.prop.theta_DIV
    P_bar_HH = model.agg.P_bar_HH
    P_bar_CF = model.agg.P_bar_CF
    P_bar_g = model.agg.P_bar_g
    a_sg = model.prop.products.a_sg
    gamma_e = model.agg.gamma_e
    pi_e = model.agg.pi_e

    # Individual firm quantity and price adjustments
    I = length(firms.G_i)
    gamma_d_i = zeros(I)
    pi_d_i = zeros(I)

    for i in 1:I
        if firms.Q_s_i[i] <= firms.Q_d_i[i] && firms.P_i[i] >= P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1
            pi_d_i[i] = 0
        elseif firms.Q_s_i[i] <= firms.Q_d_i[i] && firms.P_i[i] < P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = 0
            pi_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1
        elseif firms.Q_s_i[i] > firms.Q_d_i[i] && firms.P_i[i] >= P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = 0
            pi_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1
        elseif firms.Q_s_i[i] > firms.Q_d_i[i] && firms.P_i[i] < P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1
            pi_d_i[i] = 0
        end
    end
    #pi_d_i = min.(pi_d_i, 0.3) # cap the price adjustment to 30%. Otherwise it can reach 200% in some cases
    Q_s_i = firms.Q_s_i .* (1 .+ gamma_e) .* (1 .+ gamma_d_i)

    # price setting
    # dividing equation for pi_c_i into smaller pieces
    pi_l_i = (1 + tau_SIF) .* firms.w_bar_i ./ firms.alpha_bar_i .* (P_bar_HH ./ firms.P_i .- 1)
    term = dropdims(sum(a_sg[:, firms.G_i] .* P_bar_g, dims = 1), dims = 1)
    pi_k_i = firms.delta_i ./ firms.kappa_i .* (P_bar_CF ./ firms.P_i .- 1)

    pi_m_i = 1 ./ firms.beta_i .* (term ./ firms.P_i .- 1)
    pi_c_i = pi_l_i .+ pi_k_i .+ pi_m_i
    new_P_i = firms.P_i .* (1 .+ pi_c_i) .* (1 + pi_e) .* (1 .+ pi_d_i)
    I_d_i = firms.delta_i ./ firms.kappa_i .* min(Q_s_i, firms.K_i .* firms.kappa_i)

    # intermediate goods to purchase
    DM_d_i = min.(Q_s_i, firms.K_i .* firms.kappa_i) ./ firms.beta_i
    # target employment
    N_d_i = max.(1.0, round.(min(Q_s_i, firms.K_i .* firms.kappa_i) ./ firms.alpha_bar_i))
    # expected profits 
    Pi_e_i = firms.Pi_i .* (1 + pi_e) * (1 + gamma_e)
    # target loans
    DD_e_i =
        Pi_e_i .- theta .* firms.L_i .- tau_FIRM .* max.(0, Pi_e_i) .- (theta_DIV .* (1 .- tau_FIRM)) .* max.(0, Pi_e_i) # expected future cash flow
    DL_d_i = max.(0, -DD_e_i - firms.D_i)
    # expected capital
    K_e_i = P_bar_CF .* (1 + pi_e) .* firms.K_i
    # expected loans
    L_e_i = (1 - theta) .* firms.L_i

    return Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, new_P_i, pi_d_i, pi_c_i, pi_l_i, pi_k_i, pi_m_i
end

function Bit.central_bank_rate(cb::CentralBankCANVAS, model::Bit.AbstractModel)
    # unpack arguments
    gamma_EA = model.rotw.gamma_EA
    pi_EA = model.rotw.pi_EA
    T_prime = model.prop.T_prime
    t = model.agg.t

    a1 = cb.r_bar_series[1:(T_prime + t - 1)]
    a2 = model.rotw.Y_EA_series[1:(T_prime + t - 1)]
    a3 = model.rotw.pi_EA_series[1:(T_prime + t - 1)]

    # update central bank parameters
    rho, r_star, xi_pi, xi_gamma, pi_star = Bit.estimate_taylor_rule(a1, a2, a3)
    model.cb.rho = rho
    model.cb.r_star = r_star
    model.cb.xi_pi = xi_pi
    model.cb.xi_gamma = xi_gamma
    model.cb.pi_star = pi_star

    r_bar = Bit.taylor_rule(cb.rho, cb.r_bar, cb.r_star, cb.pi_star, cb.xi_pi, cb.xi_gamma, gamma_EA, pi_EA)

    cb.r_bar_series[T_prime + t] = r_bar
    return r_bar
end

function Bit.growth_inflation_EA(rotw::RestOfTheWorldCANVAS, model::Bit.AbstractModel)
    # unpack model variables
    epsilon_Y_EA = model.agg.epsilon_Y_EA
    T_prime = model.prop.T_prime
    t = model.agg.t

    Y_EA = exp(rotw.alpha_Y_EA * log(rotw.Y_EA) + rotw.beta_Y_EA + epsilon_Y_EA) # GDP EA
    gamma_EA = Y_EA / rotw.Y_EA - 1                                              # growht EA
    epsilon_pi_EA = randn() * rotw.sigma_pi_EA
    pi_EA = exp(rotw.alpha_pi_EA * log(1 + rotw.pi_EA) + rotw.beta_pi_EA + epsilon_pi_EA) - 1   # inflation EA

    rotw.pi_EA_series[T_prime + t] = pi_EA
    rotw.Y_EA_series[T_prime + t] = Y_EA

    return Y_EA, gamma_EA, pi_EA
end

# new firms initialisation
firms_st, args = Bit.init_firms(p, ic)
firms = FirmsCANVAS(args...)
firms.Q_s_i = copy(firms.Q_d_i) # overwrite to avoid division by zero for new firm price and quantity setting mechanism

# new central bank initialisation
central_bank_st, args = Bit.init_central_bank(p, ic)
central_bank = CentralBankCANVAS(args..., r_bar_series) # add new variables to the aggregates

# new rotw initialisation
rotw_st, args = Bit.init_rotw(p, ic)
rotw = RestOfTheWorldCANVAS(args..., Y_EA_series, pi_EA_series) # add new variables to the aggregates

# standard initialisations: workers, bank, aggregats, government and properties
w_act, w_inact, V_i_new, _, _ = Bit.init_workers(p, ic, firms)
firms_st.V_i .= V_i_new
firms.V_i .= V_i_new
bank, _ = Bit.init_bank(p, ic, firms)
agg, _ = Bit.init_aggregates(p, ic, T)
gov, _ = Bit.init_government(p, ic)
prop = Bit.init_properties(p, T)

# define a standard model
model_std = Bit.Model(w_act, w_inact, firms_st, bank, central_bank_st, gov, rotw_st, agg, prop)

# define a CANVAS model
model_canvas = Bit.Model(w_act, w_inact, firms, bank, central_bank, gov, rotw, agg, prop)

# adjust accounting
Bit.update_variables_with_totals!(model_std)
Bit.update_variables_with_totals!(model_canvas)

# run the model(s)
data_vector_std = Bit.ensemblerun(model_std, 8)
data_vector_canvas = Bit.ensemblerun(model_canvas, 8)

# plot the results
ps = Bit.plot_data_vectors([data_vector_std, data_vector_canvas])
plot(ps..., layout = (3, 3))
