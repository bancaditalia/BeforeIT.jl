import BeforeIT as Bit
using Test, JLD2, StatsBase

@testset "hpfilter" begin
    y = [1.0, 3.0, 2.0, 5.0, 4.0, 7.0, 6.0, 9.0]
    trend, cycle = Bit.hpfilter(y)
    # trend and cycle decompose the series exactly
    @test trend .+ cycle ≈ y
    # the HP filter reproduces a linear trend, leaving (almost) no cycle
    _, linear_cycle = Bit.hpfilter(collect(1.0:20.0))
    @test all(abs.(linear_cycle) .< 1.0e-6)
end

@testset "auto/cross correlation" begin
    x = collect(1.0:30.0) .+ sin.(1:30)
    y = collect(1.0:30.0)

    # lag-0 autocorrelation is 1, result has one entry per lag
    @test Bit.auto_correlation(x, 0:5)[1] ≈ 1.0
    @test length(Bit.auto_correlation(x, 0:5)) == 6

    # cross-correlation requires equal lengths and spans -L:L
    @test_throws ErrorException Bit.cross_correlation(x, y[1:(end - 1)], 3)
    @test length(Bit.cross_correlation(x, y, 5)) == 11

    # self cross-correlation: symmetric about lag 0, and its non-negative
    # half equals the autocorrelation (pins both functions together)
    L = 5
    xc = Bit.cross_correlation(x, x, L)
    @test xc[L + 1] ≈ 1.0
    @test xc[(L + 1):end] ≈ Bit.auto_correlation(x, 0:L)
    @test xc[1:L] ≈ reverse(xc[(L + 2):end])
end

@testset "primitives do not shadow StatsBase" begin
    # `crosscor`/`autocor` must remain StatsBase's; ours are `*_correlation`
    @test parentmodule(Bit.crosscor) === StatsBase
    @test parentmodule(Bit.autocor) === StatsBase
end

@testset "correlation_stats (in-memory)" begin
    L, H, T = 5, 8, 60
    gdp = collect(1.0:T) .+ sin.(1:T)

    # empirical-style data: one vector per variable -> a single sample column
    real_data = Dict("real_gdp_quarterly" => gdp, "wages_quarterly" => gdp .+ 0.3 .* cos.(1:T))
    rs = Bit.correlation_stats(real_data, ["wages_quarterly"]; correlation_lags = L, autocorr_lags = H)
    @test rs.variables == ["wages_quarterly"]
    @test size(rs.crosscor["wages_quarterly"]) == (2L + 1, 1)
    @test size(rs.autocor["wages_quarterly"]) == (H + 1, 1)
    @test length(rs.volatility["wages_quarterly"]) == 1
    # accessors return per-lag vectors; for one sample the mean is that column
    @test length(Bit.mean_crosscor(rs, "wages_quarterly")) == 2L + 1
    @test Bit.mean_crosscor(rs, "wages_quarterly") ≈ vec(rs.crosscor["wages_quarterly"])

    # simulation-style data: time × n_sims matrices -> one sample column per sim
    n_sims = 3
    sims = Dict(
        "real_gdp_quarterly" => repeat(gdp, 1, n_sims),
        "wages_quarterly" => repeat(gdp .+ 0.3 .* cos.(1:T), 1, n_sims),
    )
    ss = Bit.correlation_stats(sims, ["wages_quarterly"]; correlation_lags = L, autocorr_lags = H)
    @test size(ss.crosscor["wages_quarterly"]) == (2L + 1, n_sims)
    @test length(ss.volatility["wages_quarterly"]) == n_sims

    # GDP correlated with itself peaks at 1 at lag 0
    gs = Bit.correlation_stats(real_data, ["real_gdp_quarterly"]; correlation_lags = L, autocorr_lags = H)
    @test Bit.mean_crosscor(gs, "real_gdp_quarterly")[L + 1] ≈ 1.0

    # variables that are absent or have a mismatched sample count are skipped
    mismatched = Dict("real_gdp_quarterly" => repeat(gdp, 1, 2), "wages_quarterly" => gdp)
    ms = Bit.correlation_stats(mismatched, ["wages_quarterly", "missing_var"]; correlation_lags = L, autocorr_lags = H)
    @test ms.variables == String[]
end

@testset "correlation_stats (folder merge)" begin
    L, H, T, n_sims = 5, 8, 60, 2
    gdp = collect(1.0:T) .+ sin.(1:T)

    folder = mktempdir()
    for yq in ("2010Q1", "2010Q2")
        predictions_dict = Dict(
            "real_gdp_quarterly" => repeat(gdp, 1, n_sims),
            "wages_quarterly" => repeat(gdp .+ 0.3 .* cos.(1:T), 1, n_sims),
        )
        save(joinpath(folder, "$(yq).jld2"), "predictions_dict", predictions_dict)
    end

    stats = Bit.correlation_stats(folder, ["wages_quarterly"]; correlation_lags = L, autocorr_lags = H)
    # samples from both files are concatenated: 2 files × n_sims
    @test size(stats.crosscor["wages_quarterly"]) == (2L + 1, 2 * n_sims)
    @test length(stats.volatility["wages_quarterly"]) == 2 * n_sims
end
