
"""
    _bank_profits(L_i, D_i, D_h, D_k, r_bar, r)

Helper function to calculate the total profits of a bank.

# Arguments
- `L_i`: Array of loans provided by the bank
- `D_i`: Array of deposits from firms
- `D_h`: Array of deposits from households
- `D_k`: Residual and balancing item on the bank’s balance sheet
- `r_bar`: Base interest rate
- `r`: Interest rate set by the bank

# Returns
- `Pi_k`: Total profits of the bank

The total profits `Pi_k` are calculated as follows:

```math
\\Pi_k = r \\cdot \\sum_i(L_i + \\max(0, -D_i)) + r \\cdot \\sum_h(\\max(0, -D_h)) + r_{bar} 
\\cdot \\max(0, D_k) - r_{bar} \\cdot \\sum_i(\\max(0, D_i)) - r_{bar} \\cdot 
\\sum_h(\\max(0, D_h)) - r_{bar} \\cdot \\max(0, -D_k)
```
"""
function _bank_profits(
    L_i::AbstractVector{T},
    D_i::AbstractVector{T},
    D_h::AbstractVector{T},
    D_k::T,
    r_bar::T,
    r::T,
) where {T}
    r_terms = reduce(+, L_i)
    r_terms += mapreduce(x -> max(zero(T), -x), +, D_i)
    r_terms += mapreduce(x -> max(zero(T), -x), +, D_h)

    r_bar_terms = mapreduce(x -> max(zero(T), x), +, D_k)
    r_bar_terms -= mapreduce(x -> max(zero(T), x), +, D_i)
    r_bar_terms -= mapreduce(x -> max(zero(T), x), +, D_h)
    r_bar_terms -= mapreduce(x -> max(zero(T), -x), +, D_k)
    return r * r_terms + r_bar * r_bar_terms
end

"""
    bank_profits(bank, model)

Calculate the total profits of a bank.

# Arguments
- `bank`: The bank object.
- `model`: The model object.

# Returns
- `Pi_k`: The total profits of the bank.

The total profits `Pi_k` are calculated as:

```math
\\Pi_k = r \\cdot \\sum_i(L_i + \\max(0, -D_i)) + r \\cdot \\sum_h(\\max(0, -D_h)) + r_{bar}
\\cdot \\max(0, D_k) - r_{bar} \\cdot \\sum_i(\\max(0, D_i)) - r_{bar} \\cdot
\\sum_h(\\max(0, D_h)) - r_{bar} \\cdot \\max(0, -D_k)
```
"""
function bank_profits(bank, model)
    L_i = model.firms.L_i
    D_i = model.firms.D_i
    D_h = [model.w_act.D_h; model.w_inact.D_h; model.firms.D_h; bank.D_h]
    r_bar = model.cb.r_bar

    Pi_k = _bank_profits(L_i, D_i, D_h, bank.D_k, r_bar, bank.r)
    return Pi_k
end


"""
    bank_equity(bank, model)

Calculate the net profits of a bank.

# Arguments
- `bank`: The bank object.
- `model`: The model object.

# Returns
- `E_k`: The updated equity of the bank.

The net profits `DE_k` are calculated as:

```math
DE_k = \\Pi_k - \\theta_{DIV} \\cdot (1 - \\tau_{FIRM}) \\cdot \\max(0, \\Pi_k) - \\tau_{FIRM} \\cdot \\max(0, \\Pi_k)
```

and the equity `E_k` is updated as:

```math
E_k = E_k + DE_k
```
"""
function bank_equity(bank, model)
    # unpack non-bank variables    
    theta_DIV, tau_FIRM = model.prop.theta_DIV, model.prop.tau_FIRM
    DE_k = _bank_net_profits(bank.Pi_k, theta_DIV, tau_FIRM)
    E_k = bank.E_k + DE_k
    return E_k
end

function _bank_net_profits(Pi_k, theta_DIV, tau_FIRM)
    DE_k = Pi_k - theta_DIV * (1 - tau_FIRM) * max(0, Pi_k) - tau_FIRM * max(0, Pi_k)
    return DE_k
end


"""
    bank_rate(bank, model)

Update the interest rate set by the bank.

# Arguments
- `bank`: The bank whose interest rate is to be updated
- `model`: Model object

# Returns
- `r`: The updated interest rate

```math
r = \\bar{r} + \\mu
```
"""
function bank_rate(bank, model)
    # unpack arguments
    r_bar = model.cb.r_bar
    mu = model.prop.mu
    r = r_bar + mu

    return r
