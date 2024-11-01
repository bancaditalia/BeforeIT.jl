

"""
    search_and_matching_credit(firms::Firms, model)

This function calculates the credit allocation for each firm in the given firms object.

Parameters:
- firms::Firms: The firms object.
- model: The model object.

Returns:
- DL_i: An array of credit allocations for each firm.
"""
function search_and_matching_credit(firms::AbstractFirms, model)

    # unpack arguments
    DL_d_i, K_e_i, L_e_i = firms.DL_d_i, firms.K_e_i, firms.L_e_i
    E_k, zeta, zeta_LTV = model.bank.E_k, model.prop.zeta, model.prop.zeta_LTV

    DL_i = zeros(size(DL_d_i))
    I_FG = findall(DL_d_i .> 0)
    # I_FG = I_FG[randperm(length(I_FG))]
    shuffle!(I_FG)
    for f in eachindex(I_FG)
        i = I_FG[f]
        DL_i[i] = max(0, min(min(DL_d_i[i], zeta_LTV * K_e_i[i] - L_e_i[i]), E_k / zeta - (sum(L_e_i) + sum(DL_i))))
    end
    return DL_i
end
