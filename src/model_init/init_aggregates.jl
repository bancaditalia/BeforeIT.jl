
"""
    Aggregates(parameters, initial_conditions, T)

Initialize aggregates for the model.

# Arguments
- `parameters`: The model parameters.
- `initial_conditions`: The initial conditions.
- `T`: The total simulation time.

# Returns
- `agg`: The initialized aggregates.
"""
function Aggregates(parameters, initial_conditions, T; typeInt = Int64, typeFloat = Float64)
    
    Y = initial_conditions["Y"]
    pi_ = initial_conditions["pi"]
    Y = Vector{typeFloat}(vec(vcat(Y, zeros(typeFloat, T))))
    pi_ = Vector{typeFloat}(vec(vcat(pi_, zeros(typeFloat, T))))

    G = typeInt(parameters["G"])

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

    agg_args = (
        Y,
        pi_,
        P_bar,
        P_bar_g,
        P_bar_HH,
        P_bar_CF,
        P_bar_h,
        P_bar_CF_h,
        Y_e,
        gamma_e,
        pi_e,
        epsilon_Y_EA,
        epsilon_E,
        epsilon_I,
        t,
    )

    agg = Aggregates(agg_args...)

    return agg
end