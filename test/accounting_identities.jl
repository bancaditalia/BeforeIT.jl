
import BeforeIT as Bit

using Random
using Test

@testset "accounting identities" begin
    dir = @__DIR__

    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

    T = 1
    model = Bit.Model(parameters, initial_conditions)
    for t in 1:T
        Bit.step!(model; multi_threading = false)
        Bit.update_data!(model)
    end

    # income accounting and production accounting should be equal
    zero = sum(model.data.nominal_gva - model.data.compensation_employees - model.data.operating_surplus - model.data.taxes_production)
    @test isapprox(zero, 0.0, atol = 1e-8)

    # compare nominal_gdp to total expenditure
    zero = sum(
        model.data.nominal_gdp - model.data.nominal_household_consumption - model.data.nominal_government_consumption -
        model.data.nominal_capitalformation - model.data.nominal_exports + model.data.nominal_imports,
    )
    @test isapprox(zero, 0.0, atol = 1e-8)

    zero = sum(
        model.data.real_gdp - model.data.real_household_consumption - model.data.real_government_consumption -
        model.data.real_capitalformation - model.data.real_exports + model.data.real_imports,
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
