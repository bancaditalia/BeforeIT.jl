"""
=====================================================================
GROWTH-RATE AR(1) EXTENSION
=====================================================================

Implementation of AR(1) on growth rates (instead of log-levels) via method overloading.
This follows the CANVAS_extension.jl pattern for type-based dispatch.

Standard AR(1) on log-levels (default BeforeIT):
    log(Y_t) = alpha * log(Y_{t-1}) + beta + epsilon
    => Y_t = exp(alpha * log(Y_{t-1}) + beta + epsilon)

Growth-rate AR(1) (this extension):
    g_t = alpha * g_{t-1} + beta + epsilon
    where g_t = (Y_t - Y_{t-1}) / Y_{t-1}
    => Y_t = Y_{t-1} * (1 + g_t)

Applied to C_G, C_E, Y_I only. Y_EA keeps the base log-level AR(1) so that
gamma_EA (which feeds the Taylor rule → Euribor) remains consistent with the
base calibration.


## Usage:
    include("examples/GrowthRateAR1_extension.jl")
    model_gr = create_model(p, ic)
    Bit.run!(model_gr, 12)
"""

import BeforeIT as Bit
using Statistics, LinearAlgebra
using Plots, StatsPlots, Dates

# =====================================================
# ABSTRACT TYPES FOR DISPATCH
# =====================================================

abstract type AbstractRestOfTheWorldGR <: Bit.AbstractRestOfTheWorld end
abstract type AbstractGovernmentGR <: Bit.AbstractGovernment end

# =====================================================
# EXTENDED STRUCTS WITH LAGGED GROWTH RATES
# =====================================================

"""
Extended RestOfTheWorld with lagged growth rates for AR(1) dynamics on C_E and Y_I.
Y_EA keeps the base log-level AR(1) to preserve Taylor rule / Euribor consistency.
"""
Bit.@object mutable struct RestOfTheWorldGR(Bit.RestOfTheWorld) <: AbstractRestOfTheWorldGR
    # Growth-rate AR(1) parameters for C_E and Y_I (not Y_EA)
    alpha_E_gr::Bit.typeFloat
    beta_E_gr::Bit.typeFloat
    sigma_E_gr::Bit.typeFloat
    alpha_I_gr::Bit.typeFloat
    beta_I_gr::Bit.typeFloat
    sigma_I_gr::Bit.typeFloat
    # Lagged growth rates (levels come from actual model values)
    g_prev_C_E::Bit.typeFloat
    g_prev_Y_I::Bit.typeFloat
end

"""
Extended Government with lagged growth rate for AR(1) dynamics.
"""
Bit.@object mutable struct GovernmentGR(Bit.Government) <: AbstractGovernmentGR
    # Growth-rate AR(1) parameters
    alpha_G_gr::Bit.typeFloat
    beta_G_gr::Bit.typeFloat
    sigma_G_gr::Bit.typeFloat
    # Lagged growth rate (level comes from actual model value)
    g_prev_C_G::Bit.typeFloat
end

# =====================================================
# HELPER: ESTIMATE AR(1) ON GROWTH RATES
# =====================================================

"""
    estimate_gr_ar1(series)

Estimate AR(1) parameters on growth rates of the series.

Returns (alpha, beta, sigma) where:
    g_t = alpha * g_{t-1} + beta + epsilon
    epsilon ~ N(0, sigma^2)
"""
function estimate_gr_ar1(series::Vector)
    if length(series) < 3
        return 0.0, 0.0, 0.0
    end

    # Compute growth rates
    growth_rates = diff(series) ./ series[1:end-1]

    if length(growth_rates) < 2
        return 0.0, mean(growth_rates), std(growth_rates)
    end

    # Estimate AR(1) on growth rates
    alpha, beta, sigma, _ = Bit.estimate_for_calibration_script(growth_rates)

    return alpha, beta, sigma
end

"""
    last_growth_rate(series)

Compute the last growth rate from a historical series.
"""
function last_growth_rate(series::Vector)
    if length(series) < 2
        return 0.0
    end
    return (series[end] - series[end-1]) / series[end-1]
end

