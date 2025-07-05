
import BeforeIT as Bit

using Test, Random, MAT

@testset "nfvar3" begin
    xxi = [[0.2000, -0.5000] [-0.5000, 1.5000]]
    u = [0, 0, 0, 0]

    y = Matrix{Float64}([1.0; 2.0; 3.0; 4.0; 5.0][:, :])
    var_ = Bit.rfvar3(y, 1, ones(size(y, 1), 1))

    @test isapprox(var_.Bx[1, 1], 1.0)
    @test isapprox(var_.By[1], 1.0)
    @test isapprox(var_.xxi, xxi)
    @test isapprox(var_.u, u; atol = 1e-14)
end

@testset "estimate" begin
    dir = @__DIR__

    init_conds = Bit.AUSTRIA2010Q1.initial_conditions#matopen(joinpath(dir, "../data/austria/initial_conditions/2010Q1.mat"))

    Y = init_conds["Y"]

    Random.seed!(123)
    alpha, beta, epsilon_ = Bit.estimate(log.(Y))

    @test isapprox(alpha, 0.971001709000414)
    @test isapprox(beta, 0.344659199612863)
    @test isapprox(epsilon_, -0.00415932810164292)

    Random.seed!(123)
    Yvec = vec(Y)
    alpha, beta, epsilon_ = Bit.estimate(log.(Yvec))
    @test isapprox(alpha, 0.971001709000414)
    @test isapprox(beta, 0.344659199612863)
    @test isapprox(epsilon_, -0.00415932810164292)

    dummy_series = [
        9.567778424837963
        9.574191416943812
        9.580605059126121
        9.588931171444848
        9.600311304740346
        9.604640931220233
        9.613107726219265
        9.618230372010803
        9.626726085704139
        9.642208926006326
        9.641763844732605
        9.649690917106851
    ]

    alpha_e = 0.984009645632709
    beta_e = 0.161039024858073
    sigma_e = 0.004012824377165
    epsilon_e = [
        -0.001633865231344
        -0.001530669138557
        0.000484357409141
        0.003671515872391
        -0.003197018579078
        0.001009382201758
        -0.002199379953346
        0.001255600869955
        0.008378576951367
        -0.007301768521497
        0.001063268119180
    ]

    alpha, beta, sigma, epsilon_ = Bit.estimate_for_calibration_script(dummy_series)

    @test isapprox(alpha, alpha_e)
    @test isapprox(beta, beta_e)
    @test isapprox(sigma, sigma_e)
    @test isapprox(epsilon_, epsilon_e)
end
