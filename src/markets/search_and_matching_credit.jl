"""
    search_and_matching_credit!(firms::Firms, model)

This function calculates the credit allocation for each firm in the given firms object.

Parameters:
- firms::Firms: The firms object.
- model: The model object.

Returns:
- DL_i: An array of credit allocations for each firm.
"""
function search_and_matching_credit!(model::AbstractModel)
    firms = model.firms
    zeta, zeta_LTV = model.prop.zeta, model.prop.zeta_LTV

    DL_i = zeros(typeFloat, size(firms.DL_i))
    for bank_id in eachbank(model)
        DL_d_i = [firms.DL_d_i[i] for i in eachfirm(model) if firms.B_i[i] == bank_id]
        K_e_i = [firms.K_e_i[i] for i in eachfirm(model) if firms.B_i[i] == bank_id]
        L_e_i = [firms.L_e_i[i] for i in eachfirm(model) if firms.B_i[i] == bank_id]
        E_k = model.banks.E_k[bank_id]

        s_DL = zero(typeFloat)
        s_L_e = sum(L_e_i)
        I_FG = findall(DL_d_i .> 0)
        fshuffle!(I_FG)
        for i in I_FG
            DL_i_p = DL_i[i]
            DL_i[i] = max(0.0, min(DL_d_i[i], zeta_LTV * K_e_i[i] - L_e_i[i], E_k / zeta - s_L_e - s_DL))
            s_DL += (DL_i[i] - DL_i_p)
        end
    end
    return firms.DL_i .= DL_i # actual new loans obtained
end
