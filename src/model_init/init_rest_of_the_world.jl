"""
    RestOfTheWorld(parameters, initial_conditions)

Initialize the rest of the world (rotw) agent.

# Arguments
- `parameters`: The parameters.
- `initial_conditions`: The initial conditions.

# Returns
- rotw::RestOfTheWorld: The initialized rest of the world agent.
"""
function RestOfTheWorld(parameters, initial_conditions)
    L = Int(parameters["L"])
    G = Int(parameters["G"])
    alpha_E = parameters["alpha_E"]
    beta_E = parameters["beta_E"]
    sigma_E = parameters["sigma_E"]
    alpha_I = parameters["alpha_I"]
    beta_I = parameters["beta_I"]
    sigma_I = parameters["sigma_I"]

    alpha_pi_EA = parameters["alpha_pi_EA"]
    beta_pi_EA = parameters["beta_pi_EA"]
    sigma_pi_EA = parameters["sigma_pi_EA"]
    alpha_Y_EA = parameters["alpha_Y_EA"]
    beta_Y_EA = parameters["beta_Y_EA"]
    sigma_Y_EA = parameters["sigma_Y_EA"]
    T_prime = Int(parameters["T_prime"])

    Y_EA = initial_conditions["Y_EA"]
    gamma_EA = typeFloat(0.0)
    pi_EA = initial_conditions["pi_EA"]
    D_RoW = typeFloat(initial_conditions["D_RoW"])
    Y_I = Vector{typeFloat}(vec(initial_conditions["Y_I"]))
    C_E = Vector{typeFloat}(vec(initial_conditions["C_E"]))

    C_d_l = zeros(typeFloat, L)
    C_l = zero(typeFloat)
    P_l = zero(typeFloat)
    Y_m = zeros(typeFloat, G)
    Q_m = zeros(typeFloat, G)
    Q_d_m = zeros(typeFloat, G)
    P_m = zeros(typeFloat, G)

    return RestOfTheWorld(
        alpha_E, beta_E, sigma_E, alpha_I, beta_I, sigma_I, Y_EA, gamma_EA,
        pi_EA, alpha_pi_EA, beta_pi_EA, sigma_pi_EA, alpha_Y_EA, beta_Y_EA, sigma_Y_EA, D_RoW,
        Y_I[T_prime], C_E[T_prime], C_d_l, C_l, Y_m, Q_m, Q_d_m, P_m, P_l
    )
end