end

"""
    bank_expected_profits(Pi_k, pi_e, gamma_e)

Calculate the expected profits of a bank.

# Arguments
- `Pi_k`: Past profits of the bank
- `pi_e`: Expected inflation rate
- `gamma_e`: Expected growth rate

# Returns
- `E_Pi_k`: Expected profits of the bank

The expected profits `E_Pi_k` are calculated as follows:

```math
E_{\\Pi_k} = \\Pi_k \\cdot (1 + \\pi_e) \\cdot (1 + \\gamma_e)
```
"""
function bank_expected_profits(bank, model)
    # unpack arguments
    pi_e = model.agg.pi_e
    gamma_e = model.agg.gamma_e

    return _bank_expected_profits(bank.Pi_k, pi_e, gamma_e)
end

function _bank_expected_profits(Pi_k, pi_e, gamma_e)
    return Pi_k * (1 + pi_e) * (1 + gamma_e)
end

"""
    finance_insolvent_firms!(firms, bank, P_bar_CF, zeta_b,  insolvent)

Rifinance insolvent firms using bank equity.

# Arguments
- `firms`: The `Firms` object containing the firms of the model
- `bank`: The `Bank` object containing the bank of the model
- `P_bar_CF`: Capital price index
- `zeta_b`: Parameter of loan-to-capital ratio for new firms after bankruptcy

# Returns
- This function does not return a value. It modifies the `banks` and `firms` collections in-place.

"""
function finance_insolvent_firms!(firms::AbstractFirms, bank::AbstractBank, model)
    # unpack arguments 
    P_bar_CF, zeta_b = model.agg.P_bar_CF, model.prop.zeta_b

    # find insolvent firms, and re-initialise their variables for the next epoch
    insolvent = findall((firms.D_i .< 0) .&& (firms.E_i .< 0))

    for i in insolvent

        # finance insolvent firm from bank
        bank.E_k = bank.E_k - (firms.L_i[i] - firms.D_i[i] - zeta_b * P_bar_CF * firms.K_i[i])

        # set variables of newly created firm
        firms.E_i[i] = firms.E_i[i] + (firms.L_i[i] - firms.D_i[i] - zeta_b * P_bar_CF * firms.K_i[i])
        firms.L_i[i] = zeta_b * P_bar_CF * firms.K_i[i]
        firms.D_i[i] = 0.0
    end
end

"""
    deposits_bank(bank, w_act, w_inact, firms)

Calculate the new deposits of a bank.

# Arguments
- `bank`: The `Bank` object containing the bank of the model
- `w_act`: The `Workers` object containing the active workers of the model
- `w_inact`: The `Workers` object containing the inactive workers of the model
- `firms`: The `Firms` object containing the firms of the model

# Returns
- `D_k`: New deposits of the bank

The new deposits `D_k` are calculated as the sum of the deposits of the active workers, the inactive workers, the firms,
and the bank owner itself, plus the bank's equity, minus the loans of the firms.

"""
function bank_deposits(bank, model)
    w_act, w_inact, firms = model.w_act, model.w_inact, model.firms
    return _bank_deposits(w_act.D_h, w_inact.D_h, firms.D_h, bank.D_h, firms.D_i, bank.E_k, firms.L_i)
end

"""
    _deposit_bank(waD_h, wiD_h, fD_h, bD_h, fD_i, bE_k, fL_i)

Helper function to calculate the new deposits of a bank.

# Arguments
- `waD_h`: Array of deposits from active workers
- `wiD_h`: Array of deposits from inactive workers
- `fD_h`: Array of deposits from firms
- `bD_h`: Deposits from the bank owner
- `fD_i`: Array of deposits from firms
- `bE_k`: Bank equity
- `fL_i`: Array of loans to firms

# Returns
- `D_k`: New deposits of the bank

The new deposits `D_k` are calculated as the sum of the deposits of the active workers, the inactive workers, the firms,
and the bank owner itself, plus the bank's equity, minus the loans of the firms.
"""
function _bank_deposits(waD_h, wiD_h, fD_h, bD_h, fD_i, bE_k, fL_i)

    tot_D_h = sum(waD_h) + sum(wiD_h) + sum(fD_h) + bD_h

    D_k = sum(fD_i) + tot_D_h + bE_k - sum(fL_i)
    return D_k
end
