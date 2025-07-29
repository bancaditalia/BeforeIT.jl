
"""
    Aggregates(parameters, initial_conditions)

Initialize aggregates for the model.

# Arguments
- `parameters`: The model parameters.
- `initial_conditions`: The initial conditions.

# Returns
- `agg`: The initialized aggregates.
"""
function Aggregates(parameters, initial_conditions)
    Y = Vector{typeFloat}(vec(initial_conditions["Y"]))
    pi_ = Vector{typeFloat}(vec(initial_conditions["pi"]))

    G = Int(parameters["G"])

    P_bar = one(typeFloat)
    P_bar_g = ones(typeFloat, G)
    P_bar_HH = one(typeFloat)
    P_bar_CF = one(typeFloat)

    P_bar_h = zero(typeFloat)
    P_bar_CF_h = zero(typeFloat)
    t = typeInt(1)
    Y_e = zero(typeFloat)
    gamma_e = zero(typeFloat)
    pi_e = zero(typeFloat)
    epsilon_Y_EA = zero(typeFloat)
    epsilon_E = zero(typeFloat)
    epsilon_I = zero(typeFloat)

    return Aggregates(Y, pi_, P_bar, P_bar_g, P_bar_HH, P_bar_CF, P_bar_h, P_bar_CF_h, Y_e,
                      gamma_e, pi_e, epsilon_Y_EA, epsilon_E, epsilon_I, t)
end