"""
    gr_next_value(current_value, g_prev, alpha, beta, sigma)

Compute next growth rate using AR(1) and return (new_value, new_growth_rate).

Uses the actual model value for level (not historical series), ensuring correct scale.
"""
function gr_next_value(current_value::Real, g_prev::Real, alpha::Real, beta::Real, sigma::Real)
    # AR(1) on growth rate
    epsilon = randn() * sigma
    g_new = alpha * g_prev + beta + epsilon

    # Compute new level 
    Y_new = current_value * (1 + g_new)

    return Y_new, g_new
end

# NOTE: No override for growth_inflation_EA — Y_EA uses base log-level AR(1)
# so that gamma_EA (Taylor rule input → Euribor) stays consistent.

# =====================================================
# OVERRIDE: gov_expenditure (C_G, C_d_j)
# =====================================================

function Bit.gov_expenditure(gov::AbstractGovernmentGR, model)
    # Unpack non-government arguments
    c_G_g = model.prop.c_G_g
    P_bar_g = model.agg.P_bar_g
    pi_e = model.agg.pi_e

    # Compute C_G using growth-rate AR(1) 
    C_G_new, g_new = gr_next_value(
        gov.C_G,             # Use actual model value 
        gov.g_prev_C_G,      # Lagged growth rate
        gov.alpha_G_gr,
        gov.beta_G_gr,
        gov.sigma_G_gr
    )

    # Update lagged growth rate for next iteration
    gov.g_prev_C_G = g_new

    # Compute local government consumptions (same as base)
    J = size(gov.C_d_j, 1)
    C_d_j = C_G_new ./ J .* ones(J) .* sum(c_G_g .* P_bar_g) .* (1 + pi_e)

    return C_G_new, C_d_j
end

# =====================================================
# OVERRIDE: rotw_import_export (C_E, Y_I, ...)
# =====================================================

function Bit.rotw_import_export(rotw::AbstractRestOfTheWorldGR, model)
    # Unpack model arguments
    c_E_g = model.prop.c_E_g
    c_I_g = model.prop.c_I_g
    P_bar_g = model.agg.P_bar_g
    pi_e = model.agg.pi_e

    L = size(rotw.C_d_l, 1)

    # Compute C_E using growth-rate AR(1) 
    C_E_new, g_new_E = gr_next_value(
        rotw.C_E,            # Use actual model value 
        rotw.g_prev_C_E,     # Lagged growth rate
        rotw.alpha_E_gr,
        rotw.beta_E_gr,
        rotw.sigma_E_gr
    )

    # Update lagged growth rate for next iteration
    rotw.g_prev_C_E = g_new_E

    # Compute demand for export
    C_d_l = C_E_new ./ L .* ones(L) .* sum(c_E_g .* P_bar_g) .* (1 + pi_e)

    # Compute Y_I using growth-rate AR(1) 
    Y_I_new, g_new_I = gr_next_value(
        rotw.Y_I,            # Use actual model value 
        rotw.g_prev_Y_I,     # Lagged growth rate
        rotw.alpha_I_gr,
        rotw.beta_I_gr,
        rotw.sigma_I_gr
    )

    # Update lagged growth rate for next iteration
    rotw.g_prev_Y_I = g_new_I

    # Compute supply of imports (same as base)
    Y_m = c_I_g * Y_I_new
    P_m = P_bar_g * (1 + pi_e)

    return C_E_new, Y_I_new, C_d_l, Y_m, P_m
end

# =====================================================
# FACTORY: Create Growth-Rate AR(1) Model
# =====================================================

