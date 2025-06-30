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
abstract type AbstractCentralBankCANVAS <: Bit.AbstractCentralBank end
Bit.@object mutable struct CentralBankCANVAS{Float64}(CentralBank{Float64}) <: AbstractCentralBankCANVAS
    r_bar_series::Vector{Float64}
end

# define new firms for the CANVAS model
abstract type AbstractFirmsCANVAS <: Bit.AbstractFirms end
Bit.@object struct FirmsCANVAS{T,I}(Firms{Float64,Int}) <: AbstractFirmsCANVAS end

# define a new rest of the world for the CANVAS model
abstract type AbstractRestOfTheWorldCANVAS <: Bit.AbstractRestOfTheWorld end
Bit.@object mutable struct RestOfTheWorldCANVAS{Float64}(RestOfTheWorld{Float64}) <: AbstractRestOfTheWorldCANVAS
    Y_EA_series::Vector{Float64}
    pi_EA_series::Vector{Float64}
end

# define new functions for the CANVAS-specific agents

function Bit.firms_expectations_and_decisions(firms::AbstractFirmsCANVAS, model::Bit.AbstractModel)
    # unpack non-firm variables
    P_bar_g = model.agg.P_bar_g
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

    # cost push inflation
    pi_c_i = Bit.cost_push_inflation(firms, model)
    # price setting
    new_P_i = firms.P_i .* (1 .+ pi_c_i) .* (1 + pi_e) .* (1 .+ pi_d_i)
    # target investments in capital, intermediate goods to purchase and employment
    I_d_i, DM_d_i, N_d_i = Bit.desired_capital_material_employment(firms, Q_s_i)
    # expected profits 
    Pi_e_i = firms.Pi_i .* (1 + pi_e) * (1 + gamma_e)
    # expected deposits, capital and loans
    DD_e_i, K_e_i, L_e_i = Bit.expected_deposits_capital_loans(firms, model, Pi_e_i)
    # target loans
    DL_d_i = max.(0, -DD_e_i - firms.D_i)

    return Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, new_P_i
end

function Bit.central_bank_rate(cb::AbstractCentralBankCANVAS, model::Bit.AbstractModel)
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

function Bit.growth_inflation_EA(rotw::AbstractRestOfTheWorldCANVAS, model::Bit.AbstractModel)
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

# run the model(s)
data_vector_std = Bit.ensemblerun(model_std, 8)
data_vector_canvas = Bit.ensemblerun(model_canvas, 8)

# plot the results
ps = Bit.plot_data_vectors([data_vector_std, data_vector_canvas])
plot(ps..., layout = (3, 3))
