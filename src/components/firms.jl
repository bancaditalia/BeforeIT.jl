abstract type FirmComponent <: AbstractComponent end
@component struct PrincipalProduct <: FirmComponent #G_i
    id::Int64
end

@component struct LaborProductivity <: FirmComponent #alpha_bar_i
    value::Float64
end

@component struct IntermediateProductivity <: FirmComponent #beta_i
    value::Float64
end

@component struct CapitalProductivity <: FirmComponent #kappa_i
    value::Float64
end

@component struct CapitalDeprecationRate <: FirmComponent #delta_i
    rate::Float64
end

@component struct OperatingMargins <: FirmComponent  #pi_bar_i
    rate::Float64
end

@component struct WageBill <: FirmComponent #w_i
    amount::Float64
end

@component struct AverageWageRate <: FirmComponent #w_bar_i
    rate::Float64
end

@component struct OutputTaxRate <: FirmComponent #tau_Y
    rate::Float64
end

@component struct CapitalTaxRate <: FirmComponent #tau_k
    rate::Float64
end

@component struct Price <: FirmComponent #P_i
    value::Float64
end

@component struct PriceIndex <: FirmComponent #P_bar_i
    value::Float64
end

@component struct CFPriceIndex <: FirmComponent #P_CF_i
    value::Float64
end

@component struct Employment <: FirmComponent #N_i
    amount::Int
end

@component struct Vacancies <: FirmComponent #V_i
    amount::Int
end

@component struct DesiredEmployment <: FirmComponent #N_d_i
    amount::Int
end

@component struct Output <: FirmComponent #Y_i
    amount::Float64
end

@component struct Sales <: FirmComponent #Q_i
    amount::Float64
end

@component struct GoodsDemand <: FirmComponent #Q_d_i
    amount::Float64
end

@component struct Inventories <: FirmComponent #S_i
    amount::Float64
end

@component struct Intermediates <: FirmComponent #M_i
    amount::Float64
end

@component struct Investment <: FirmComponent  #I_i
    amount::Float64
end

@component struct Equity <: FirmComponent #E_i
    amount::Float64
end

@component struct FinalGoodsStockChange <: FirmComponent #DS_i
    amount::Float64
end

@component struct MaterialsStockChange <: FirmComponent #DM_i
    amount::Float64
end

@component struct TargetLoans <: FirmComponent #DL_d_i
    amount::Float64
end

@component struct ExpectedCapital <: FirmComponent #K_e_i
    amount::Float64
end

@component struct ExpectedLoans <: FirmComponent #L_e_i
    amount::Float64
end

@component struct ExpectedSales <: FirmComponent #Q_s_i
    amount::Float64
end

@component struct DesiredInvestment <: FirmComponent #I_d_i
    amount::Float64
end

@component struct DesiredMaterials <: FirmComponent #DM_d_i
    amount::Float64
end

@component struct Owner <: Ark.Relationship
end

@component struct Capitalist <: FirmComponent end
