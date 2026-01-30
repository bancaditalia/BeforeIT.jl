using LinearAlgebra, Random, Distributions

function estimate_next_value(data, type = nothing)
    alpha, beta, epsilon = estimate(data)
    return alpha * data[end] + beta + epsilon
end

function estimate(ydata::Union{Matrix, Vector})
    if typeof(ydata) <: Vector
        ydata = ydata[:, :]
    end
    var = rfvar3(ydata, 1, ones(size(ydata, 1), 1))
    alpha = var.By[1]
    beta = var.Bx[1]
    epsilon = rand(Normal(0, sqrt(cov(var.u))[1, 1]))
    return alpha, beta, epsilon
end

function estimate_for_calibration_script(ydata::Union{Matrix, Vector})
    if typeof(ydata) <: Vector
        ydata = ydata[:, :]
    end
    var = rfvar3(ydata, 1, ones(size(ydata, 1), 1))
    alpha = var.By[1]
    beta = var.Bx[1]
    sigma = sqrt(cov(var.u))[1, 1]
    epsilon = var.u
    return alpha, beta, sigma, epsilon
end

# function estimate_with_predictors(ydata::Union{Matrix{Float64}, Vector{Float64}}, exo::Matrix)

#     if typeof(ydata) == Vector{Float64}
#         ydata = ydata[:, :]
#     end

#     var = rfvar3(ydata, 1, [ones(size(ydata, 1)), exo[1:length(ydata), :]])
#     alpha = var.By[1]
#     beta = var.Bx[1]
#     gamma_1 = var.Bx[2]
#     gamma_2 = var.Bx[3]
#     gamma_3 = var.Bx[4]
#     epsilon = rand(Normal(0, sqrt(cov(var.u))))
#     return alpha, beta, gamma_1, gamma_2, gamma_3, epsilon
# end

function estimate_taylor_rule(
        r_bar::Union{Matrix, Vector},
        pi_EA::Vector,
        gamma_EA::Vector,
    )
    ydata = r_bar
    if typeof(ydata) <: Vector
        ydata = ydata[:, :]
    end

    exo = [pi_EA gamma_EA]
    var = rfvar3(ydata, 1, exo[1:length(ydata), :])
    alpha = var.By[1]
    gamma_1 = var.Bx[1]
    gamma_2 = var.Bx[2]

    rho = alpha
    xi_pi = gamma_1 ./ (1 .- rho)
    xi_gamma = gamma_2 ./ (1 .- rho)
    pi_star = (0.02 + 1)^(1 / 4) - 1
    r_star = pi_star .* (xi_pi .- 1)

    return rho, r_star, xi_pi, xi_gamma, pi_star
end
