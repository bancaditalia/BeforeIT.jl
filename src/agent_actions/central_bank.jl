
"""
    central_bank_rate(cb, model)

Update the base interest rate set by the central bank according to the Taylor rule.

# Arguments
- `cb`: The central bank whose base interest rate is to be updated
- `model`: The model object

# Returns
- `r_bar`: The updated base interest rate
"""
function central_bank_rate(cb::AbstractCentralBank, model::AbstractModel)
    # unpack arguments
    gamma_EA = model.rotw.gamma_EA
    pi_EA = model.rotw.pi_EA

    r_bar = taylor_rule(cb.rho, cb.r_bar, cb.r_star, cb.pi_star, cb.xi_pi, cb.xi_gamma, gamma_EA, pi_EA)
    return r_bar
end


"""
    taylor_rule(rho, r_bar, r_star, pi_star, xi_pi, xi_gamma, gamma_EA, pi_EA)

Calculate the interest rate according to the Taylor rule.

# Arguments
- `rho`: Parameter for gradual adjustment of the policy rate.
- `r_bar`: Nominal interest rate.
- `r_star`: Real equilibrium interest rate.
- `pi_star`: The target inflation rate.
- `xi_pi`: Weight the CB puts on inflation targeting.
- `xi_gamma`: Weight placed on economic growth.
- `gamma_EA`: The output growth rate.
- `pi_EA`: The inflation rate.

# Returns
- `rate`: The calculated interest rate.

The Taylor rule is given by the following equation:

```math
r_t = ρ * r_{t-1} + (1 - ρ) * (r^* + π^* + ξ_π * (π_t - π^*) + ξ_γ * γ_t)```
```

"""
function taylor_rule(rho::T, r_bar::T, r_star::T, pi_star::T, xi_pi::T, xi_gamma::T, gamma_EA::T, pi_EA::T) where {T}
    rate = rho * r_bar + (one(T) - rho) * (r_star + pi_star + xi_pi * (pi_EA - pi_star) + xi_gamma * gamma_EA)
    return pos(rate)
end


"""
    _central_bank_profits(r_bar, D_k, L_G, r_G)

Helper function to calculate the profits of a central bank.

# Arguments
- `r_bar`: The base interest rate
- `D_k`: Deposits from commercial banks
- `L_G`: Loans provided to the government
- `r_G`: Interest rate on government loans

# Returns
- `Pi_CB`: Profits of the central bank

The profits `Pi_CB` are calculated as follows:

```math
\\{Pi}_{CB} = r_{G} \\cdot L_{G} - r_{bar} \\cdot D_{k}
```

"""
function _central_bank_profits(r_bar, D_k, L_G, r_G)
    Pi_CB = r_G * L_G - r_bar * D_k
    return Pi_CB
end

"""
    central_bank_equity(cb, model)

Calculate the equity of the central bank.

# Arguments
- `cb`: The central bank
- `model`: The model object

# Returns
- `E_CB`: The equity of the central bank

The equity `E_CB` is calculated as follows:

```math
E_{CB} = E_{CB} + \\Pi_{CB}
```

where `\\Pi_{CB}` are the profits of the central bank.
"""
function central_bank_equity(cb, model)
    Pi_CB = _central_bank_profits(cb.r_bar, model.bank.D_k, model.gov.L_G, model.cb.r_G)
    E_CB = cb.E_CB + Pi_CB
    return E_CB
end
