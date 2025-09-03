"""
    rotw_import_export(rotw, model)

Calculate the demand for exports and supply of imports of the rest of the world.

# Arguments
- `rotw`: The rest of the world object.
- `model`: The model object.

# Returns
- `C_E`: Total demand for exports.
- `Y_I`: Supply of imports (in real terms).
- `C_d_l`: TDemand for exports of specific product.
- `Y_m`: Supply of imports per sector.
- `P_m`: Price of imports per sector.
"""
function rotw_import_export(rotw, model)
    # unpack
    c_E_g, c_I_g, P_bar_g, pi_e = model.prop.c_E_g, model.prop.c_I_g, model.agg.P_bar_g, model.agg.pi_e
    epsilon_E, epsilon_I = model.agg.epsilon_E, model.agg.epsilon_I

    # compute demand for export
    L = length(rotw.C_d_l)
    C_E = exp.(rotw.alpha_E * log(rotw.C_E) + rotw.beta_E + epsilon_E)
    C_d_l = C_E ./ L .* ones(L) .* sum(c_E_g .* P_bar_g) .* (1 + pi_e)

    # compute supply of imports
    Y_I = exp(rotw.alpha_I * log(rotw.Y_I) + rotw.beta_I .+ epsilon_I)
    Y_m = c_I_g * Y_I
    P_m = P_bar_g * (1 + pi_e)

    return C_E, Y_I, C_d_l, Y_m, P_m
end

"""
    rotw_deposits(rotw, model)

Calculate the deposits of the rest of the world.

# Arguments
- `rotw`: The rest of the world object.
- `model`: The model object.

# Returns
- `D_RoW`: The deposits of the rest of the world.

The deposits `D_RoW` are calculated as follows:

```math
D_{RoW} = D_{RoW} + \\left( \\sum_{m} P_m \\cdot Q_m \\right) - (1 + \\tau_{EXPORT}) \\cdot C_l
```
"""
function rotw_deposits(rotw, model)
    tau_EXPORT = model.prop.tau_EXPORT
    DD_RoW = sum(rotw.P_m .* rotw.Q_m) - (1 + tau_EXPORT) * rotw.C_l
    D_RoW = rotw.D_RoW + DD_RoW
    return D_RoW
end
