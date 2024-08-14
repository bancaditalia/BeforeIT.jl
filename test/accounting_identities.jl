using BeforeIT, MAT, FileIO, Random
using Test

@testset "accounting identities" begin
    dir = @__DIR__

    parameters = BeforeIT.AUSTRIA2010Q1.parameters
    initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions

    T = 1
    model = BeforeIT.init_model(parameters, initial_conditions, T)
    data = BeforeIT.init_data(model)

    for t in 1:T
        BeforeIT.one_epoch!(model; multi_threading = false)
        BeforeIT.update_data!(data, model)
    end

    # income accounting and production accounting should be equal
    zero = sum(data.nominal_gva - data.compensation_employees - data.operating_surplus - data.taxes_production)
    @test isapprox(zero, 0.0, atol = 1e-8)

    # compare nominal_gdp to total expenditure
    zero = sum(
        data.nominal_gdp - data.nominal_household_consumption - data.nominal_government_consumption -
        data.nominal_capitalformation - data.nominal_exports + data.nominal_imports,
    )
    @test isapprox(zero, 0.0, atol = 1e-8)

    zero = sum(
        data.real_gdp - data.real_household_consumption - data.real_government_consumption -
        data.real_capitalformation - data.real_exports + data.real_imports,
    )    
    @test isapprox(zero, 0.0, atol = 1e-8)

    # accounting identity of balance sheet of central bank
    zero = model.cb.E_CB + model.rotw.D_RoW - model.gov.L_G + model.bank.D_k
    @test isapprox(zero, 0.0, atol = 1e-8)

    # accounting identity of balance sheet of commercial bank
    tot_D_h = sum(model.w_act.D_h) + sum(model.w_inact.D_h) + sum(model.firms.D_h) + model.bank.D_h
    zero = sum(model.firms.D_i) + tot_D_h + sum(model.bank.E_k) - sum(model.firms.L_i) - model.bank.D_k
    @test isapprox(zero, 0.0, atol = 1e-8)
end
