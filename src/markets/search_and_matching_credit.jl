
"""
    search_and_matching_credit(firms::Firms, model)

This function calculates the credit allocation for each firm in the given firms object.

Parameters:
- firms::Firms: The firms object.
- model: The model object.

Returns:
- DL_i: An array of credit allocations for each firm.
"""
function search_and_matching_credit(firms::AbstractFirms, model::AbstractModel)

    # unpack arguments
    DL_d_i, K_e_i, L_e_i = firms.DL_d_i, firms.K_e_i, firms.L_e_i
    E_k, zeta, zeta_LTV = model.bank.E_k, model.prop.zeta, model.prop.zeta_LTV

    DL_i = zeros(typeFloat, size(DL_d_i))
    sum_DL_i = sum(DL_i)
    I_FG = findall(DL_d_i .> 0)
    fshuffle!(I_FG)
    s_L_e_i = sum(L_e_i)
    for i in I_FG
        DL_i_p = DL_i[i]
        DL_i[i] = max(0.0,
                      min(DL_d_i[i], zeta_LTV * K_e_i[i] - L_e_i[i],
                          E_k / zeta - s_L_e_i - sum_DL_i))
        sum_DL_i += (DL_i[i] - DL_i_p)
    end
    return DL_i
end
