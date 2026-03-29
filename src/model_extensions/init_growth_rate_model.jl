"""
--------- Growth-Rate AR(1) model extension ---------

Replaces the standard log-level AR(1) processes with growth-rate AR(1):

    Standard (log-level):   log(Y_t) = α·log(Y_{t-1}) + β + ε
    This extension:         g_t = α·g_{t-1} + β + ε,  Y_t = Y_{t-1}·(1 + g_t)

Applied to:
- GDP expectations (Y_e, gamma_e) and inflation expectations (pi_e)
- Government consumption (C_G)
- Export demand (C_E) and import supply (Y_I)

Y_EA keeps the base log-level AR(1) so that gamma_EA (Taylor rule input)
remains consistent with the base calibration, preserving Euribor dynamics.
"""

Bit.@object mutable struct ModelGR(Bit.Model) <: Bit.AbstractModel end

# define a new rest of the world for the GR model
abstract type AbstractRestOfTheWorldGR <: Bit.AbstractRestOfTheWorld end
Bit.@object mutable struct RestOfTheWorldGR(Bit.RestOfTheWorld) <: AbstractRestOfTheWorldGR
    alpha_E_gr::Float64
    beta_E_gr::Float64
    sigma_E_gr::Float64
    alpha_I_gr::Float64
    beta_I_gr::Float64
    sigma_I_gr::Float64
    g_prev_C_E::Float64
    g_prev_Y_I::Float64
end

# define a new government for the GR model
abstract type AbstractGovernmentGR <: Bit.AbstractGovernment end
Bit.@object mutable struct GovernmentGR(Bit.Government) <: AbstractGovernmentGR
    alpha_G_gr::Float64
    beta_G_gr::Float64
    sigma_G_gr::Float64
    g_prev_C_G::Float64
end

# define new functions for the GR-specific agents

function Bit.growth_inflation_expectations(model::Bit.ModelGR)
    Y = model.agg.Y
    pi_ = model.agg.pi_
    T_prime = model.prop.T_prime
    t = model.agg.t

    Y_slice = Y[1:(T_prime + t - 1)]

    # AR(1) on growth rates: g(t) = Y(t)/Y(t-1) - 1
    gamma_series = Y_slice[2:end] ./ Y_slice[1:(end - 1)] .- 1.0
    gamma_e = estimate_next_value(gamma_series)
    Y_e = Y_slice[end] * (1 + gamma_e)

    # AR(1) on (1+π) directly
    pi_e = estimate_next_value(1 .+ pi_[1:(T_prime + t - 1)]) - 1

    return Y_e, gamma_e, pi_e
end

function Bit.gov_expenditure(model::Bit.ModelGR)
    gov = model.gov
    c_G_g = model.prop.c_G_g
    P_bar_g = model.agg.P_bar_g
    pi_e = model.agg.pi_e

    g_new = gov.alpha_G_gr * gov.g_prev_C_G + gov.beta_G_gr + randn() * gov.sigma_G_gr
    C_G = gov.C_G * (1 + g_new)
    gov.g_prev_C_G = g_new

    J = length(gov.C_d_j)
    C_d_j = C_G ./ J .* ones(J) .* sum(c_G_g .* P_bar_g) .* (1 + pi_e)

    return C_G, C_d_j
end

function Bit.rotw_import_export(model::Bit.ModelGR)
    rotw = model.rotw
    c_E_g = model.prop.c_E_g
    c_I_g = model.prop.c_I_g
    P_bar_g = model.agg.P_bar_g
    pi_e = model.agg.pi_e

    L = length(rotw.C_d_l)

    g_E = rotw.alpha_E_gr * rotw.g_prev_C_E + rotw.beta_E_gr + randn() * rotw.sigma_E_gr
    C_E = rotw.C_E * (1 + g_E)
    rotw.g_prev_C_E = g_E
    C_d_l = C_E ./ L .* ones(L) .* sum(c_E_g .* P_bar_g) .* (1 + pi_e)

    g_I = rotw.alpha_I_gr * rotw.g_prev_Y_I + rotw.beta_I_gr + randn() * rotw.sigma_I_gr
    Y_I = rotw.Y_I * (1 + g_I)
    rotw.g_prev_Y_I = g_I

    Y_m = c_I_g * Y_I
    P_m = P_bar_g * (1 + pi_e)

    return C_E, Y_I, C_d_l, Y_m, P_m
end

# NOTE: No override for growth_inflation_EA — Y_EA uses base log-level AR(1)
# so that gamma_EA (Taylor rule input) stays consistent with base calibration.


"""
    ModelGR(parameters, initial_conditions)

Initializes a Growth-Rate AR(1) model with given parameters and initial conditions.

The model can run for an arbitrary number of time steps without pre-specifying T.

Parameters:
- `parameters`: A dictionary containing the model parameters.
- `initial_conditions`: A dictionary containing the initial conditions.

Returns:
- `model::AbstractModel`: The initialized Growth-Rate AR(1) model.
"""
function ModelGR(parameters::Dict{String, Any}, initial_conditions::Dict{String, Any})
    p, ic = parameters, initial_conditions
    T_prime = Int(p["T_prime"])

    # estimate AR(1) on growth rates for C_G, C_E, Y_I
    function estimate_gr_ar1(series)
        length(series) < 3 && return 0.0, 0.0, 0.0
        growth_rates = diff(series) ./ series[1:(end - 1)]
        length(growth_rates) < 2 && return 0.0, mean(growth_rates), std(growth_rates)
        alpha, beta, sigma, _ = estimate_for_calibration_script(growth_rates)
        return alpha, beta, sigma
    end

    last_gr(s) = length(s) < 2 ? 0.0 : (s[end] - s[end - 1]) / s[end - 1]

    C_G_series = Vector{Float64}(vec(ic["C_G"]))[1:T_prime]
    C_E_series = Vector{Float64}(vec(ic["C_E"]))[1:T_prime]
    Y_I_series = Vector{Float64}(vec(ic["Y_I"]))[1:T_prime]

    alpha_G_gr, beta_G_gr, sigma_G_gr = estimate_gr_ar1(C_G_series)
    alpha_E_gr, beta_E_gr, sigma_E_gr = estimate_gr_ar1(C_E_series)
    alpha_I_gr, beta_I_gr, sigma_I_gr = estimate_gr_ar1(Y_I_series)

    # new rotw initialisation
    rotw_st = RestOfTheWorld(p, ic)
    rotw = RestOfTheWorldGR(
        fields(rotw_st)...,
        alpha_E_gr, beta_E_gr, sigma_E_gr,
        alpha_I_gr, beta_I_gr, sigma_I_gr,
        last_gr(C_E_series), last_gr(Y_I_series)
    )

    # new government initialisation
    gov_st = Government(p, ic)
    gov = GovernmentGR(
        fields(gov_st)...,
        alpha_G_gr, beta_G_gr, sigma_G_gr,
        last_gr(C_G_series)
    )

    # standard initialisations
    workers_act, workers_inact = Workers(p, ic)
    firms = Firms(p, ic)
    bank = Bank(p, ic)
    central_bank = CentralBank(p, ic)
    agg = Aggregates(p, ic)
    properties = Properties(p, ic)
    data = Data()

    return ModelGR((workers_act, workers_inact, firms, bank, central_bank, gov, rotw, agg, properties, data))
end
