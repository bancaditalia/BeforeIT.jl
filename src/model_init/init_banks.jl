"""
    Banks(parameters, initial_conditions)

Initialize a bank with the given parameters and initial conditions.

# Arguments
- `parameters`: The parameters.
- `initial_conditions`: The initial conditions.

# Returns
- bank::Bank: The initialized bank.
"""
function Banks(parameters, initial_conditions)

    # unpacking useful parameters
    B = get(parameters, "n_banks", 1) # default to 1 if not provided

    theta_DIV = parameters["theta_DIV"]
    tau_INC = parameters["tau_INC"]
    tau_FIRM = parameters["tau_FIRM"]
    mu = parameters["mu"]
    D_H = initial_conditions["D_H"] / B
    K_H = initial_conditions["K_H"] / B

    E_k = initial_conditions["E_k"] / B
    E_k = fill(E_k, B)
    r_bar = initial_conditions["r_bar"]
    sb_other = initial_conditions["sb_other"]

    P_bar_HH = one(typeFloat)

    r = r_bar + mu
    r = fill(r, B)

    Pi_k = zeros(typeFloat, B)
    Y_h = zeros(typeFloat, B)
    D_h = zeros(typeFloat, B)
    K_h = zeros(typeFloat, B)
    D_k = zeros(typeFloat, B)

    C_d_h = zeros(typeFloat, B)
    I_d_h = zeros(typeFloat, B)
    C_h = zeros(typeFloat, B)
    I_h = zeros(typeFloat, B)
    Pi_e_k = zeros(typeFloat, B)

    id_to_index = Dict{Int, Int}()
    index_to_id = collect(1:Int(B))
    lastid = Ref(Int(B))
    del = Ref(false)

    firms = [Agent{Firms}[] for _ in 1:B]
    w_act = [Agent{Workers}[] for _ in 1:B]
    w_inact = [Agent{Workers}[] for _ in 1:B]

    return Banks(
        del, lastid, id_to_index, index_to_id,
        E_k, Pi_k, Pi_e_k, D_k, r, Y_h, C_d_h, I_d_h, C_h, I_h, K_h, D_h,
        firms, w_act, w_inact
    )
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
