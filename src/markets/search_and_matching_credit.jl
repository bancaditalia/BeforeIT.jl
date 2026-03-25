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
        bank_firms = model.banks.firms[bank_id]
        DL_d_i = [f.DL_d_i for f in bank_firms if f.DL_d_i > 0]
        K_e_i = [f.K_e_i for f in bank_firms if f.DL_d_i > 0]
        L_e_i = [f.L_e_i for f in bank_firms if f.DL_d_i > 0]
        f_id = [f.ID for f in bank_firms if f.DL_d_i > 0]
        E_k = model.banks.E_k[bank_id]

        s_DL = zero(typeFloat)
        s_L_e = sum(L_e_i)
        #I_FG = findall(DL_d_i .> 0)
        I_FG = collect(1:length(DL_d_i))
        fshuffle!(I_FG)
        for i in I_FG
            DL_i_p = DL_i[f_id[i]]
            DL_i[f_id[i]] = max(0.0, min(DL_d_i[i], zeta_LTV * K_e_i[i] - L_e_i[i], E_k / zeta - s_L_e - s_DL))
            s_DL += (DL_i[f_id[i]] - DL_i_p)
        end
    end
    return firms.DL_i .= DL_i # actual new loans obtained
end
