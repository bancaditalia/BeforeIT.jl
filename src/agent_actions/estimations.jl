
"""
    growth_expectations(model)

Calculate the expected growth rate of GDP.

# Arguments
- `model`: Model object

# Returns
- `Y_e`: Expected GDP
- `gamma_e`: Expected growth rate of GDP
- `pi_e`: Expected inflation rate

The expected GDP `Y_e` and the expected growth rate `gamma_e` are calculated as follows:

```math
Y_e = exp(\\alpha_Y \\cdot \\log(Y_{T^\\prime + t - 1}) + \\beta_Y + \\epsilon_Y)
```

```math
\\gamma_e = \\frac{Y_e}{Y_{T^\\prime + t - 1}} - 1
```

where `alpha_Y`, `beta_Y` and `epsilon_Y` are estimated using the past log-GDP data using the `estimate` function.

The expected inflation rate `pi_e` is calculated as follows:

```math
\\pi_e = exp(\\alpha_\\pi \\cdot \\pi_{T^\\prime + t - 1} + \\beta_\\pi + \\epsilon_\\pi) - 1
```
"""
function growth_inflation_expectations(model)
    # unpack arguments
    Y = model.agg.Y
    pi = model.agg.pi_
    T_prime = model.prop.T_prime
    t = model.agg.t

    lY_e = estimate_next_value(log.(Y[1:(T_prime + t - 1)]))
    Y_e = exp(lY_e)                # expected GDP
    gamma_e = Y_e / Y[T_prime + t - 1] - 1                   # expected growth

    lpi = estimate_next_value(pi[1:(T_prime + t - 1)])
    pi_e = exp(lpi) - 1                                      # expected inflation rate
    return Y_e, gamma_e, pi_e
end

"""
    growth_inflation_EA(rotw, epsilon_Y_EA)

Update the growth and inflation of the economic area.

# Arguments
- `rotw`: A RestOfTheWorld object
- `epsilon_Y_EA`: Random shock to GDP

# Returns
- `Y_EA`: GDP of the economic area
- `gamma_EA`: Growth rate of GDP of the economic area
- `pi_EA`: Inflation rate of the economic area

The GDP `Y_EA`, the growth rate `gamma_EA` and the inflation rate `pi_EA` of the economic area are calculated as follows:

```math
Y_{EA} = exp(\\alpha_Y \\cdot \\log(Y_{EA}) + \\beta_Y + \\epsilon_{Y_{EA}})
```

```math
\\gamma_{EA} = \\frac{Y_{EA}}{Y_{EA}} - 1
```

```math
\\pi_{EA} = exp(\\alpha_\\pi \\cdot \\log(1 + \\pi_{EA}) + \\beta_\\pi + \\epsilon_{\\pi_{EA}}) - 1
```

where `alpha_Y`, `beta_Y`, `alpha_pi`, `beta_pi`, `epsilon_Y_EA` and `epsilon_pi_EA` are estimated using the past log-GDP and inflation data using the `estimate` function.

"""
function growth_inflation_EA(rotw::AbstractRestOfTheWorld, model)
    # unpack model variables
    epsilon_Y_EA = model.agg.epsilon_Y_EA

    Y_EA = exp(rotw.alpha_Y_EA * log(rotw.Y_EA) + rotw.beta_Y_EA + epsilon_Y_EA) # GDP EA
    gamma_EA = Y_EA / rotw.Y_EA - 1                                              # growht EA
    epsilon_pi_EA = randn() * rotw.sigma_pi_EA
    pi_EA = exp(rotw.alpha_pi_EA * log(1 + rotw.pi_EA) + rotw.beta_pi_EA + epsilon_pi_EA) - 1   # inflation EA
    return Y_EA, gamma_EA, pi_EA
end

# compute inflation and global price index
"""
    inflation_priceindex(P_i, Y_i, P_bar)

Calculate the inflation rate and the global price index.

# Arguments
- `P_i`: Vector of prices
- `Y_i`: Vector of quantities
- `P_bar`: Global price index

# Returns
- `inflation`: Inflation rate
- `price_index`: Global price index

The inflation rate `inflation` and the global price index `price_index` are calculated as follows:

```math
inflation = \\log(\\frac{\\sum_{i=1}^N P_i \\cdot Y_i}{\\sum_{i=1}^N Y_i \\cdot P_{bar}})
```

```math
price_index = \\frac{\\sum_{i=1}^N P_i \\cdot Y_i}{\\sum_{i=1}^N Y_i}
```
"""
function inflation_priceindex(P_i, Y_i, P_bar)
    price_index = mapreduce(x -> x[1] * x[2], +, zip(P_i, Y_i)) / sum(Y_i)
    inflation = log(price_index / P_bar)
    return inflation, price_index
end

# compute sector-specific price index
"""
    sector_specific_priceindex(firms, rotw, G)

Calculate the sector-specific price indices.

# Arguments
- `firms`: A Firms object
- `rotw`: A RestOfTheWorld object
- `G`: Number of sectors

# Returns
- `vec`: Vector of sector-specific price indices

The sector-specific price index `vec` is calculated as follows:

```math
vec_g = \\frac{\\sum_{i=1}^N P_i \\cdot Y_i}{\\sum_{i=1}^N Y_i}
```
"""
function sector_specific_priceindex(firms::AbstractFirms, rotw::AbstractRestOfTheWorld, G::Int)
    vec = zeros(G)
    for g in 1:G
        vec[g] = _sector_specific_priceindex(
            firms.P_i[firms.G_i .== g],
            firms.Q_i[firms.G_i .== g],
            rotw.P_m[g],
            rotw.Q_m[g],
        )
        # internal = sum(firms.P_i[firms.G_i.==g] .* firms.Q_i[firms.G_i.==g])
        # external = rotw.P_m[g] * rotw.Q_m[g]
        # tot_quantity = sum(firms.Q_i[firms.G_i.==g]) + rotw.Q_m[g]
        # vec[g] = (internal + external) / tot_quantity
    end
    return vec
end

function _sector_specific_priceindex(P_i, Y_i, P_m, Q_m)
    internal = mapreduce(x -> x[1] * x[2], +, zip(P_i, Y_i))
    external = P_m * Q_m
    tot_quantity = sum(Y_i) + Q_m
    return (internal + external) / tot_quantity
end
