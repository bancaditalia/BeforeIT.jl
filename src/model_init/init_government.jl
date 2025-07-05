
"""
    Government(parameters, initial_conditions)

Initialize the government agent.

# Arguments
- `parameters`: The parameters.
- `initial_conditions`: The initial conditions.

# Returns
- The initialized government model.
"""
function Government(parameters, initial_conditions)
    alpha_G = parameters["alpha_G"]
    beta_G = parameters["beta_G"]
    sigma_G = parameters["sigma_G"]
    L_G = initial_conditions["L_G"]
    sb_inact = initial_conditions["sb_inact"]
    sb_other = initial_conditions["sb_other"]
    J = typeInt(parameters["J"])

    C_G = Vector{typeFloat}(vec(initial_conditions["C_G"]))
    T_prime = typeInt(parameters["T_prime"])

    C_d_j = Vector{typeFloat}(zeros(J))
    C_j = zero(typeFloat)
    P_j = zero(typeFloat)
    Y_G = zero(typeFloat)

    return Government(alpha_G, beta_G, sigma_G, Y_G, C_G[T_prime], L_G, sb_inact, sb_other, C_d_j, C_j, P_j)
end