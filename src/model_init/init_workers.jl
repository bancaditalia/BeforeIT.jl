"""
    Workers(parameters, initial_conditions)

Initialize the workers for the given parameters, initial conditions.

# Arguments
- `parameters`: The parameters for the initialization.
- `initial_conditions`: The initial conditions for the initialization.

# Returns
- The initialized active workers.
- The initialized inactive workers.
"""
function Workers(parameters, initial_conditions)

    H_act = Int(parameters["H_act"])
    H_inact = Int(parameters["H_inact"])
    I = Int(sum(parameters["I_s"]))
    theta_UB = parameters["theta_UB"]
    tau_SIW = parameters["tau_SIW"]
    tau_INC = parameters["tau_INC"]

    sb_other = initial_conditions["sb_other"]
    sb_inact = initial_conditions["sb_inact"]
    w_UB = initial_conditions["w_UB"]
    D_H = initial_conditions["D_H"]
    K_H = initial_conditions["K_H"]

    H_W = H_act - I - 1
    P_bar_HH = one(typeFloat)
    w_h = zeros(typeFloat, H_W)
    O_h = zeros(typeInt, H_W)

    w_h[O_h .== 0] .= w_UB / theta_UB

    Y_h = zeros(typeFloat, H_W)
    D_h = zeros(typeFloat, H_W)
    K_h = zeros(typeFloat, H_W)
    C_d_h = zeros(typeFloat, H_W)
    I_d_h = zeros(typeFloat, H_W)
    C_h = zeros(typeFloat, H_W)
    I_h = zeros(typeFloat, H_W)

    # active workers (both employed and unemployed)
    id_to_index = Dict{Int, Int}(id => id for id in 1:H_W)
    lastid = Ref(H_W)
    workers_act = Workers(lastid, id_to_index, Y_h, D_h, K_h, w_h, O_h, C_d_h, I_d_h, C_h, I_h)

    # inactive workers
    Y_h = zeros(typeFloat, H_inact)
    for h in 1:H_inact
        Y_h[h] = (sb_inact + sb_other) * P_bar_HH
    end
    D_h = D_H * Y_h #/ sum(Y_h)
    K_h = K_H * Y_h #/ sum(Y_h)

    w_h_inact = zeros(typeFloat, H_inact)
    O_h_inact = -ones(typeInt, H_inact)
    C_d_h = zeros(typeFloat, H_inact)
    I_d_h = zeros(typeFloat, H_inact)
    C_h = zeros(typeFloat, H_inact)
    I_h = zeros(typeFloat, H_inact)

    id_to_index = Dict{Int, Int}(id => id for id in 1:H_inact)
    lastid = Ref(H_inact)
    workers_inact = Workers(lastid, id_to_index, Y_h, D_h, K_h, w_h_inact, O_h_inact, C_d_h, I_d_h, C_h, I_h)

    return workers_act, workers_inact
end
