
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