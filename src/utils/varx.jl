
"""
    forecast_k_steps_VAR(data, n_forecasts; intercept = false, lags = 1)

Forecasts the next `n_forecasts` steps of a Vector Autoregression (VAR) model.

# Arguments
- `data::Matrix{Float64}`: The input time series data, where rows represent time steps and columns represent variables.
- `n_forecasts::Int`: The number of steps to forecast.
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
```
"""
function _prepare_alpha(alpha, n_vars, lags)
    prepared_alpha = dropdims(alpha, dims = tuple(findall(size(alpha) .== 1)...))
    lags > 1 && (prepared_alpha = reshape(prepared_alpha, n_vars, lags * n_vars))
    length(prepared_alpha) == 1 && (prepared_alpha = only(prepared_alpha))
    return prepared_alpha
end

function _get_lagged_data(data, lags)
    if lags == 1
        return data[end, :]
    else
        return vec(data[end:-1:(end - lags + 1), :]')
    end
end

function _generate_stochastic_epsilon(n_vars, sigma)
    epsilon = zeros(n_vars)
    for i in 1:n_vars
        epsilon[i] = rand(Normal(0, sqrt(sigma[i, i])))
    end
    return epsilon
end

function forecast_k_steps_VAR(data, n_forecasts; intercept = false, lags = 1,
        stochastic = false)
    forecasted_values = Matrix{Float64}(undef, 0, size(data, 2))
    current_data = copy(data)

    alpha, beta, sigma, _ = estimate_VAR(current_data; intercept = intercept, lags = lags)
    alpha = _prepare_alpha(alpha, size(current_data, 2), lags)

    for i in 1:n_forecasts
        epsilon = stochastic ? _generate_stochastic_epsilon(size(current_data, 2), sigma) :
                  zeros(size(current_data, 2))
        lagged_data = _get_lagged_data(current_data, lags)

        next_value = alpha * lagged_data .+ epsilon
        intercept && (next_value .+= beta)

        forecasted_values = vcat(forecasted_values, next_value')
        current_data = vcat(current_data, next_value')
    end

    return forecasted_values
end

"""
    forecast_k_steps_VARX(data, n_forecasts; intercept = false, lags = 1)

Forecasts the next `n_forecasts` steps of a Vector Autoregression with exogenous predictors (VARX) model.

# Arguments
- `data::Matrix{Float64}`: The input time series data, where rows represent time steps and columns represent variables.
- `exogenous::Matrix{Float64}`: The exogenous time series data, where rows represent time steps and columns represent variables.
- `n_forecasts::Int`: The number of steps to forecast.
- `intercept::Bool`: Whether to include an intercept in the VAR model. Default is `false`.
- `lags::Int`: The number of lags to include in the VAR model. Default is `1`.

# Returns
- `forecasted_values::Matrix{Float64}`: A matrix containing the forecasted values for the next `n_forecasts` steps.
"""
function forecast_k_steps_VARX(data, exogenous, n_forecasts; intercept = false, lags = 1,
        stochastic = false)
    forecasted_values = Matrix{Float64}(undef, 0, size(data, 2))
    current_data = copy(data)

    alpha, beta, gamma, sigma, _ = estimate_VARX(current_data,
        exogenous[2:(size(current_data, 1) + 1),
            :];
        intercept = intercept, lags = lags)
    alpha = _prepare_alpha(alpha, size(current_data, 2), lags)

    for i in 1:n_forecasts
        epsilon = stochastic ? _generate_stochastic_epsilon(size(current_data, 2), sigma) :
                  zeros(size(current_data, 2))
        lagged_data = _get_lagged_data(current_data, lags)
        exogenous_term = gamma * exogenous[end - n_forecasts + i, :]

        next_value = alpha * lagged_data .+ exogenous_term .+ epsilon
        intercept && (next_value .+= beta)

        forecasted_values = vcat(forecasted_values, next_value')
        current_data = vcat(current_data, next_value')
    end

    return forecasted_values
end

function estimate_VAR(ydata::Union{Matrix{Float64}, Vector{Float64}}; intercept = false,
        lags = 1)
    if typeof(ydata) == Vector{Float64}
        ydata = ydata[:, :]
    end

    if intercept
        var = rfvar3(ydata, lags, ones(size(ydata, 1), 1))
    else
        var = rfvar3(ydata, lags, Array{Float64}(undef, size(ydata, 1), 0))
    end

    alpha = var.By
    beta = var.Bx
    sigma = cov(var.u)

    return alpha, beta, sigma, var.u
end

function estimate_VARX(ydata::Union{Matrix{Float64}, Vector{Float64}},
        xdata::Union{Matrix{Float64}, Vector{Float64}}; intercept = false,
        lags = 1)
    typeof(ydata) == Vector{Float64} && (ydata = ydata[:, :])
    typeof(xdata) == Vector{Float64} && (xdata = xdata[:, :])
    intercept && (xdata = hcat(ones(size(xdata, 1), 1), xdata))

    var = rfvar3(ydata, lags, xdata)
    alpha = var.By
    beta = var.Bx[:, 1]
    gamma = var.Bx[:, 2:end]
    sigma = cov(var.u)

    return alpha, beta, gamma, sigma, var.u
end
