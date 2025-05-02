
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

function forecast_k_steps_VAR(data, n_forecasts; intercept = false, lags = 1, stochastic = false)
    """
    
    forecast_k_steps_VAR(data, k; intercept = false, lags = 1)

    Forecasts the next `k` steps of a Vector Autoregression (VAR) model.

    # Arguments
    - `data::Matrix{Float64}`: The input time series data, where rows represent time steps and columns represent variables.
    - `k::Int`: The number of steps to forecast.
    - `intercept::Bool`: Whether to include an intercept in the VAR model. Default is `false`.
    - `lags::Int`: The number of lags to include in the VAR model. Default is `1`.

    # Returns
    - `forecasted_values::Matrix{Float64}`: A matrix containing the forecasted values for the next `k` steps.

    # Example
    ```julia
    N = 500  # Number of time steps
    p = 2  # Number of lags
    alpha = [0.9 -0.2; 0.5 -0.1]  # Coefficient matrix (2 variables, 1 lag)
    alpha = [0.9 -0.2 0.1 0.05; # Coefficient matrix   (2 variables, 2 lags)
            0.5 -0.1 0.2 -0.3]
    beta = [0.1, -0.2]  # Intercept vector
    sigma = [0.1 0.05; 0.05 0.1]  # Covariance matrix for the noise
    timeseries = generate_var_timeseries(N, p, alpha, beta, sigma)
    alpha_hat, beta_hat, epsilon_hat = BIT.estimate_VAR(timeseries, intercept = false, lags = p)
    # Run the forecast function
    forecast = BIT.forecast_k_steps_VAR(timeseries, 10, intercept = true, lags = p)
    """

    forecasted_values = Matrix{Float64}(undef, 0, size(data, 2))
    
    alpha, beta, epsilon, sigma = estimate_VAR(data; intercept = intercept , lags = lags)

    alpha = dropdims(alpha, dims = tuple(findall(size(alpha) .== 1)...))

    if lags > 1
        alpha = reshape(alpha,  size(data,2), lags *size(data,2))
    end

    if length(alpha) == 1
        alpha = only(alpha)
    end

    if !stochastic
        epsilon .=0
    end
    
    
    for i in 1:n_forecasts

        if stochastic
            epsilon = zeros(size(data, 2))
            for i = 1:size(data, 2)
                epsilon[i] = rand(Normal(0, sqrt(sigma[i, i])))
            end 
        end

        if lags ==1
            if intercept
                next_value = alpha * data[end,:] .+ beta .+ epsilon
            else
                next_value = alpha * data[end,:] .+ epsilon
            end
        else
            if intercept
                next_value = alpha * vec(data[end:-1:end-lags+1,:]') .+ beta .+ epsilon
            else
                next_value = alpha * vec(data[end:-1:end-lags+1,:]') .+ epsilon
            end
        end
        forecasted_values = vcat(forecasted_values, next_value')
        data = vcat(data, next_value')
    end

    return forecasted_values
end

function forecast_k_steps_VARX(data, exogenous, n_forecasts; intercept = false, lags = 1, stochastic = false)
    """
    
    forecast_k_steps_VARX(data, k; intercept = false, lags = 1)

    Forecasts the next `k` steps of a Vector Autoregression with exogenous predictors (VARX) model.

    # Arguments
    - `data::Matrix{Float64}`: The input time series data, where rows represent time steps and columns represent variables.
    - `exogenous::Matrix{Float64}`: The exogenous time series data, where rows represent time steps and columns represent variables.
    - `k::Int`: The number of steps to forecast.
    - `intercept::Bool`: Whether to include an intercept in the VAR model. Default is `false`.
    - `lags::Int`: The number of lags to include in the VAR model. Default is `1`.

    # Returns
    - `forecasted_values::Matrix{Float64}`: A matrix containing the forecasted values for the next `k` steps.
    """

    alpha, beta, gamma, epsilon, sigma = estimate_VARX(data, exogenous[2:size(data,1)+1,:]; intercept = intercept , lags = lags)

    alpha = dropdims(alpha, dims = tuple(findall(size(alpha) .== 1)...))

    if lags > 1
        alpha = reshape(alpha,  size(data,2), lags *size(data,2))
    end

    if length(alpha) == 1
        alpha = only(alpha)
    end

    if !stochastic
        epsilon .=0
    end

    forecasted_values = Matrix{Float64}(undef, 0, size(data, 2))
    
    for i in 1:n_forecasts
        
        if stochastic
            epsilon = zeros(size(data, 2))
            for i = 1:size(data, 2)
                epsilon[i] = rand(Normal(0, sqrt(sigma[i, i])))
            end 
        end

        if lags ==1
            if intercept
                next_value = alpha * data[end,:] .+ gamma * exogenous[end - n_forecasts + i ,:] .+ beta .+ epsilon
            else
                next_value = alpha * data[end,:] .+ gamma * exogenous[end - n_forecasts + i ,:] .+ epsilon
            end
        else
            if intercept
                next_value = alpha * vec(data[end:-1:end-lags+1,:]') .+ gamma * exogenous[end - n_forecasts + i ,:] .+ beta .+ epsilon
            else
                next_value = alpha * vec(data[end:-1:end-lags+1,:]') .+ gamma * exogenous[end - n_forecasts + i ,:] .+ epsilon
            end
        end
        forecasted_values = vcat(forecasted_values, next_value')
        data = vcat(data, next_value')
    end

    return forecasted_values
end

function estimate_VAR(ydata::Union{Matrix{Float64}, Vector{Float64}}; intercept = false, lags = 1)    
    if typeof(ydata) == Vector{Float64}
        ydata = ydata[:, :]
    end

    if intercept
        var = rfvar3(ydata, lags, ones(size(ydata, 1), 1))
    else
        var = rfvar3(ydata, lags,Array{Float64}(undef, size(ydata, 1), 0))
    end
    
    alpha = var.By
    beta = var.Bx
    sigma = cov(var.u)

    epsilon = zeros(size(ydata, 2))
    for i = 1:size(ydata, 2)
        epsilon[i] = rand(Normal(0, sqrt(sigma[i, i])))
    end 

    return alpha, beta, epsilon, sigma, var.u
end

function estimate_VARX(ydata::Union{Matrix{Float64}, Vector{Float64}}, xdata::Union{Matrix{Float64}, Vector{Float64}}; intercept = false, lags = 1)    

    if typeof(ydata) == Vector{Float64}
        ydata = ydata[:, :]
    end
    if typeof(xdata) == Vector{Float64}
        xdata = xdata[:, :]
    end

    if intercept
        xdata = hcat(ones(size(xdata, 1), 1), xdata)
    end
        
    var = rfvar3(ydata, lags, xdata)
    
    
    alpha = var.By
    beta = var.Bx[:,1]
    gamma = var.Bx[:,2:end]
    sigma = cov(var.u)

    epsilon = zeros(size(ydata, 2))
    for i = 1:size(ydata, 2)
        epsilon[i] = rand(Normal(0, sqrt(sigma[i, i])))
    end 

    return alpha, beta, gamma, epsilon, sigma, var.u
end
