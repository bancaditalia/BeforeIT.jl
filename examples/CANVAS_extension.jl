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
using Plots, Dates, StatsPlots

# get parameters and initial conditions
T = 12
cal = Bit.ITALY_CALIBRATION
calibration_date = DateTime(2010, 03, 31)

p, ic = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.001)

# initialize with historical data only - series will grow dynamically during simulation
Y_EA_series = vec(ic["Y_EA_series"])
pi_EA_series = vec(ic["pi_EA_series"])
r_bar_series = vec(ic["r_bar_series"])

Bit.@object mutable struct ModelCANVAS(Bit.Model) <: Bit.AbstractModel end

# define a new central bank for the CANVAS model
abstract type AbstractCentralBankCANVAS <: Bit.AbstractCentralBank end
Bit.@object mutable struct CentralBankCANVAS(Bit.CentralBank) <: AbstractCentralBankCANVAS
    r_bar_series::Vector{Float64}
end

# define new firms for the CANVAS model
abstract type AbstractFirmsCANVAS <: Bit.AbstractFirms end
Bit.@object mutable struct FirmsCANVAS(Firms) <: AbstractFirmsCANVAS end

# define a new rest of the world for the CANVAS model
abstract type AbstractRestOfTheWorldCANVAS <: Bit.AbstractRestOfTheWorld end
Bit.@object mutable struct RestOfTheWorldCANVAS(Bit.RestOfTheWorld) <: AbstractRestOfTheWorldCANVAS
    Y_EA_series::Vector{Float64}
    pi_EA_series::Vector{Float64}
end

# define new functions for the CANVAS-specific agents
function Bit.firms_expectations_and_decisions(model::Bit.ModelCANVAS)
    firms = model.firms

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

function Bit.central_bank_rate(model::Bit.ModelCANVAS)
    cb = model.cb
    gamma_EA, pi_EA, T_prime, t = model.rotw.gamma_EA, model.rotw.pi_EA, model.prop.T_prime, model.agg.t

    a1 = cb.r_bar_series[1:(T_prime + t - 1)]
    a2 = model.rotw.Y_EA_series[1:(T_prime + t - 1)]
    a3 = model.rotw.pi_EA_series[1:(T_prime + t - 1)]

    # update central bank parameters
    cb.rho, cb.r_star, cb.xi_pi, cb.xi_gamma, cb.pi_star = Bit.estimate_taylor_rule(a1, a2, a3)
    r_bar = Bit.taylor_rule(cb.rho, cb.r_bar, cb.r_star, cb.pi_star, cb.xi_pi, cb.xi_gamma, gamma_EA, pi_EA)
    # push new values to time series
    push!(cb.r_bar_series, r_bar)
    return r_bar
end

function Bit.growth_inflation_EA(model::Bit.ModelCANVAS)
    rotw = model.rotw
    epsilon_Y_EA = model.agg.epsilon_Y_EA

    Y_EA = exp(rotw.alpha_Y_EA * log(rotw.Y_EA) + rotw.beta_Y_EA + epsilon_Y_EA) # GDP EA
    gamma_EA = Y_EA / rotw.Y_EA - 1 # growth EA
    epsilon_pi_EA = randn() * rotw.sigma_pi_EA
    pi_EA = exp(rotw.alpha_pi_EA * log(1 + rotw.pi_EA) + rotw.beta_pi_EA + epsilon_pi_EA) - 1 # inflation EA
    # push new values to time series
    push!(rotw.Y_EA_series, Y_EA)
    push!(rotw.pi_EA_series, pi_EA)
    return Y_EA, gamma_EA, pi_EA
end

# new firms initialisation
firms_st = Bit.Firms(p, ic)
firms = FirmsCANVAS(Bit.fields(firms_st)...)
firms.Q_s_i .= firms.Q_d_i # overwrite to avoid division by zero for new firm price and quantity setting mechanism

# new central bank initialisation
cb_st = Bit.CentralBank(p, ic)
cb = CentralBankCANVAS(Bit.fields(cb_st)..., r_bar_series) # add new variables to the aggregates

# new rotw initialisation
rotw_st = Bit.RestOfTheWorld(p, ic)
rotw = RestOfTheWorldCANVAS(Bit.fields(rotw_st)..., Y_EA_series, pi_EA_series) # add new variables to the aggregates

# standard initialisations: workers, bank, aggregats, government, properties and data
w_act, w_inact = Bit.Workers(p, ic)
bank = Bit.Bank(p, ic)
agg = Bit.Aggregates(p, ic)
gov = Bit.Government(p, ic)
prop = Bit.Properties(p, ic)
data = Bit.Data()

# define a standard model
model_std = Bit.Model(w_act, w_inact, firms_st, bank, cb_st, gov, rotw_st, agg, prop, data)

# define a CANVAS model
model_canvas = ModelCANVAS(w_act, w_inact, firms, bank, cb, gov, rotw, agg, prop, data)

# The CANVAS model extension is also included in the BeforeIT package.
# You can instantiate a CANVAS model directly from parameters and initial conditions in a single line of code as
model_canvas_2 = Bit.ModelCANVAS(p, ic)

# run the model(s)
model_vector_std = Bit.ensemblerun(model_std, T, 8)
model_vector_canvas = Bit.ensemblerun(model_canvas, T, 8)
model_vector_canvas_2 = Bit.ensemblerun(model_canvas_2, T, 8)

# plot the results
ps = Bit.plot_data_vectors([model_vector_std, model_vector_canvas, model_vector_canvas_2])
plot(ps..., layout = (3, 3))
