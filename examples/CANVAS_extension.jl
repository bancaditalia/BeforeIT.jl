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

# =====================================================
# AGENT TYPES
# =====================================================

# define a new central bank for the CANVAS model
abstract type AbstractCentralBankCANVAS <: Bit.AbstractCentralBank end
Bit.@object mutable struct CentralBankCANVAS(Bit.CentralBank) <: AbstractCentralBankCANVAS
    r_bar_series::Vector{Float64}
end

# define new firms for the CANVAS model
abstract type AbstractFirmsCANVAS <: Bit.AbstractFirms end
Bit.@object mutable struct FirmsCANVAS(Bit.Firms) <: AbstractFirmsCANVAS end

# define a new rest of the world for the CANVAS model
abstract type AbstractRestOfTheWorldCANVAS <: Bit.AbstractRestOfTheWorld end
Bit.@object mutable struct RestOfTheWorldCANVAS(Bit.RestOfTheWorld) <: AbstractRestOfTheWorldCANVAS
    Y_EA_series::Vector{Float64}
    pi_EA_series::Vector{Float64}
end

# =====================================================
# ADAPTIVE EXPECTATIONS (Eq. 15a-15b)
# =====================================================
# γ^e(t) = exp(α^γ · γ(t-1) + β^γ + ε^γ) - 1
# π^e(t) = exp(α^π · π(t-1) + β^π + ε^π) - 1
# where parameters are re-estimated every period from the full history

function Bit.growth_inflation_expectations(
    model::Bit.Model{<:Bit.AbstractWorkers, <:Bit.AbstractWorkers, <:AbstractFirmsCANVAS,
                     <:Bit.AbstractBank, <:Bit.AbstractCentralBank, <:Bit.AbstractGovernment,
                     <:Bit.AbstractRestOfTheWorld, <:Bit.AbstractAggregates})
    Y = model.agg.Y
    pi_ = model.agg.pi_
    T_prime = model.prop.T_prime
    t = model.agg.t

    Y_slice = Y[1:(T_prime + t - 1)]

    # Eq. 15a: AR(1) on growth rates γ(t) = Y(t)/Y(t-1) - 1
    gamma_series = Y_slice[2:end] ./ Y_slice[1:end-1] .- 1.0
    gamma_e = Bit.estimate_next_value(gamma_series)

    Y_e = Y_slice[end] * (1 + gamma_e)

    # Eq. 15b: AR(1) on inflation π(t)
    pi_slice = pi_[1:(T_prime + t - 1)]
    pi_e = Bit.estimate_next_value(pi_slice) -1 

    return Y_e, gamma_e, pi_e
end

# =====================================================
# DEMAND-PULL PRICING (Eq. 17)
# =====================================================

function Bit.firms_expectations_and_decisions(firms::AbstractFirmsCANVAS, model::Bit.AbstractModel)
    P_bar_g = model.agg.P_bar_g
    gamma_e = model.agg.gamma_e
    pi_e = model.agg.pi_e

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

# =====================================================
# ADAPTIVE TAYLOR RULE (Eq. 19)
# =====================================================

function Bit.central_bank_rate(cb::AbstractCentralBankCANVAS, model::Bit.AbstractModel)
    gamma_EA = model.rotw.gamma_EA
    pi_EA = model.rotw.pi_EA
    T_prime = model.prop.T_prime
    t = model.agg.t

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

# =====================================================
# EA DYNAMICS — push! to series
# =====================================================

function Bit.growth_inflation_EA(rotw::AbstractRestOfTheWorldCANVAS, model::Bit.AbstractModel)
    epsilon_Y_EA = model.agg.epsilon_Y_EA

    Y_EA = exp(rotw.alpha_Y_EA * log(rotw.Y_EA) + rotw.beta_Y_EA + epsilon_Y_EA)
    gamma_EA = Y_EA / rotw.Y_EA - 1
    epsilon_pi_EA = randn() * rotw.sigma_pi_EA
    pi_EA = exp(rotw.alpha_pi_EA * log(1 + rotw.pi_EA) + rotw.beta_pi_EA + epsilon_pi_EA) - 1
    # push new values to time series
    push!(rotw.Y_EA_series, Y_EA)
    push!(rotw.pi_EA_series, pi_EA)
    return Y_EA, gamma_EA, pi_EA
end

# =====================================================
# FACTORY: Create CANVAS Model
# =====================================================

"""
    create_model(p, ic)

Create a CANVAS model with demand-pull pricing and adaptive Taylor rule.

Standard factory interface for `save_all_simulations`:
    include("examples/CANVAS_extension.jl")
    Bit.save_all_simulations(folder; model_factory=create_model, output_suffix="canvas")
"""
function create_model(p, ic)
    # initialize series
    Y_EA_series = Vector{Float64}(vec(ic["Y_EA_series"]))
    pi_EA_series = Vector{Float64}(vec(ic["pi_EA_series"]))
    r_bar_series = Vector{Float64}(vec(ic["r_bar_series"]))

    # custom agents
    firms_st = Bit.Firms(p, ic)
    firms = FirmsCANVAS((getfield(firms_st, x) for x in fieldnames(Bit.Firms))...)
    firms.Q_s_i .= firms.Q_d_i

    cb_st = Bit.CentralBank(p, ic)
    cb = CentralBankCANVAS((getfield(cb_st, x) for x in fieldnames(Bit.CentralBank))..., r_bar_series)

    rotw_st = Bit.RestOfTheWorld(p, ic)
    rotw = RestOfTheWorldCANVAS(
        (getfield(rotw_st, x) for x in fieldnames(Bit.RestOfTheWorld))...,
        Y_EA_series, pi_EA_series)

    # standard agents
    w_act, w_inact = Bit.Workers(p, ic)
    bank = Bit.Bank(p, ic)
    gov = Bit.Government(p, ic)
    agg = Bit.Aggregates(p, ic)
    prop = Bit.Properties(p, ic)
    data = Bit.Data(p)

    return Bit.Model(w_act, w_inact, firms, bank, cb, gov, rotw, agg, prop, data)
end

# =====================================================
# DEMO: Only runs when executed directly
# =====================================================

#T = 12
#cal = Bit.ITALY_CALIBRATION
#calibration_date = DateTime(2010, 03, 31)

#p, ic = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.001)

#model_std = Bit.Model(p, ic)
#model_canvas = create_model(p, ic)

#model_vector_std = Bit.ensemblerun(model_std, T, 8)
#model_vector_canvas = Bit.ensemblerun(model_canvas, T, 8)

#ps = Bit.plot_data_vectors([model_vector_std, model_vector_canvas])
#plot(ps..., layout = (3, 3))
