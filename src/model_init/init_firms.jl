
"""
    Firms(parameters, initial_conditions)

Initialize firms with given parameters and initial conditions.

# Arguments
- `parameters`: The parameters for initializing the firms.
- `initial_conditions`: The initial conditions for the firms.

# Returns
- firms::Firms: The initialized firms.
"""
function Firms(parameters, initial_conditions)

    # unpacking useful parameters
    I_s = Vector{typeInt}(vec(parameters["I_s"]))
    I = Int(sum(parameters["I_s"])) # number of firms
    G = Int(parameters["G"])
    tau_SIF = parameters["tau_SIF"]
    mu = parameters["mu"]
    theta_DIV = parameters["theta_DIV"]
    tau_INC = parameters["tau_INC"]
    tau_FIRM = parameters["tau_FIRM"]

    sb_other = initial_conditions["sb_other"]
    r_bar = initial_conditions["r_bar"]
    D_I = initial_conditions["D_I"]
    L_I = initial_conditions["L_I"]
    omega = initial_conditions["omega"]
    N_s = round.(Int, initial_conditions["N_s"])
    r_bar = initial_conditions["r_bar"]
    D_H = initial_conditions["D_H"]
    K_H = initial_conditions["K_H"]

    P_bar_HH = one(typeFloat)

    # computation of parameters for each firm
    alpha_bar_i = zeros(typeFloat, I)
    beta_i = zeros(typeFloat, I)
    kappa_i = zeros(typeFloat, I)
    w_bar_i = zeros(typeFloat, I)
    delta_i = zeros(typeFloat, I)
    tau_Y_i = zeros(typeFloat, I)
    tau_K_i = zeros(typeFloat, I)

    G_i = zeros(typeInt, I)
    for g in 1:G
        i = Int(sum(parameters["I_s"][1:(g - 1)]))
        j = Int(parameters["I_s"][g])
        G_i[(i + 1):(i + j)] .= typeInt(g)
    end

    for i in 1:I
        g = typeInt(G_i[i])
        alpha_bar_i[i] = parameters["alpha_s"][g]
        beta_i[i] = parameters["beta_s"][g]
        kappa_i[i] = parameters["kappa_s"][g]
        delta_i[i] = parameters["delta_s"][g]
        w_bar_i[i] = parameters["w_s"][g]
        tau_Y_i[i] = parameters["tau_Y_s"][g]
        tau_K_i[i] = parameters["tau_K_s"][g]
    end

    N_i = zeros(typeInt, I)
    for g in 1:G
        N_i[G_i .== g] .= randpl(I_s[g], 2.0, N_s[g])
    end

    Y_i = alpha_bar_i .* N_i
    Q_d_i = copy(Y_i)
    P_i = ones(typeFloat, I)
    S_i = zeros(typeFloat, I)
    K_i = Y_i ./ (omega .* kappa_i)
    M_i = Y_i ./ (omega .* beta_i)
    L_i = L_I .* K_i / sum(K_i)

    pi_bar_i = 1 .- (1 + tau_SIF) .* w_bar_i ./ alpha_bar_i .- delta_i ./ kappa_i .-
               1 ./ beta_i .- tau_K_i .- tau_Y_i
    D_i = D_I .* max.(0, pi_bar_i .* Y_i) / sum(max.(0, pi_bar_i .* Y_i))

    r = r_bar + mu
    Pi_i = pi_bar_i .* Y_i - r .* L_i + r_bar .* max.(0, D_i)

    V_i = copy(N_i)

    Y_h = zeros(typeFloat, I)
    for i in 1:I
        Y_h[i] = theta_DIV * (1 - tau_INC) * (1 - tau_FIRM) * max(0, Pi_i[i]) +
                 sb_other * P_bar_HH
    end

    # firms
    w_i = zeros(typeFloat, I) # initial wages, dummy variable for now, really initialised at runtime
    I_i = zeros(typeFloat, I) # initial investments, dummy variable for now, set at runtime
    Q_i = zeros(typeFloat, I) # goods sold, dummy variable for now, set at runtime
    E_i = zeros(typeFloat, I) # equity, dummy variable for now, set at runtime
    C_d_h = zeros(typeFloat, I)
    I_d_h = zeros(typeFloat, I)

    C_h = zeros(typeFloat, I)
    I_h = zeros(typeFloat, I)
    P_bar_i = zeros(typeFloat, I)
    P_CF_i = zeros(typeFloat, I)
    DS_i = zeros(typeFloat, I)
    DM_i = zeros(typeFloat, I)

    K_h = K_H * Y_h # TODO: K_h[(H_W + H_inact + 1):(H_W + H_inact + I)]
    D_h = D_H * Y_h # TODO: D_h[(H_W + H_inact + 1):(H_W + H_inact + I)]

    # additional tracking variables initialised to zero
    DL_i = zeros(typeFloat, I)
    DL_d_i = zeros(typeFloat, I)
    K_e_i = zeros(typeFloat, I)
    L_e_i = zeros(typeFloat, I)
    Q_s_i = zeros(typeFloat, I)
    I_d_i = zeros(typeFloat, I)
    DM_d_i = zeros(typeFloat, I)
    N_d_i = zeros(typeInt, I)
    Pi_e_i = zeros(typeFloat, I)

    return Firms(G_i, alpha_bar_i, beta_i, kappa_i, w_i, w_bar_i,
                 delta_i, tau_Y_i, tau_K_i, N_i, Y_i, Q_i, Q_d_i,
                 P_i, S_i, K_i, M_i, L_i, pi_bar_i, D_i, Pi_i, V_i,
                 I_i, E_i, P_bar_i, P_CF_i, DS_i, DM_i, DL_i,
                 DL_d_i, K_e_i, L_e_i, Q_s_i, I_d_i, DM_d_i, N_d_i,
                 Pi_e_i, Y_h, C_d_h, I_d_h, C_h, I_h, K_h, D_h)
end
