import BeforeIT as Bit

using Random
using Test

@testset "accounting identities" begin
    dir = @__DIR__

    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

    T = 3
    model = Bit.Model(parameters, initial_conditions)
    n_banks = length(model.banks)
    L_i_per_bank = Vector{Vector{Float64}}()
    push!(L_i_per_bank, [sum(f.L_i for f in model.banks.firms[k]; init = 0.0) for k in 1:n_banks])
    for t in 1:T
        Bit.step!(model; parallel = false)
        Bit.collect_data!(model)
        push!(L_i_per_bank, [sum(f.L_i for f in model.banks.firms[k]; init = 0.0) for k in 1:n_banks])
    end

    # income accounting and production accounting should be equal
    zero = sum(model.data.nominal_gva - model.data.compensation_employees - model.data.operating_surplus - model.data.taxes_production)
    @test isapprox(zero, 0.0, atol = 1.0e-8)

    # compare nominal_gdp to total expenditure
    zero = sum(
        model.data.nominal_gdp - model.data.nominal_household_consumption - model.data.nominal_government_consumption -
            model.data.nominal_capitalformation - model.data.nominal_exports + model.data.nominal_imports,
    )
    @test isapprox(zero, 0.0, atol = 1.0e-8)

    zero = sum(
        model.data.real_gdp - model.data.real_household_consumption - model.data.real_government_consumption -
            model.data.real_capitalformation - model.data.real_exports + model.data.real_imports,
    )
    @test isapprox(zero, 0.0, atol = 1.0e-8)

    # accounting identity of balance sheet of central bank
    zero = model.cb.E_CB + model.rotw.D_RoW - model.gov.L_G + sum(model.banks.D_k)
    @test isapprox(zero, 0.0, atol = 1.0e-8)

    # accounting identity of balance sheet of all banks
    banks = model.banks
    zero = fill(0.0, n_banks)
    for bank_id in 1:n_banks
        L_i = Bit.typeFloat[f.L_i for f in banks.firms[bank_id]]
        D_i = Bit.typeFloat[f.D_i for f in banks.firms[bank_id]]
        D_h_firms = Bit.typeFloat[f.D_h for f in banks.firms[bank_id]]
        D_h_act = Bit.typeFloat[w.D_h for w in banks.w_act[bank_id]]
        D_h_inact = Bit.typeFloat[w.D_h for w in banks.w_inact[bank_id]]
        D_h = [D_h_act; D_h_inact; D_h_firms; banks.D_h[bank_id]]
        zero[bank_id] = sum(D_i) + sum(D_h) + banks.E_k[bank_id] - sum(L_i) - banks.D_k[bank_id]
    end
    @test isapprox(zero, fill(0.0, n_banks), atol = 1.0e-8)

    # credit_stock_per_bank should equal sum of L_i for all firms of that bank
    for t in 1:(T + 1)
        for bank_id in 1:n_banks
            @test isapprox(model.data.credit_stock_per_bank[t][bank_id], L_i_per_bank[t][bank_id], atol = 1.0e-8)
        end
    end
end

@testset "bank initialisation invariant to N_banks" begin
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    reference = nothing
    for n_banks in (1, 2, 5)
        parameters = copy(Bit.AUSTRIA2010Q1.parameters)
        parameters["N_banks"] = n_banks
        Random.seed!(1234)
        model = Bit.Model(parameters, initial_conditions)
        @test length(model.banks) == n_banks

        # splitting the sector into more banks must not create or destroy equity,
        # initial profits or deposits
        aggregates = (sum(model.banks.E_k), sum(model.banks.Pi_k), sum(model.banks.D_k))
        if isnothing(reference)
            reference = aggregates
        else
            @test all(isapprox.(aggregates, reference; rtol = 1.0e-10))
        end
    end
end
