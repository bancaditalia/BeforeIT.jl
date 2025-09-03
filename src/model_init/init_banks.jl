"""
    Bank(parameters, initial_conditions)

Initialize a bank with the given parameters and initial conditions.

# Arguments
- `parameters`: The parameters.
- `initial_conditions`: The initial conditions.

# Returns
- bank::Bank: The initialized bank.
"""
function Bank(parameters, initial_conditions)

    theta_DIV = parameters["theta_DIV"]
    tau_INC = parameters["tau_INC"]
    tau_FIRM = parameters["tau_FIRM"]
    mu = parameters["mu"]
    D_H = initial_conditions["D_H"]
    K_H = initial_conditions["K_H"]

    E_k = initial_conditions["E_k"]
    r_bar = initial_conditions["r_bar"]
    sb_other = initial_conditions["sb_other"]

    P_bar_HH = one(typeFloat)

    r = r_bar + mu

    Pi_k = typeFloat(0.0)
    Y_h = typeFloat(0.0)
    D_h = typeFloat(0.0)
    K_h = typeFloat(0.0)
    D_k = typeFloat(0.0)

    C_d_h = zero(typeFloat)
    I_d_h = zero(typeFloat)
    C_h = zero(typeFloat)
    I_h = zero(typeFloat)
    Pi_e_k = typeFloat(0.0)

    return Bank(E_k, Pi_k, Pi_e_k, D_k, r, Y_h, C_d_h, I_d_h, C_h, I_h, K_h, D_h)
end

"""
    CentralBank(parameters, initial_conditions)

Initialize the central bank with the given parameters and initial conditions.

# Arguments
- `parameters`: The parameters.
- `initial_conditions`: The initial conditions.

# Returns
- central_bank::CentralBank: The initialized central bank.
"""
function CentralBank(parameters, initial_conditions)
    r_bar = initial_conditions["r_bar"]
    r_G = parameters["r_G"]
    rho = parameters["rho"]
    r_star = parameters["r_star"]
    pi_star = parameters["pi_star"]
    xi_pi = parameters["xi_pi"]
    xi_gamma = parameters["xi_gamma"]
    E_CB = initial_conditions["E_CB"]

    cb_args = (r_bar, r_G, rho, r_star, pi_star, xi_pi, xi_gamma, E_CB)
    central_bank = CentralBank(cb_args...)

    return central_bank
end
