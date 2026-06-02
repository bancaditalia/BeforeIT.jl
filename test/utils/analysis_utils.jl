import BeforeIT as Bit
using Test

@testset "growth_rate" begin
    # simple doubling each step -> 100% growth
    @test Bit.growth_rate([1.0, 2.0, 4.0]) ≈ [1.0, 1.0]
    # works along an explicit dimension for matrices
    m = [1.0 10.0; 2.0 20.0; 4.0 40.0]
    @test Bit.growth_rate(m; dims = 1) ≈ [1.0 1.0; 1.0 1.0]
    # handles negative values (the log-based version could not)
    @test Bit.growth_rate([-1.0, -2.0]) ≈ [1.0]
    # a zero denominator is replaced by eps() rather than producing Inf
    @test all(isfinite, Bit.growth_rate([0.0, 1.0]))
end

@testset "bias_ttest" begin
    # zero-mean errors -> t-statistic ~ 0, large p-value
    errors = Float64[0.1, -0.1, 0.1, -0.1, 0.1, -0.1]
    t, p = Bit.bias_ttest(errors, 1)
    @test abs(t) < 1.0e-8
    @test p ≈ 1.0
    # strongly biased errors -> small p-value
    _, p_biased = Bit.bias_ttest(fill(1.0, 20) .+ Float64[0.01 * (-1)^i for i in 1:20], 1)
    @test p_biased < 0.05
    # falls back to short-run variance when the HAC estimate is negative
    @test Bit.bias_ttest(Float64[1.0, -1.0, 1.0, -1.0], 2) isa Tuple
    # short samples (n <= h) must not error on the autocovariance lags
    @test Bit.bias_ttest(Float64[0.5, -0.5], 12) isa Tuple
    # fewer than two observations returns NaN rather than throwing
    @test all(isnan, Bit.bias_ttest(Float64[0.3], 1))
end

@testset "stars / rmse_improvement" begin
    @test Bit.stars(0.005) == "***"
    @test Bit.stars(0.02) == "**"
    @test Bit.stars(0.07) == "*"
    @test Bit.stars(0.5) == ""
    # improvement is positive when rmse1 < rmse2 (lower error is better)
    @test Bit.rmse_improvement([1.0 2.0], [2.0 2.0]) ≈ [50.0 0.0]
end

@testset "model variant folder names" begin
    # the pipeline names variant folders after the model struct (no registration needed)
    @test string(nameof(Bit.Model)) == "Model"
    @test string(nameof(Bit.ModelGR)) == "ModelGR"
    @test string(nameof(Bit.ModelCANVAS)) == "ModelCANVAS"
end

@testset "discover_countries" begin
    # missing folder yields no countries rather than erroring
    @test Bit.discover_countries(folder = "/tmp/__beforeit_nonexistent__") == String[]
end
