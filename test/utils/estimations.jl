
import BeforeIT as Bit

using Random

@testset "estimation functions" begin
    dir = @__DIR__

    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.Model(parameters, initial_conditions)

    Y, T_prime = model.agg.Y, model.prop.T_prime

    Random.seed!(123)

    model.agg.t = 1

    Y_e, gamma_e, pi_e = Bit.growth_inflation_expectations(model)
    Y_e_matlab_single_run, pi_e_matlab_single_run = 136263.963578048, 0.0120934296669606

    @test isapprox(Y_e, Y_e_matlab_single_run, rtol = 0.1)
    @test isapprox(pi_e, pi_e_matlab_single_run, atol = 0.1)

    r_bar = collect(Float64, 1:10)
    pi_EA = collect(Float64, 5:15)
    gamma_EA = collect(Float64, 10:20)

    rho_e = 0.733333333333333
    r_star_e = 0.001240732893301
    xi_pi_e = 1.250000000000001
    xi_gamma_e = -0.250000000000001
    pi_star_e = 0.004962931573204


    rho, r_star, xi_pi, xi_gamma, pi_star = Bit.estimate_taylor_rule(r_bar, pi_EA, gamma_EA)

    @test isapprox(rho, rho_e, rtol = 1e-5)
    @test isapprox(r_star, r_star_e, rtol = 1e-5)
    @test isapprox(xi_pi, xi_pi_e, rtol = 1e-5)
    @test isapprox(xi_gamma, xi_gamma_e, rtol = 1e-5)
    @test isapprox(pi_star, pi_star_e, rtol = 1e-5)
end