"""
    create_model(p, ic)

Create a model using growth-rate AR(1) for C_G, C_E, and Y_I.

Y_EA keeps the base log-level AR(1) so that gamma_EA (Taylor rule input)
remains consistent with the base calibration, preserving Euribor dynamics.

The standard BeforeIT model uses log-level AR(1):
    log(Y_t) = alpha * log(Y_{t-1}) + beta + epsilon

This model uses growth-rate AR(1) for selected variables:
    g_t = alpha * g_{t-1} + beta + epsilon
    Y_t = Y_{t-1} * (1 + g_t)

AR(1) parameters are re-estimated on growth rates ONCE at model creation.

This function is the standard factory interface for extensions - when `save_all_simulations`
is called with an extension file, it `include`s that file and calls `create_model(p, ic)`.
"""
function create_model(p, ic)
    T_prime = Int(p["T_prime"])

    # =====================================================
    # 1. Initialize standard agents FIRST (to get correct scales)
    # =====================================================

    w_act, w_inact = Bit.Workers(p, ic)
    firms = Bit.Firms(p, ic)
    bank = Bit.Bank(p, ic)
    cb = Bit.CentralBank(p, ic)
    agg = Bit.Aggregates(p, ic)
    prop = Bit.Properties(p, ic)
    data = Bit.Data(p)

    # Initialize standard RestOfTheWorld and Government to get actual model values
    rotw_std = Bit.RestOfTheWorld(p, ic)
    gov_std = Bit.Government(p, ic)

    # =====================================================
    # 2. Load historical series and estimate AR(1) on growth rates
    # =====================================================
    # Note: Y_EA is NOT included — it keeps base log-level AR(1)
    # to preserve Taylor rule / Euribor consistency.

    # C_G, C_E, Y_I series
    C_G_series = Vector{Bit.typeFloat}(vec(ic["C_G"]))[1:T_prime]
    C_E_series = Vector{Bit.typeFloat}(vec(ic["C_E"]))[1:T_prime]
    Y_I_series = Vector{Bit.typeFloat}(vec(ic["Y_I"]))[1:T_prime]

    # Estimate AR(1) parameters on growth rates (scale-invariant)
    alpha_G_gr, beta_G_gr, sigma_G_gr = estimate_gr_ar1(C_G_series)
    alpha_E_gr, beta_E_gr, sigma_E_gr = estimate_gr_ar1(C_E_series)
    alpha_I_gr, beta_I_gr, sigma_I_gr = estimate_gr_ar1(Y_I_series)

    # =====================================================
    # 3. RESCALE series to match actual model values
    # =====================================================
    # AR(1) parameters are unaffected (computed on growth rates, which are scale-invariant).
    # Rescaling ensures series[end] matches the actual model starting value.

    C_G_scale = gov_std.C_G / C_G_series[end]
    C_G_series = C_G_series .* C_G_scale

    C_E_scale = rotw_std.C_E / C_E_series[end]
    C_E_series = C_E_series .* C_E_scale

    Y_I_scale = rotw_std.Y_I / Y_I_series[end]
    Y_I_series = Y_I_series .* Y_I_scale

    # Compute lagged growth rates from rescaled series
    g_prev_C_G = last_growth_rate(C_G_series)
    g_prev_C_E = last_growth_rate(C_E_series)
    g_prev_Y_I = last_growth_rate(Y_I_series)

    # =====================================================
    # 4. Initialize extended agents with growth-rate params
    # =====================================================

    # Create extended RestOfTheWorld (C_E, Y_I use growth-rate AR; Y_EA uses base)
    rotw = RestOfTheWorldGR((getfield(rotw_std, f) for f in fieldnames(Bit.RestOfTheWorld))...,
        alpha_E_gr, beta_E_gr, sigma_E_gr,
        alpha_I_gr, beta_I_gr, sigma_I_gr,
        g_prev_C_E, g_prev_Y_I
    )

    # Create extended Government with growth-rate AR(1)
    gov = GovernmentGR((getfield(gov_std, f) for f in fieldnames(Bit.Government))...,
        alpha_G_gr, beta_G_gr, sigma_G_gr,
        g_prev_C_G
    )

    return Bit.Model(w_act, w_inact, firms, bank, cb, gov, rotw, agg, prop, data)
end


T = 12
cal = Bit.ITALY_CALIBRATION
calibration_date = DateTime(2010, 03, 31)

p, ic = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.001)

model_std = Bit.Model(p, ic)
model_gr = create_model(p, ic)

model_vector_std = Bit.ensemblerun(model_std, T, 8)
model_vector_gr = Bit.ensemblerun(model_gr, T, 8)

ps = Bit.plot_data_vectors([model_vector_std, model_vector_gr])
plot(ps..., layout = (3, 3))
