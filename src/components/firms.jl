abstract type FirmComponent <: AbstractComponent end
@component struct PrincipalProduct <: FirmComponent #G_i
    id::IntType
end

@component struct LaborProductivity <: FirmComponent #alpha_bar_i
    value::FloatType
end

@component struct IntermediateProductivity <: FirmComponent #beta_i
    value::FloatType
end

@component struct CapitalProductivity <: FirmComponent #kappa_i
    value::FloatType
end

@component struct CapitalDeprecationRate <: FirmComponent #delta_i
    rate::FloatType
end

@component struct OperatingMargins <: FirmComponent  #pi_bar_i
    rate::FloatType
end

@component struct WageBill <: FirmComponent #w_i
    amount::FloatType
end

@component struct AverageWageRate <: FirmComponent #w_bar_i
    rate::FloatType
end

@component struct OutputTaxRate <: FirmComponent #tau_Y
    rate::FloatType
end

@component struct CapitalTaxRate <: FirmComponent #tau_k
    rate::FloatType
end

@component struct Price <: FirmComponent #P_i
    value::FloatType
end

@component struct PriceIndex <: FirmComponent #P_bar_i
    value::FloatType
end

@component struct CFPriceIndex <: FirmComponent #P_CF_i
    value::FloatType
end

@component struct Employment <: FirmComponent #N_i
    amount::IntType
end

@component struct Vacancies <: FirmComponent #V_i
    amount::IntType
end

@component struct DesiredEmployment <: FirmComponent #N_d_i
    amount::IntType
end

@component struct Output <: FirmComponent #Y_i
    amount::FloatType
end

@component struct Sales <: FirmComponent #Q_i
    amount::FloatType
end

@component struct GoodsDemand <: FirmComponent #Q_d_i
    amount::FloatType
end

@component struct Inventories <: FirmComponent #S_i
    amount::FloatType
end

@component struct Intermediates <: FirmComponent #M_i
    amount::FloatType
end

@component struct Investment <: FirmComponent  #I_i
    amount::FloatType
end

@component struct Equity <: FirmComponent #E_i
    amount::FloatType
end

@component struct FinalGoodsStockChange <: FirmComponent #DS_i
    amount::FloatType
end

@component struct MaterialsStockChange <: FirmComponent #DM_i
    amount::FloatType
end

@component struct TargetLoans <: FirmComponent #DL_d_i
    amount::FloatType
end

@component struct ExpectedCapital <: FirmComponent #K_e_i
    amount::FloatType
end

@component struct ExpectedLoans <: FirmComponent #L_e_i
    amount::FloatType
end

@component struct ExpectedSales <: FirmComponent #Q_s_i
    amount::FloatType
end

@component struct DesiredInvestment <: FirmComponent #I_d_i
    amount::FloatType
end

@component struct DesiredMaterials <: FirmComponent #DM_d_i
    amount::FloatType
end

@component struct Owner <: Ark.Relationship
end

@component struct Capitalist <: FirmComponent end
@component struct Firm <: FirmComponent end
