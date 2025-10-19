"""
    growth_expectations(model)

Calculate the expected growth rate of GDP.

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
function growth_inflation_expectations(model::AbstractModel)
    agg = model.agg

    Y, pi_, T_prime, t = model.agg.Y, model.agg.pi_, model.prop.T_prime, model.agg.t

    lY_e = estimate_next_value(log.(Y[1:(T_prime + t - 1)]))
    Y_e = exp(lY_e) # expected GDP
    gamma_e = Y_e / Y[T_prime + t - 1] - 1 # expected growth

    lpi = estimate_next_value(pi_[1:(T_prime + t - 1)])
    pi_e = exp(lpi) - 1 # expected inflation rate

    return Y_e, gamma_e, pi_e
end
function set_growth_inflation_expectations!(model::AbstractModel)
    agg = model.agg
    return agg.Y_e, agg.gamma_e, agg.pi_e = growth_inflation_expectations(model)
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

The GDP `Y_EA`, the growth rate `gamma_EA` and the inflation rate `pi_EA` of the economic area are calculated
as follows:

```math
Y_{EA} = exp(\\alpha_Y \\cdot \\log(Y_{EA}) + \\beta_Y + \\epsilon_{Y_{EA}})
```

```math
\\gamma_{EA} = \\frac{Y_{EA}}{Y_{EA}} - 1
```

```math
\\pi_{EA} = exp(\\alpha_\\pi \\cdot \\log(1 + \\pi_{EA}) + \\beta_\\pi + \\epsilon_{\\pi_{EA}}) - 1
```

where `alpha_Y`, `beta_Y`, `alpha_pi`, `beta_pi`, `epsilon_Y_EA` and `epsilon_pi_EA` are estimated using
the past log-GDP and inflation data using the `estimate` function.
"""
function growth_inflation_EA(model::AbstractModel)
    rotw = model.rotw

    epsilon_Y_EA = model.agg.epsilon_Y_EA
    epsilon_pi_EA = randn() * rotw.sigma_pi_EA

    Y_EA = exp(rotw.alpha_Y_EA * log(rotw.Y_EA) + rotw.beta_Y_EA + epsilon_Y_EA)              # GDP EA
    gamma_EA = Y_EA / rotw.Y_EA - 1                                                           # growth EA
    pi_EA = exp(rotw.alpha_pi_EA * log(1 + rotw.pi_EA) + rotw.beta_pi_EA + epsilon_pi_EA) - 1 # inflation EA

    return Y_EA, gamma_EA, pi_EA
end
function set_growth_inflation_EA!(model::AbstractModel)
    rotw = model.rotw
    return rotw.Y_EA, rotw.gamma_EA, rotw.pi_EA = growth_inflation_EA(model)
end

"""
    inflation_priceindex(model)

Calculate the inflation rate and the global price index.

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

where

- `P_i`: Vector of prices
- `Y_i`: Vector of quantities
- `P_bar`: Global price index
"""
function inflation_priceindex(model)
    firms, agg, prop = model.firms, model.agg, model.prop

    P_i, Y_i, P_bar = firms.P_i, firms.Y_i, model.agg.P_bar

    price_index = sum(P_i .* Y_i) / sum(Y_i)
    inflation = log(price_index / P_bar)

    return inflation, price_index
end
function set_inflation_priceindex!(model)
    agg, prop = model.agg, model.prop
    push!(agg.pi_, 0.0)
    return agg.pi_[prop.T_prime + agg.t], agg.P_bar = inflation_priceindex(model)
end

"""
    sector_specific_priceindex(model)

Calculate the sector-specific price indices.

# Returns
- `vec`: Vector of sector-specific price indices

The sector-specific price index `vec` is calculated as follows:

```math
vec_g = \\frac{\\sum_{i=1}^N P_i \\cdot Y_i}{\\sum_{i=1}^N Y_i}
```
"""
function sector_specific_priceindex(model::AbstractModel)
    firms, rotw = model.firms, model.rotw

    G = model.prop.G
    vec = zeros(typeFloat, G)
    for g in 1:G
        P_i = firms.P_i[firms.G_i .== g]
        Y_i = firms.Q_i[firms.G_i .== g]
        P_m = rotw.P_m[g]
        Q_m = rotw.Q_m[g]
        internal = sum(P_i .* Y_i)
        external = P_m * Q_m
        tot_quantity = sum(Y_i) + Q_m
        vec[g] = (internal + external) / tot_quantity
    end
    return vec
end
function set_sector_specific_priceindex!(model::AbstractModel)
    return model.agg.P_bar_g .= sector_specific_priceindex(model)
end

function capital_formation_priceindex(model::AbstractModel)
    agg, prop = model.agg, model.prop
    return sum(prop.b_CF_g .* agg.P_bar_g)
end
function set_capital_formation_priceindex!(model::AbstractModel)
    return model.agg.P_bar_CF = capital_formation_priceindex(model)
end

function households_priceindex(model::AbstractModel)
    agg, prop = model.agg, model.prop
    return sum(prop.b_HH_g .* agg.P_bar_g)
end
function set_households_priceindex!(model)
    return model.agg.P_bar_HH = households_priceindex(model)
end
